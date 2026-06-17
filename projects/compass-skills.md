---
title: "compass-skills — COMPASS Personal Alignment Skills OS"
date: 2026-06-17
tags: [skill-md, alignment, agent-skills, portable, clarification-gate, task-graph, user-profile]
status: tracking
revisit: 2026-06-24
last_verified: 2026-06-17
---

# compass-skills (dongshuyan)

**Repo:** [dongshuyan/compass-skills](https://github.com/dongshuyan/compass-skills)
**First seen:** 2026-06-17 quick scan
**Stars:** 199⭐ (created 06-15, 2 days, ~100⭐/day burst)
**Forks:** 18 (~10% fork rate — strong adoption signal)
**Language:** Python (script layer) + portable SKILL.md
**Topics:** agent-skills, claude-skills, codex-skills, skill-md, agent-memory, task-management, local-first
**Dev signal:** Solo dev (dongshuyan), 0 issues / 0 PRs, last push 06-17

## What

COMPASS = **"Personal Alignment Skills OS"** — three composable, agent-agnostic `SKILL.md` skills targeting *the same need-alignment pain point* that [[why-was-fable-banned]] addresses for spec, but **one step earlier** (clarification before spec):

| Skill | Role | Persistence |
| --- | --- | --- |
| `task-clarifier` | Convergent need-alignment, 10-dim alignment tree, ask-before-research | None (instruction-only) |
| `task-forest` | Repo-local task DAG with deviations, history, HTML export | `.agent-workbench/task-forest/` |
| `user-profile-keeper` | Local collaboration profile (preferences, risk tolerance) | `~/.compass-skills/user-profiles/v1/` |

Composition:
```
user-profile-keeper → who is the user, how to collaborate?
task-forest         → where does this task fit, still aligned?
task-clarifier      → what should the agent do now?
```

## Architecture Insight — Alignment as a Distinct Phase

**Novel framing:** treat *user-need-alignment* as a deterministic skill, not a runtime intuition.

`task-clarifier`'s **10-dimension alignment tree** (3 core + 7 auxiliary):

| Kind | Dimensions |
| --- | --- |
| Core (must resolve before execution) | Outcome / Constraints / Acceptance |
| Auxiliary (fill with safe defaults + label) | Audience / Deliverable / Scope / Tradeoffs / Evidence Boundary / Safety/Permission / Non-goals/Stop Condition |

Per-dimension state: ✅ resolved / ❓ unresolved / ➖ N/A

Critical insight: **constraints come in two flavors that require different resolution paths**:

- **Fact-inferrable** (tech stack, file format, framework version) → detect from code/config → ✅ silently
- **User-owned decision** (budget, deadline, region, priority) → **must ask** — no safe default exists

This separation is **load-bearing**: it prevents both "asking trivia the agent could lookup" and "assuming defaults on user-owned axes".

## Why This Matters For Us

### Cross-system relevance

1. **Phase-0 pattern family**: [[why-was-fable-banned]] (spec-gate), `task-clarifier` (clarification-gate), and our [[FlowForge]] align-node are three flavors of the same insight — **pre-execution gates beat post-execution corrections**. compass adds a dimension neither of the others did: explicit fact-vs-decision splitting on each constraint.

2. **Skill portability standard**: COMPASS explicitly supports Codex / Claude Code / OpenClaw / OpenCode. The contract is just `SKILL.md` + `references/` + `scripts/` + `agents/` — same shape as [[addyosmani-agent-skills]] and the broader [[claude-code-skills-ecosystem]]. Reinforces [[skill-distribution-convergence]] thesis.

3. **Task forest = lightweight project-level memory**: Sits between session memory and full project management. Lives in `.agent-workbench/task-forest/`, exports HTML, has explicit deviation-tracking. Related to [[memory-os-claudiodrews]] but project-graph-scoped, not user-knowledge-scoped.

4. **User-profile-keeper = explicit collaboration profile**: Parallels our `USER.md` but more structured. Notable: distinguishes `clarification_summary` (low-risk, shared with other skills) from full profile (private). This **view-based access** for skill composition is a pattern worth borrowing.

### Anti-patterns to learn from

- **Mature publishing discipline**: `PUBLICATION_AUDIT.md` (2026-06-15) documents sanitization log, smoke tests, sensitive-data scans. Plaintext warning explicitly stated in `SECURITY.md`. This is more rigorous than most of our public skills.
- **Composable but each works alone**: `task-clarifier` runs without `user-profile-keeper`. Soft coupling, no installation order dependency.

### Distinctive grade-scaling angle

`task-clarifier` has a built-in **"How to Ask"** policy: ask 1–3 questions per turn, choose upstream dimensions first, prefix recommended answers ("我的建议：[X]"). This matches our [[why-was-fable-banned]] grade-scaling philosophy but applied to user dialogue rather than spec rigor.

## Tradeoffs / Risks

- **Solo dev velocity** = fragility. 100⭐/day for 2 days then could plateau like many recent skill repos.
- **Python scripts** add an install step (vs pure prose skill). Tradeoff: persistent state needs storage; you can't do task-forest without a script layer.
- **`user-profile-keeper` plaintext storage** is honest but operationally limits adoption — explicit warning helps.
- **Zero issues / zero external PRs** at 2 days. Real community signal won't be visible until week 2.

## Composition vs Our Stack

| Concern | Ours (existing) | COMPASS approach | Verdict |
| --- | --- | --- | --- |
| Pre-execution alignment | FlowForge align-node, DNA preflight | task-clarifier 10-dim tree + 1-3 question batch | **Complementary** — their alignment tree is more granular per-task; ours is more workflow-level |
| Task tracking | TODO.md flat list + GitHub Issues | task-forest DAG with HTML export | **Different scope** — ours is contribution backlog, theirs is per-repo work graph |
| User profile | `USER.md` + `MEMORY.md` (manual) | user-profile-keeper structured + view-based access | **Pattern worth borrowing** — view-based access for skill composition |

## Decision

**Track + reread in a week.** Not adopting immediately:

1. **Don't fork their skills** — we already have FlowForge + DNA covering pre-execution discipline. Importing would create duplicate gates.
2. **Worth borrowing**: the **fact-vs-decision constraint split** (mentioned in [[align-tree-pattern]] candidate), and **view-based profile access** (clarification_summary as low-risk view).
3. **Watch for**: 1-week community signal (fork → contributor conversion rate), and whether the `compass-skills` install path becomes a standard (`npx skills add ...`).

## Links

- [[why-was-fable-banned]] — sibling Phase-0 gate (spec instead of clarification)
- [[FlowForge]] — workflow engine with our own align-node
- [[skill-distribution-convergence]] — `SKILL.md` standard emerging
- [[addyosmani-agent-skills]] — earlier skill packaging pattern
- [[memory-os-claudiodrews]] — different memory scope (user knowledge vs project task graph)
- [[architect-loop]] — sibling discipline pattern (orchestration vs alignment)
