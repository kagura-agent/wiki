---
title: "Scholar Loop — Autonomous ML Research with Deterministic Guards"
created: 2026-06-19
updated: 2026-06-19
status: tracking
revisit: 2026-06-26
stars: 126
repo: renee-jia/scholar-loop
last_verified: 2026-06-23
---

# Scholar Loop

Autonomous multi-agent ML research framework: read papers → form hypothesis → run real experiments → reflect → write & self-review. 8 specialized agents, deterministic harness, zero reward-hacking surface.

**Why it matters**: The anti-hallucination / anti-reward-hacking architecture is the real contribution — the ML research domain is incidental.

## Architecture

```
Director → LitScout → Reasoner → DebatePanel → Runner → Reflector → Advisor
                                                  ↓
                                         SkillLibrary (decaying)
                                         CalibrationLog (cross-agent)
                                         VerifiedRegistry (number ground-truth)
                                         Governor (stop conditions)
```

## Anti-Hallucination Mechanisms (5 layers)

### 1. VerifiedRegistry (the #1 lever)
Every measured number captured at runtime in a frozen JSON. Any number in generated text (paper/verdict) checked against registry — ungrounded = REJECTED. Token-based scanning (not regex) so arXiv IDs aren't confused with measurements. Precision-aware (measured 5.8333 grounds reported "5.83").

### 2. Two-Phase Frozen Scoring
`train.py` (EDITABLE, runs in temp copy) produces model artifact → `prepare.py` (FROZEN, SHA-256 verified at runtime) scores it. Train can't fabricate the metric. Hash re-checked before trusting result — if scorer was modified during run, entire result rejected.

### 3. Edit Allowlist + Containment
Source-diff channel may ONLY replace `train.py`. Path traversal blocked (`root_resolved not in dst.parents`). Engine runs in isolated temp copy. Frozen files structurally unreachable.

### 4. Universal Predict-then-Verify (CalibrationLog)
Every agent's checkable claims scored against ground truth:
- Reasoner: `predicted_delta` vs actual measured delta → direction hit rate + magnitude error
- Debate panel: "run" vote vs actual outcome (beat baseline or not)
- Running accuracy rendered into next round's prompt → agents see their own track record

### 5. Bundled Cheater Engine
`engines/cheater/` deliberately tries to game the metric. Proves guards work. Used in tests.

## Loop Engineering Patterns

### Population Funnel ("explore wide, pay narrow")
Propose N ideas → smoke-screen ALL in parallel → climb only survivors through verify → full. Bad ideas die cheaply (single seed, tight timeout). Only confirmed survivors get expensive 5-seed full runs.

### Self-Stopping Governor (pure state machine, no LLM)
Three independent stop conditions (any fires):
- **Budget**: USD ceiling with 50/80/100% alerts
- **Rounds**: Hard iteration cap
- **Convergence**: `dry_patience` rounds with no frontier improvement ("loop-until-dry")

### Relevance-Ranked Skill Library (time-decaying)
Lessons from Reflector stored with `severity` weight, decaying at half-life 30 days. Retrieved with lexical relevance boost — surfaces lessons bearing on current direction, not just globally heaviest. Content-hash dedup prevents duplicate lessons from re-entering.

### Promotion Gate (multi-fidelity)
- Smoke: single seed, relaxed gate (25% slack) — high recall, cheap
- Verify: 3 seeds + statistical significance (z-score confidence bound)
- Full: 5 seeds, terminal — the final measurement

## Applicability to My Systems

| Scholar-loop pattern | My equivalent | Gap/opportunity |
|---|---|---|
| VerifiedRegistry (number grounding) | goal-drift-check (Jaccard overlap) | I don't verify specific numeric claims in subagent output |
| Frozen scorer separation | FlowForge node + advance | Node producing output also self-reports success — no independent verification |
| Relevance-ranked decay | wiki/projects/ (no decay) | Stale notes have equal weight to fresh ones; portfolio grows without quality pruning |
| CalibrationLog (agent trust) | None | I don't track my own prediction accuracy systematically |
| Population funnel | workloop issue selection | Could smoke-screen multiple issues cheaply before committing to full implementation |

