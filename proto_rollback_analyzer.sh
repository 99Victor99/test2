#!/bin/bash

# Proto 回滚影响分析工具
# 分析从当前版本回滚到目标版本的影响

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SAFE]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[BREAK]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# 使用方法
usage() {
    echo "Proto 回滚影响分析工具"
    echo ""
    echo "用法:"
    echo "  $0 <proto_dir> <current_version> <target_version>"
    echo ""
    echo "示例:"
    echo "  $0 proto/users v1.2.0 v1.1.0"
    echo "  $0 proto/goods v2.1.0 v2.0.0"
    echo ""
    echo "功能:"
    echo "  - 分析字段变更影响"
    echo "  - 识别破坏性变更"
    echo "  - 生成回滚建议"
    echo "  - 评估通知需求"
}

# 检查参数
check_params() {
    if [ $# -ne 3 ]; then
        usage
        exit 1
    fi
    
    local proto_dir=$1
    local current_version=$2
    local target_version=$3
    
    if [ ! -d "$proto_dir" ]; then
        log_error "Proto 目录不存在: $proto_dir"
        exit 1
    fi
    
    if [ ! -f "${proto_dir}/.git" ]; then
        log_error "$proto_dir 不是 git submodule"
        exit 1
    fi
}

# 获取版本间的文件差异
get_version_diff() {
    local proto_dir=$1
    local current_version=$2
    local target_version=$3
    
    cd "$proto_dir"
    
    # 检查版本是否存在
    if ! git tag | grep -q "^${current_version}$"; then
        log_error "当前版本不存在: $current_version"
        exit 1
    fi
    
    if ! git tag | grep -q "^${target_version}$"; then
        log_error "目标版本不存在: $target_version"
        exit 1
    fi
    
    # 获取差异
    git diff "$target_version".."$current_version" -- "*.proto"
    
    cd - >/dev/null
}

# 分析字段变更
analyze_field_changes() {
    local diff_content="$1"
    
    echo "$diff_content" | while IFS= read -r line; do
        case "$line" in
            "+    "*)
                # 新增的字段（回滚时会被移除）
                if echo "$line" | grep -q "= [0-9]*;"; then
                    field_info=$(echo "$line" | sed 's/^+    //' | sed 's/;$//')
                    echo "REMOVE_FIELD:$field_info"
                fi
                ;;
            "-    "*)
                # 删除的字段（回滚时会被恢复）
                if echo "$line" | grep -q "= [0-9]*;"; then
                    field_info=$(echo "$line" | sed 's/^-    //' | sed 's/;$//')
                    echo "RESTORE_FIELD:$field_info"
                fi
                ;;
            "+    rpc "*)
                # 新增的 RPC 方法（回滚时会被移除）
                method_info=$(echo "$line" | sed 's/^+    rpc //' | sed 's/{$//')
                echo "REMOVE_RPC:$method_info"
                ;;
            "-    rpc "*)
                # 删除的 RPC 方法（回滚时会被恢复）
                method_info=$(echo "$line" | sed 's/^-    rpc //' | sed 's/{$//')
                echo "RESTORE_RPC:$method_info"
                ;;
            "+    reserved "*)
                # 新增的保留字段（回滚时字段会恢复）
                reserved_info=$(echo "$line" | sed 's/^+    reserved //' | sed 's/;$//')
                echo "UNRESERVE:$reserved_info"
                ;;
        esac
    done
}

# 评估变更影响
assess_impact() {
    local changes="$1"
    
    local safe_changes=()
    local warning_changes=()
    local breaking_changes=()
    
    echo "$changes" | while IFS= read -r change; do
        if [ -z "$change" ]; then
            continue
        fi
        
        case "$change" in
            "REMOVE_FIELD:"*)
                field=$(echo "$change" | cut -d: -f2)
                safe_changes+=("移除字段: $field")
                echo "SAFE:移除字段: $field"
                ;;
            "RESTORE_FIELD:"*)
                field=$(echo "$change" | cut -d: -f2)
                warning_changes+=("恢复字段: $field")
                echo "WARN:恢复字段: $field"
                ;;
            "REMOVE_RPC:"*)
                method=$(echo "$change" | cut -d: -f2)
                breaking_changes+=("移除方法: $method")
                echo "BREAK:移除 RPC 方法: $method"
                ;;
            "RESTORE_RPC:"*)
                method=$(echo "$change" | cut -d: -f2)
                warning_changes+=("恢复方法: $method")
                echo "WARN:恢复 RPC 方法: $method"
                ;;
            "UNRESERVE:"*)
                field=$(echo "$change" | cut -d: -f2)
                warning_changes+=("取消保留: $field")
                echo "WARN:取消字段保留: $field"
                ;;
        esac
    done
}

