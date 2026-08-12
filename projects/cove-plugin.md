# cove-plugin

Cove channel plugin for OpenClaw. Lives at `~/repos/forks/cove/packages/plugin/`, bundled to `~/.openclaw/extensions/cove/dist/index.js`.

## Ground Truth: `main` 行为是对的

> "main 上的这个 plugin 虽然是手写的但是行为都是对的" — Luna, 2026-06-18

**任何 refactor 必须前后行为一致。** 不只是"测试都过"，是真实运行（流式回复、draft edit、chunking、tool progress、context injection、thread binding）观感和 main 一样。

## 经验教训：PR #399 (closed 2026-06-18)

委托软糖按 issue #398 重构（"adopt SDK outbound adapter framework, Discord parity"），结果：

- 结构性外壳换成了 `createChatChannelPlugin`，但**inbound 还是绕回 `dispatchInboundDirectDmWithRuntime`**（issue 明说这是要绕开的 bypass path）
- 引入 `sendDurableMessageBatch` 和 `createFinalizableDraftLifecycle` 后又删掉，最终 dispatch.ts **净增 20 行**手写补丁（没删干净的 manual delivery + 新加的 chunking/streaming 防御）
- 改完产生 editQueue race → **流式回复重复** → 写进 transcript → Anthropic provider 拒收（`Invalid signature in thinking block`）→ session 不可用
- 软糖还把进度报告成"达到了 issue 要求"

**复盘：**
1. issue 说"删 200 行"，PR 不能"加 20 行"——行数走反就是没真做
2. 一边 import SDK 一边删 SDK 的 commit pattern = 在不同方向之间摇摆，每一步都不知道目标
3. 委托做 refactor 前要先有 **before/after 真实行为对照**，不只是测试通过
4. **下次 #398 自己做，不再外包**（Luna directive）

## 经验教训：PR #404 (closed 2026-06-18)

Workloop 选了 issue #401（Discord-parity draft preview & delivery），走了一整个 workloop cycle（find_work → study → plan → implement → submit → verify），但 PR 在 submit 后 ~1h 被自己 close。

**失败原因：**
- 同样是 "copy Discord wholesale" approach —— 和 #399 同一个 anti-pattern
- `sendDurableMessageBatch` silent failure、draft lifecycle race、CI failures
- 明明 #399 已经证明这条路走不通，#400 证明 phase-by-phase works，却还是选了 wholesale 路径

**复盘：**
1. **选题失误**：选了一个已经连续失败两次的 approach（#399 → #404），没有先消化 #399 和 #400 的教训
2. **workloop 白转了一圈**：从 find_work 到 submit 花了 ~6 小时 token，PR 1 小时后就被 close
3. **自己 repo 的 issue 不适合 workloop**：workloop 是给外部开源贡献设计的，cove 是自己的项目，应该用更 deliberate 的方式（读 SDK 源码、写集成测试、phase-by-phase），不是走打工流水线
4. **pattern**: 同一个坑掉两次 = 没真正学到。下次选 issue 时如果看到"之前 PR 因为 approach 问题被 close"，必须先确认 approach 变了再动手

## Plugin 现状（2026-06-18 06:45 重置后）

- 分支：`main`
- bundle：`~/.openclaw/extensions/cove/dist/index.js` 175kb（main 版本）
- 部署到自己 OpenClaw：`pnpm run build && cp dist/index.js ~/.openclaw/extensions/cove/dist/index.js && openclaw gateway restart`
- 部署到 cove staging server（VM1 上的服务）：是另一套，由 cove server 自己的 deploy 流程管，不在这边

## Dispatch 路径（main 的真实结构）

详见 `~/repos/forks/cove/packages/plugin/src/dispatch.ts` 和 `channel.ts`。关键：

1. `ChannelPlugin<CoveAccount>` 低层接口（不是 `createChatChannelPlugin`）
2. inbound：`dispatchInboundDirectDmWithRuntime` —— SDK 提供的 dispatch helper，但要求 plugin 自己提供 `deliver` callback
3. `deliver` 内部手写：draft message 生命周期（send → edit queue → seal → final edit/fallback）+ tool progress + chunking
4. 重启时 abort tracking 通过 `pendingDispatches: Map<channelId, AbortController>`

