#!/bin/bash

# 构建脚本

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

# 项目信息
APP_NAME="users-service"
VERSION=${VERSION:-$(git describe --tags --always --dirty 2>/dev/null || echo "dev")}
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

log_info "构建 $APP_NAME"
log_info "版本: $VERSION"
log_info "构建时间: $BUILD_TIME"
log_info "Git 提交: $GIT_COMMIT"

# 设置构建参数
LDFLAGS="-X main.version=$VERSION -X main.buildTime=$BUILD_TIME -X main.gitCommit=$GIT_COMMIT"

# 清理旧的构建文件
log_info "清理旧的构建文件..."
rm -rf dist/
mkdir -p dist/

# 生成 proto 代码
log_info "生成 proto 代码..."
make proto-gen || {
    log_warning "Makefile 不存在，使用脚本生成 proto 代码..."
    for proto_dir in proto/*/; do
        if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then
            proto_name=$(basename "$proto_dir")
            mkdir -p "api/$proto_name"
            
            (
                cd "$proto_dir"
                if ls *.proto >/dev/null 2>&1; then
                    protoc --go_out="../../api/$proto_name" --go_opt=paths=source_relative \
                           --go-grpc_out="../../api/$proto_name" --go-grpc_opt=paths=source_relative \
                           *.proto
                    log_success "生成 $proto_name proto 代码完成"
                fi
            )
        fi
    done
}

# 运行测试
log_info "运行测试..."
go test ./... -v

# 构建二进制文件
log_info "构建二进制文件..."

# Linux amd64
log_info "构建 Linux amd64..."
GOOS=linux GOARCH=amd64 go build -ldflags "$LDFLAGS" -o "dist/${APP_NAME}-linux-amd64" ./cmd/server

# macOS amd64
log_info "构建 macOS amd64..."
GOOS=darwin GOARCH=amd64 go build -ldflags "$LDFLAGS" -o "dist/${APP_NAME}-darwin-amd64" ./cmd/server

# macOS arm64
log_info "构建 macOS arm64..."
GOOS=darwin GOARCH=arm64 go build -ldflags "$LDFLAGS" -o "dist/${APP_NAME}-darwin-arm64" ./cmd/server

# Windows amd64
log_info "构建 Windows amd64..."
GOOS=windows GOARCH=amd64 go build -ldflags "$LDFLAGS" -o "dist/${APP_NAME}-windows-amd64.exe" ./cmd/server

# 显示构建结果
log_success "构建完成！"
echo ""
log_info "构建文件:"
ls -la dist/

# 创建版本信息文件
cat > dist/version.txt << EOF
App: $APP_NAME
Version: $VERSION
Build Time: $BUILD_TIME
Git Commit: $GIT_COMMIT
Go Version: $(go version)
EOF

log_success "版本信息已保存到 dist/version.txt"
