# 个人开发流程指南 - 多人协作场景

## 🎯 场景描述

**团队协作模式**：
- 多人同时开发一个迭代
- 每人维护私有功能分支
- 不断向 dev 分支合并
- 通知运维测试环境发版

## 📋 完整个人操作流程

### 1. 开始新功能开发
```bash
# 创建个人功能分支（自动基于最新 dev）
./personal_dev_workflow.sh start user-role

# 输出示例：
# 功能分支创建完成: feature/zhangsan/user-role
```

### 2. 日常开发循环

#### ❌ 问题：原版本只处理主项目提交
```bash
# 修改代码
vim proto/users/users.proto      # 修改 proto
vim internal/service/user.go     # 修改业务逻辑

# 主git提交到个人分支（自动验证、测试、生成代码）, proto变更先不提交.
./personal_dev_workflow.sh commit "添加用户角色字段"
# ⚠️ 问题：proto 更改没有提交和版本管理！
```

#### ✅ 解决：增强版本（完整的 Submodule 处理）
```bash
# 修改代码
vim proto/users/users.proto      # 修改 proto（submodule）
vim internal/service/user.go     # 修改业务逻辑

# 增强版提交（自动处理 proto 版本管理）
./enhanced_personal_workflow.sh commit "添加用户角色字段" minor

# 自动化流程：
# 1. ✅ 检测 proto 文件修改
# 2. ✅ 验证 proto 语法  
# 3. ✅ 在 proto submodule 中提交更改
# 4. ✅ 创建 proto 版本标签（如 v1.3.0）
# 5. ✅ 推送 proto 更改到远程
# 6. ✅ 更新主项目的 submodule 指针
# 7. ✅ 生成最新的 proto 代码
# 8. ✅ 运行测试验证
# 9. ✅ 提交主项目更改

# 同步最新代码
./enhanced_personal_workflow.sh sync
```

### 3. 功能完成，合并到 dev

#### 基础版本
```bash
# 合并到 dev 分支（自动推送）
./personal_dev_workflow.sh merge
```

#### 增强版本（包含 Proto 版本信息）⭐️ **推荐**
```bash
# 增强版合并到 dev 分支
./enhanced_personal_workflow.sh merge

# 输出示例：
# ✅ 功能已合并到 dev 分支
# 📢 完整的运维部署通知:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 dev 分支已更新，请部署测试环境
# 
# 📋 功能信息:
#   - 功能分支: feature/zhangsan/user-role
#   - 开发者: 张三
#   - 主项目提交: a1b2c3d
# 
# 📦 Proto 版本信息:
#   - proto/users: v1.3.0 (def4567)
#   - proto/goods: v2.1.0 (abc1234)
#   - proto/orders: v1.0.0 (xyz9876)
# 
# ⏰ 更新时间: 2024-01-15 14:30:00
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4. 通知运维测试环境发版
```bash
# 发送消息给运维（钉钉/企微/邮件）：
"dev 分支已更新，请部署测试环境
- 功能: 添加用户角色字段
- 分支: dev
- 提交: a1b2c3d  
- 开发者: 张三"
```

## 🔄 分支流转图

```
个人分支                    dev分支                     测试环境
    │                        │                          │
    ├─ start ────────────────→│                          │
    │                        │                          │
    ├─ commit ──┐             │                          │
    ├─ commit ──┼─ 本地开发    │                          │
    ├─ commit ──┘             │                          │
    │                        │                          │
    ├─ merge ────────────────→│                          │
    │                        ├─ 自动推送 ──────────────→│
    │                        │                          ├─ 运维部署
    │                        │                          │
    └─ 删除分支               │                          │
```

## 📊 多人协作时间线

```
时间线    张三              李四              王五              dev分支
─────────────────────────────────────────────────────────────────────
09:00   start user-role                                      
09:30                     start payment                       
10:00   commit "字段1"                                        
10:30                     commit "支付1"    start order       
11:00   commit "字段2"                                        
11:30                                       commit "订单1"    
12:00   merge ──────────────────────────────────────────────→ 合并1
12:30                     merge ──────────────────────────────→ 合并2
13:00                                       commit "订单2"    
13:30                                       merge ───────────→ 合并3
14:00                                                         通知运维
```

## 🛠️ 工具使用示例

### 查看当前状态
```bash
$ ./personal_dev_workflow.sh status

=== 个人开发状态 ===
[INFO] 当前分支: feature/zhangsan/user-role
[INFO] 用户信息: 张三 <zhangsan@company.com>
[SUCCESS] 工作区干净

[INFO] 个人功能分支:
  feature/zhangsan/user-role
  feature/zhangsan/user-permission

[INFO] 与 dev 分支的差异:
  领先 dev: 3 个提交
  落后 dev: 1 个提交