issue #398 想换的是把这个手写 deliver 换成 framework 的 `sendDurableMessageBatch` + outbound adapter 自动 chunk/draft。但 SDK 那条路径在 inbound 端能不能完全替代手写还需要验证 —— **PR #399 的失败说明可能没那么平滑**。

## 下次重做 #398 时的硬性约束

1. **Phase 0 写真实集成测试**：不只是 mock，要在本地 cove server 上跑流式回复对比 main vs branch
2. **每个 commit 必须保持可运行**：每个 phase 结束都能 build + run + 跑过一条真实 dispatch
3. **dispatch.ts 行数必须降，不能升**（issue 明说要删 200 行）
4. **不许同时 import SDK 又 删 SDK** —— 决定走 framework 就别留手写补丁，走不通就回退整段
5. **疑点写下来**：每次发现"这个 SDK 函数好像不对劲"，停下来查 SDK 源码 + 给 issue 加 comment，而不是绕过

## Cove 服务端 staging（VM1）

- 服务：`cove-staging.service` on VM1 (74.226.216.75)，监听 :3501
- 数据库：`/home/azureuser/cove-staging/cove-staging.db`（better-sqlite3）
- 域名：`https://staging.cove.kagura-agent.com`（**不是** `cove-dev.*` —— 那个不存在）
- cove-dev channel id: `1514140991349587968`，软糖 user id: `1512349650189811713`

## 软糖（ruantang） OpenClaw session 管理

- workspace：`~/.openclaw/workspace-ruantang/`
- sessions 索引：`~/.openclaw/agents/ruantang/sessions/sessions.json`，按 `agent:ruantang:cove:group:<channelId>` 为 key
- session 文件：同目录 `<uuid>.jsonl` + `<uuid>.trajectory.jsonl`
- 重置方法：mv jsonl → `.reset.<ts>` + sessions.json 里把对应 key 的 `sessionId/sessionFile` 清成 null，`status` 改 `idle`，`contextTokens/inputTokens/outputTokens` 归零
- `/new` 这种 trigger 是 OpenClaw CLI/TUI 层的命令，cove channel **不会**把它翻译成 reset，要从文件层操作

## PR #502 — task-level recurrence (pending, 2026-08-05)

- **Result:** pending review. The PR exposes optional recurrence through the task API while retaining the legacy recurring-task surface. Copilot’s first review flagged schedule re-anchoring; the follow-up commit `3228fc0` preserves `next_run_at` when clients resend an unchanged `interval_ms`.
- **Review style:** the only feedback so far is Copilot, not a human maintainer. It checks state-reset defaults, shared-contract duplication, and schedule stability. The latter two suppressed findings were already addressed on current HEAD: client re-exports the shared occurrence-mode type, and the creation dialog resets heartbeat to its `true` default.
- **Test / CI notes:** `pnpm --filter @cove/server test -- src/__tests__/recurring-tasks.test.ts` completed the full server suite (21 files / 357 tests), rather than filtering to that one file. `pnpm --filter @cove/client exec tsc --noEmit` and `pnpm --filter @cove/client test -- src/components/CreateTaskDialog.test.ts` passed (the latter ran 13 files / 60 tests). Use `git diff --check main...HEAD` before review follow-up.
- **Next time:** recurrence editor saves may resend fields unrelated to the user’s change. Test all three schedule cases explicitly: omitted interval, unchanged interval, and changed interval. Prefer shared contract imports/re-exports over duplicate client unions, and reset dialog state to its initialization defaults.

## Dispatch implementation re-read — 2026-08-07 [已验证]

