---
title: Followup Pre-Check Aggregation
tags: [workflow, efficiency, study, tooling]
created: 2026-06-19
status: applied
last_verified: 2026-06-19
---

# Followup Pre-Check Aggregation

## Problem

Study followup mode required 3-4 sequential script invocations before actual project investigation could begin:
1. `tracking-health.sh` (~2s) — portfolio overview
2. `tracking-due.sh` (~5s) — which items are due
3. `tracking-activity.sh --all` (~15s) — which repos have recent pushes
4. Optionally `tracking-community.sh` per project

Each produced siloed output. Mental overhead to cross-reference (e.g., "is this due item also active?") was non-trivial. Observed: 25%+ of followup round time was housekeeping vs actual investigation (2026-06-18 measurement).

## Solution

Created `study/followup-status.sh` — single aggregator that:
- Extracts due items from TODO.md (same logic as tracking-due.sh)
- Batch-checks GitHub API for each due repo's `pushed_at` (same logic as tracking-activity.sh)
- Shows portfolio health summary (same as tracking-health.sh header)
- Outputs unified per-item view: name + stars + due date + activity status (🟢/⚪/❌) inline
- Emits actionable recommendation at bottom

Key implementation choices:
- Used `grep -oP` + `sed` instead of `[[ =~ ]]` for complex patterns (avoids bash regex bracket issues with Unicode)
- Added `-L` flag to `curl` to handle GitHub repo redirects (301 Moved Permanently for renamed repos)
- Fixed `pushed_at` grep pattern to handle JSON spacing variants (`"pushed_at": "..."` vs `"pushed_at":"..."`)
- Org-only pattern fallback: if TODO has `(org-name)` without `/repo`, constructs `org/name-slug` automatically

## Impact

- **Tool calls**: 3 → 1 per followup round
- **Cross-referencing**: eliminated (due + activity shown inline per item)
- **Recommendation**: automated (ACTIVE targets highlighted, all-QUIET → bump dates suggested)
- Original scripts remain for ad-hoc use

## Related

- [[study-saturation]] — similar aggregation pattern for mode selection
- [[flowforge]] — workflow integration point (study.yaml followup node)
