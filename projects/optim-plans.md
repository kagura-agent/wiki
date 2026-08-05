---
title: "optim-plans — Dual-Ring Planning & Execution Controller"
created: 2026-07-29
updated: 2026-07-29
source: https://github.com/Optim-Agent/optim-plans
stars: 86
status: active
category: agent-harness
last_verified: 2026-08-05
---

# optim-plans

Human-in-the-loop planning + verified execution plugin for Claude Code and Codex. Created 2026-07-23. Solo dev, 86⭐, 0 forks, 0 issues. Python 3.11+. MIT.

## Core Concept: Two Rings

**Planning-refining ring**: Vague intent → grilling questions → PLAN_v1.md → reviewer/criticizer refinement → PLAN_vN.md. Each decision opens sub-Q&A loops. Fights "building the wrong thing."

**Executing-validating ring**: Immutable manifest → human approval → serial item execution in isolated worktree → read-only validator → bounded retry → checkpoint → final audit → auto-integration. Fights "building the right thing wrong."

## Architecture

- **Event-sourced state machine** (6500 LOC): All transitions are append-only events with cryptographic nonces, delta fingerprints, and stable JSON hashes. State lives under `.git/commondir`. Full replay capability.
- **Role-sandboxed multi-agent**: Controller spawns separate agents per role:
  - Reviewer/criticizer/validator: read-only sandbox
  - Executor: workspace-write, confined to `allowed_paths`
  - Same-platform constraint (no cross-calling Claude↔Codex)
- **Agent adapter layer**: Auto-detects Claude/Codex CLI, configures per-role with isolated CODEX_HOME/settings for executors.
- **Plugin model**: Ships as `.claude-plugin` + `.codex-plugin` with hooks (SessionStart, PreToolUse). Skills at multiple depths (mini/small/plan/big/huge).
- **Test suite**: 12,900+ lines covering E2E, execution, git isolation, adapters, hooks, skill contracts.

## Key Design Decisions

1. **Serial execution with checkpoints** — slower but guarantees each item starts from verified base state
2. **Validator is read-only** — can only report pass/fail + bounded feedback, cannot modify code. Prevents "validator drift"
3. **Human approval is mandatory for execution** — planning can auto-complete, execution gate cannot
4. **Delta fingerprinting** — SHA256 of changed files before/after, prevents worktree tampering between phases
5. **Bounded retry** — validator failures retry up to limit, then route to recovery (human decision)

## Plan Depth Levels

| Level | Questions | Refinement Rounds | Timeout/round |
|-------|-----------|-------------------|---------------|
| mini | 1 | 0-1 | — |
| small | 1-3 | 1 | — |
| plan | 1-5 | ≤3 | 600s |
| big | 5-10 | ≤5 | 1800s |
| huge | 10+ | unlimited | unlimited |

## Relation to Our Direction

- **vs FlowForge**: optim-plans is coding-task-specific with git-backed verification; FlowForge is general-purpose workflow. Different niches.
- **Portable pattern — read-only validator**: Could apply to FlowForge — a validation step that cannot modify output, only accept/reject with bounded feedback.
- **Portable pattern — delta fingerprinting**: Integrity check between phases. More rigorous than trusting executor implicitly.
- **Portable pattern — event-sourced agent state**: Append-only event log with replay. Stronger durability than file-per-day approach.

## Criticisms

- Solo dev, 0 community (0 forks, 0 issues, 0 PRs)
- 6500 LOC core is very complex for planning — potential over-engineering
- Serial execution is bottleneck for large plans
- Tightly coupled to CLI agents (Codex exec / Claude -p), no API agent support
- No evidence of real-world usage beyond README demos
- "Anti-pattern: Too Small To Plan" philosophy may create friction for trivial changes

## Ecosystem Position

Competes loosely with [[centaur-loop]] (human-governed AI feedback loop) and [[lazycodex]] (planning + memory), but is more rigorous on the execution verification side. Closer to a "formal methods" approach than the lightweight skill-based patterns in [[agent-harness-landscape]].

## Tracking Decision

Worth tracking short-term for the verification patterns. Check in 1 week for: community growth signal, real adoption evidence, architecture changes.

Links: [[agent-harness-landscape]], [[centaur-loop]], [[lazycodex]], [[self-evolving-agent-landscape]]

## 2026-08-05 — Follow-up: validator behavior is becoming the product

The repository grew 86→301⭐ and remained active through 2026-07-31. Recent changes add a `research-and-plan` alias, PLAN_v2 “retry until blocked” behavior, and stable validator plan-context/recovery diagnostics. The notable direction is not broader orchestration: it makes the plan validator more explicit about bounded recovery. That supports the [[failable-verification]] principle already used by [[flowforge]], while its single-fork community signal means adoption remains unproven.
