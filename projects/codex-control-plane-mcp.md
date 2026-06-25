---
title: codex-control-plane-mcp — Durable Async Control Plane for Codex Desktop
tags: [codex, mcp, orchestration, durability, agent-harness]
created: 2026-06-18
stars: 222
url: https://github.com/aresyn/codex-control-plane-mcp
status: deep-read
last_verified: 2026-06-25
---

# codex-control-plane-mcp

Durable MCP control plane for long-running Codex Desktop tasks. Turns Codex Desktop + `codex-app-server` into an async worker: submit task → get `operationId` → poll → approve interactions → read report.

**Author:** aresyn (solo dev). **Lang:** Python 3.11+. **License:** Apache-2.0. Created 2026-06-17. 116⭐ in ~1 day.

## Problem Space

Thin Codex wrappers leave the "awkward middle" to the caller: app-server startup, retry safety, duplicate prompt detection, approval handling, Plan Mode lifecycle, crash recovery. This project handles all of it behind a standard MCP stdio interface.

## Architecture (16k LOC)

Core in `openclaw_codex_mcp/` (legacy naming — OpenClaw was a first-class target):

| Module | LOC | Role |
|---|---|---|
| `tools.py` | 6097 | MCP tool definitions + dispatch (30+ tools) |
| `storage.py` | 2603 | SQLite WAL persistence: operations, turns, messages, hooks, events |
| `turn_tracker.py` | 1113 | Turn lifecycle: register, record events, progress journal, redaction |
| `pending_interactions.py` | 648 | Approval/question/elicitation as pollable state |
| `search.py` | 496 | FTS5 index over hook history + transcripts |
| `transcripts.py` | 443 | JSONL transcript parser |
| `runtime_capabilities.py` | 368 | Inventory: models, hooks, skills, providers, sandbox |
| `codex_app_server.py` | ~400 | Manages `codex app-server` subprocess, JSON-RPC I/O |

### Key Primitives

1. **Durable Operation Queue** — `codex_submit_task(operation_type, message)` → returns `operationId` immediately. Poll with `codex_get_operation_status`. Types: `start_chat`, `send_message`, `execute_plan`, `steer_turn`. No multi-hour blocking MCP calls.

2. **Retry-Safe Dedup** — `client_request_id` for idempotent retries. Plus active prompt similarity detection (`prompt_dedup.py`, ~40 LOC) to catch near-duplicate submissions.

3. **Turn Steering** — `steer_turn` injects context into an active turn without creating a new turn. Uses app-server `turn/steer` endpoint. Novel — most frameworks can't "poke" a running agent mid-execution.

4. **Pending Interactions API** — Codex approval/question requests surfaced as `codex_list_pending_interactions` → `codex_answer_pending_interaction`. Supports: command approval, file approval, MCP elicitation, tool user input, permissions approval. No blocking — all pollable.

5. **Plan Mode Workflows** — `codex_start_plan_workflow` → `codex_get_workflow_status` → `codex_approve_plan`. Structured lifecycle for plan-then-execute.

6. **Progress Journal** — Records `agentMessage/delta`, `plan/delta`, `reasoning/summary`, `tokenUsage`, `model/rerouted`, `warning` events. Redacts secrets (`sk-*`, Bearer tokens, api_key patterns). Stores diff metadata (size/lines) but not diff content.

7. **SQLite Leases + Heartbeats** — Multiple MCP processes compete safely. Lease TTL 120s, heartbeat 30s.

8. **Diagnostics** — `codex_health_summary`, `codex_collect_diagnostics`, `codex_analyze_issue`, `codex_repair_issue` (dry-run capable).

### Contract Versioning

`contractVersion=1`. Stable tool set (12 tools) with `toolSurfaceHash`. New fields may be added; existing machine-readable fields never removed without version bump.

## Key Insights

