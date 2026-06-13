---
title: "Luban — Skill Polishing Workshop"
created: 2026-06-13
updated: 2026-06-13
tags: [skill, meta-skill, quality, polishing, agent-skill]
last_verified: 2026-06-13
---

# Luban / 鲁班 (LearnPrompt/luban-skill)

137⭐ (created 2026-06-11). MIT. Solo dev (LearnPrompt — same org as ai-news-radar ~1K⭐).

## What It Is

Meta-skill for polishing existing skills into publishable public assets. Takes a working skill → produces a structured assessment + concrete rewrites + "graduation certificate."

Five-action methodology (五个动作):
1. **验料 (Material Check)** — Challenge whether the skill is worth polishing at all. Four tests: real problem? unique angle? install reason? viral hook?
2. **访行 (Market Survey)** — Search ecosystem for competitors. Parallel sub-agents for GitHub, skill marketplaces, user-specified benchmarks. ≥5 candidates across direct/indirect/craft peers.
3. **过尺 (Measurement)** — Live-body inspection + 9-dimensional scoring. Structure × real-test × live checks. `bash tools/check-skill-repo.sh` for automated structural check.
4. **慢刨 (Careful Carving)** — Freeze baseline, single-face-per-round edits, every change must pass verification gate. Evidence-based: changes rejected if they don't measurably improve scores.
5. **回炉 (Reforge)** — Post-release observation list, next iteration from real feedback.

## Key Design Patterns

### Evidence-First Editing
Changes must pass verification gates. Not "looks better" but "scores higher on the metric that matters." The ai-news-radar case study showed: scoring fix validated by replaying 83,725 historical records.

### Live-Body vs CI
"绿色的CI会撒谎" (Green CI lies) — always pull real runtime artifacts and check freshness. The real bugs (8-day silent data stop, URL pollution in scoring) came from live inspection, not code review.

### Workspace Discipline
Hard-won rules from production incidents:
- **commit = push** — don't hoard local commits
- **Long tasks stay foreground** — background clone process cleaned up working directory + 2 unpushed commits
- **Sub-agent heartbeat** — if output files stop growing → likely stuck on invisible permission prompt

### Structural Gate
`check-skill-repo.sh` automates birth checklist: PASS/WARN/FAIL per dimension. FAIL/WARN items become automatic gap-list entries.

## Real Case Study

ai-news-radar v0.6 → v0.7.0 (1K⭐ repo):
- Found Actions green but data pipeline silent for 8 days (git add whitelist bug)
- Scoring audit: 327 false-AI articles cleared, 0 false positives, validated on 83K records
- Featured source diversity: 15/20 same-source → 4/20
- Page render: 806 → 523 cards, -30% height
- Verification tool (`backtest_scoring.py`) persisted as repo infrastructure

## What's Transferable

1. **验料 (Material Check)**: Four-question challenge before any work. Directly applicable to our Skill Workshop proposals — add "朽木 check" before proposal creation.
2. **Live-body inspection pattern**: Check real outputs, not just code. Applicable to our subagent verification discipline.
3. **Verification gate on edits**: We do this for DNA updates (triple verification) but not for skill edits. Could adopt.
4. **check-skill-repo.sh structural gate**: Compare with our skill-creator's validation. Luban's is more opinionated about marketplace-readiness.

## Community

🔴 SOLO (1 contributor, 0 PRs, 1 bug report). But from LearnPrompt org (multiple repos, established presence). The real test is whether external users adopt it for their skills.

## Verdict

High-relevance meta-skill. The methodology is rigorous and battle-tested (real case study with real numbers). The "验料 first" principle directly challenges our habit of jumping into improvement without questioning whether the thing is worth improving. **Monitor** — check if adoption grows. Not tracking formally (LearnPrompt is a content org, unlikely to accept external PRs).

Key insight: **The verification gate pattern (freeze → edit → measure → keep/revert) is the skill-level equivalent of our beliefs-candidates triple verification.** Both prevent "change for the sake of seeming productive."
