---
title: Diff-Scoped Followup
slug: diff-scoped-followup
type: pattern
status: active
created: 2026-05-20
tags: [workflow, study, efficiency]
last_verified: 2026-05-20
---

# Diff-Scoped Followup

Extension of [[diff-scoped-review]] to study followup: before manually checking tracked projects for updates, run a pre-filter that queries actual GitHub activity (`pushed_at` via API). Only invest followup time on repos that have had commits since last check.

## Implementation

`study/tracking-activity.sh` — one command shows 🟢 ACTIVE / ⚪ QUIET status for all tracked repos. QUIET repos can be safely skipped, focusing time on repos with real changes.

## Key Design Decisions

- **Wiki fallback for repo URLs**: tracking table often has project names without links. Script resolves owner/repo from targets.md markdown links first, then falls back to wiki/projects/ files (supporting both `github.com/owner/repo` URLs and backtick `owner/repo` format).
- **Rate limiting**: 0.3s delay between API calls to avoid GitHub rate limits.
- **`--all` vs default**: default only checks repos due for revisit today; `--all` checks everything.

## Origin

Applied [[diff-scoped-review]] pattern (from [[dreamer]] deep read, already applied to review.yaml) + [[mirage-vfs]] truth.txt fixture-based verification to study followup workflow.

## Measured Impact

In the first run, 3/9 repos flagged QUIET (agentic-stack, OpenChronicle, Orb) — these would have been checked manually and found unchanged, wasting ~5 minutes per followup session.
