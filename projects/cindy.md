---
title: "Cindy — Multi-Harness Unified AI Agent Desktop"
created: 2026-07-27
updated: 2026-07-27
source: https://github.com/makecindy/cindy
stars: 476
status: deep-read
tags: [multi-harness, agent-orchestration, desktop-app, coding-agent, electron, orca]
last_verified: 2026-08-10
---

# Cindy — Multi-Harness Agent Desktop with Orca Orchestration

**By:** makecindy (team: dashhuang + MagicLizi + others, likely ex-startup)
**Stars:** 476 (created 2026-07-22, 5 days old)
**Language:** TypeScript (pnpm monorepo, Electron + React Native)
**License:** Apache-2.0
**Forks:** 48 | **Issues:** 143 (very active governance)

## What It Solves

Desktop agent app that unifies multiple coding agent harnesses (Claude Code, Codex, more planned native) under one workspace with shared memory, skills, tools, and model switching mid-task. Mobile companion (iOS/Android). Parallel execution across harness×model combos.

## Key Architectural Patterns

### 1. Orca Multi-Agent Orchestration

Lead/Worker model — NOT simple subagent spawning:
- **Lead session**: plans, delegates, reviews. Can be Claude Code OR Codex
- **Worker session**: full persistent session with own model/effort/tools/context. Has lifecycle: idle → running → done → error
- **Team**: one active team per Lead (partial unique constraint in SQLite)
- **Inter-agent dispatch**: message queue with accepted callbacks, rollback/settle semantics
- **MCP control plane**: 16 tools for team lifecycle (start/end team, create workers, switch focus, send to worker, queue management)
- **Split view**: Lead + focused Worker side-by-side in Electron layout tree

Key difference from [[OpenClaw]] subagents: Workers persist across turns, have queue management, and the Lead can switch focus between workers. More like a team manager than a task dispatcher.

### 2. maker-core Agent Abstraction

Central event loop + translator pattern:
- `BaseAgent` abstract class, per-harness subclasses (claude-code, codex)
- `translator.ts` per harness: vendor SDK events → unified `AgentEvent` union (text/thinking/tool_use/tool_result)
- **"Code over prompt" principle** (§2): deterministic logic in code, prompt only for genuine language understanding. Explicitly forbidden: branching, validation, state machines, flow orchestration in prompts
- Usage tracker with per-turn/session cache hit rate monitoring

### 3. Four Invariant Metrics (Novel Governance)

Every maker-core change must guard:
1. **Cache rate**: system prompt prefix must be byte-stable. No per-turn timestamps, no dynamic content in prefix. MEMORY.md snapshots at session start only
2. **Performance**: AsyncQueue event loop, no sync blocking on hot path
3. **Content accuracy**: translator must not lose/reorder/mistype events. Model routing: explicit version IDs only, bare aliases (`'opus'`/`'sonnet'`) FORBIDDEN
4. **System prompt gate**: NO unauthorized system prompt changes. Must get owner approval first. PR must include impact assessment + empirical measurement

### 4. Architecture Governance Process

- Bot (MagicLizi) auto-creates "architecture discussion" issues for PRs touching rule docs
- `dash-s-cindy` bot relays Slack discussions into GitHub issues (bidirectional sync)
- Each dev-rules doc has explicit: status, read-trigger, scope, review checklist
- "Document and code disagree → code wins, but must fix doc in same PR"

### 5. Plugin Setup Runtime (Ghost System)

- `ghost_call` = plugin invocation via MCP
- Deterministic readiness check before dispatch (OAuth, secrets, connections)
- Agent can orchestrate setup UX but Host controls security surface
- Setup cards reuse Ask card UI, never send user input to model
- Manifest declares capabilities; Host remains sole authority source

## Comparison with Related Tools

| Tool | Approach | Multi-harness? | Orchestration |
|------|----------|---------------|---------------|
| **Cindy** | Unified desktop, Orca teams | Yes (CC + Codex + native) | Lead/Worker persistent |
| **OpenClaw** | Gateway + config | Yes (via ACP) | Subagent spawning |
| **BossConsole** | JVM operator console | Yes (CC + Codex + Gemini) | Multi-threaded |
| **wmux** | Terminal multiplexer | Yes (any CLI agent) | PTY fan-out |

## Novel Insights

1. **Workers ≠ Subagents**: Persistent sessions with queue management vs one-shot delegation. The Lead can send multiple messages to a running Worker, manage its queue, and switch focus — more like managing a team member than dispatching a task.

2. **"Code over prompt" as architectural invariant**: Not just good practice — explicitly forbidden to put deterministic logic in prompts. This prevents "behavior drift" from model updates. Directly applicable: review our FlowForge/workflow prompts for logic that should be code.

3. **Prompt cache as performance metric**: Treating cache hit rate as a guarded invariant (not just nice-to-have) changes how you design system prompts. Implications for OpenClaw: system prompt stability across heartbeats matters for cost.

4. **Architecture-by-issue**: Every rules-touching PR gets a mandatory discussion issue before merge. Heavy for small teams but prevents drift in multi-contributor codebases.

5. **Anti-bare-alias pattern**: Forbidding `'opus'`/`'sonnet'` aliases and requiring explicit version strings (`claude-sonnet-4-20250514`) prevents silent model upgrades from changing behavior. Our `floway-sg/claude-opus-4-6` style is already compliant with this principle.

## Concerns

- 5 days old, 476⭐ — growing fast but no external adoption validation yet
- 47MB repo size for a "just open-sourced" project — heavy private dev history
- Very opinionated governance for an open-source project (system prompt changes need owner approval)
- Electron desktop-only (React Native mobile is secondary)
- CN/Global region split suggests Chinese company (startup?) with regulatory considerations
- No external contributors visible yet — team-internal open-source

## Relevance to Us

- **High (patterns)**: Orca Lead/Worker model informs future OpenClaw multi-agent orchestration. The queue management + focus switching is more sophisticated than our current subagent model.
- **Medium (practices)**: "Code over prompt" and prompt cache stability are directly applicable to how we structure system prompts and workflow logic.
- **Low (adoption)**: We won't switch to Cindy — it's a desktop app, we're a gateway/server. But architecture patterns are transferable.

## Follow-up — 2026-08-10

GitHub API verification: **1,944⭐ / 248 forks / 676 open issues**, a 4× star increase since the initial 07-27 review. The project released **v0.1.38** on 08-09 and landed same-day fixes for Anthropic collaboration-message replay, Telegram progress finalization, mobile compact commands, and context-window compaction routing. This is now a maintained multi-harness product rather than merely a launch spike.

**Architecture signal:** the recent fixes cluster at harness/event-boundary seams, reinforcing that Cindy’s `maker-core` translator abstraction is valuable precisely because vendor-specific event semantics keep changing. The counterpoint is its very high open-issue load: durable worker/queue orchestration needs operational support capacity, not just a clean Lead/Worker model. For [[OpenClaw]] and [[FlowForge]], borrow the explicit event-contract and queue-ownership ideas—not the desktop-first control plane.

## Links

- [[agent-harness-landscape]] — broader ecosystem context
- [[coding-agent-ecosystem]] — competitive landscape
- [[agentacct]] — complementary tool (could monitor Cindy's harness usage)
