# AnythingLLM Fix

社区维护的 AnythingLLM Bug 修复分支。基于 [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm) 官方仓库，专注修复影响日常使用的严重缺陷。不添加额外功能，保持与上游的高度同步。

## 定位

- 仅修复 Bug，不引入新功能或重构
- 定期与上游 master 同步
- 每次修复附带详细变更记录
- 所有改动经过代码审查

## 当前修复内容

详见 [CHANGES.md](./CHANGES.md)

主要修复：

1. 线程切换后流式回复丢失（[#5195](https://github.com/Mintplex-Labs/anything-llm/issues/5195)，上游 3 月提出至今未修）
2. Agent Session 空指针崩溃
3. 推理 Token 在代码重构中被删除（[#5676](https://github.com/Mintplex-Labs/anything-llm/issues/5676)）
4. chatPrompt 参数缺失导致记忆检索失效
5. 用量指标 duration 丢失

## 快速开始

### 环境要求

- Node.js >= 18.12（推荐使用 nvm 切换）
- yarn
- Docker（可选，用于容器化部署）

### Docker 部署

```bash
git clone https://github.com/heihei999/anythingllm-fix.git
cd anythingllm-fix/docker

# 复制环境配置
cp .env.example .env
# 按需编辑 .env（默认配置即可启动）

# 启动
docker compose up -d
# 访问 http://localhost:3001
```

### 本地开发

```bash
git clone https://github.com/heihei999/anythingllm-fix.git
cd anythingllm-fix

# 一键安装依赖 + 初始化环境
yarn setup

# 同时启动 server、frontend、collector
yarn dev:all
# 或者分三个终端分别运行：
#   yarn dev:server    (端口 3001)
#   yarn dev:frontend  (端口 3000)
#   yarn dev:collector
```

### 生产构建

```bash
yarn prod:frontend   # 构建前端到 frontend/dist/
yarn prod:server     # 启动生产服务
```

## 与上游同步

```bash
git remote add upstream https://github.com/Mintplex-Labs/anything-llm.git
git fetch upstream master
git merge upstream/master
```

## 修复原则

1. 最小改动 — 只修改存在问题的代码，不做无关重构
2. 向上兼容 — 修复不改变 API 接口和用户数据格式
3. 可追溯 — 每个修复在 CHANGES.md 中有详细记录
4. 及时同步 — 上游发布新版本后尽快合并

## 贡献

如发现官方仓库的 Bug 但上游 PR 长期未合并，欢迎提交 Issue 或 Pull Request。

## License

与上游保持一致：MIT
