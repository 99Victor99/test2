# Proto 仓库分支策略分析

## 🎯 核心问题：proto/users 需要 dev/prod 环境分支吗？

### ❌ **通常不需要环境分支**

Proto 定义是**接口契约**，不是**运行时代码**，因此：

## 📋 Proto vs 业务代码的区别

| 特性 | 业务代码 | Proto 定义 |
|------|----------|------------|
| **性质** | 运行时逻辑 | 接口契约 |
| **环境差异** | 有（配置、数据库等） | 无 |
| **部署方式** | 编译部署 | 编译时集成 |
| **版本管理** | 环境分支 | 语义化标签 |

## 🏭 业界标准做法

### 1. Google APIs
```
googleapis/
├── main (唯一分支)
└── tags: v1.0.0, v1.1.0, v2.0.0...
```

### 2. Kubernetes API  
```
k8s.io/api/
├── main (唯一分支)
└── tags: v1.28.0, v1.29.0...
```

### 3. gRPC Protos
```
grpc/grpc-proto/
├── main (唯一分支)  
└── tags: v1.0.0, v1.1.0...
```

## ✅ **推荐的 Proto 分支策略**

### 单分支 + 标签管理
```
userproto/
├── main                    # 唯一分支，持续开发
├── tags/
│   ├── v1.0.0             # 稳定版本
│   ├── v1.1.0             # 功能更新
│   ├── v1.2.0             # 新功能
│   └── v2.0.0             # 破坏性变更
```

### 各服务引用不同版本
```
# 开发环境
users-service-dev:   users-proto@v1.2.0
goods-service-dev:   users-proto@v1.1.0

# 生产环境  
users-service-prod:  users-proto@v1.1.0
goods-service-prod:  users-proto@v1.0.0
```

## 🚫 **为什么不需要环境分支？**

### 1. Proto 没有环境差异
```protobuf
// proto 定义在所有环境都相同
message User {
  int32 uid = 1;
  string name = 2;
  string email = 3;
}
```

### 2. 版本通过标签管理
```bash
# 不同环境使用不同版本标签
dev:  git checkout v1.2.0
test: git checkout v1.1.0  
prod: git checkout v1.0.0
```

### 3. 避免分支管理复杂度
```bash
# ❌ 复杂的分支管理
main -> dev -> test -> prod (4个分支需要维护)

# ✅ 简单的标签管理
main + tags (1个分支，多个版本)
```

## ⚠️ **特殊情况：什么时候需要分支？**

### 1. 长期并行开发
```bash
main                    # 稳定版本开发
feature/v2-redesign     # 大版本重构（长期）
```

### 2. 维护多个主版本
```bash
main                    # v2.x 开发
release/v1.x           # v1.x 维护（安全修复）
```

### 3. 实验性功能
```bash
main                    # 稳定功能
experimental/new-auth   # 实验性认证功能
```

## 🎯 **具体建议**

### 对于你的 users proto：

#### ✅ **推荐方案：单分支 + 标签**
```bash
userproto/
├── main                # 主开发分支
├── v1.0.0             # 初始版本
├── v1.1.0             # 添加角色字段
├── v1.2.0             # 添加权限字段
└── v2.0.0             # 重构用户结构
```

#### 🔄 **工作流程**
```bash
# 1. 开发新功能
git checkout main
vim users.proto
git commit -m "feat: add user role"

# 2. 创建版本标签  
git tag v1.1.0

# 3. 各服务选择版本
users-service: git checkout v1.1.0
goods-service: git checkout v1.0.0  # 暂不升级
```

## 📊 **环境管理通过服务层实现**

### Proto 层：版本管理
```bash
# proto 只管版本，不管环境
users-proto: v1.0.0, v1.1.0, v1.2.0
```

### 服务层：环境管理
```bash
# 服务管理环境差异
users-service/
├── dev/     # 开发环境配置
├── test/    # 测试环境配置  
├── prod/    # 生产环境配置
└── proto/users/ (submodule) # 引用特定版本
```

## 🏆 **最佳实践总结**

### Do's ✅
1. **Proto 仓库使用单分支 + 标签**
2. **语义化版本管理**（v1.0.0, v1.1.0, v2.0.0）
3. **各服务独立选择 proto 版本**
4. **环境差异在服务层处理**

### Don'ts ❌
1. **不要为 proto 创建环境分支**
2. **不要让 proto 包含环境特定配置**
3. **不要在 proto 中处理业务逻辑差异**

## 🎉 **结论**

**proto/users 不需要 dev/prod 等环境分支！**

**原因**：
- Proto 是接口定义，所有环境都相同
- 版本通过标签管理更清晰
- 环境差异应该在服务层处理
- 简化分支管理，减少复杂度

**推荐**：保持 main 单分支 + 语义化版本标签的简洁策略！