1. **Submit-poll-complete is the right abstraction for long-running agent work.** Blocking calls are fragile; fire-and-forget has no observability. The operation queue pattern gives both durability and visibility. Compare to our [[taskflow]] which operates at a higher abstraction level.

2. **Turn steering is a missing primitive in most frameworks.** Being able to inject context mid-execution without creating a new turn solves a real problem. Our `sessions_send` is related but works at session level, not turn level. Worth watching if this pattern standardizes.

3. **Interactions as pollable state > blocking approvals.** Instead of hanging on an approval callback, expose pending approvals as queryable data. [[OpenClaw]]'s native approval system does something similar but from the gateway side. This is the MCP-client-side complement.

4. **Prompt deduplication is underrated.** Client retries + network hiccups → duplicate turns. Simple prompt hash + similarity check prevents expensive double-execution. ~40 LOC for significant reliability improvement.

5. **Progress journal with redaction is good observability.** Capture enough to understand what's happening, redact enough to be safe. Pattern applies beyond Codex.

## Relevance to Us

| Pattern | Our Status | Actionable? |
|---|---|---|
| Durable async operations | [[taskflow]] at higher level; cron jobs at lower level | Conceptual alignment, no direct adoption |
| Turn steering | No equivalent — can't inject into running subagent | Watch for standardization |
| Interaction polling | Native approvals in [[OpenClaw]] gateway | Already have similar |
| Prompt dedup | Not implemented in our subagent spawning | Worth considering if duplicate spawns become a problem |
| Progress journal | session logs + memory writes | Similar intent, different mechanism |

**Not immediately adoptable** — we use Claude Code CLI (`claude --print`), not Codex Desktop. The specific tool targets Windows Codex Desktop. But the patterns (durability, dedup, steering) are transportable.

## v0.2.0 Update (2026-06-25 followup)

**222⭐ (+91% in 7 days).** Major architecture rewrite released 06-20.

New in v0.2.0:
- **Worker-first architecture** — four execution modes: `client` (submit+poll), `worker` (execute queue), `observe` (read-only status), `inline` (synchronous single-process)
- **Durable scheduling** — queue state, worker heartbeats, resource locks, per-thread locks, concurrency limits. SQLite-backed.
- **Self-describing MCP contract** — `codexMcpGuide` + `codex_get_agent_contract` + tool annotations + `guideHash`. Server tells agents how to use it without external docs. Pattern: inline discovery > separate skill files.
- **Turn steering shipped** — `turn/steer` for injecting context mid-execution is now stable
- **Thread forking** — `thread/fork` branches existing thread with/without initial message
- **Code review workflows** — `review/start` with polling and final report capture
- **Runtime policy floor** — MCP raises `read-only` to `workspace-write` for Plan Mode, reports adjustment in status

v0.2.1 (06-21): Project ID canonicalization fix for reliable task submission.

### New Pattern: Self-Describing MCP

The most interesting evolution. Instead of requiring external docs/guides:
1. `tools/list` returns `codexMcpGuide`, `toolGroups`, `recommendedStartupTool`, `recommendedPrimaryWriteTool`
2. Contract versioning via `contractVersion` + `toolSurfaceHash` + `guideHash`
3. Agents verify contract stability on connect
4. Structured errors with `nextSteps` tell agents whether to poll/wait/diagnose/repair/stop

This is "SKILL.md embedded in the protocol itself" — worth watching as a pattern for MCP tool design.

## Tracking

- Solo dev, 22 issues (7 open), 4 forks, 2 watchers
- Windows-primary (Linux/macOS = protocol-only)
- 7 days old, growth velocity high (+91%)
- No external contributors beyond MseeP badge bot
- Architecture maturing fast (16k → likely 20k+ LOC now)

**Verdict:** Track for patterns. Worker architecture and self-describing MCP are reference-worthy. Revisit 07-02.

Links: [[taskflow]], [[OpenClaw]], [[cwc-long-running-agents]], [[thin-harness-fat-skills]], [[codex-chatgpt-control]]
