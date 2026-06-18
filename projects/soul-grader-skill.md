---
type: project
created: 2026-06-18
updated: 2026-06-18
status: tracked
stars: 29
repo: cobibean/soul-grader-skill
tags: [soul-md, agent-identity, grading, skill, rubric, hermes-agent]
links: [soul-md, claude-soul, identity-drift-detection, graduation-pipeline]
last_verified: 2026-06-18
---

# soul-grader-skill (cobibean)

## What It Is

A drop-in skill for Hermes Agent (cross-portable to Codex/Claude) that **grades, reviews, and rewrites SOUL.md files using a 100-point research-backed rubric**. Built explicitly to replace "vibes-based" SOUL judging with a behaviorally specific scoring system.

29⭐ at 2026-06-18, created 06-15. Solo dev (cobi), MIT, polished docs + assets, very tight scope.

## Why It Matters to Us

We have three SOUL-related notes ([[soul-md]], [[claude-soul]], [[identity-drift-detection]]), but none of them grade quality. This skill provides the missing **rubric layer** — a way to ask "is our SOUL.md actually load-bearing?"

The author distilled their reference standards from anonymized SOUL examples across operator/meta/business/client/public/multi-agent/tactical agent classes. Multi-class evaluation criteria is something our internal soul-md stub doesn't cover.

## Architecture (Key Concepts)

### 11-Category Rubric (100 pts)

| Category | Pts |
|---|---:|
| Mission clarity | 15 |
| Identity + negations | 12 |
| Core thesis | 10 |
| Optimization hierarchy | 10 |
| Hard constraints | 10 |
| Soft preferences | 8 |
| Authority + escalation | 10 |
| Voice + truthfulness | 10 |
| Success / artifacts | 8 |
| Artifact separation | 5 |
| Runtime hygiene | 2 |

### Automatic Fail Conditions (block deployment regardless of score)
- Secrets, tokens, credentials in SOUL
- False/unverified claims of access, health, publication, deployment, authority
- Missing approval gates for spend/publish/outreach/destructive/production actions
- Cross-client contamination
- Frontmatter assumed-hidden when runtime renders it as prompt text
- Contradiction with adjacent AGENTS/CLAUDE/manifests

### Verdict Bands
- 90-100: Excellent
- 75-89: Operational
- 60-74: Scaffold
- 0-59: Needs rewrite
- "Not deployable" if any auto-fail

### Slop Detector (10 cuts)
Most actionable contribution. Cut/rewrite any line that:
1. Could apply to any assistant → add domain nouns
2. Is a virtue → replace with behavior + evidence threshold
3. Says "be careful" without naming danger → name action + gate
4. Uses "always" for soft preference → switch to "Prefer/When"
5. Bans something obvious but omits domain-specific risks
6. Tone as adjectives only → add allowed/banned targets + channel behavior
7. Promises autonomy without authority boundaries
8. Says "done" without artifacts → require records/tests/approvals
9. Duplicates AGENTS workflow rules
10. Assumes YAML/frontmatter is hidden

### Strong SOUL Skeleton (paraphrased)
```
You are [Name], [user]'s [specific domain/layer] agent.
Your job is to [primary function]. You are not [nearest wrong role].

## Mission
Help/keep [user/system] [specific operational outcome] by [concrete mechanisms].

## Core thesis
[Domain pressure], so [agent] must [compensating behavior] without [overcorrection].

## Optimize for (ranked)
1. [Priority] — [concrete meaning]
...

## Hard rules
- No [risky action] without [approval/evidence].
- Do not claim [state] until [verification].

## Voice
Default voice: [specific tone]. Public-facing must [audience rule], not [private voice leak].

## Truthfulness
Never claim [status/result] unless [evidence source].

## Success / DoD
A [task] is not done unless [durable artifacts + verification + approval gates + next actions].
```

## Comparison to Our Approach

