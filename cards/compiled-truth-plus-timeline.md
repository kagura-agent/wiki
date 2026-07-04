---
title: Compiled Truth + Timeline
created: 2026-06-24
last_verified: 2026-07-04
tags: [agent-memory, architecture-pattern, knowledge-management]
---

# Compiled Truth + Timeline

A memory-page architecture where each knowledge entry has two structurally distinct sections:

1. **Compiled truth** — the rewritable "current best understanding" (a cache of what's believed now)
2. **Timeline** — an append-only evidence chain (log of decisions, reversals, evidence)

The key invariant: **every compiled_truth rewrite atomically appends a timeline entry**. The write path enforces this — you cannot update the current understanding without recording why. Silent overwrites are structurally impossible.

## Origin

From [[brain-md]] (mindmuxai/brain.md) — a file-based per-repo memory layer for coding agents. The CLI is the only write path, which makes the atomic invariant enforceable by construction rather than by convention.

## Comparison with Alternatives

| Approach | Current state | History | Integrity guarantee |
|----------|--------------|---------|-------------------|
| **Compiled Truth + Timeline** | Explicit `compiled_truth` section | Explicit `timeline` section, same file | By construction (CLI enforces) |
| **Git-backed files** (our wiki approach) | File content = current state | Git log / blame | By convention (must commit) |
| **Append-only logs** | Derived by reading last entry | The log itself | By construction, but no "current state" cache |
| **Database + audit table** | Row in main table | Row in audit table | By application code (can be bypassed) |

## When It's Useful

- **Decision tracking** where "why did this change?" matters as much as the current state
- **Multi-agent / multi-session** workflows where different sessions update shared knowledge and need to see each other's reasoning
- **Regulated or compliance contexts** where audit trails are required

## When It's Overkill

- Low-churn knowledge (write once, read many) — the timeline adds ceremony for no benefit
- Systems where git history already provides sufficient audit trail
- High-write-volume data where per-entry timelines become unwieldy

## Related

- [[brain-md]] — the project that implements this pattern
- [[git-backed-agent-memory]] — alternative approach using git as the history layer
- [[write-time-vs-read-time-arbitration]] — related tradeoff: when to pay the cost of organizing knowledge
