#!/bin/bash

# 改进的 Git 工作区检查函数

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

# 方法1：只检查已跟踪文件的变更（原方法）
check_tracked_changes() {
    log_info "检查已跟踪文件的变更..."
    
    if ! git diff-index --quiet HEAD --; then
        log_warning "已跟踪文件有未提交的更改:"
        git diff --name-only HEAD
        return 1
    else
        log_success "已跟踪文件无变更"
        return 0
    fi
}

# 方法2：检查所有变更（包括未跟踪文件）
check_all_changes() {
    log_info "检查所有变更（包括未跟踪文件）..."
    
    # 使用 git status --porcelain 检查所有变更
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "工作区有变更:"
        git status --short
        return 1
    else
        log_success "工作区完全干净"
        return 0
    fi
}

# 方法3：分别检查不同类型的变更
check_workspace_detailed() {
    log_info "详细检查工作区状态..."
    
    local has_changes=false
    
    # 检查已跟踪文件的修改
    if ! git diff-index --quiet HEAD --; then
        log_warning "已跟踪文件有修改:"
        git diff --name-only HEAD | sed 's/^/  M /'
        has_changes=true
    fi
    
    # 检查暂存区
    if ! git diff-index --quiet --cached HEAD --; then
        log_warning "暂存区有变更:"
        git diff --name-only --cached HEAD | sed 's/^/  A /'
        has_changes=true
    fi
    
    # 检查未跟踪文件
    local untracked=$(git ls-files --others --exclude-standard)
    if [ -n "$untracked" ]; then
        log_warning "有未跟踪文件:"
        echo "$untracked" | sed 's/^/  ?? /'
        has_changes=true
    fi
    
    if [ "$has_changes" = true ]; then
        return 1
    else
        log_success "工作区完全干净"
        return 0
    fi
}

# 方法4：智能检查（推荐用于发版脚本）
check_workspace_smart() {
    log_info "智能检查工作区状态..."
    
    # 检查已跟踪文件的变更（必须干净）
    if ! git diff-index --quiet HEAD --; then
        log_error "已跟踪文件有未提交的更改，发版前必须提交:"
        git status --short | grep -E "^[ M]M|^[ A]A|^[ D]D"
        return 1
    fi
    
    # 检查暂存区（必须干净）
    if ! git diff-index --quiet --cached HEAD --; then
        log_error "暂存区有未提交的更改，请先提交:"
        git status --short | grep -E "^[MA]"
        return 1
    fi
    
    # 检查未跟踪文件（警告但不阻止）
    local untracked=$(git ls-files --others --exclude-standard)
    if [ -n "$untracked" ]; then
        log_warning "发现未跟踪文件:"
        echo "$untracked" | sed 's/^/  ?? /'
        echo ""
        read -p "是否继续发版？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "发版已取消"
            return 1
        fi
    fi
    
    log_success "工作区状态检查通过"
    return 0
}

# 演示所有方法
demo_all_methods() {
    echo "=== Git 工作区检查方法对比 ==="
    echo ""
    
    echo "当前 git status:"
    git status --short
    echo ""
    
    echo "1. 只检查已跟踪文件 (git diff-index --quiet HEAD --):"
    check_tracked_changes
    echo ""
    
    echo "2. 检查所有变更 (git status --porcelain):"
    check_all_changes
    echo ""
    
    echo "3. 详细分类检查:"
    check_workspace_detailed
    echo ""
    
    echo "4. 智能检查 (推荐用于发版):"
    check_workspace_smart
}

# 主函数
main() {
    case "${1:-demo}" in
        "tracked")
            check_tracked_changes
            ;;
        "all")
            check_all_changes
            ;;
        "detailed")
            check_workspace_detailed
            ;;
        "smart")
            check_workspace_smart
            ;;
        "demo"|*)
            demo_all_methods
            ;;
    esac
}

main "$@"