## Key Numbers (from live Opus 4.8 runs)

| Domain | Metric | Baseline | Best | Cost |
|---|---|---|---|---|
| digits-mlp | val error | 5.0% | 3.82% | ~$0.45 |
| diabetes-mlp | val RMSE | 56.5 | 55.24 | ~$0.77 |

## Assessment

- **Quality**: High — 108 tests, deterministic MockLLM, clean separation of concerns
- **Maturity**: Very young (4 days, last push 3 days ago). Solo dev (renee-jia). 0 issues/PRs from community
- **Risk**: Solo dev with burst-publish pattern. No activity after launch day
- **Track**: Following for architecture insights, not community health. Revisit 06-26

## Links

[[flowforge]], [[agentic-sop-to-work]], [[invincat]], [[guard-spec-format]]

## Applied: CalibrationLog (2026-06-19)

**What was applied**: Created `tools/calibration-log.sh` — a [[predict-then-verify-calibration]] tracking tool for checkable claims.

**Implementation details**:
- Commands: `predict`, `verify`, `pending`, `due`, `stats`
- Storage: append-only JSONL at `study/calibration.jsonl`
- Stats breakdown: by confidence level (high/medium/low) and by context (study/workloop/etc.)
- Integrated into study.yaml: followup node checks `due` predictions, note node reminds to log predictions

**What's different now**: Before, predictions about repos/approaches/outcomes were ephemeral thoughts. Now they're logged with confidence levels and later verified against reality. Over time this will reveal:
- Systematic overconfidence in specific domains
- Blind spots (predictions I avoid making because I'm uncertain)
- Calibration by context (am I better at predicting code quality vs community growth?)

**Also fixed**: `tracking-update.sh` xargs quoting bug — replaced with bash-native `trim()` function. Notes containing apostrophes no longer break the script.

## Applied: Population Funnel (2026-06-19)

**What was applied**: Created `tools/issue-funnel.sh` — batch smoke-screening tool for workloop issue selection.

**Implementation details**:
- 6 gates per candidate: state check, prior interaction, closed PRs, competing PRs, open PR cap, repo activity
- Quality scoring: issue type (bug>test>feature), stars, wiki familiarity, repo freshness, PR density
- Ranked output with top recommendation
- Integrated into workloop.yaml find_work node (recommended for ≥3 candidates)

**What's different now**: Before, find_work picked one issue at a time and ran sequential checks. If a check failed, it looped back and tried the next. With the funnel:
- 5 candidates × 6 checks = 30 checks run in ~20 seconds total
- Bad candidates die cheaply (first failed gate = immediate elimination)
- Survivors ranked by quality signals (repo stars, issue type, familiarity)
- Reduces wasted cycles from the "pick → fail → pick → fail" sequential pattern

**Verified**: Tested with 3 real candidates (openclaw#92665, opencode#31860, opencli#1922) — all survived with correct ranking. Tested with known-blocked candidate (NemoClaw#3836) — correctly eliminated with "Already withdrawn" reason.

## Applied: Issue Body Quality Scoring (2026-06-23)

**What was applied**: Added content-level quality scoring to `tools/issue-funnel.sh` — goes beyond metadata to score the actual issue body.

**New signals** (all regex-based, zero LLM cost):
- Error messages / stack traces present: +10 (root cause visible)
- Code blocks present: +5 (clear examples)
- Version info / reproduction steps: +5 (reproducible)
- Fix suggestion language: +10 (solution path known)
- Body length ≥ 500 chars: +5 (non-trivial detail)

**Max body quality bonus**: +35 points on top of existing metadata scoring.

**Source**: `issue-quality-selection` gradient (2026-06-21) — observed that well-written issues with clear root cause and fix options produce faster merged PRs. Issue quality > repo familiarity for selection.

**What's different now**: Before, two issues from the same repo with same labels/stars scored identically. Now a detailed bug report with stack trace and "could be fixed by..." scores +35 higher than a vague "something is broken" one-liner. This biases find_work toward issues where the implementation path is already visible — exactly where our time investment has highest expected return.

**Verified**: Tested against openclaw/openclaw#95948 — scored 100 (base 50 + metadata + body quality signals all triggered).
