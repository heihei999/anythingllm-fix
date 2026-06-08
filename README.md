# AnythingLLM Fix

社区维护的 AnythingLLM Bug 修复分支。基于 [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm) 官方仓库，专注修复影响日常使用的严重缺陷。不添加额外功能，保持与上游的高度同步。

## 修复了什么

1. **切换对话后流式回复丢失** — 写着写着突然断了（[#5195](https://github.com/Mintplex-Labs/anything-llm/issues/5195)，上游 5 个月没修）
2. **Agent 会话崩溃** — 使用 Agent 时软件闪退（[#5676](https://github.com/Mintplex-Labs/anything-llm/issues/5676)）
3. **推理模型回复异常** — 使用 Cerebras 等推理模型时 Token 丢失（[#3553](https://github.com/Mintplex-Labs/anything-llm/issues/3553)）
4. **聊天上下文丢失** — 某些情况下对话记忆失效
5. **使用统计不准** — 推理耗时不显示

## 桌面版用户：一键修复（推荐）

**三步搞定，不需要懂技术：**

1. **下载** — 从 [Releases](https://github.com/heihei999/anythingllm-fix/releases) 下载最新补丁包，解压
2. **双击** `patcher.bat`
3. **完成** — 重新打开 AnythingLLM 即可

**前提条件：** 电脑上需要安装 [Node.js](https://nodejs.org/)（下载 LTS 版本，安装后重启一次电脑就行）。没装的话双击补丁会提示你去下载。

**不会影响你的数据。** 聊天记录、文档、设置都保存在别的目录，补丁只改程序文件。

**出了问题可以恢复。** 补丁会自动备份原文件，想恢复原版只要把 `app.asar.bak` 改名为 `app.asar`。

详见 [desktop-patcher/README.md](./desktop-patcher/README.md)。

## Docker 部署

```bash
git clone https://github.com/heihei999/anythingllm-fix.git
cd anythingllm-fix/docker

cp .env.example .env
# 按需编辑 .env（默认配置即可启动）

docker compose up -d
# 访问 http://localhost:3001
```

## 本地开发

```bash
git clone https://github.com/heihei999/anythingllm-fix.git
cd anythingllm-fix

yarn setup
yarn dev:all
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
