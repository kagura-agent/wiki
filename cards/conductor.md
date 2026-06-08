---
title: Conductor Pattern
created: 2026-06-08
source: GenericAgent frontends/conductor.py + conductor.html (855 lines)
tags: [pattern, multi-agent, orchestration]
last_verified: 2026-06-08
---

A WebUI-based multi-agent orchestrator where a conductor agent **never executes tasks directly** — all work is dispatched to sub-agents via API.

**Core design principle**: "You never execute any task yourself. All work must be dispatched via POST /subagent." The conductor only decomposes, delegates, reviews, and communicates with the user.

**Architecture** (from [[genericagent]]):
- FastAPI + WebSocket real-time UI with 6 endpoints (chat, subagent CRUD, readme)
- Event-driven wake: user message OR subagent completion triggers conductor
- Minimum action principle: "each wake-up, do the minimum necessary action, then immediately stop"
- Subagent lifecycle: spawn → progress (WebSocket cards) → intervention (keyinfo inject) → resume → done

**Three-role hierarchy**:
| Role | Purpose |
|------|---------|
| Conductor | Orchestration — dispatches, reviews, communicates with user |
| Supervisor | Quality — monitors workers, intervenes on deviations (see [[supervisor-pattern]]) |
| Worker | Execution — does actual tasks |

**Comparison with OpenClaw**: OpenClaw's main session IS the conductor — no separate process needed because sessions are first-class. GenericAgent needed a separate conductor because single-session was the baseline architecture. Convention (AGENTS.md: "code must go through Claude Code") vs architecture (conductor API enforces it) — both work but architecture is harder to bypass.

Related: [[supervisor-pattern]], [[mechanism-vs-evolution]], [[acp]]
