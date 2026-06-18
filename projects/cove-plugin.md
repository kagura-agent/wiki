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

## 已知坑

- **Anthropic `thinking` block signature**：用 extended thinking 的 session 历史里有 `thinking` block 时，model 切换或签名过期会导致后续 replay 报 `Invalid signature in thinking block`，runtime 显示为 `replay_invalid` —— 这种 session 救不回来，只能 reset
- **cove staging server REST POST → WS broadcast**：从 `openclaw message send --account kagura` POST 出去的消息，似乎不会广播给同 channel 其他用户的 WS 连接（待验证）。所以测试软糖能不能回，要在 cove web UI 里发消息
