# Makefile for Users Service
# 标准 Go 微服务项目管理

.PHONY: help dev build test proto-gen clean run docker-build docker-run deps lint

# 默认目标
help:
	@echo "🚀 Users Service 开发工具"
	@echo ""
	@echo "📋 开发命令:"
	@echo "  make dev              - 开发模式（生成代码 + 运行服务）"
	@echo "  make build            - 构建项目"
	@echo "  make test             - 运行测试"
	@echo "  make run              - 运行服务"
	@echo ""
	@echo "🔧 代码生成:"
	@echo "  make proto-gen        - 生成 proto 代码"
	@echo "  make deps             - 安装依赖"
	@echo ""
	@echo "🏷️ 发版命令:"
	@echo "  make release-minor    - 发布 minor 版本（新功能）"
	@echo "  make release-patch    - 发布 patch 版本（修复）"
	@echo "  make release-major    - 发布 major 版本（破坏性变更）"
	@echo ""
	@echo "🐳 Docker 命令:"
	@echo "  make docker-build     - 构建 Docker 镜像"
	@echo "  make docker-run       - 运行 Docker 容器"
	@echo "  make docker-compose   - 启动完整环境"
	@echo ""
	@echo "🧹 维护命令:"
	@echo "  make clean            - 清理生成文件"
	@echo "  make lint             - 代码检查"
	@echo ""
	@echo "💡 示例:"
	@echo "  make dev                              # 开发模式"
	@echo "  make release-minor DESC=\"添加用户角色功能\""

# 开发模式 - 生成代码并运行服务
dev: proto-gen
	@echo "🛠️ 开发模式：启动服务..."
	go run cmd/server/main.go

# 生成 proto 代码
proto-gen:
	@echo "🔧 生成 proto 代码..."
	@for proto_dir in proto/*/; do \
		if [ -d "$$proto_dir" ] && [ -f "$${proto_dir}.git" ]; then \
			proto_name=$$(basename "$$proto_dir"); \
			mkdir -p "api/$$proto_name"; \
			echo "  生成 $$proto_name proto..."; \
			(cd "$$proto_dir" && \
			 if ls *.proto >/dev/null 2>&1; then \
				protoc --go_out="../../api/$$proto_name" --go_opt=paths=source_relative \
				       --go-grpc_out="../../api/$$proto_name" --go-grpc_opt=paths=source_relative \
				       *.proto; \
			 fi); \
		fi; \
	done
	@echo "✅ Proto 代码生成完成"

# 安装依赖
deps:
	@echo "📦 安装依赖..."
	go mod download
	go mod tidy
	@echo "✅ 依赖安装完成"

# 构建项目
build: proto-gen
	@echo "🔨 构建项目..."
	go build -o bin/users-service cmd/server/main.go
	@echo "✅ 构建完成: bin/users-service"

# 运行服务
run: proto-gen
	@echo "🚀 运行服务..."
	go run cmd/server/main.go

# 运行测试
test:
	@echo "🧪 运行测试..."
	go test -v ./...
	@echo "✅ 测试完成"

# 运行测试并生成覆盖率报告
test-coverage:
	@echo "🧪 运行测试并生成覆盖率报告..."
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "✅ 覆盖率报告生成完成: coverage.html"

# 代码检查
lint:
	@echo "🔍 代码检查..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "⚠️ golangci-lint 未安装，使用 go vet"; \
		go vet ./...; \
	fi
	@echo "✅ 代码检查完成"

# Docker 构建
docker-build:
	@echo "🐳 构建 Docker 镜像..."
	docker build -f deployments/docker/Dockerfile -t users-service:latest .
	@echo "✅ Docker 镜像构建完成"

# Docker 运行
docker-run: docker-build
	@echo "🐳 运行 Docker 容器..."
	docker run -d --name users-service -p 8080:8080 users-service:latest
	@echo "✅ Docker 容器已启动"

# Docker Compose
docker-compose:
	@echo "🐳 启动完整环境..."
	docker-compose -f deployments/docker-compose.yml up -d
	@echo "✅ 完整环境已启动"

# 停止 Docker Compose
docker-compose-down:
	@echo "🐳 停止完整环境..."
	docker-compose -f deployments/docker-compose.yml down
	@echo "✅ 完整环境已停止"

# 清理生成文件
clean:
	@echo "🧹 清理生成文件..."
	rm -rf api/*/*.pb.go
	rm -rf bin/
	rm -rf dist/
	rm -f coverage.out coverage.html
	go clean ./...
	@echo "✅ 清理完成"

# 发布 minor 版本
release-minor:
	@if [ -z "$(DESC)" ]; then \
		echo "❌ 请提供描述: make release-minor DESC=\"功能描述\""; \
		exit 1; \
	fi
	@echo "🚀 发布 minor 版本: $(DESC)"
	./enhanced_personal_workflow.sh commit "$(DESC)" minor

# 发布 patch 版本
release-patch:
	@if [ -z "$(DESC)" ]; then \
		echo "❌ 请提供描述: make release-patch DESC=\"修复描述\""; \
		exit 1; \
	fi
	@echo "🔧 发布 patch 版本: $(DESC)"
	./enhanced_personal_workflow.sh commit "$(DESC)" patch

# 发布 major 版本
release-major:
	@if [ -z "$(DESC)" ]; then \
		echo "❌ 请提供描述: make release-major DESC=\"重大变更描述\""; \
		exit 1; \
	fi
	@echo "💥 发布 major 版本: $(DESC)"
	./enhanced_personal_workflow.sh commit "$(DESC)" major

# 推送更新
push:
	@echo "📤 推送所有更新..."
	./enhanced_personal_workflow.sh merge

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
	./enhanced_personal_workflow.sh commit "$(DESC)" patch
	./enhanced_personal_workflow.sh merge
	@echo "✅ 紧急修复已发布！"

# 多平台构建
build-all:
	@echo "🔨 多平台构建..."
	./scripts/build.sh
	@echo "✅ 多平台构建完成"

# 安装开发工具
install-tools:
	@echo "🛠️ 安装开发工具..."
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		echo "安装 golangci-lint..."; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.54.2; \
	fi
	@echo "✅ 开发工具安装完成"

# 项目初始化
init: install-tools deps proto-gen
	@echo "🎉 项目初始化完成！"
	@echo ""
	@echo "📋 下一步："
	@echo "  make dev     # 启动开发服务器"
	@echo "  make test    # 运行测试"