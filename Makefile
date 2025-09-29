# Makefile for Users Service
# 统一管理 Proto + 接口开发流程

.PHONY: help dev build test release push status clean

# 默认目标
help:
	@echo "🚀 Users Service 开发工具"
	@echo ""
	@echo "📋 可用命令:"
	@echo "  make dev              - 开发模式（验证 + 生成代码）"
	@echo "  make build            - 构建项目"
	@echo "  make test             - 运行测试"
	@echo "  make status           - 查看项目状态"
	@echo ""
	@echo "🏷️ 发版命令:"
	@echo "  make release-minor    - 发布 minor 版本（新功能）"
	@echo "  make release-patch    - 发布 patch 版本（修复）"
	@echo "  make release-major    - 发布 major 版本（破坏性变更）"
	@echo "  make push             - 推送所有更新到远程"
	@echo ""
	@echo "🧹 维护命令:"
	@echo "  make clean            - 清理生成文件"
	@echo ""
	@echo "💡 示例:"
	@echo "  make release-minor DESC=\"添加用户角色功能\""
	@echo "  make release-patch DESC=\"修复用户验证错误\""

# 开发模式 - 验证和生成代码
dev:
	@echo "🛠️ 开发模式：验证 proto 并生成代码..."
	./unified_release.sh validate

# 构建项目
build:
	@echo "🔨 构建项目..."
	go build -v ./...

# 运行测试
test:
	@echo "🧪 运行测试..."
	go test -v ./...

# 查看状态
status:
	@echo "📊 项目状态..."
	./unified_release.sh status

# 发布 minor 版本
release-minor:
	@if [ -z "$(DESC)" ]; then \
		echo "❌ 请提供描述: make release-minor DESC=\"功能描述\""; \
		exit 1; \
	fi
	@echo "🚀 发布 minor 版本: $(DESC)"
	./unified_release.sh minor "$(DESC)"

# 发布 patch 版本
release-patch:
	@if [ -z "$(DESC)" ]; then \
		echo "❌ 请提供描述: make release-patch DESC=\"修复描述\""; \
		exit 1; \
	fi
	@echo "🔧 发布 patch 版本: $(DESC)"
	./unified_release.sh patch "$(DESC)"

# 发布 major 版本
release-major:
	@if [ -z "$(DESC)" ]; then \
		echo "❌ 请提供描述: make release-major DESC=\"重大变更描述\""; \
		exit 1; \
	fi
	@echo "💥 发布 major 版本: $(DESC)"
	./unified_release.sh major "$(DESC)"

# 推送更新
push:
	@echo "📤 推送所有更新..."
	./unified_release.sh push

# 清理生成文件
clean:
	@echo "🧹 清理生成文件..."
	rm -rf api/users/*.pb.go
	go clean ./...

# 完整发版流程（推荐）
release: release-minor push
	@echo "✅ 完整发版流程完成！"

# 快速发版（用于紧急修复）
hotfix:
	@if [ -z "$(DESC)" ]; then \
		echo "❌ 请提供描述: make hotfix DESC=\"紧急修复描述\""; \
		exit 1; \
	fi
	@echo "🚨 紧急修复发版: $(DESC)"
	./unified_release.sh patch "$(DESC)"
	./unified_release.sh push
	@echo "✅ 紧急修复已发布并推送！"
