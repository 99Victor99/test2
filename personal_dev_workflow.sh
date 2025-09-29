#!/bin/bash

# 个人开发工作流 - 多人协作场景
# 支持：私有分支 -> dev分支 -> 测试环境发版

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# 获取当前用户名（用于分支命名）
get_username() {
    git config user.name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr ' ' '-' || echo "dev"
}

# 获取当前分支
get_current_branch() {
    git branch --show-current
}

# 检查是否在 git 仓库中
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是 git 仓库"
        exit 1
    fi
}

# 更新本地 dev 分支
update_dev_branch() {
    log_step "更新本地 dev 分支..."
    
    local current_branch=$(get_current_branch)
    
    # 切换到 dev 分支并拉取最新代码
    git checkout dev
    git pull origin dev
    
    # 更新 submodules
    git submodule update --remote --merge
    
    # 切换回原分支
    if [ "$current_branch" != "dev" ] && [ -n "$current_branch" ]; then
        git checkout "$current_branch"
    fi
    
    log_success "dev 分支已更新"
}

# 创建个人功能分支
create_feature_branch() {
    local feature_name=$1
    local username=$(get_username)
    local branch_name="feature/${username}/${feature_name}"
    
    if [ -z "$feature_name" ]; then
        log_error "请提供功能名称"
        echo "用法: $0 start <feature-name>"
        exit 1
    fi
    
    log_step "创建个人功能分支: $branch_name"
    
    # 确保基于最新的 dev 分支
    update_dev_branch
    git checkout dev
    
    # 创建并切换到功能分支
    git checkout -b "$branch_name"
    
    log_success "功能分支创建完成: $branch_name"
    echo ""
    log_info "接下来可以进行开发:"
    echo "  1. 修改 proto/users/users.proto"
    echo "  2. 修改业务代码"
    echo "  3. 运行 $0 commit \"提交信息\""
    echo "  4. 完成后运行 $0 merge"
}

# 个人分支提交
personal_commit() {
    local commit_msg="$1"
    
    if [ -z "$commit_msg" ]; then
        log_error "请提供提交信息"
        echo "用法: $0 commit \"提交信息\""
        exit 1
    fi
    
    local current_branch=$(get_current_branch)
    if [[ ! "$current_branch" =~ ^feature/ ]]; then
        log_error "当前不在功能分支上，当前分支: $current_branch"
        exit 1
    fi
    
    log_step "在个人分支提交更改..."
    
    # 检查 proto 语法（如果修改了 proto）
    if git diff --name-only HEAD | grep -q "\.proto$"; then
        log_info "检测到 proto 文件修改，验证语法..."
        if command -v protoc >/dev/null 2>&1; then
            find . -name "*.proto" -exec protoc --descriptor_set_out=/dev/null {} \;
            log_success "proto 语法验证通过"
        else
            log_warning "未安装 protoc，跳过 proto 语法验证"
        fi
    fi
    
    # 生成代码（如果修改了 proto）
    if git diff --name-only HEAD | grep -q "proto/.*\.proto$"; then
        log_info "重新生成 proto 代码..."
        if [ -f "Makefile" ] && grep -q "proto-gen\|dev" Makefile; then
            make dev 2>/dev/null || make proto-gen 2>/dev/null || {
                log_warning "无法通过 Makefile 生成代码，尝试直接使用 protoc"
                if command -v protoc >/dev/null 2>&1; then
                    mkdir -p api/users
                    protoc --go_out=api/users --go_opt=paths=source_relative \
                           --go-grpc_out=api/users --go-grpc_opt=paths=source_relative \
                           proto/users/users.proto 2>/dev/null || true
                fi
            }
        fi
    fi
    
    # 运行测试
    log_info "运行测试..."
    if [ -f "go.mod" ]; then
        go test ./... -v || {
            log_error "测试失败，请修复后重试"
            exit 1
        }
    fi
    
    # 提交更改
    git add .
    git commit -m "feat: $commit_msg

Branch: $current_branch
Author: $(git config user.name) <$(git config user.email)>"
    
    log_success "提交完成: $commit_msg"
}

