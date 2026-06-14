---
title: Agent Autonomy Models
created: 2026-06-14
tags: [concept, agent-trust, autonomy, safety]
last_verified: 2026-06-14
---

# Agent Autonomy Models

Frameworks for how AI agents earn and exercise increasing levels of independence. The core question: how does an agent move from fully supervised to autonomous, and what gates the transitions?

## Common Tiers

| Tier | Behavior | Gate |
|------|----------|------|
| **Suggest** | Proposes action, waits for approval | None (default) |
| **Supervised** | Executes immediately, notifies + offers undo | Initial trust threshold |
| **Autonomous** | Executes silently, logs only | Sustained success record |

## Design Tensions

- **Suggest vs Act-first**: [[ghostwork]] skips the suggest tier entirely — philosophy is "action + undo is faster than approval + action." Most other agents default to suggest.
- **Per-action vs global trust**: Trust can apply globally (agent is autonomous) or per-action-type (autonomous for reads, supervised for writes). Per-action is safer but more complex.
- **Safety boundaries**: Even fully autonomous agents typically hard-gate externally visible actions (send, post, publish) behind approval. The autonomy model applies to internal/reversible actions.

## Earning Trust

Ghostwork's math: ≥5 accepts AND <2 rejections in last 10 → autonomous. Key properties:
- **Rolling window** — recent behavior matters more than lifetime stats
- **Demotion path** — rejections can revoke autonomy (not just prevent promotion)
- **Cap on trust** — accept count capped at 4, forcing periodic re-supervision

## Links

- [[ghostwork]]
- [[screenpipe]]
- [[memory-consolidation-as-skill-entry]]
