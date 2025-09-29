#!/bin/bash

# 统一发版脚本 - Proto + 接口实现一起更新
# 一句命令完成：proto 修改 -> 代码生成 -> 接口实现 -> 版本发布

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查工作区状态
check_workspace() {
    log_info "检查工作区状态..."
    
    # 检查主项目工作区
    if ! git diff-index --quiet HEAD --; then
        log_warning "主项目有未提交的更改:"
        git status --short
        echo ""
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
    
    # 检查 proto submodule 状态
    cd proto/users
    if ! git diff-index --quiet HEAD --; then
        log_warning "users proto 有未提交的更改:"
        git status --short
        echo ""
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            cd ../..
            exit 0
        fi
    fi
    cd ../..
}

# 验证 proto 语法
validate_proto() {
    log_info "验证 proto 语法..."
    
    if command -v protoc >/dev/null 2>&1; then
        if protoc --descriptor_set_out=/dev/null proto/users/users.proto 2>/dev/null; then
            log_success "proto 语法验证通过"
        else
            log_error "proto 语法验证失败"
            exit 1
        fi
    else
        log_warning "未安装 protoc，跳过语法验证"
    fi
}

# 生成代码
generate_code() {
    log_info "生成 proto 代码..."
    
    # 确保输出目录存在
    mkdir -p api/users
    
    # 生成 Go 代码
    if command -v protoc >/dev/null 2>&1; then
        protoc --go_out=api/users --go_opt=paths=source_relative \
               --go-grpc_out=api/users --go-grpc_opt=paths=source_relative \
               proto/users/users.proto
        
        log_success "代码生成完成"
    else
        log_error "未安装 protoc，无法生成代码"
        exit 1
    fi
}

# 运行测试
run_tests() {
    log_info "运行测试..."
    
    if [ -f "go.mod" ]; then
        if go test ./... -v; then
            log_success "测试通过"
        else
            log_error "测试失败"
            exit 1
        fi
    else
        log_warning "未找到 go.mod，跳过测试"
    fi
}

