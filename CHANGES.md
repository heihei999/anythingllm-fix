# AnythingLLM — Thread-Switch Streaming & Agent Session Hardening

## Overview

This patchset addresses two major classes of issues in AnythingLLM:

1. **Thread-switch streaming loss** — When a user switches threads while an LLM response is still streaming, the response is lost because the server-side SSE connection is closed and the incomplete response is never persisted to the database.

2. **Agent session hardening** — Several crash paths and edge cases in the agent WebSocket flow were causing unhandled errors, race conditions, and missing error handling.

---

## Changes

### PR 1: Thread-Switch Streaming Persistence

**Files changed:**
- `server/utils/helpers/chat/responses.js` — Modified `handleDefaultStreamResponseV2` to detect client disconnection via the response `close` event. Instead of aborting the stream on disconnect, it now lets the LLM stream finish naturally and persists the complete response to the database via `persistOrphanedStream()`.
- `server/utils/chats/stream.js` — Updated `streamChatWithWorkspace` to pass a `persistContext` object (containing workspaceId, prompt, threadId, user, chatMode, attachments) to `handleStream` so that orphaned responses can be saved.
- `frontend/src/components/WorkspaceChat/ChatContainer/index.jsx` — Modified the streaming `useEffect` to pass an `abortSignal` to `Workspace.multiplexStream`. On effect cleanup (thread switch / unmount), the abort signal triggers server-side orphan persistence instead of silently dropping the response.
- `frontend/src/models/workspace.js` — Added `abortSignal` parameter to `streamChat` and `multiplexStream`. When an external signal is provided, the local `AbortController` is set to `null` and the external signal is used directly, avoiding double-abort issues.
- `frontend/src/models/workspaceThread.js` — Same abort signal plumbing as `workspace.js`.

### PR 2: Agent Session Hardening

**Files changed:**
- `frontend/src/utils/chat/index.js` — Added `cacheStreamingHistory` function to allow in-progress streaming messages to be cached and restored when switching back to a thread. Added `clearStreamingHistory` for cleanup on session end.
- `frontend/src/utils/chat/agent.js` — Hardened the agent WebSocket response handler with proper error boundaries, null checks, and consistent state management.
- `server/endpoints/agentWebsocket.js` — Minor hardening of the agent WebSocket endpoint.

---

## Bugs Found and Fixed During Code Review

### Bug 1 (CRITICAL): useEffect chatHistory dependency causes SSE abort loop
**File:** `frontend/src/components/WorkspaceChat/ChatContainer/index.jsx`

The `useEffect` responsible for streaming had `chatHistory` in its dependency array. Every SSE chunk updates `chatHistory` via `setChatHistory(...)`, which triggers the effect to re-run, creating a new `AbortController` and aborting the previous one. This caused streaming to hang after the first chunk.

**Fix:** Added a `chatHistoryRefForEffect` ref that always holds the latest `chatHistory` value. The `fetchReply` function reads from the ref instead of the closure variable. Removed `chatHistory` from the dependency array so the effect only re-runs when `loadingResponse` or `workspace` changes.

### Bug 2 (HIGH): Missing null guard on ctrl.abort()
**File:** `frontend/src/models/workspace.js` (lines 189, 200, 217)

When `abortSignal` is passed externally, `ctrl` is set to `null` (line 153). However, three call sites in `onopen` and `onerror` handlers called `ctrl.abort()` without a null guard, causing `TypeError: Cannot read properties of null` crashes.

**Fix:** Changed all three occurrences to `if (ctrl) ctrl.abort();` to match the pattern used in `workspaceThread.js`.

### Bug 3 (MEDIUM): Reasoning token handling was removed
**File:** `server/utils/helpers/chat/responses.js`

The upstream code handles reasoning tokens (`delta.reasoning_content`, `delta.reasoning`) from models like DeepSeek and Cerebras. These tokens are accumulated in a `<think>` tag wrapper and appended to the full response text. This block was completely removed during the PR's refactoring.

**Fix:** Restored the full reasoning token handling block from upstream, including:
- Extraction of `reasoningToken` from `message?.delta?.reasoning_content || message?.delta?.reasoning`
- Initialization and streaming of `<think>` wrapper tags
- Transition from reasoning to content tokens
- Proper `clientDisconnected` guards on all write calls

### Bug 4 (MEDIUM): Orphan persistence only works with handleDefaultStreamResponseV2
**File:** N/A (design limitation)

The orphan persistence mechanism (`persistContext` + `persistOrphanedStream`) is only invoked for providers that use `handleDefaultStreamResponseV2`. Providers with custom `handleStream` implementations (OpenAI, Anthropic, Cohere, Foundry, Apipie) do not receive or use `persistContext`, so orphaned responses from these providers are still lost on thread switch.

**Status:** Documented as a known limitation. Fixing this would require updating each provider's custom `handleStream` to accept and use the `persistContext` parameter.

### Bug 5 (MEDIUM): chatPrompt missing third argument
**File:** `server/utils/chats/stream.js`

The `chatPrompt(workspace, user)` call was missing the third argument `{ prompt: updatedMessage, rawHistory }`. Without it, the `promptWithMemories` function receives empty prompt and history, preventing proper memory reranking during system prompt construction.

**Fix:** Restored the full call: `chatPrompt(workspace, user, { prompt: updatedMessage, rawHistory })`.

### Bug 6 (LOW): usage.duration was removed
**File:** `server/utils/helpers/chat/responses.js`

The block that extracts `usage.duration` from `chunk.usage.time_info.completion_time` (used by Cerebras and similar providers) was removed during refactoring.

**Fix:** Restored the `usage.duration` extraction block inside the usage metrics handling section.

---

## Known Limitations

- **Orphan persistence for custom providers (Bug 4):** Providers with custom `handleStream` (OpenAI, Anthropic, Cohere, Foundry, Apipie) do not persist orphaned streaming responses on thread switch. Only providers using `handleDefaultStreamResponseV2` benefit from this feature.
- **Agent WebSocket orphan persistence:** Agent sessions managed via WebSocket (`/api/agent-invocation`) do not currently participate in the orphan persistence flow.

---

## How to Build and Run

### Prerequisites
- Node.js >= 18
- yarn or npm

### Backend
```bash
cd server
yarn install  # or npm install
yarn dev      # starts the server on port 3001
```

### Frontend
```bash
cd frontend
yarn install  # or npm install
yarn dev      # starts the dev server on port 3000
```

### Production Build
```bash
cd frontend
yarn build    # outputs to frontend/dist/

cd ../server
yarn start    # serves the built frontend + API
```

### Environment
Copy `.env.example` to `.env` and configure your LLM provider, vector DB, and other settings as needed.