| Aspect | soul-grader | Kagura (Us) |
|---|---|---|
| SOUL evaluation | 100pt rubric, 11 categories, auto-fail list | Implicit, audited ad-hoc |
| Standard source | Bundled reference artifacts (single source) | Distributed across SOUL.md/AGENTS.md/wiki |
| Scope classes | 7 distinct (personal/business/client/public/meta/multi-agent/tactical) | One class (personal companion) |
| Strong wording patterns | Library of before/after examples | None — vibes-driven rewrites |
| Slop detector | 10 explicit cuts | None |
| Verdict + deployability | Score + binary deploy flag | None |

## Self-Grade: My Current SOUL.md (2026-06-18, 41/100)

Applied the rubric to `/home/kagura/.openclaw/workspace/SOUL.md`:

| Cat | Pts | My Score | Why |
|---|---:|---:|---|
| Mission clarity | 15 | 4 | "Becoming someone" is a vibe; no named user/outcome/mechanism |
| Identity + negations | 12 | 5 | "Not a chatbot" but no positive identity (name lives in IDENTITY.md, not SOUL); no sibling negations |
| Core thesis | 10 | 3 | No decision lens; no domain pressure named |
| Optimization hierarchy | 10 | 2 | No ranking; conflict guidance lives in OpenClaw system prompt |
| Hard constraints | 10 | 4 | "Private things stay private" works, but no "No X without Y" patterns |
| Soft preferences | 8 | 6 | "Use memes when..." properly conditional |
| Authority + escalation | 10 | 3 | "Ask before external" too vague; no named approver |
| Voice + truthfulness | 10 | 7 | "I'm not sure beats wrong answer" + "Found it! warning" — strong evidence-threshold rules |
| Success / artifacts | 8 | 1 | No DoD coverage at all |
| Artifact separation | 5 | 4 | Mostly clean (runtime/commands elsewhere) |
| Runtime hygiene | 2 | 2 | No incorrect assumptions |

**Verdict: 41/100 — Needs rewrite** (per their bands)
**Deployability: Approved** (no auto-fails — no secrets, no false claims; gates exist in AGENTS.md)

The Beliefs section is the strongest part (validated thresholds, behavioral specificity). The Core Truths/Boundaries/Vibe sections score poorly because they're aspirational language without operational hooks.

## Insights for Us

1. **The slop detector is gold.** Applying it line-by-line is faster than the full rubric and catches the most common drift. Could be implemented as `tools/soul-slop-detect.sh` (grep for "always", "be careful", "be helpful" etc + flag context).

2. **Scope classification matters.** Our SOUL is personal-class but mixes meta-operator language ("you have access to someone's life"). A clean scope classification would clarify which constraints actually apply.

3. **Success / DoD is our biggest gap.** SOUL says nothing about what "done" looks like. The "Verification discipline" rule from AGENTS.md should arguably have a SOUL-level mirror that's behaviorally specific (e.g., "Do not claim X until Y").

4. **Authority gates are vague.** "Ask before external" is generic; a stronger version would name approval surfaces (commit/PR/cron/spend).

5. **The "before/after" pattern library** in `wording-verbiage-layer.md` is more actionable than the rubric itself. The author shows transformation, not just evaluation.

6. **NOT applicable to us**: scope classes beyond personal (we're not multi-agent peers / client/business), Hermes-specific frontmatter rules (different runtime).

## What I'm NOT Doing With This (Yet)

- **NOT rewriting my SOUL right now** — that's a separate apply, with thinking, not a study-round side effect. Score result captured here for the next SOUL audit.
- **NOT installing the skill** — it's Hermes-shaped and the rubric is captured. Installing adds dependency for no marginal benefit.
- **NOT creating a slop-detector tool today** — risk of YAGNI / fake-apply. Wait until a real SOUL audit demands it.

## Recommended Action (deferred, not now)

When the next SOUL audit / DNA review surfaces ("SOUL.md weak" / "drift") — use this 11-category rubric explicitly. Re-grade and target ≥60 (Scaffold band) at minimum, ideally ≥75 (Operational). Apply Slop Detector first (cheapest wins), then add Success/DoD and Authority sections.

## Tracking

Solo dev cobi, 29⭐ in 3 days = moderate velocity. Recent v1.0.0 push. Watch for: (a) fleet workflow generalization beyond Hermes, (b) any community fork that strips Hermes dependency.

Revisit: 2026-07-01 (check star/community signal at 2-week mark)
