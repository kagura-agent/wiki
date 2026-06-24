---
title: Progressive Thinning
created: 2026-06-24
last_verified: 2026-06-24
source: sofagent (KongFangXun/sofagent)
tags: [agent-governance, orchestration, sofagent, token-efficiency]
---

## Pattern

**Reduce orchestration overhead for tasks that repeatedly succeed.** Success builds trust; trust reduces ceremony. Failure rolls back to full orchestration.

The insight: governance layers have a cost. Paying that cost for familiar, proven-safe tasks wastes tokens and attention without producing new information.

## SofAgent Implementation (4-Level Orchestration Depth)

| Level | Description |
|-------|-------------|
| Full | Complete 3-layer loading chain + orchestrator decomposition |
| Standard | Loading chain, no decomposition |
| Light | Minimal constraint loading |
| Skip | Direct execution, no governance overhead |

**Rollback mechanism**: Sliding window of last 5 runs. Any failure in the window triggers rollback toward fuller orchestration. This prevents "silent drift" where a task that used to work starts failing under lighter governance.

## Our Application (Kagura workspace, 2026-06-24)

We applied a **narrower version** — thinning the *output* of a specific tool (dna-preflight chronic-pattern demotion), not skipping the tool entirely.

- Chronic patterns (surfaced 3+ unique days without resolution) get a score penalty (-5), demoting them from top-3 display
- Fresh violations surface instead — patterns where a reminder can still drive behavioral change
- Penalty-based, not hard filter: fresh reinforcement can overcome the penalty
- Combined with [[tokdiet]] per-strategy backoff for targeted noise reduction

**Key distinction**: SofAgent thins entire governance layers. We thin specific outputs within a layer. Structural fixes remain the full resolution; thinning is interim noise reduction until those fixes land.

## Relationship to Other Patterns

- [[adaptive-workflow-rigidity]] — the tension this pattern resolves (overhead vs safety)
- [[tokdiet]] — complementary: tokdiet reduces token cost per-strategy; thinning reduces invocation frequency
- [[sofagent]] — origin project

## When to Apply

- Task has stable success history (not just 1-2 runs)
- Governance output has stopped producing actionable information
- Rollback path exists and is automatic (never trust-without-verify permanently)

## When NOT to Apply

- Novel or high-risk tasks (always full orchestration)
- Tasks where failure is silent or delayed (no reliable signal for rollback)
- As a replacement for structural fixes to underlying issues
