---
created: 2026-06-18
tags: [pattern, clarification, alignment, agent-workflow]
status: insight
last_verified: 2026-06-18
---

# Align-Tree Pattern

> A structured approach to pre-execution need-alignment using a multi-dimension tree. Resolve what the user actually wants *before* writing a spec or touching code.

## The Pattern

Before execution, systematically probe a fixed set of alignment dimensions. Each dimension gets a state: **resolved**, **unresolved**, or **N/A**. Work doesn't start until critical dimensions are resolved.

**The 10-dimension tree** (from [[compass-skills]] task-clarifier):

| Layer | Dimensions |
|-------|-----------|
| **Core (3)** | Outcome, Constraints, Acceptance Criteria |
| **Auxiliary (7)** | Audience, Deliverable, Scope, Tradeoffs, Evidence Boundary, Safety-Permission, Non-goals/Stop Condition |

## Two Flavors of Constraint

The critical insight: constraints split into two types requiring different resolution:

- **Fact-inferrable** — resolvable from code, config, or environment. Resolve silently (grep the codebase, read the config). Don't waste the user's time asking.
- **User-owned decisions** — no safe default exists. Must ask. Examples: "should this be backwards-compatible?" or "is downtime acceptable during migration?"

Mixing these up causes either unnecessary questions (asking what the code already answers) or silent wrong assumptions (guessing a user-owned decision).

## Relationship to Other Patterns

- **Sibling of spec-gate** (from [[why-was-fable-banned]]): spec-gate ensures a spec exists before implementation. Align-tree operates one step earlier — clarification before the spec is written.
- **Feeds into [[flowforge]]** workflow nodes: alignment results become inputs to spec and implementation nodes.

## When to Apply

Any task where jumping straight to implementation risks building the wrong thing. The tree is most valuable when the user's request is ambiguous on 2+ dimensions — a clear single-dimension task ("rename X to Y") doesn't need it.

Links: [[compass-skills]], [[why-was-fable-banned]], [[flowforge]]
