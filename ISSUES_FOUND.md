# anythingllm-fix 仓库 — 问题汇总

## 一、上游代码 Bug（已修复）

### Bug 1: 线程切换导致流式回复丢失（Critical）
- **现象:** 切换聊天线程后，正在进行的 SSE 回复彻底丢失
- **根因:** `ChatContainer/index.jsx` 的 `useEffect` 依赖数组包含 `chatHistory`，每次 SSE chunk 更新状态都会触发 effect 重建 AbortController，导致流式传输在第一个 chunk 后卡死
- **官方 Issue:** #5195（2026年3月提出，至今 Open）
- **修复:** 用 `useRef` 替代闭包捕获，从依赖数组移除 `chatHistory`；服务端检测断连后持久化孤儿消息
- **涉及文件:** ChatContainer/index.jsx, workspace.js, workspaceThread.js, responses.js, stream.js

### Bug 2: Agent Session 空指针崩溃（High）
- **现象:** Agent 模式下 WebSocket 连接异常断开
- **根因:** 外部 AbortSignal 传入时 `ctrl` 被置 null，但 onopen/onerror 回调中 3 处 `ctrl.abort()` 未做空值守卫
- **修复:** 所有 `ctrl.abort()` 前加 `if (ctrl)` 守卫
- **涉及文件:** frontend/src/models/workspace.js

### Bug 3: 推理 Token 在重构中被删除（Medium）
- **现象:** DeepSeek 等模型的思维链过程对用户不可见
- **根因:** PR 合并重构时整体移除了 reasoning token 处理逻辑
- **官方 Issue:** #5676（2026年5月提出）, #3553（2025年3月提出，超过一年未解决）
- **修复:** 恢复完整 reasoning token 处理代码块
- **涉及文件:** server/utils/helpers/chat/responses.js

### Bug 4: chatPrompt 参数缺失导致记忆检索失效（Medium）
- **现象:** AI "忘记之前的对话"，长期记忆不生效
- **根因:** `chatPrompt(workspace, user)` 缺少第三个参数 `{ prompt, rawHistory }`
- **修复:** 恢复完整参数调用
- **涉及文件:** server/utils/chats/stream.js

### Bug 5: usage.duration 用量指标丢失（Low）
- **现象:** Cerebras 等 Provider 的用量面板缺少响应时间数据
- **根因:** 重构中移除了 `usage.duration` 提取逻辑
- **修复:** 恢复提取代码
- **涉及文件:** server/utils/helpers/chat/responses.js

### Bug 6: SourcesSidebarProvider 未导出导致构建失败（Critical）
- **现象:** Vite/Rollup 构建报错 "SourcesSidebarProvider is not exported"
- **根因:** ChatContainer 导入 `{ SourcesSidebarProvider }` from `./SourcesSidebar`，但 SourcesSidebar 只 re-export 了 `useSourcesSidebar`，没有 re-export Provider
- **修复:** 在 SourcesSidebar/index.jsx 添加 `export { ChatSidebarProvider as SourcesSidebarProvider } from "../ChatSidebar"`
- **涉及文件:** frontend/src/components/WorkspaceChat/ChatContainer/SourcesSidebar/index.jsx

## 二、仓库配置问题（已修复）

### 问题 7: .gitignore 误忽略 yarn.lock
- **现象:** Docker build 报错 "yarn.lock: not found"
- **根因:** 根目录 .gitignore 包含 `yarn.lock` 规则，导致 frontend 和 server 的 lock 文件未被提交
- **修复:** 从 .gitignore 移除 `yarn.lock`，补提交缺失的 lock 文件

### 问题 8: Docker compose 路径错误
- **现象:** README 写的 `docker compose up -d` 在根目录执行会失败
- **根因:** docker-compose.yml 在 `docker/` 子目录
- **修复:** README 中改为 `cd docker && docker compose up -d`

### 问题 9: 本地开发命令错误
- **现象:** README 写的 `yarn dev` 在根目录不存在
- **根因:** 根目录只有 `yarn dev:all`、`yarn dev:server` 等脚本
- **修复:** README 中改为 `yarn setup` + `yarn dev:all`

## 三、待验证

- Docker build 是否能完整通过（上次卡在 SourcesSidebarProvider 修复后的重新 build）
- 修复后的代码能否正常启动并通过基本功能测试
