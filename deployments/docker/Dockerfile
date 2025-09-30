# 多阶段构建 Dockerfile

# 构建阶段
FROM golang:1.21-alpine AS builder

# 安装必要工具
RUN apk add --no-cache git protobuf-dev

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 生成 proto 代码
RUN for proto_dir in proto/*/; do \
        if [ -d "$proto_dir" ] && [ -f "${proto_dir}.git" ]; then \
            proto_name=$(basename "$proto_dir"); \
            mkdir -p "api/$proto_name"; \
            (cd "$proto_dir" && \
             if ls *.proto >/dev/null 2>&1; then \
                protoc --go_out="../../api/$proto_name" --go_opt=paths=source_relative \
                       --go-grpc_out="../../api/$proto_name" --go-grpc_opt=paths=source_relative \
                       *.proto; \
             fi); \
        fi; \
    done

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server

# 运行阶段
FROM alpine:latest

# 安装 ca-certificates 用于 HTTPS 请求
RUN apk --no-cache add ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 创建非 root 用户
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /root/

# 从构建阶段复制二进制文件
COPY --from=builder /app/main .

# 复制配置文件（如果有）
# COPY --from=builder /app/configs ./configs

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD grpc_health_probe -addr=:8080 || exit 1

# 运行应用
CMD ["./main"]
