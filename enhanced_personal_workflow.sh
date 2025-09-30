#!/bin/bash

# 增强版个人开发工作流 - 支持 Submodule Proto 管理
# 完整处理：主项目分支 + submodule 提交 + proto 版本管理

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }
log_proto() { echo -e "${PURPLE}[PROTO]${NC} $1"; }

# 获取当前用户名
get_username() {
    git config user.name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr ' ' '-' || echo "dev"
}

# 获取当前分支
get_current_branch() {
    git branch --show-current
}

# 检查 proto 文件是否有修改
check_proto_changes() {
    local has_proto_changes=false
    
    for proto_dir in proto/*/; do
        if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then
            cd "$proto_dir"
            if ! git diff-index --quiet HEAD --; then
                echo "$proto_dir"
                has_proto_changes=true
            fi
            cd - >/dev/null
        fi
    done
    
    [ "$has_proto_changes" = true ]
}

# 获取修改的 proto 目录列表
get_modified_proto_dirs() {
    for proto_dir in proto/*/; do
        if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then
            cd "$proto_dir"
            if ! git diff-index --quiet HEAD --; then
                echo "${proto_dir%/}"
            fi
            cd - >/dev/null
        fi
    done
}

# 计算下一个版本号
calculate_next_version() {
    local current_version=$1
    local version_type=$2
    
    current_version=${current_version#v}
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case $version_type in
        "major")
            major=$((major + 1)); minor=0; patch=0 ;;
        "minor")
            minor=$((minor + 1)); patch=0 ;;
        "patch")
            patch=$((patch + 1)) ;;
        *)
            log_error "无效的版本类型: $version_type"
            exit 1 ;;
    esac
    
    echo "v${major}.${minor}.${patch}"
}