[WARNING] 建议运行 './personal_dev_workflow.sh sync' 同步最新代码
```

### 同步最新代码
```bash
$ ./personal_dev_workflow.sh sync

[STEP] 同步 dev 分支最新代码...
[INFO] 更新本地 dev 分支...
[SUCCESS] dev 分支已更新
[SUCCESS] 已同步 dev 分支最新代码
```

## ⚠️ 常见问题处理

### 1. 合并冲突
```bash
# 同步时遇到冲突
./personal_dev_workflow.sh sync
# 手动解决冲突
vim conflicted_file.go
git add .
git commit -m "resolve merge conflict"
```

### 2. Proto 语法错误
```bash
# 提交时自动检查
./personal_dev_workflow.sh commit "修改proto"
# 如果语法错误，修复后重新提交
vim proto/users/users.proto
./personal_dev_workflow.sh commit "修复proto语法"
```

### 3. 测试失败
```bash
# 提交时自动运行测试
./personal_dev_workflow.sh commit "新功能"
# 如果测试失败，修复后重新提交
vim internal/service/user_test.go
./personal_dev_workflow.sh commit "修复测试"
```

## 🏆 最佳实践

### 1. 分支命名规范
```bash
feature/用户名/功能名
feature/zhangsan/user-role
feature/lisi/payment-gateway
feature/wangwu/order-status
```

### 2. 提交信息规范
```bash
# 好的提交信息
./personal_dev_workflow.sh commit "添加用户角色字段"
./personal_dev_workflow.sh commit "修复用户权限验证"
./personal_dev_workflow.sh commit "重构用户服务接口"

# 避免的提交信息
./personal_dev_workflow.sh commit "修改"
./personal_dev_workflow.sh commit "fix bug"
```

### 3. 开发节奏建议
```bash
# 频繁小提交（推荐）
09:00 - commit "添加字段定义"
10:00 - commit "实现字段验证"  
11:00 - commit "添加单元测试"
12:00 - merge

# 避免大批量提交
一天结束 - commit "完成整个功能"
```

### 4. 协作沟通
```bash
# 合并前检查
git log dev..HEAD --oneline  # 查看即将合并的提交

# 合并后通知
"dev分支已更新，包含用户角色功能，请部署测试环境"
```

## 🎉 总结

这套个人开发流程：
- ✅ **自动化程度高** - 一句命令完成复杂操作
- ✅ **多人协作友好** - 避免分支冲突和代码污染
- ✅ **质量保证** - 自动验证、测试、代码生成
- ✅ **运维集成** - 清晰的发版通知流程

## 📊 原版 vs 增强版对比

| 功能 | 原版 personal_dev_workflow.sh | 增强版 enhanced_personal_workflow.sh |
|------|-------------------------------|-------------------------------------|
| **主项目提交** | ✅ 支持 | ✅ 支持 |
| **Proto 修改检测** | ❌ 不处理 | ✅ 自动检测 |
| **Proto 语法验证** | ❌ 跳过 | ✅ 自动验证 |
| **Proto 版本管理** | ❌ 手动处理 | ✅ 自动创建标签 |
| **Submodule 提交** | ❌ 遗漏 | ✅ 自动提交推送 |
| **Submodule 指针更新** | ❌ 手动 | ✅ 自动更新 |
| **运维通知信息** | ❌ 基础 | ✅ 包含 Proto 版本 |
| **多 Proto 支持** | ❌ 不支持 | ✅ 支持多个 submodule |

## 🎯 推荐使用方案

### 场景 1：只修改业务代码
```bash
# 使用原版即可
./personal_dev_workflow.sh commit "修复用户服务bug"
```

### 场景 2：修改了 Proto 文件 ⭐️
```bash
# 必须使用增强版
./enhanced_personal_workflow.sh commit "添加用户角色字段" minor
```

### 场景 3：大型功能开发
```bash
# 推荐全程使用增强版
./enhanced_personal_workflow.sh start user-management
./enhanced_personal_workflow.sh commit "添加用户CRUD接口" minor  
./enhanced_personal_workflow.sh commit "添加权限验证" patch
./enhanced_personal_workflow.sh merge
```

## 🏆 核心命令记忆

### 增强版命令：
1. `start` - 开始新功能
2. `commit "描述" [版本类型]` - 智能提交（处理 proto）
3. `merge` - 智能合并（包含 proto 版本信息）
4. `status` - 完整状态（主项目 + 所有 submodule）

### 版本类型：
- `major` - 破坏性变更 (v1.0.0 → v2.0.0)
- `minor` - 新功能 (v1.0.0 → v1.1.0) 
- `patch` - 修复 (v1.0.0 → v1.0.1) [默认]

**一句话总结：原版处理主项目，增强版处理完整的 Submodule Proto 生态！** 🚀
