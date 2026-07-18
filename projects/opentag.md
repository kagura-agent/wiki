---
title: "OpenTag — Channel-Native Agent Gateway for Slack"
date: 2026-07-01
status: tracking
stars: 451
last_verified: 2026-07-18
---

# OpenTag (linxidnju)

Open-source, channel-native agent gateway for **Slack**. Route team threads to Claude Code, Codex, OpenCode, Docker, HTTP agents, and custom CLIs with policy, approvals, memory, audit logs, and artifacts.

Created 2026-06-27, JavaScript, Apache-2.0, MVP status. Actively developed (pushed 07-02). 194⭐, 0 forks, 0 issues.

## Followup Log

### 2026-07-18
- Stars: 194→451 (+132%). Still 0 forks, 0 issues, 0 external PRs.
- New feature (07-10): **Team Knowledge** — scoped knowledge service with partitions, versioning, auditing, memory API bridging, CLI commands. 9 commits in one burst.
- No commits since 07-10 (8 days silent).
- Community health: SOLO (0/6) — zero external engagement despite strong star growth.
- Assessment: Passive growth continues strong but complete absence of community is concerning at 451 stars. The "team knowledge" feature is interesting (shared, auditable context across team members — novel for agent gateways). One more cycle — if still SOLO next check, downgrade to monthly.
- Revisit: 07-25

### 2026-07-08
- Stars: 65→194 (+198%/7d, tripling). Still 0 forks, 0 issues, 0 external PRs.
- Recent dev: channel profiles + local governance, local setup wizard (07-02).
- Community health: SOLO (0/6) — no external engagement signals whatsoever.
- Assessment: Star growth is impressive but community engagement is zero. Solo dev actively building features (good) but no one is trying to use or contribute (concerning). The project is maturing from MVP but lacks any validation beyond the author. Worth one more followup cycle before deciding.

## Architecture

**Core engine** (`OpenTagEngine`): handles incoming Slack messages, routes to runtime adapters, manages sessions per-thread, enforces policy, builds context prompts.

**Key components:**

1. **TaskRouter** — analyzes message text via regex to classify task type (code/artifact/research/general) and required capabilities (writeAccess, shell, network). Selects runtime from candidates using channel config → fallback → cost ordering. Novel: cost-based runtime ordering (`preferLowestCost`).

2. **PolicyEngine** — evaluates at two levels: turn-level (prompt patterns) and tool-call-level. Decisions: allow/deny/require_approval. Channel-level configuration for allowed users, blocked users, allowed runtimes, deny patterns, approval patterns. Tool-call policy aliases (bash ↔ Shell, file_change ↔ Edit). Self-approval optionally allowed.

3. **ContextBuilder** — assembles flat prompt (no structured messages) from: session messages, hydrated thread messages, channel history, pinned items, channel memory, workspace search hits (local index + Slack search), downloaded files. Truncation strategy: head 25% + tail 70% (loses middle context — risky).

4. **RuntimeRegistry + Adapters** — pluggable runtime system. `ClaudeCodeAdapter` extends `GenericCliRuntimeAdapter` (spawns `claude -p` with `--output-format stream-json`). Also: CodexAdapter, OpenCodeAdapter, DockerRuntimeAdapter, HttpRuntimeAdapter, MockRuntimeAdapter. All emit a normalized event stream (started/token/log/tool_call/artifact/completed/failed).

5. **SessionManager** — thread = session. Per-session queue (strict serialization, one turn at a time). AbortController for cancellation. Status lifecycle: active → running → waiting_approval → completed/failed/cancelled.

6. **Approval flow** — HITL approvals with 2h expiry. Mid-runtime tool-call approvals pause the run. Approved-by coverage: if turn is approved, subsequent tool-call approvals skip (blanket approval).

7. **Channel memory** — simple remember/forget/list commands. Both config-based notes and runtime-collected entries. No semantic search.

8. **Sandbox + artifacts** — ephemeral sandboxes per run. Automatic artifact collection from sandbox output dir. PR candidate auto-generation from collected artifacts. Artifact upload back to Slack thread.

9. **Agent proxy** — registered run context with proxy URL for external API access during runtime. Bearer token scoped to run.

## Comparison with OpenClaw

| Aspect | OpenTag | OpenClaw |
|---|---|---|
| Platform | Slack-first | Multi-platform (Discord, Feishu, Telegram, etc.) |
| Model | Team-oriented (multi-user channels) | Personal assistant (one agent, one user) |
| Runtime routing | Automatic (TaskRouter + capability matching) | ACP-based, more manual selection |
| Policy | Structured (regex patterns, per-channel, turn + tool-call levels) | Tool execution policy, config-based |
| Context | Flat prompt assembly, workspace search | Structured messages, memory system |
| Memory | Simple key-value, channel-scoped | Semantic search, multi-layered (MEMORY.md, wiki, daily) |
| Approval | Built-in with expiry, mid-run pause | Native approvals via tool policy |
| Sandbox | Ephemeral per-run, artifact collection | Sandbox support via exec |

## Novel Patterns

1. **Task classification via text analysis** — regex-based capability inference from user message. Fragile (e.g., "explain the bug" → research, but may need shell), but the principle of automatic capability detection for runtime selection is interesting. [[centaur-paradigm]] does K8s-based sandbox selection but doesn't auto-classify task type.

2. **Cost-based runtime ordering** — when multiple runtimes can handle a task, prefer cheapest. Not seen in other gateways.

3. **Channel history as searchable context** — indexes recent channel messages (configurable window) and feeds them as context. Both local index + Slack workspace search. Gives agents awareness of broader team discussion.

4. **Blanket turn approval** — if a turn is approved, subsequent tool-call approval requests within that turn are auto-approved. Reduces approval fatigue.

5. **PR candidate auto-generation** — automatically creates PR candidates from sandbox artifacts without explicit agent action.

## Weaknesses

1. No community activity (0 issues, 0 forks) — too early to assess real-world viability
2. Task analysis via regex is fragile — misclassification risks routing to wrong runtime
3. Context truncation head+tail loses potentially critical middle context
4. All runtimes are CLI-based — limits integration with API-first agents
5. No streaming back to Slack (events emitted but Slack message updates are batch, not streaming)
6. Memory is simple text — no semantic search, no hierarchical organization

## Relevance to Us

- **Team-oriented agent gateway** is a different design point from OpenClaw's personal-assistant model. Worth watching how team dynamics (approval, shared context) evolve.
- **TaskRouter auto-classification** could inspire smarter ACP runtime selection in OpenClaw.
- **Channel history indexing** as context — we don't do this (agent sees only direct messages). Could be valuable for Discord channel awareness.
- **Cost-based routing** is a clean pattern if/when we support multiple model backends with different costs.

Links: [[centaur-paradigm]], [[openclaw-architecture]], [[felix]], [[agent-harness-landscape]], [[acp]]