# 计算版本号
calculate_version() {
    local version_type=$1
    local current_version=$2
    
    # 移除 v 前缀
    current_version=${current_version#v}
    
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case $version_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            log_error "无效的版本类型: $version_type"
            exit 1
            ;;
    esac
    
    echo "v${major}.${minor}.${patch}"
}

# 统一提交和发版
unified_release() {
    local version_type=$1
    local description=$2
    
    log_info "开始统一发版流程..."
    
    # 1. 验证 proto
    validate_proto
    
    # 2. 生成代码
    generate_code
    
    # 3. 运行测试
    run_tests
    
    # 4. 提交 proto 更改
    log_info "提交 proto 更改..."
    cd proto/users
    
    # 获取 proto 当前版本
    local proto_current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    local proto_new_version=$(calculate_version "$version_type" "$proto_current_version")
    
    # 提交 proto 更改
    if ! git diff-index --quiet HEAD --; then
        git add .
        git commit -m "feat: $description

Proto version: $proto_new_version"
    fi
    
    # 创建 proto 版本标签
    git tag -a "$proto_new_version" -m "$description"
    
    log_success "Proto 版本创建: $proto_new_version"
    cd ../..
    
    # 5. 更新主项目的 submodule 引用
    log_info "更新主项目 submodule 引用..."
    cd proto/users
    git checkout "$proto_new_version"
    cd ../..
    
    # 6. 提交主项目更改（包括生成的代码和 submodule 更新）
    log_info "提交主项目更改..."
    
    # 获取主项目当前版本
    local main_current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    local main_new_version=$(calculate_version "$version_type" "$main_current_version")
    
    git add .
    git commit -m "feat: $description

- Update users proto to $proto_new_version
- Regenerate proto code
- Update service implementation

Service version: $main_new_version"
    
    # 创建主项目版本标签
    git tag -a "$main_new_version" -m "$description

Proto version: $proto_new_version
Service version: $main_new_version"
    
    log_success "服务版本创建: $main_new_version"
    
    # 7. 显示发版信息
    echo ""
    log_success "🎉 统一发版完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Proto 版本:   $proto_new_version"
    echo "🚀 服务版本:     $main_new_version"
    echo "📝 更改描述:     $description"
    echo "🕐 发布时间:     $(date)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 8. 推送选项
    echo ""
    log_warning "下一步操作:"
    echo "1. 推送 proto 更新:"
    echo "   cd proto/users && git push origin main --tags && cd ../.."
    echo ""
    echo "2. 推送服务更新:"
    echo "   git push origin main --tags"
    echo ""
    echo "3. 或者使用快捷命令:"
    echo "   $0 push"
    echo ""
    echo "4. 通知其他服务团队更新 users proto 到 $proto_new_version"
}

# 推送所有更新
push_updates() {
    log_info "推送所有更新..."
    
    # 推送 proto 更新
    log_info "推送 proto 更新..."
    cd proto/users
    git push origin main
    git push origin --tags
    cd ../..
    
    # 推送主项目更新
    log_info "推送服务更新..."
    git push origin main
    git push origin --tags
    
    log_success "所有更新已推送到远程仓库"
}

# 显示状态
show_status() {
    echo "=== 项目状态 ==="
    
    # 主项目状态
    echo ""
    log_info "主项目 (users-service):"
    echo "  当前版本: $(git describe --tags --always 2>/dev/null || echo '无版本')"
    echo "  当前分支: $(git branch --show-current)"
    echo "  工作区状态: $(git diff-index --quiet HEAD -- && echo '干净' || echo '有未提交更改')"
    
    # Proto 状态
    echo ""
    log_info "Users Proto:"
    cd proto/users
    echo "  当前版本: $(git describe --tags --always 2>/dev/null || echo '无版本')"
    echo "  当前分支: $(git branch --show-current)"
    echo "  工作区状态: $(git diff-index --quiet HEAD -- && echo '干净' || echo '有未提交更改')"
    cd ../..
    
    # 其他 Proto 状态
    echo ""
    log_info "外部依赖 Proto:"
    for proto_dir in "goods" "orders"; do
        if [ -d "proto/$proto_dir" ]; then
            cd "proto/$proto_dir"
            echo "  $proto_dir: $(git describe --tags --always 2>/dev/null || echo '无版本')"
            cd ../..
        fi
    done
}

# 主函数
main() {
    echo "=== 统一发版工具 (Proto + 接口实现) ==="
    
    case "${1:-}" in
        "major"|"minor"|"patch")
            local version_type=$1
            local description="${2:-Update users service}"
            
            if [ -z "$description" ]; then
                log_error "请提供更改描述"
                echo "用法: $0 $version_type \"更改描述\""
                exit 1
            fi
            
            echo ""
            log_info "准备发布:"
            echo "  版本类型: $version_type"
            echo "  更改描述: $description"
            echo ""
            
            read -p "确认执行统一发版？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                check_workspace
                unified_release "$version_type" "$description"
            else
                log_info "发版已取消"
            fi
            ;;
            
        "push")
            push_updates
            ;;
            
        "status")
            show_status
            ;;
            
        "validate")
            validate_proto
            generate_code
            log_success "验证和代码生成完成"
            ;;
            
        *)
            echo "用法:"
            echo "  $0 <major|minor|patch> \"更改描述\"  - 统一发版"
            echo "  $0 push                              - 推送所有更新"
            echo "  $0 status                            - 查看状态"
            echo "  $0 validate                          - 验证和生成代码"
            echo ""
            echo "版本类型说明:"
            echo "  major  - 破坏性变更 (v1.0.0 -> v2.0.0)"
            echo "  minor  - 新功能 (v1.0.0 -> v1.1.0)"  
            echo "  patch  - 修复 (v1.0.0 -> v1.0.1)"
            echo ""
            echo "示例:"
            echo "  $0 minor \"添加用户角色功能\""
            echo "  $0 patch \"修复用户信息验证\""
            echo "  $0 major \"重构用户数据结构\""
            ;;
    esac
}

# 执行主函数
main "$@"