# 生成回滚建议
generate_recommendations() {
    local proto_dir=$1
    local current_version=$2
    local target_version=$3
    local impact_analysis="$4"
    
    echo ""
    echo "🎯 回滚建议:"
    
    local has_breaking_changes=false
    local has_warning_changes=false
    
    if echo "$impact_analysis" | grep -q "^BREAK:"; then
        has_breaking_changes=true
    fi
    
    if echo "$impact_analysis" | grep -q "^WARN:"; then
        has_warning_changes=true
    fi
    
    if [ "$has_breaking_changes" = true ]; then
        echo "❌ 发现破坏性变更，回滚风险高"
        echo "   建议："
        echo "   1. 通知所有依赖服务"
        echo "   2. 准备应急回滚脚本"
        echo "   3. 分阶段执行回滚"
        echo "   4. 密切监控服务状态"
    elif [ "$has_warning_changes" = true ]; then
        echo "⚠️ 发现需要注意的变更"
        echo "   建议："
        echo "   1. 通知相关开发团队"
        echo "   2. 验证业务逻辑兼容性"
        echo "   3. 在测试环境先验证"
    else
        echo "✅ 回滚风险较低"
        echo "   建议："
        echo "   1. 可以直接执行回滚"
        echo "   2. 无需特殊通知"
        echo "   3. 正常监控即可"
    fi
}

# 生成通知模板
generate_notice_template() {
    local proto_dir=$1
    local current_version=$2
    local target_version=$3
    local impact_analysis="$4"
    
    echo ""
    echo "📧 通知模板:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚨 Proto 回滚通知"
    echo ""
    echo "📦 服务: ${proto_dir##*/}-service"
    echo "📋 Proto: $proto_dir"
    echo "🔄 回滚: $current_version → $target_version"
    echo "⏰ 时间: 预计 $(date -d '+1 hour' '+%Y-%m-%d %H:%M')"
    echo ""
    
    if echo "$impact_analysis" | grep -q "^SAFE:"; then
        echo "✅ 自动兼容变更（无需处理）:"
        echo "$impact_analysis" | grep "^SAFE:" | sed 's/^SAFE:/  - /'
        echo ""
    fi
    
    if echo "$impact_analysis" | grep -q "^WARN:"; then
        echo "⚠️ 需要注意的变更（建议验证）:"
        echo "$impact_analysis" | grep "^WARN:" | sed 's/^WARN:/  - /'
        echo ""
    fi
    
    if echo "$impact_analysis" | grep -q "^BREAK:"; then
        echo "❌ 破坏性变更（必须处理）:"
        echo "$impact_analysis" | grep "^BREAK:" | sed 's/^BREAK:/  - /'
        echo ""
        echo "📢 受影响的服务:"
        echo "  - 请各服务团队检查是否使用了上述变更"
        echo "  - 如有使用，请准备应对措施"
        echo ""
    fi
    
    echo "🔧 回滚执行命令:"
    echo "  cd $proto_dir"
    echo "  git checkout $target_version"
    echo "  cd ../.. && git add $proto_dir"
    echo "  git commit -m \"Rollback $proto_dir: $current_version -> $target_version\""
    echo ""
    echo "📞 联系人: $(git config user.name) <$(git config user.email)>"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 主函数
main() {
    local proto_dir=$1
    local current_version=$2
    local target_version=$3
    
    check_params "$@"
    
    echo "=== Proto 回滚影响分析 ==="
    echo ""
    log_info "分析参数:"
    echo "  Proto 目录: $proto_dir"
    echo "  当前版本: $current_version"
    echo "  目标版本: $target_version"
    echo ""
    
    log_step "获取版本差异..."
    local diff_content=$(get_version_diff "$proto_dir" "$current_version" "$target_version")
    
    if [ -z "$diff_content" ]; then
        log_success "两个版本之间没有 proto 文件差异"
        echo "✅ 可以安全回滚，无需通知"
        return 0
    fi
    
    log_step "分析变更影响..."
    local changes=$(analyze_field_changes "$diff_content")
    local impact_analysis=$(assess_impact "$changes")
    
    echo ""
    echo "📊 回滚影响分析 ($current_version → $target_version):"
    echo ""
    
    if echo "$impact_analysis" | grep -q "^SAFE:"; then
        log_success "自动兼容变更:"
        echo "$impact_analysis" | grep "^SAFE:" | sed 's/^SAFE:/  /'
        echo ""
    fi
    
    if echo "$impact_analysis" | grep -q "^WARN:"; then
        log_warning "需要注意的变更:"
        echo "$impact_analysis" | grep "^WARN:" | sed 's/^WARN:/  /'
        echo ""
    fi
    
    if echo "$impact_analysis" | grep -q "^BREAK:"; then
        log_error "破坏性变更:"
        echo "$impact_analysis" | grep "^BREAK:" | sed 's/^BREAK:/  /'
        echo ""
    fi
    
    generate_recommendations "$proto_dir" "$current_version" "$target_version" "$impact_analysis"
    generate_notice_template "$proto_dir" "$current_version" "$target_version" "$impact_analysis"
}

# 执行主函数
main "$@"

