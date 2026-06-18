---
title: codex-control-plane-mcp — Durable Async Control Plane for Codex Desktop
tags: [codex, mcp, orchestration, durability, agent-harness]
created: 2026-06-18
stars: 116
url: https://github.com/aresyn/codex-control-plane-mcp
status: deep-read
last_verified: 2026-06-18
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

## Tracking

- Solo dev, all issues self-filed (15 issues, 2 closed)
- Windows-primary (Linux/macOS = "protocol-only checks")
- Very fresh — 1 day old, growth velocity uncertain
- No external contributors yet
- Roadmap: code review workflows, thread forking, image inputs, thread lifecycle management

**Verdict:** Track for patterns. Not for adoption. Revisit 06-25.

Links: [[taskflow]], [[OpenClaw]], [[cwc-long-running-agents]], [[thin-harness-fat-skills]], [[codex-chatgpt-control]]