# 合并到 dev 分支
merge_to_dev() {
    local current_branch=$(get_current_branch)
    
    if [[ ! "$current_branch" =~ ^feature/ ]]; then
        log_error "当前不在功能分支上，无法合并"
        exit 1
    fi
    
    log_step "将功能分支合并到 dev..."
    
    # 更新 dev 分支
    update_dev_branch
    
    # 推送当前功能分支
    log_info "推送功能分支到远程..."
    git push origin "$current_branch"
    
    # 切换到 dev 并合并
    git checkout dev
    git merge "$current_branch" --no-ff -m "Merge $current_branch into dev

Features added:
- $(git log --oneline "$current_branch" ^dev | head -5 | sed 's/^[a-f0-9]* /- /')

Author: $(git config user.name)"
    
    # 推送 dev 分支
    git push origin dev
    
    log_success "功能已合并到 dev 分支"
    
    # 询问是否删除功能分支
    echo ""
    read -p "是否删除本地功能分支 $current_branch？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -d "$current_branch"
        git push origin --delete "$current_branch" 2>/dev/null || true
        log_success "功能分支已删除"
    fi
    
    # 通知运维
    echo ""
    log_warning "📢 通知运维部署测试环境:"
    echo "  消息模板:"
    echo "  「dev 分支已更新，请部署测试环境」"
    echo "  - 功能: $commit_msg"
    echo "  - 分支: dev"
    echo "  - 提交: $(git rev-parse --short HEAD)"
    echo "  - 开发者: $(git config user.name)"
}

# 同步 dev 分支最新代码到个人分支
sync_with_dev() {
    local current_branch=$(get_current_branch)
    
    if [[ ! "$current_branch" =~ ^feature/ ]]; then
        log_error "当前不在功能分支上"
        exit 1
    fi
    
    log_step "同步 dev 分支最新代码..."
    
    # 更新 dev 分支
    update_dev_branch
    
    # 合并 dev 到当前分支
    git merge dev --no-ff -m "Sync with dev branch

Merged latest changes from dev into $current_branch"
    
    log_success "已同步 dev 分支最新代码"
}

# 查看个人分支状态
show_status() {
    local current_branch=$(get_current_branch)
    
    echo "=== 个人开发状态 ==="
    echo ""
    log_info "当前分支: $current_branch"
    log_info "用户信息: $(git config user.name) <$(git config user.email)>"
    
    # 显示工作区状态
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "工作区有未提交的更改:"
        git status --short
    else
        log_success "工作区干净"
    fi
    
    # 显示个人分支
    echo ""
    log_info "个人功能分支:"
    local username=$(get_username)
    git branch | grep "feature/${username}/" | sed 's/^/  /' || echo "  无个人分支"
    
    # 显示与 dev 分支的差异
    if [[ "$current_branch" =~ ^feature/ ]]; then
        echo ""
        log_info "与 dev 分支的差异:"
        local ahead=$(git rev-list --count dev.."$current_branch" 2>/dev/null || echo "0")
        local behind=$(git rev-list --count "$current_branch"..dev 2>/dev/null || echo "0")
        echo "  领先 dev: $ahead 个提交"
        echo "  落后 dev: $behind 个提交"
        
        if [ "$behind" -gt 0 ]; then
            log_warning "建议运行 '$0 sync' 同步最新代码"
        fi
    fi
}

# 主函数
main() {
    check_git_repo
    
    case "${1:-status}" in
        "start")
            create_feature_branch "$2"
            ;;
        "commit")
            personal_commit "$2"
            ;;
        "merge")
            merge_to_dev
            ;;
        "sync")
            sync_with_dev
            ;;
        "status"|"")
            show_status
            ;;
        "update")
            update_dev_branch
            ;;
        *)
            echo "个人开发工作流工具"
            echo ""
            echo "用法:"
            echo "  $0 start <feature-name>    - 创建个人功能分支"
            echo "  $0 commit \"提交信息\"      - 在个人分支提交"
            echo "  $0 sync                    - 同步 dev 最新代码"
            echo "  $0 merge                   - 合并到 dev 分支"
            echo "  $0 update                  - 更新本地 dev 分支"
            echo "  $0 status                  - 查看状态"
            echo ""
            echo "典型流程:"
            echo "  1. $0 start user-role      # 开始新功能"
            echo "  2. 编辑代码..."
            echo "  3. $0 commit \"添加用户角色\"  # 提交更改"
            echo "  4. $0 merge                # 合并到 dev"
            echo "  5. 通知运维部署测试环境"
            ;;
    esac
}

main "$@"
