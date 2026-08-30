---
title: "PI from Scratch — Minimal TypeScript Coding-Agent Tutorial"
created: 2026-08-10
updated: 2026-08-15
tags: [agent-harness, coding-agent, typescript, education]
source: https://github.com/SaladDay/pi-from-scratch
stars: 982
status: following
last_verified: 2026-08-30
---

# PI from Scratch — Minimal TypeScript Coding-Agent Tutorial

`SaladDay/pi-from-scratch` is a Chinese-language, MIT-licensed tutorial that reconstructs the core of the `pi` coding-agent data flow in roughly 754 lines of TypeScript. It deliberately removes production engineering so readers can trace one complete path: OpenAI-compatible SSE → normalized events → tool loop → transcript persistence.

## What the Code Actually Does

The four-module split is useful because each boundary is inspectable:

- `llm.ts` converts OpenAI-compatible streaming chunks into `text_delta`, `tool_call`, `done`, and `error`; it accumulates fragmented tool arguments by call index.
- `agent.ts` owns the `while` loop: it appends every assistant tool-use message, executes calls serially, and appends a corresponding tool-result message before the next model turn.
- `tools.ts` provides only `read_file`, `write_file`, exact-unique `edit`, and `run_bash`.
- `cli.ts` appends messages to one global `~/.nanopi/session.jsonl` file.

The test suite validates the normal text turn, tool-call/result transcript pairing, unknown-tool feedback, streamed tool-argument reconstruction, unique-edit behavior, and a separately invoked live-model E2E path. There are no repository issues to supply external criticism at the 2026-08-10 check.

## The Useful Boundary: Protocol Correctness, Not Agent Safety

Its strongest teaching choice is not the tiny tool set; it is making recovery rules visible. On abort it discards partially received tool calls so the resumed provider transcript does not contain unmatched calls. On `max_tokens`, it returns a tool-result error instead of executing potentially incomplete arguments. This is a compact demonstration that a tool loop is fundamentally a **conversation-protocol state machine**, not merely `LLM → shell`.

The production boundary is equally clear:

- Tool arguments are cast and executed without schema validation.
- Filesystem paths and `run_bash` are unrestricted; there is no workspace boundary, approval, or sandbox.
- The loop has no maximum-step or budget fuse.
- The 50-message compaction threshold is message-count based, asks the model to summarize untrusted transcript, and has no direct test coverage.
- A single global JSONL session has neither project isolation nor concurrent-write protection.

This makes it a good companion to [[pu-shell-agent]]: both prove the agent loop is small, but `pi-from-scratch` exposes provider transcript invariants and abort handling more directly. It also reinforces the distinction from [[deer-workflow]] and [[flowforge]]: a minimal runtime explains semantic execution, while an auditable workflow layer supplies explicit gates and completion evidence.

## Ecosystem Position and Relevance

The project is educational infrastructure rather than a credible replacement for a production harness. Its honest omission list makes a valuable review checklist: when a minimal-agent implementation adds persistence, tool execution, and compaction, safety and lifecycle controls must be introduced intentionally rather than assumed to emerge from the loop.

For our stack, retain the teaching pattern—small, evented interfaces and explicit failure transcript repair—but do not inherit its global state, direct shell access, or unbounded loop. Those omissions are exactly where [[mechanism-vs-evolution]] and FlowForge-style verification matter: the mechanism can run, but nothing in it establishes whether it should run, when to stop, or whether its outcome is trustworthy.

## Delta Check 2026-08-15 (88 → 982⭐, 11x in 5 days)

Growth is **marketing-driven, not feature-driven**: LINUX DO 社区推广 + OpenModel 赞助（README/docs 插入 ref 链接）+ star history chart。架构与代码未变（仍 ~750 行 5 模块）。

唯一实质代码变更 = **协议边界修复 #1**（外部贡献者 aaronshan）：`buildAssistantMessage('', [])` 产出 `content: []`——既无文本也无 tool_call 的 assistant 消息，旧代码 `text || null` 会发 `content: null` 触发 API 400；修复为发空串占位。新增对应单测。

**教训（验证了 08-10 的核心论点）**：tool loop 是 conversation-protocol state machine——连教学版都会踩 provider 特定的 content-null/empty 边界。真实世界断言："纯 tool_call 消息 content 必须 null" 与 "空消息 content 必须 ''" 是两条不同的、provider 相关的规则，实现时要按消息形态分支，不能一个 `||` 通吃。

**Verdict**: 值得追踪——不是因为代码（教学价值已消化），而是 11x 增长展示了中文 dev 社区的传播机制（赞助 + 社区 + star chart 的推广组合拳）。再观察 1 轮看增长是否持续、是否有实质功能演进；若纯营销增长则降级为 cool。Revisit: 08-30。

## Sources Checked

- Repository README, implementation/design documentation, and source at the default branch (2026-08-10)
- Tests read before source: `test/agent.test.ts`, `test/llm.test.ts`, `test/tools.test.ts`, `test/e2e.ts`
- `gh issue list --state all --limit 20`: no issues returned (2026-08-10)
- Delta: `gh api repos/SaladDay/pi-from-scratch/commits?since=2026-08-10` + issue #1 comments (2026-08-15, API evidence boundary)

## 08-30 Follow-up (1,143⭐, 982→1143 +16% in 15d)

- ✅ **cal-0815-2b31 CORRECT**（growth slowed <+50%，08-29 已验证）
- 08-15 后仅 2 个 docs fix commits（#5 compaction message count、#3 LAN dev origins），代码仍 ~750L 未动，pushed 08-18（12d silent）——**无真实 feature evolution，纯营销增长持续**。
- **Verdict**: **Downgrade → cool**。中文 dev 社区传播机制（赞助+社区+star chart）已消化，无新学习价值。Revisit 09-27; 仍纯营销无 code → drop。
