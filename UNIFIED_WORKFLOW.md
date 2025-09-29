# 统一发版工作流 - Proto + 接口一体化

## 🎯 核心理念

**Proto 和接口实现应该一起更改，一句命令统一 commit 和发版**

## 🚀 快速开始

### 方式一：使用 Makefile（推荐）
```bash
# 查看所有命令
make help

# 开发模式（验证 + 生成代码）
make dev

# 发布新功能
make release-minor DESC="添加用户角色功能"

# 修复 bug
make release-patch DESC="修复用户验证错误"

# 推送更新
make push
```

### 方式二：直接使用脚本
```bash
# 统一发版
./unified_release.sh minor "添加用户角色功能"

# 推送更新
./unified_release.sh push

# 查看状态
./unified_release.sh status
```

## 📋 完整工作流

### 1. 日常开发
```bash
# 1. 修改 proto 文件
vim proto/users/users.proto

# 2. 修改接口实现
vim internal/service/user_service.go

# 3. 一键发版
make release-minor DESC="添加用户角色功能"

# 4. 推送更新
make push
```

### 2. 紧急修复
```bash
# 一键热修复（patch + push）
make hotfix DESC="修复用户验证漏洞"
```

## 🔄 自动化流程

### 统一发版脚本做了什么？
1. ✅ **验证 proto 语法** - 确保 proto 文件正确
2. ✅ **生成代码** - 自动生成 Go 代码
3. ✅ **运行测试** - 验证代码变更
4. ✅ **版本管理** - 自动计算版本号
5. ✅ **双重提交** - 同时提交 proto 和服务代码
6. ✅ **标签创建** - 创建 proto 和服务版本标签
7. ✅ **状态同步** - 更新 submodule 引用

### 版本策略
```bash
# Proto 和服务版本保持同步
Proto 版本:   v1.3.0
服务版本:     v1.3.0

# 语义化版本
major: 破坏性变更 (v1.0.0 -> v2.0.0)
minor: 新功能 (v1.0.0 -> v1.1.0)
patch: 修复 (v1.0.0 -> v1.0.1)
```

## 🏭 多服务协作

### 发版通知流程
```bash
# 1. 你的服务发版
make release-minor DESC="添加用户角色功能"
make push
# 输出: Proto v1.3.0, Service v1.3.0

# 2. 通知其他服务团队
# "users proto 已更新到 v1.3.0，新增用户角色功能"

# 3. 其他服务选择升级
goods-service:
  cd proto/users && git fetch --tags && git checkout v1.3.0

orders-service:
  cd proto/users && git fetch --tags && git checkout v1.3.0
```

## 📊 对比传统方式

| 步骤 | 传统方式 | 统一发版 |
|------|----------|----------|
| 修改 proto | ✅ 手动 | ✅ 手动 |
| 生成代码 | ❌ 手动 protoc | ✅ 自动 |
| 修改接口 | ✅ 手动 | ✅ 手动 |
| 运行测试 | ❌ 容易遗忘 | ✅ 自动 |
| 提交 proto | ❌ 手动 | ✅ 自动 |
| 版本标签 | ❌ 手动计算 | ✅ 自动 |
| 提交服务 | ❌ 手动 | ✅ 自动 |
| 推送更新 | ❌ 多次推送 | ✅ 一键推送 |
| **出错概率** | **高** | **低** |
| **耗时** | **5-10分钟** | **30秒** |

## 🛡️ 安全检查

### 发版前检查
- ✅ Proto 语法验证
- ✅ 代码生成验证
- ✅ 单元测试通过
- ✅ 工作区状态检查
- ✅ 版本号合规检查

### 回滚支持
```bash
# 查看版本历史
git tag --sort=-version:refname

# 回滚到指定版本
cd proto/users && git checkout v1.2.0
cd ../.. && git add . && git commit -m "Rollback to v1.2.0"
```

## 🎉 优势总结

### ✅ 开发效率
- **一句命令** 完成所有发版步骤
- **自动化** 减少人为错误
- **标准化** 统一团队工作流

### ✅ 版本管理
- **同步版本** proto 和服务版本一致
- **语义化** 清晰的版本递增规则
- **可追溯** 完整的变更历史

### ✅ 团队协作
- **标准接口** 所有服务使用相同 proto 版本
- **渐进升级** 各服务可按需升级
- **变更通知** 清晰的发版通知流程

## 🔧 故障排除

### 常见问题
```bash
# 1. protoc 未安装
brew install protobuf  # macOS
apt install protobuf-compiler  # Ubuntu

# 2. 工作区不干净
git status  # 查看未提交文件
git add . && git commit -m "WIP"

# 3. 测试失败
go test -v ./...  # 查看详细错误

# 4. 版本冲突
git tag  # 查看现有标签
```

## 📝 最佳实践

1. **描述清晰** - 每次发版都写清楚的功能描述
2. **测试优先** - 确保测试通过再发版
3. **小步快跑** - 频繁发布小版本，避免大版本积累
4. **通知及时** - 破坏性变更要提前通知
5. **文档同步** - 重要变更要更新文档

---

🎯 **一句话总结：统一发版让 Proto + 接口开发从繁琐变简单，从容易出错变可靠！**
