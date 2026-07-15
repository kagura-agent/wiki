---
title: Two Self-Evolution Paths - Code vs Prompt
created: 2026-03-23
source: 724-office vs Kagura deep read comparison
last_verified: 2026-07-15
---
Two fundamentally different self-evolution approaches exist:

**Code-level** (724-office): Agent writes new Python tools at runtime → gains new capabilities. No quality gate on generated code. The agent evolves by creating new behaviors.

**Prompt-level** (Kagura/Hermes): Agent modifies DNA files (SOUL.md, beliefs) → changes decisions. Quality gates exist (TextGrad pipeline, audit, Luna review). The agent evolves by refining existing behaviors.

| | Code-level | Prompt-level |
|---|---|---|
| Creates new abilities | ✅ | ❌ |
| Quality evaluation | ❌ (no audit) | ✅ (audit + review) |
| Risk | High (bad code) | Low (bad prompt = suboptimal, not broken) |
| Reversibility | Hard (code in production) | Easy (revert file) |
| Platform dependency | None (owns runtime) | High (limited by host) |

**Gap in the ecosystem:** No project combines both — runtime tool creation WITH quality evaluation of created tools.

Related: [[self-evolution-architecture]], [[convergent-evolution]], [[mechanism-bootstrapping-paradox]], [[evolution-needs-eval]]
