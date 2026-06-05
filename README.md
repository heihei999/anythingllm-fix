# AnythingLLM Fix

> 🩹 **社区维护的 Bug 修复版** — 官方修不动的 Bug，我们来修。

本仓库基于 [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm) 官方仓库，专注修复影响日常使用的严重 Bug。不添加无关功能，保持与上游的高度同步。

## 🎯 定位

- ✅ 只修 Bug，不加花哨功能
- ✅ 紧跟上游 master，定期同步
- ✅ 每次修复附带详细变更说明
- ✅ 所有修复经过 Claude Code 深度审查

## 📦 当前修复内容

详见 [CHANGES.md](./CHANGES.md)

主要修复：
1. **线程切换流式中断** — 切换聊天线程后 SSE 流假死
2. **Agent Session 崩溃** — `ctrl.abort()` 空指针导致 WebSocket 断连
3. **推理 Token 丢失** — reasoning_content 在流式传输中被丢弃
4. **聊天参数缺失** — stream.js 中 chatPrompt 参数不完整
5. **用量指标丢失** — usage.duration 未正确传递

## 🚀 快速开始

```bash
# 克隆
git clone https://github.com/heihei999/anythingllm-fix.git
cd anythingllm-fix

# 启动（与官方相同）
docker compose up -d
# 或
yarn dev
```

## 🔄 与上游同步

```bash
git remote add upstream https://github.com/Mintplex-Labs/anything-llm.git
git fetch upstream master
git merge upstream/master
```

## 📋 修复原则

1. **最小改动** — 只修改有问题的代码，不做重构
2. **向上兼容** — 修复不改变 API 接口和用户数据格式
3. **可追溯** — 每个修复在 CHANGES.md 中有详细记录
4. **及时同步** — 上游发布新版本后尽快合并

## 🤝 贡献

如果你发现了官方仓库的 Bug 但 PR 长期未被合并，欢迎在这里提交 Issue 或 PR。

## 📄 License

与上游保持一致：MIT