# 提交 proto 更改并创建版本
commit_proto_changes() {
    local commit_msg="$1"
    local version_type="${2:-patch}"
    
    log_step "处理 Proto 更改..."
    
    local modified_protos=($(get_modified_proto_dirs))
    
    if [ ${#modified_protos[@]} -eq 0 ]; then
        log_info "没有 proto 文件修改"
        return 0
    fi
    
    log_proto "发现修改的 proto: ${modified_protos[*]}"
    
    for proto_dir in "${modified_protos[@]}"; do
        log_proto "处理 $proto_dir..."
        
        cd "$proto_dir"
        
        # 验证 proto 语法
        if command -v protoc >/dev/null 2>&1; then
            find . -name "*.proto" -exec protoc --descriptor_set_out=/dev/null {} \; || {
                log_error "$proto_dir proto 语法错误"
                exit 1
            }
            log_success "$proto_dir proto 语法验证通过"
        fi
        
        # 获取当前版本
        local current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
        local new_version=$(calculate_next_version "$current_version" "$version_type")
        
        # 提交 proto 更改
        git add .
        git commit -m "feat: $commit_msg

Proto changes in $proto_dir
Version: $current_version -> $new_version"
        
        # 创建版本标签
        git tag -a "$new_version" -m "$commit_msg"
        
        # 推送 proto 更改和标签
        git push origin main
        git push origin "$new_version"
        
        log_success "$proto_dir 已更新到 $new_version"
        
        cd - >/dev/null
    done
    
    # 更新主项目的 submodule 引用
    log_step "更新主项目 submodule 引用..."
    for proto_dir in "${modified_protos[@]}"; do
        git add "$proto_dir"
    done
    
    log_success "Proto 更改处理完成"
}

# 增强版个人分支提交
enhanced_personal_commit() {
    local commit_msg="$1"
    local proto_version_type="${2:-patch}"
    
    if [ -z "$commit_msg" ]; then
        log_error "请提供提交信息"
        echo "用法: $0 commit \"提交信息\" [proto-version-type]"
        echo "proto-version-type: major|minor|patch (默认: patch)"
        exit 1
    fi
    
    local current_branch=$(get_current_branch)
    if [[ ! "$current_branch" =~ ^feature/ ]]; then
        log_error "当前不在功能分支上，当前分支: $current_branch"
        exit 1
    fi
    
    log_step "增强版个人分支提交..."
    
    # 1. 检查并处理 proto 更改
    if check_proto_changes; then
        log_proto "检测到 proto 文件修改，处理 proto 版本管理..."
        commit_proto_changes "$commit_msg" "$proto_version_type"
    else
        log_info "没有 proto 文件修改"
    fi
    
    # 2. 生成代码（如果有 proto 修改）
    if git diff --name-only HEAD | grep -q "proto/.*\.proto$\|^proto/"; then
        log_info "重新生成 proto 代码..."
        if [ -f "Makefile" ] && grep -q "proto-gen\|dev" Makefile; then
            make dev 2>/dev/null || make proto-gen 2>/dev/null || {
                log_warning "无法通过 Makefile 生成代码，尝试直接使用 protoc"
                # 生成所有 proto 代码 (修复路径问题)
                for proto_dir in proto/*/; do
                    if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then
                        proto_name=$(basename "$proto_dir")
                        mkdir -p "api/$proto_name"
                        
                        # 进入 proto 目录使用相对路径，避免绝对路径问题
                        (
                            cd "$proto_dir"
                            if ls *.proto >/dev/null 2>&1; then
                                protoc --go_out="../../api/$proto_name" --go_opt=paths=source_relative \
                                       --go-grpc_out="../../api/$proto_name" --go-grpc_opt=paths=source_relative \
                                       *.proto 2>/dev/null || true
                            fi
                        )
                    fi
                done
            }
        fi
    fi
    
    # 3. 运行测试
    log_info "运行测试..."
    if [ -f "go.mod" ]; then
        go test ./... -v || {
            log_error "测试失败，请修复后重试"
            exit 1
        }
    fi
    
    # 4. 提交主项目更改
    git add .
    
    # 构建详细的提交信息
    local detailed_msg="feat: $commit_msg

Branch: $current_branch
Author: $(git config user.name) <$(git config user.email)>

Changes:
- Main project: business logic updates
- Generated code: proto code regeneration"
    
    # 添加 proto 版本信息
    local modified_protos=($(get_modified_proto_dirs))
    if [ ${#modified_protos[@]} -gt 0 ]; then
        detailed_msg+="\n- Proto updates:"
        for proto_dir in "${modified_protos[@]}"; do
            cd "$proto_dir"
            local latest_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
            detailed_msg+="\n  - $proto_dir: $latest_version"
            cd - >/dev/null
        done
    fi
    
    git commit -m "$detailed_msg"
    
    log_success "增强版提交完成: $commit_msg"
    
    # 显示提交摘要
    echo ""
    log_info "提交摘要:"
    echo "  主项目提交: $(git rev-parse --short HEAD)"
    if [ ${#modified_protos[@]} -gt 0 ]; then
        echo "  Proto 更新:"
        for proto_dir in "${modified_protos[@]}"; do
            cd "$proto_dir"
            local latest_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
            local latest_commit=$(git rev-parse --short HEAD)
            echo "    $proto_dir: $latest_version ($latest_commit)"
            cd - >/dev/null
        done
    fi
}

# 增强版合并到 dev
enhanced_merge_to_dev() {
    local current_branch=$(get_current_branch)
    
    if [[ ! "$current_branch" =~ ^feature/ ]]; then
        log_error "当前不在功能分支上，无法合并"
        exit 1
    fi
    
    log_step "增强版合并到 dev 分支..."
    
    # 更新 dev 分支
    git checkout dev
    git pull origin dev
    git submodule update --remote
    
    # 推送当前功能分支
    git checkout "$current_branch"
    log_info "推送功能分支到远程..."
    git push origin "$current_branch"
    
    # 合并到 dev
    git checkout dev
    git merge "$current_branch" --no-ff -m "Merge $current_branch into dev

Features added:
$(git log --oneline "$current_branch" ^dev | head -5 | sed 's/^[a-f0-9]* /- /')

Proto versions:
$(for proto_dir in proto/*/; do
    if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then
        cd "$proto_dir"
        echo "- ${proto_dir%/}: $(git describe --tags --abbrev=0 2>/dev/null || echo 'no version')"
        cd - >/dev/null
    fi
done)

Author: $(git config user.name)"
    
    # 推送 dev 分支
    git push origin dev
    
    log_success "功能已合并到 dev 分支"
    
    # 生成运维通知信息
    echo ""
    log_warning "📢 完整的运维部署通知:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 dev 分支已更新，请部署测试环境"
    echo ""
    echo "📋 功能信息:"
    echo "  - 功能分支: $current_branch"
    echo "  - 开发者: $(git config user.name)"
    echo "  - 主项目提交: $(git rev-parse --short HEAD)"
    echo ""
    echo "📦 Proto 版本信息:"
    for proto_dir in proto/*/; do
        if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then
            cd "$proto_dir"
            local proto_version=$(git describe --tags --abbrev=0 2>/dev/null || echo 'no version')
            local proto_commit=$(git rev-parse --short HEAD)
            echo "  - ${proto_dir%/}: $proto_version ($proto_commit)"
            cd - >/dev/null
        fi
    done
    echo ""
    echo "⏰ 更新时间: $(date)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 询问是否删除功能分支
    echo ""
    read -p "是否删除本地功能分支 $current_branch？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -d "$current_branch"
        git push origin --delete "$current_branch" 2>/dev/null || true
        log_success "功能分支已删除"
    fi
}

# 显示增强版状态
show_enhanced_status() {
    local current_branch=$(get_current_branch)
    
    echo "=== 增强版个人开发状态 ==="
    echo ""
    log_info "主项目信息:"
    echo "  当前分支: $current_branch"
    echo "  用户信息: $(git config user.name) <$(git config user.email)>"
    
    # 显示工作区状态
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "主项目工作区有未提交的更改:"
        git status --short
    else
        log_success "主项目工作区干净"
    fi
    
    # 显示 Proto 状态
    echo ""
    log_proto "Proto Submodules 状态:"
    for proto_dir in proto/*/; do
        if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then
            cd "$proto_dir"
            local proto_name=${proto_dir%/}
            local current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "no version")
            local current_commit=$(git rev-parse --short HEAD)
            local branch=$(git branch --show-current || echo "detached")
            
            echo "  📦 $proto_name:"
            echo "    版本: $current_version"
            echo "    提交: $current_commit"
            echo "    分支: $branch"
            
            if ! git diff-index --quiet HEAD --; then
                echo "    状态: ⚠️  有未提交更改"
                git status --short | sed 's/^/      /'
            else
                echo "    状态: ✅ 工作区干净"
            fi
            
            cd - >/dev/null
        fi
    done
    
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
    case "${1:-status}" in
        "start")
            # 复用原有的 start 逻辑
            ./personal_dev_workflow.sh start "$2"
            ;;
        "commit")
            enhanced_personal_commit "$2" "$3"
            ;;
        "merge")
            enhanced_merge_to_dev
            ;;
        "sync")
            # 复用原有的 sync 逻辑
            ./personal_dev_workflow.sh sync
            ;;
        "status"|"")
            show_enhanced_status
            ;;
        *)
            echo "增强版个人开发工作流工具 (支持 Proto 版本管理)"
            echo ""
            echo "用法:"
            echo "  $0 start <feature-name>                    - 创建个人功能分支"
            echo "  $0 commit \"提交信息\" [proto-version-type] - 增强版提交 (处理 proto)"
            echo "  $0 merge                                   - 增强版合并到 dev"
            echo "  $0 sync                                    - 同步 dev 最新代码"
            echo "  $0 status                                  - 增强版状态显示"
            echo ""
            echo "Proto 版本类型:"
            echo "  major  - 破坏性变更 (v1.0.0 -> v2.0.0)"
            echo "  minor  - 新功能 (v1.0.0 -> v1.1.0)"
            echo "  patch  - 修复 (v1.0.0 -> v1.0.1) [默认]"
            echo ""
            echo "典型流程:"
            echo "  1. $0 start user-role                      # 开始新功能"
            echo "  2. 编辑 proto 和业务代码..."
            echo "  3. $0 commit \"添加用户角色\" minor          # 增强版提交"
            echo "  4. $0 merge                                # 增强版合并"
            echo "  5. 根据通知信息联系运维部署测试环境"
            ;;
    esac
}

main "$@"
