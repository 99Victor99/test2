# Users Service API 文档

## 概述

Users Service 是一个基于 gRPC 的用户管理微服务，提供用户的 CRUD 操作。

## 服务信息

- **服务名**: UsersService
- **协议**: gRPC
- **端口**: 8080
- **包名**: user.ser

## API 接口

### 1. 获取用户信息

**方法**: `Get`

**请求参数**:
```protobuf
message User {
    int32 uid = 1;
    string name = 2;
    int32 age = 3;
}
```

**响应**:
```protobuf
message User {
    int32 uid = 1;
    string name = 2;
    int32 age = 3;
}
```

**示例**:
```bash
# 使用 grpcurl 调用
grpcurl -plaintext -d '{"uid": 1}' localhost:8080 user.ser.UsersService/Get
```

### 2. 创建用户

**方法**: `CreateUser`

**请求参数**:
```protobuf
message User {
    string name = 2;  // 必填
    int32 age = 3;    // 必填，0-150
}
```

**响应**:
```protobuf
message User {
    int32 uid = 1;    // 系统生成
    string name = 2;
    int32 age = 3;
}
```

**示例**:
```bash
grpcurl -plaintext -d '{"name": "张三", "age": 25}' localhost:8080 user.ser.UsersService/CreateUser
```

### 3. 更新用户

**方法**: `UpdateUser`

**请求参数**:
```protobuf
message User {
    int32 uid = 1;    // 必填
    string name = 2;  // 可选
    int32 age = 3;    // 可选
}
```

**响应**:
```protobuf
message User {
    int32 uid = 1;
    string name = 2;
    int32 age = 3;
}
```

**示例**:
```bash
grpcurl -plaintext -d '{"uid": 1, "name": "张三三", "age": 26}' localhost:8080 user.ser.UsersService/UpdateUser
```

## 数据模型

### User 用户基本信息
- `uid` (int32): 用户ID，系统自动生成
- `name` (string): 用户名，必填，3-50字符，唯一
- `age` (int32): 年龄，必填，0-150

### UserInfo 用户详细信息
- `uid` (int32): 用户ID
- `email` (string): 邮箱地址
- `ip` (int32): IP地址

### UserAddress 用户地址信息
- `uid` (int32): 用户ID
- `home` (string): 家庭地址
- `brand` (int32): 品牌标识

## 错误码

| 错误码 | 描述 | 示例 |
|--------|------|------|
| `INVALID_ARGUMENT` | 参数无效 | 用户ID为0或负数 |
| `NOT_FOUND` | 资源不存在 | 用户不存在 |
| `ALREADY_EXISTS` | 资源已存在 | 用户名重复 |
| `INTERNAL` | 内部错误 | 数据库连接失败 |

## 环境配置

### 环境变量

| 变量名 | 默认值 | 描述 |
|--------|--------|------|
| `PORT` | 8080 | 服务端口 |
| `ENVIRONMENT` | development | 运行环境 |
| `LOG_LEVEL` | info | 日志级别 |
| `DATABASE_URL` | postgres://... | 数据库连接字符串 |
| `REDIS_ADDR` | localhost:6379 | Redis 地址 |
| `JWT_SECRET` | your-secret-key | JWT 密钥 |

### 开发环境启动

```bash
# 1. 启动依赖服务
docker-compose up -d postgres redis

# 2. 生成 proto 代码
make proto-gen

# 3. 运行服务
go run cmd/server/main.go

# 4. 或使用 Docker
docker-compose up users-service
```

### 生产环境部署

```bash
# 1. 构建镜像
docker build -f deployments/docker/Dockerfile -t users-service:latest .

# 2. 运行容器
docker run -d \
  --name users-service \
  -p 8080:8080 \
  -e DATABASE_URL="postgres://..." \
  -e REDIS_ADDR="redis:6379" \
  users-service:latest
```

## 健康检查

服务提供 gRPC 健康检查接口：

```bash
# 检查服务健康状态
grpc_health_probe -addr=localhost:8080
```

## 监控和日志

### 日志格式

服务使用结构化 JSON 日志：

```json
{
  "time": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "msg": "gRPC request completed",
  "method": "/user.ser.UsersService/Get",
  "duration": "5ms"
}
```

### 指标监控

- 请求数量和延迟
- 错误率统计
- 数据库连接状态
- 内存和 CPU 使用率

## 测试

### 单元测试

```bash
# 运行所有测试
go test ./...

# 运行特定包的测试
go test ./internal/service/...

# 生成测试覆盖率报告
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### 集成测试

```bash
# 启动测试环境
docker-compose -f docker-compose.test.yml up -d

# 运行集成测试
go test -tags=integration ./tests/...
```

## 开发指南

### 添加新接口

1. 修改 `proto/users/users.proto`
2. 生成代码：`make proto-gen`
3. 在 `internal/handler/` 中实现处理器
4. 在 `internal/service/` 中实现业务逻辑
5. 在 `internal/repository/` 中实现数据访问
6. 添加单元测试
7. 更新 API 文档

### 代码规范

- 使用 `gofmt` 格式化代码
- 遵循 Go 命名约定
- 添加必要的注释
- 错误处理要完整
- 使用接口进行依赖注入
