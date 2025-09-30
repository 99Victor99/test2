# Proto Submodule 管理指南

## 🎯 重要原则

**Proto submodule 目录只能包含 proto 相关文件，不能包含项目代码结构！**

## 📁 正确的 Proto Submodule 结构

### ✅ 正确示例

```
proto/users/                    # Git Submodule
├── .git                       # Git submodule 标记文件
├── users.proto                # Proto 定义文件
├── README.md                  # Proto 说明文档
└── (可选) 其他 .proto 文件
```

### ❌ 错误示例

```
proto/users/                    # Git Submodule
├── .git
├── users.proto
├── cmd/                       # ❌ 不应该有项目代码结构
├── internal/                  # ❌ 不应该有项目代码结构
├── pkg/                       # ❌ 不应该有项目代码结构
└── ...
```

## 🔍 为什么这样设计？

### 1. **职责分离**
- **Proto Repository**: 只负责接口定义
- **Service Repository**: 负责具体实现

### 2. **版本管理**
- Proto 版本独立于服务版本
- 多个服务可以共享同一个 proto 版本
- 便于接口向后兼容性管理

### 3. **团队协作**
- 接口设计团队专注于 proto 定义
- 服务开发团队专注于业务实现
- 避免代码冲突和混乱

## 🛠️ 正确的工作流程

### Proto 开发流程

```bash
# 1. 进入 proto submodule
cd proto/users

# 2. 修改 proto 文件
vim users.proto

# 3. 提交 proto 更改
git add users.proto
git commit -m "feat: 添加用户角色字段"
git tag v1.2.0
git push origin main --tags

# 4. 回到主项目
cd ../..

# 5. 更新 submodule 指针
git add proto/users
git commit -m "update: users proto to v1.2.0"
```

### 服务代码开发流程

```bash
# 1. 在主项目中开发
vim internal/service/user_service.go

# 2. 生成 proto 代码
make proto-gen

# 3. 提交服务代码
git add .
git commit -m "feat: 实现用户角色功能"
```

## 📋 检查清单

在提交前，请确保：

- [ ] `proto/*/` 目录只包含 `.proto` 文件和 `README.md`
- [ ] 没有 `cmd/`, `internal/`, `pkg/` 等项目结构目录
- [ ] Proto 文件语法正确
- [ ] 版本标签符合语义化版本规范

## 🔧 清理命令

如果意外添加了项目结构，使用以下命令清理：

```bash
# 清理所有 proto submodule 中的项目结构
for proto_dir in proto/*/; do
    if [ -d "$proto_dir" ]; then
        cd "$proto_dir"
        rm -rf cmd internal pkg deployments docs scripts
        cd - > /dev/null
    fi
done
```

## 🚨 常见错误

### 1. 在 proto submodule 中创建项目结构
**错误**: 在 `proto/users/` 中创建 `cmd/`, `internal/` 等目录
**解决**: 删除这些目录，只保留 `.proto` 文件

### 2. 混合提交 proto 和服务代码
**错误**: 同时修改 proto 文件和服务代码，一次性提交
**解决**: 分别提交 proto 更改和服务代码更改

### 3. 忘记更新 submodule 指针
**错误**: 修改了 proto 但没有在主项目中更新 submodule 指针
**解决**: 使用 `git add proto/users && git commit` 更新指针

## 📚 相关文档

- [Git Submodule 官方文档](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Protocol Buffers 语言指南](https://developers.google.com/protocol-buffers/docs/proto3)
- [项目架构说明](PROJECT_STRUCTURE.md)
- [个人开发指南](PERSONAL_DEV_GUIDE.md)

---

**记住**: Proto submodule 是接口定义的地方，不是项目代码的地方！
