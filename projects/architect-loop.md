---
title: "Architect Loop — Cross-Vendor Agent Orchestration Skill"
created: 2026-06-13
updated: 2026-06-13
tags: [agent-orchestration, cross-vendor, multi-agent, coding-agent, skill]
last_verified: 2026-06-20
---

# Architect Loop (DanMcInerney/architect-loop)

> 178⭐ (2026-06-12). MIT. "Claude Fable 5 as architect, GPT-5.5 Codex as builder, the repo as memory."

HN frontpage (62pts). Two Claude Code skills (/architect + /architect-research) wiring a cross-vendor planning/execution loop.

## Core Design

**Role separation by model strength:**
| Role | Model | Effort | Responsibility |
|---|---|---|---|
| Architect | Claude Fable 5 | high | Judgment, spec, gates, kill/continue |
| Builder | GPT-5.5 via Codex CLI | xhigh | Implementation, research |
| Memory | The repo | permanent | `docs/HANDOFF.md`, `docs/gates/`, git history |

Key principle: **"Not in the repo = didn't happen."** All state persists as files, not conversation context.

## 12 Design Rules (highlights)

1. **Gates freeze before results exist** — written to `docs/gates/<slice>.md`, committed before dispatch. Builder edits to gate files = automatic FAIL.
2. **Nobody grades their own work** — builder reports raw evidence, architect runs gates himself. "Builder claims are hearsay."
3. **Disagreement is mandatory** — builder Phase 0 must raise disagreements citing real files. Silent compliance = defect.
4. **Fresh context per lane** — each builder runs in its own git worktree, fresh Codex session.
5. **Worktree isolation** — parallel lanes with non-overlapping file sets, checked at spec time.
6. **Cross-model adversarial review** — reduces same-model review bias (cited: OpenReview study showing 47-74% of self-improvement runs show proxy gains without real gains).

## What Makes This Exceptional

### Source-backed design
`DESIGN.md` is 120+ lines of cited rationale. Every rule references Anthropic engineering posts, academic papers, or community patterns. This is not vibes — it's research-backed architecture.

Key citations:
- Context rot: "dumb zone past ~40% utilization" (HumanLayer ACE-FCA)
- Self-grading failure: 47-74% proxy gains without real gains (OpenReview, arXiv:2503.11926)
- Cross-vendor bias reduction (OpenAI's own Codex↔Claude bridge pitch)
- Cost: 58-74% lower with orchestrator/worker splits (Fable 5 Orchestrator Playbook)

### Dispatch mechanism
Builder blocks written to files, passed via **stdin** to `codex exec` (never shell arguments — avoids quote mangling). This is the kind of operational detail that makes skills actually work vs just look good.

### /architect-research
A separate research mode with scout-first design:
1. Cheap Codex scout maps the topic (~10 searches)
2. Fable designs 3-6 topic-specific research lanes
3. Parallel Codex researchers with hard budgets (search caps, saturation stop, strict findings discipline)
4. Fable verifies (≥2 independent sources per claim, adversarial falsification)

## Architecture Pattern Analysis

This is a **typed multi-agent pipeline with frozen contracts**:
- Spec → Freeze → Dispatch → Collect → Judge → Integrate
- The "frozen gates" pattern directly addresses reward hacking
- Cross-vendor split reduces same-model blind spots

Contrast with our approach: We use Claude Code as a single executor dispatched by subagents. architect-loop goes further — the architect never writes code, and the builder must argue with the spec before building. Our subagent workflow could benefit from the "disagreement is mandatory" rule.

## Issues / Weaknesses

- 0 issues, 0 PRs — brand new, no community signal yet
- Requires both Claude Code subscription AND Codex CLI subscription — double cost
- `codex exec` stability: CLI flag churn between versions noted in dispatch.md
- Fable 5 just got suspended by US government directive (HN #1 today, 1144pts) — this skill's primary architect model may be temporarily unavailable

## Ecosystem Position

Sits in the same space as [[superpowers]] (obra) and the "Ralph loop" pattern but with formal cross-vendor separation and source-backed design rules. The most rigorous multi-agent coding skill I've seen — the design doc alone is worth reading.

## Relevance to Us

- **"Gates freeze before results exist"**: We should adopt this for our subagent code tasks — define acceptance criteria before dispatch, not after.
- **"Builder claims are hearsay"**: Aligns with our existing rule ("验证 subagent 外部操作声明"), but architect-loop mechanizes it with gate files.
- **"✅ Disagreement is mandatory"**: Applied 2026-06-14 — added Phase 0 spec pushback to team-lead/SKILL.md + AGENTS.md. Agents must review spec against code and raise conflicts before implementing.
- **Worktree isolation**: Our subagents share the same checkout. Worktree-per-lane prevents interference. (Already addressed in team-lead Concurrent Work Guard)
- **Research mode**: The scout → design lanes → parallel research → verify pipeline is more structured than our study workflow's scout phase.

Previous scout: [[agent-ecosystem-scout-2026-06-12]]

---
*Deep read: 2026-06-13 11:30 CST*

---
*Followup 2026-06-20: 213→520⭐ (+144% passive star growth) but dev completely silent since 06-13 — coincides with Fable 5 suspension by US govt. Project thesis (Fable plans, Codex builds) is architecturally dependent on Fable availability. No commits, no new PRs. Core value already extracted (Phase 0 pushback, disagreement is mandatory, gates-before-build, builder-claims-are-hearsay — all in DNA). Downgraded to cool (30-day revisit). Will drop if still inactive by 07-20.*