- Evidence: `cove/packages/plugin/src/dispatch.ts` (read 2026-08-07) now uses SDK primitives rather than the older fully handwritten lifecycle described above: `createFinalizableDraftLifecycle`, `createChannelProgressDraftCompositor`, and `deliverWithFinalizableLivePreviewAdapter`.
- The plugin still owns Cove-specific transport and failure boundaries: `sendOrEdit` streams preview updates through `CoveRestClient`; `freshSend` delegates final delivery to `createCoveOutboundBridgeAdapter`; a final send failure retains `coveFinalPayload` on the error and logs it as recoverable rather than claiming delivery.
- Finalization invariant: `deliver()` cleans typing before final delivery; in-place final editing seals the draft and sets `draftState.stopped`; if the final reply was not edited in place, `finally` discards/deletes any orphaned draft. All callbacks are abort-gated.
- Test focus for future changes: preserve these observable boundaries—no post-final preview overwrite, no delivery claim after `sendText` fails, and draft cleanup after fallback/abort. `dispatch-behavior.test.ts` contains the behavior suite; do not infer current behavior from the June-era manual-delivery description without re-reading this module.

## Offline source review — 2026-08-09 [已验证]

- Context: [[workloop]] entered `fallback_offline` because the required structured finder returned `FINDER_RESULT=UNAVAILABLE`; this was not a Cove PR or a request to change plugin behavior.
- `packages/plugin/src/dispatch.ts` and `dispatch-behavior.test.ts` at local Cove commit `98e6f5d` show the current delivery boundary: previews are deduplicated, throttled (250ms), and bounded; an active draft is finalized in place via `deliverWithFinalizableLivePreviewAdapter`, otherwise `freshSend` deletes the draft before using `createCoveOutboundBridgeAdapter`.
- On a failed final outbound send, the code attaches `coveFinalPayload` to the error and logs a recoverable failure instead of asserting a successful delivery. The behavioral suite covers preview POST/PATCH, duplicate suppression, final-edit fallback, and failed-fallback recovery.
- Next time: any dispatch change needs these observable contracts preserved by `dispatch-behavior.test.ts` plus a real transport-path check; a typecheck alone cannot establish delivery correctness. See [[workloop]].

## Related

- [[cove-plugin-message-actions]] — message tool action dispatch 架构调研
- [[gogetajob]] — this workloop’s finder failure was recorded as unavailable discovery evidence, not as an absence of contribution candidates

## 已知坑

- **Anthropic `thinking` block signature**：用 extended thinking 的 session 历史里有 `thinking` block 时，model 切换或签名过期会导致后续 replay 报 `Invalid signature in thinking block`，runtime 显示为 `replay_invalid` —— 这种 session 救不回来，只能 reset
- **cove staging server REST POST → WS broadcast**：从 `openclaw message send --account kagura` POST 出去的消息，似乎不会广播给同 channel 其他用户的 WS 连接（待验证）。所以测试软糖能不能回，要在 cove web UI 里发消息

## Offline task-tool review — 2026-08-12 [已验证]

- Context: [[workloop]] entered `fallback_offline` after the required structured finder returned `FINDER_RESULT=UNAVAILABLE` (evidence: `github-contribution/offline/evidence/2026-08-12/20260812T100858+0800-find-work.md`). This was source review only, not a task API change or a new contribution selection.
- At local commit `98e6f5d`, `packages/plugin/src/cove-task-tool.ts` establishes `cove_task` as the supported task boundary and maps supplied camelCase inputs to REST snake_case fields. Normal `create` requires channel/title and a recurrence interval when recurrence is present; normal `update` keeps the deliberate distinction between omitted recurrence (no change), partial fields (patch), and `null` (remove recurrence).
- Legacy recurring-template actions remain a separate REST surface: `recurring_create` requires a positive interval and validates `same_task`/`new_task`; list/get/update/delete each route to their corresponding client method. `recurring-task-tool.test.ts` covers normal-task recurrence mapping, template routing, and invalid-input rejection.
- Next time: preserve the normal-task versus legacy-template boundary and exercise omitted/partial/null recurrence behavior with focused tests. The current PR #529 comment is only a successful GitHub Actions staging-preview notice, not maintainer review or a request to alter task behavior.
