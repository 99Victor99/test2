# 项目架构说明

## 🏗️ 标准 Go 微服务项目结构

```
test2/                          # 项目根目录 (users-service)
├── cmd/                        # 应用程序入口
│   └── server/
│       └── main.go            # 主程序入口
├── internal/                   # 私有应用代码
│   ├── config/                # 配置管理
│   │   └── config.go
│   ├── handler/               # gRPC 处理器 (Controller 层)
│   │   └── user_handler.go
│   ├── service/               # 业务逻辑层 (Service 层)
│   │   └── user_service.go
│   ├── repository/            # 数据访问层 (Repository 层)
│   │   └── user_repository.go
│   └── middleware/            # 中间件
│       └── logging.go
├── pkg/                       # 可被外部应用使用的库代码
│   ├── logger/               # 日志工具
│   │   └── logger.go
│   └── utils/                # 通用工具
│       └── validator.go
├── api/                      # 生成的 proto 代码
│   ├── users/               # users proto 生成的代码
│   ├── goods/               # goods proto 生成的代码
│   └── orders/              # orders proto 生成的代码
├── proto/                   # Proto 定义文件 (submodules)
│   ├── users/              # 本服务的 proto (submodule)
│   │   ├── users.proto     # 用户服务 proto 定义
│   │   └── README.md       # proto 说明文档
│   ├── goods/              # 外部依赖 proto (submodule)
│   │   ├── goods.proto     # 商品服务 proto 定义
│   │   └── README.md
│   └── orders/             # 外部依赖 proto (submodule)
│       ├── orders.proto    # 订单服务 proto 定义
│       └── README.md
├── scripts/                # 构建和部署脚本
│   └── build.sh
├── deployments/            # 部署配置
│   ├── docker/
│   │   └── Dockerfile
│   ├── docker-compose.yml
│   └── init.sql
├── docs/                   # 文档
│   └── API.md
├── tests/                  # 测试文件
├── go.mod                  # Go 模块定义
├── go.sum                  # Go 模块校验
└── README.md              # 项目说明
```

## 📋 目录职责说明

### `/cmd` - 应用程序入口
- **用途**: 存放应用程序的主要入口点
- **原则**: 每个应用一个子目录
- **示例**: `cmd/server/main.go` - gRPC 服务器入口

### `/internal` - 私有应用代码
- **用途**: 不希望被其他应用导入的代码
- **原则**: Go 编译器会阻止其他项目导入 internal 目录中的代码
- **子目录**:
  - `config/` - 配置管理
  - `handler/` - gRPC 处理器 (类似 Controller)
  - `service/` - 业务逻辑层
  - `repository/` - 数据访问层
  - `middleware/` - 中间件

### `/pkg` - 公共库代码
- **用途**: 可以被外部应用使用的库代码
- **原则**: 其他项目可以导入这些库
- **示例**: 日志工具、通用验证器等

### `/api` - 生成的代码
- **用途**: 存放 protobuf 生成的 Go 代码
- **原则**: 自动生成，不要手动修改
- **结构**: 按 proto 服务分目录

### `/proto` - Proto 定义
- **用途**: 存放 protobuf 定义文件
- **管理**: 使用 git submodule 管理
- **策略**: 本服务 proto 和外部依赖 proto
- **重要**: 每个 submodule 只包含 `.proto` 文件和 `README.md`，不包含项目代码

### `/scripts` - 脚本
- **用途**: 构建、安装、分析等脚本
- **示例**: `build.sh`, `deploy.sh`, `test.sh`

### `/deployments` - 部署配置
- **用途**: 容器化、编排、CI/CD 配置
- **包含**: Dockerfile, docker-compose, k8s yaml 等

## 🏛️ 分层架构

### 1. Handler 层 (Presentation Layer)
```go
// internal/handler/user_handler.go
// 职责：
// - 接收 gRPC 请求
// - 参数验证
// - 调用 Service 层
// - 返回响应
// - 错误处理和状态码转换
```

### 2. Service 层 (Business Logic Layer)
```go
// internal/service/user_service.go
// 职责：
// - 业务逻辑处理
// - 数据验证
// - 调用 Repository 层
// - 事务管理
// - 业务规则实现
```

### 3. Repository 层 (Data Access Layer)
```go
// internal/repository/user_repository.go
// 职责：
// - 数据库操作
// - 数据持久化
// - 查询构建
// - 数据映射
```

## 🔄 依赖注入模式

```go
// main.go 中的依赖注入
func main() {
    // 配置
    cfg := config.Load()
    
    // 基础设施
    logger := logger.New(cfg.LogLevel)
    db := database.Connect(cfg.DatabaseURL)
    
    // Repository 层
    userRepo := repository.NewUserRepository(db)
    
    // Service 层
    userService := service.NewUserService(userRepo, logger)
    
    // Handler 层
    userHandler := handler.NewUserHandler(userService, logger)
    
    // gRPC 服务器
    server := grpc.NewServer()
    users.RegisterUsersServiceServer(server, userHandler)
}
```

## 🧪 测试策略

### 单元测试
```
internal/service/user_service_test.go
internal/repository/user_repository_test.go
pkg/utils/validator_test.go
```

### 集成测试
```
tests/integration/user_api_test.go
tests/integration/database_test.go
```

### 端到端测试
```
tests/e2e/user_workflow_test.go
```

## 📦 构建和部署

### 本地开发
```bash
# 1. 生成 proto 代码
make proto-gen

# 2. 运行服务
go run cmd/server/main.go

# 3. 运行测试
go test ./...
```

### Docker 构建
```bash
# 构建镜像
docker build -f deployments/docker/Dockerfile -t users-service .

# 运行容器
docker-compose up
```

### 生产部署
```bash
# 构建多平台二进制
./scripts/build.sh

# 部署到 Kubernetes
kubectl apply -f deployments/k8s/
```

## 🔧 配置管理

### 环境变量
- 开发环境：`.env.development`
- 测试环境：`.env.testing`
- 生产环境：环境变量或配置中心

### 配置优先级
1. 环境变量
2. 配置文件
3. 默认值

## 📊 监控和日志

### 日志
- 结构化日志 (JSON)
- 分级别记录
- 请求追踪

### 监控
- 健康检查
- 性能指标
- 错误率统计

## 🚀 最佳实践

### 代码组织
1. **单一职责**: 每个包只负责一个功能
2. **依赖倒置**: 高层模块不依赖低层模块
3. **接口隔离**: 使用接口定义契约
4. **开闭原则**: 对扩展开放，对修改关闭

### 错误处理
1. **错误包装**: 使用 `fmt.Errorf` 包装错误
2. **错误分类**: 区分业务错误和系统错误
3. **错误日志**: 记录详细的错误信息
4. **优雅降级**: 提供备用方案

### 性能优化
1. **连接池**: 数据库和 Redis 连接池
2. **缓存策略**: 合理使用缓存
3. **批量操作**: 减少数据库往返
4. **异步处理**: 使用 goroutine 处理耗时操作

这个架构遵循了 Go 社区的最佳实践，提供了清晰的分层结构和良好的可维护性！
