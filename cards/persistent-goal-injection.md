---
title: Persistent Goal Injection
created: 2026-05-21
tags: [agent-architecture, context-management, long-running-tasks]
last_verified: 2026-05-21
---

# Persistent Goal Injection

Pattern where an agent's active objective is stored in session metadata and automatically injected into every LLM turn's context window, surviving compaction and tool chains.

## Key Properties
- **Compaction-safe**: Goal text lives in metadata, not chat history — compaction can't erase it
- **Idempotent**: Goal phrasing must be state-oriented ("ensure X exists") not sequential ("first do A, then B") because the model may re-read it cold after compaction
- **Bounded**: Explicit done-ness criteria prevent drift
- **Single-active**: Only one goal per session to avoid conflicting objectives

## Implementations
- **[[nanobot]]** v0.2.0: `long_task` / `complete_goal` tools. Goal stored as `goal_state` in session metadata. `goal_state_runtime_lines()` injects into Runtime Context block every turn. Wall-clock timeout auto-widens during active goals. WebUI shows goal in chat header.
- **[[GenericAgent]]**: `goal_mode.py` — budget-constrained self-driving with objective + time limit + turn cap

## Contrast with Workflow Engines
- **[[FlowForge]]** (ours): More structured — explicit nodes, branching, state machine. Heavier but supports multi-step workflows with decision points.
- **Persistent goal injection**: Lighter — single tool call sets context. Better for "do one big thing" tasks. No branching or step tracking.

## Tradeoffs
- Lightweight (tool call vs workflow definition) but less capable (no multi-step orchestration)
- Goal text has a size limit (nanobot: 4000 chars in runtime context) — complex objectives may need truncation
- No sub-goal decomposition — agent must self-organize work within the single objective
- `fallback_models` pattern (also from nanobot v0.2.0) complements this by ensuring provider failures don't kill long-running goals

## Related
- [[metadata-driven-context-injection]] — the underlying mechanism
- [[agent-context-files]] — static context injection (AGENTS.md, CLAUDE.md)
- [[write-ahead-session-persistence]] — session durability for long tasks
