#!/bin/bash

# 共享 Proto 开发工作流
# 适用于需要被其他服务引用的 proto

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

# 获取当前版本
get_current_version() {
    cd proto/users
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
    cd ../..
}

# 检查 proto 兼容性
check_proto_compatibility() {
    log_info "检查 proto 兼容性..."
    
    if [ ! -f "proto/users/users.proto" ]; then
        log_error "未找到 users.proto 文件"
        return 1
    fi
    
    # 验证 proto 语法
    if command -v protoc >/dev/null 2>&1; then
        if protoc --descriptor_set_out=/dev/null proto/users/users.proto 2>/dev/null; then
            log_success "proto 语法验证通过"
        else
            log_error "proto 语法验证失败"
            return 1
        fi
    else
        log_warning "未安装 protoc，跳过语法验证"
    fi
}

# 更新 proto 版本
update_proto_version() {
    local version_type=$1
    local description=$2
    
    log_info "更新 users proto 版本..."
    
    cd proto/users
    
    # 检查工作区状态
    if ! git diff-index --quiet HEAD --; then
        log_error "proto 工作区有未提交的更改"
        git status --short
        cd ../..
        return 1
    fi
    
    # 获取当前版本并计算下一版本
    local current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
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
            cd ../..
            return 1
            ;;
    esac
    
    local new_version="v${major}.${minor}.${patch}"
    
    # 创建标签
    git tag -a "$new_version" -m "$description"
    
    log_success "Proto 版本已更新: $current_version -> $new_version"
    
    cd ../..
    echo "$new_version"
}

# 更新本地 submodule 引用
update_local_submodule() {
    local proto_version=$1
    
    log_info "更新本地 submodule 引用到 $proto_version..."
    
    cd proto/users
    git checkout "$proto_version"
    cd ../..
    
    # 更新主项目的 submodule 引用
    git add proto/users
    git commit -m "Update users proto to $proto_version"
    
    log_success "本地 submodule 已更新到 $proto_version"
}

# 推送 proto 更新
push_proto_updates() {
    local proto_version=$1
    
    log_info "推送 proto 更新..."
    
    cd proto/users
    git push origin main
    git push origin --tags
    cd ../..
    
    log_success "Proto 更新已推送到远程仓库"
    
    log_warning "其他服务需要手动更新 users proto 版本："
    echo "  cd proto/users && git fetch --tags && git checkout $proto_version"
}

# 主函数
main() {
    echo "=== 共享 Proto 开发工作流 ==="
    
    case "${1:-}" in
        "dev")
            log_info "开发模式 - 修改 proto 文件"
            echo "1. 修改 proto/users/users.proto"
            echo "2. 运行 ./shared_proto_workflow.sh validate"
            echo "3. 运行 ./shared_proto_workflow.sh release <type> \"描述\""
            ;;
            
        "validate")
            log_info "验证 proto 文件..."
            check_proto_compatibility
            log_success "验证完成"
            ;;
            
        "release")
            local version_type=$2
            local description=${3:-"Update users proto"}
            
            if [ -z "$version_type" ]; then
                log_error "请指定版本类型: major/minor/patch"
                exit 1
            fi
            
            log_info "发布 users proto..."
            
            # 验证 proto
            check_proto_compatibility
            
            # 更新 proto 版本
            local new_version=$(update_proto_version "$version_type" "$description")
            
            if [ $? -eq 0 ]; then
                # 更新本地引用
                update_local_submodule "$new_version"
                
                # 推送更新
                push_proto_updates "$new_version"
                
                echo ""
                log_success "Proto 发布完成！"
                echo "新版本: $new_version"
                echo ""
                log_warning "通知其他服务团队更新 users proto 版本"
            fi
            ;;
            
        "sync")
            log_info "同步最新的 proto 版本..."
            cd proto/users
            git fetch --tags
            local latest_tag=$(git tag --sort=-version:refname | head -1)
            if [ -n "$latest_tag" ]; then
                git checkout "$latest_tag"
                cd ../..
                git add proto/users
                git commit -m "Sync users proto to $latest_tag"
                log_success "已同步到最新版本: $latest_tag"
            else
                log_warning "未找到版本标签"
                cd ../..
            fi
            ;;
            
        "status")
            log_info "Proto 状态信息"
            cd proto/users
            echo "当前版本: $(git describe --tags --always)"
            echo "当前分支: $(git branch --show-current)"
            echo "最新标签: $(git tag --sort=-version:refname | head -1 || echo '无')"
            cd ../..
            ;;
            
        *)
            echo "用法:"
            echo "  $0 dev                           - 开发指引"
            echo "  $0 validate                      - 验证 proto 文件"
            echo "  $0 release <type> [description]  - 发布新版本"
            echo "  $0 sync                          - 同步最新版本"
            echo "  $0 status                        - 查看状态"
            echo ""
            echo "版本类型:"
            echo "  major  - 破坏性变更 (v1.0.0 -> v2.0.0)"
            echo "  minor  - 新功能 (v1.0.0 -> v1.1.0)"
            echo "  patch  - 修复 (v1.0.0 -> v1.0.1)"
            echo ""
            echo "示例:"
            echo "  $0 release minor \"添加用户角色字段\""
            echo "  $0 release patch \"修复用户信息结构\""
            ;;
    esac
}

# 执行主函数
main "$@"

