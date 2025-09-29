#!/bin/bash

# 统一发版流程演示

echo "=== 统一发版流程演示 ==="

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[DEMO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[TIP]${NC} $1"; }

echo ""
log_info "传统方式 vs 统一发版对比"

echo ""
echo "❌ 传统方式（多步骤，容易出错）："
echo "1. vim proto/users/users.proto          # 修改 proto"
echo "2. protoc --go_out=... users.proto      # 生成代码"
echo "3. vim internal/service/user.go         # 修改接口实现"
echo "4. go test ./...                        # 运行测试"
echo "5. cd proto/users && git add . && git commit && git tag"
echo "6. cd ../.. && git add . && git commit && git tag"
echo "7. cd proto/users && git push --tags"
echo "8. cd ../.. && git push --tags"
echo "9. 通知其他团队..."

echo ""
echo "✅ 统一发版（一句命令）："
echo "1. vim proto/users/users.proto          # 修改 proto"
echo "2. ./unified_release.sh minor \"添加用户角色功能\""
echo "3. ./unified_release.sh push"

echo ""
log_success "统一发版的优势："
echo "• 🎯 一句命令完成所有步骤"
echo "• 🔒 确保 proto 和接口实现同步"
echo "• 📦 版本号自动管理"
echo "• 🧪 自动运行测试验证"
echo "• 🏷️ 同时创建 proto 和服务版本标签"
echo "• 🔄 避免遗漏步骤导致的版本不一致"

echo ""
log_info "实际使用示例："

echo ""
echo "📝 场景 1: 添加新字段"
echo "   ./unified_release.sh minor \"添加用户角色字段\""
echo "   输出："
echo "   📦 Proto 版本:   v1.3.0"
echo "   🚀 服务版本:     v1.3.0"

echo ""
echo "🐛 场景 2: 修复 bug"
echo "   ./unified_release.sh patch \"修复用户信息验证\""
echo "   输出："
echo "   📦 Proto 版本:   v1.3.1"
echo "   🚀 服务版本:     v1.3.1"

echo ""
echo "💥 场景 3: 破坏性变更"
echo "   ./unified_release.sh major \"重构用户数据结构\""
echo "   输出："
echo "   📦 Proto 版本:   v2.0.0"
echo "   🚀 服务版本:     v2.0.0"

echo ""
log_info "完整的开发流程："

cat << 'EOF'

🔄 日常开发循环:
┌─────────────────────────────────────────────┐
│  1. 修改 proto/users/users.proto            │
│  2. 修改 internal/service/user_service.go   │
│  3. ./unified_release.sh minor "功能描述"   │
│  4. ./unified_release.sh push               │
│  5. 通知其他服务团队                        │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│  其他服务更新:                              │
│  cd proto/users                             │
│  git fetch --tags                           │
│  git checkout v1.3.0                       │
│  cd ../.. && git commit -m "Update users"  │
└─────────────────────────────────────────────┘

EOF

echo ""
log_warning "最佳实践建议："
echo "• 📋 每次发版都要写清楚的描述信息"
echo "• 🧪 发版前确保所有测试通过"
echo "• 📢 破坏性变更要提前通知相关团队"
echo "• 🏷️ 使用语义化版本号 (major.minor.patch)"
echo "• 📝 维护 CHANGELOG 记录重要变更"

echo ""
log_success "现在可以尝试："
echo "1. 查看当前状态: ./unified_release.sh status"
echo "2. 验证环境: ./unified_release.sh validate"
echo "3. 模拟发版: ./unified_release.sh minor \"测试统一发版\""

echo ""
echo "🎉 统一发版让 Proto + 接口开发更高效！"
