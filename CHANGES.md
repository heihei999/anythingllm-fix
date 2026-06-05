# AnythingLLM Fix — 变更记录

本仓库基于 Mintplex-Labs/anything-llm 官方代码，修复了多个影响日常使用的严重缺陷。以下问题在官方仓库中已有用户报告（附 issue 编号），但长期未被修复或在代码重构中被意外引入。

---

## 修复 1: 线程切换导致流式回复丢失

**严重程度:** Critical
**影响范围:** 所有使用流式传输的聊天场景
**官方 Issue:** [#5195](https://github.com/Mintplex-Labs/anything-llm/issues/5195) — 2026年3月12日提交，至今（6月）仍为 Open 状态，多名用户确认复现

**问题描述:**

用户在 LLM 回复尚未完成时切换到另一个聊天线程，当前回复会彻底丢失。具体表现为：切换线程后，正在进行的 SSE 连接被前端 `useEffect` 的清理函数中断，服务端收到断连信号后直接终止流式传输，已生成的内容既没有完整返回给用户，也没有持久化到数据库。用户花费了 Token 却看不到结果。

更严重的是，前端 `useEffect` 的依赖数组中包含了 `chatHistory`，而每次 SSE 收到新 chunk 都会调用 `setChatHistory` 更新状态，这触发 `useEffect` 重新执行，创建新的 `AbortController` 并中止上一个连接。结果是流式传输在第一个 chunk 之后就卡死——用户看到的现象是"回复只显示了思考块就停了"。

**修复方案:**

- 使用 `useRef` 替代闭包变量捕获 `chatHistory`，避免 `useEffect` 被反复触发
- 服务端在检测到客户端断连后，不再终止 LLM 流，而是让其自然完成并将完整回复持久化为"孤儿消息"
- 前端通过 `AbortSignal` 通知服务端进入孤儿持久化模式，而非直接中断连接

**涉及文件:**
- `frontend/src/components/WorkspaceChat/ChatContainer/index.jsx`
- `frontend/src/models/workspace.js`
- `frontend/src/models/workspaceThread.js`
- `server/utils/helpers/chat/responses.js`
- `server/utils/chats/stream.js`

---

## 修复 2: Agent Session 空指针崩溃

**严重程度:** High
**影响范围:** Agent 模式下的 WebSocket 通信
**相关讨论:** [#5706](https://github.com/Mintplex-Labs/anything-llm/issues/5706)

**问题描述:**

当外部 `AbortSignal` 传入时，前端代码将内部的 `AbortController` 引用设为 `null`，这是为了避免双重中止冲突。但 `onopen` 和 `onerror` 回调中仍有三处直接调用 `ctrl.abort()` 而未做空值检查，导致 `TypeError: Cannot read properties of null (reading 'abort')` 崩溃，WebSocket 连接异常断开。

**修复方案:**

所有 `ctrl.abort()` 调用前增加 `if (ctrl)` 空值守卫，与同仓库 `workspaceThread.js` 中的已有模式保持一致。

**涉及文件:**
- `frontend/src/models/workspace.js`

---

## 修复 3: 推理 Token（Reasoning Token）在重构中被删除

**严重程度:** Medium
**影响范围:** 使用 DeepSeek、Cerebras 等支持推理输出的模型
**官方 Issue:** [#5676](https://github.com/Mintplex-Labs/anything-llm/issues/5676) — 2026年5月提交，至今 Open；[#3553](https://github.com/Mintplex-Labs/anything-llm/issues/3553) — 2025年3月提交，超过一年未解决

**问题描述:**

上游代码中有一套完整的 reasoning token 处理逻辑：从 `delta.reasoning_content` 或 `delta.reasoning` 字段提取推理内容，包裹在 `<think>` 标签中流式输出，并在推理结束后平滑过渡到正式回复内容。这套逻辑在 PR 合并的代码重构过程中被整体移除，导致 DeepSeek 等模型的思维链过程对用户完全不可见。

**修复方案:**

从上游恢复完整的 reasoning token 处理代码块，包括字段提取、`<think>` 标签初始化与流式输出、推理到内容的过渡状态管理，以及所有写入操作的 `clientDisconnected` 守卫。

**涉及文件:**
- `server/utils/helpers/chat/responses.js`

---

## 修复 4: chatPrompt 参数缺失导致记忆检索失效

**严重程度:** Medium
**影响范围:** 使用长期记忆（Long-term Memory）功能的聊天

**问题描述:**

`streamChatWithWorkspace` 中调用 `chatPrompt(workspace, user)` 时缺少第三个参数 `{ prompt: updatedMessage, rawHistory }`。`chatPrompt` 内部的 `promptWithMemories` 函数依赖这个参数来构建带记忆上下文的系统提示词。参数缺失导致记忆重排序和上下文注入完全失效，用户会感觉 AI "忘记了之前的对话"。

**修复方案:**

恢复完整调用：`chatPrompt(workspace, user, { prompt: updatedMessage, rawHistory })`。

**涉及文件:**
- `server/utils/chats/stream.js`

---

## 修复 5: 用量指标 duration 丢失

**严重程度:** Low
**影响范围:** Cerebras 等提供完成时间统计的 Provider 的用量追踪

**问题描述:**

上游代码从 `chunk.usage.time_info.completion_time` 中提取 `usage.duration` 用于统计模型推理耗时，该代码块在重构中被移除，导致这些 Provider 的用量面板中缺少响应时间数据。

**修复方案:**

恢复 `usage.duration` 提取逻辑。

**涉及文件:**
- `server/utils/helpers/chat/responses.js`

---

## 已知局限

1. **孤儿持久化仅适用于默认 Provider:** 使用自定义 `handleStream` 实现的 Provider（OpenAI、Anthropic、Cohere 等）暂不支持线程切换时的孤儿消息持久化，需要逐个 Provider 适配 `persistContext` 参数。
2. **Agent WebSocket 模式未纳入孤儿持久化:** 通过 `/api/agent-invocation` 管理的 Agent 会话目前不在孤儿持久化流程内。

---

## 构建说明

### 环境要求
- Node.js >= 18
- yarn 或 npm

### 开发模式
```bash
# 后端
cd server && yarn install && yarn dev    # 端口 3001

# 前端
cd frontend && yarn install && yarn dev  # 端口 3000
```

### 生产构建
```bash
cd frontend && yarn build    # 输出到 frontend/dist/
cd ../server && yarn start   # 同时提供前端静态文件和 API
```

### 环境配置
复制 `.env.example` 为 `.env`，按需配置 LLM Provider、向量数据库等参数。
