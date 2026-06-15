---
title: tracking-health.sh
type: tool
created: 2026-05-05
status: active
last_verified: 2026-06-15
---

# tracking-health.sh — Tracking Portfolio Health Dashboard

**Location**: `~/.openclaw/workspace/study/tracking-health.sh`
**Usage**: `bash tracking-health.sh [YYYY-MM-DD]`

## What It Does

Portfolio-level health check for the study tracking list in TODO.md:

1. **Overdue items** — past revisit date, need immediate action
2. **Auto-drop candidates** — detected via signals: stalled, no commits, low traction (<20⭐) without deep read, explicit "consider drop" markers
3. **Revisit date distribution** — shows load clustering (e.g., 15 items on 05-09 = overload)
4. **Star tier distribution** — portfolio composition by traction level
5. **Recommendations** — actionable: portfolio too large (>40), overdue count, drop candidates

## Why It Exists

The tracking list grew to 51 items organically. `tracking-due.sh` only shows today's due items — no portfolio overview, no drop detection, no load distribution. This tool applies the "observability must close the loop" principle: see the problem → act on it.

## Applied From

- **GenericAgent** — "fold agent, keep user" heuristic led to thinking about information management at scale
- **bux** — "proactive agency" pattern (structured suggestions → action) inspired the recommendation engine
- **AGENTS.md** — "观测必须闭环" principle directly: every `发现 X 问题` needs action in the same turn

## Integration

- Integrated into [[flowforge]] `study.yaml` followup node as step 0 (before tracking-due.sh)
- Rule: if auto-drop candidates > 5 or total > 40, clean first, then follow up

## Known Issues & Fixes

### 05-16: False positive on "flat" keyword
**Problem**: Bare `flat` in signal 1 grep matched "star growth flat" in observations about THRIVING projects (e.g., kiwifs/kiwifs 425⭐ 🟢 THRIVING). Flagged 05-14, reproduced and fixed 05-16.

**Root cause**: `grep -qiP "...flat..."` too broad — matched any line containing "flat" regardless of context.

**Fix**: Three changes:
1. Replaced bare `flat` with specific phrases: `flat growth`, `stars flat`, `growth flat`
2. Added THRIVING/HEALTHY negative gate — if line contains positive health signal, skip
3. Removed `flash` (typo, never a valid signal)
4. Aligned summary `drop_count` grep with detection grep

**Lesson**: Signal detection keywords need context-awareness. Bare adjectives ("flat", "slow") appear in many contexts — use 2-word phrases for precision. Negative gates ("but this line also says X") prevent false positives on mixed-signal entries.

## Links

- [[tracking-due-script]] (predecessor, date-only check)
- [[study-workflow]] (where it's used)
- [[genericagent]] (architectural inspiration)

## 2026-05-17 Bug Fix: study-saturation.sh

**Bug**: `grep -c` outputs `0` AND exits with status 1 when no matches found. The `|| echo 0` fallback pattern (`var=$(grep -c ... || echo 0)`) then fires, producing `"0\n0"` which breaks bash arithmetic `(( ))`.

**Fix**: Changed to `var=$(grep -c ...) || var=0` — the assignment captures grep's stdout (the `0`), and only if the subshell fails does the fallback assignment run. No double-output.

**Pattern**: This is a common bash pitfall. `grep -c` is unusual among commands because it outputs a result (`0`) even on failure (exit 1). Most `$(cmd || echo default)` patterns assume the command produces no stdout on failure. When using `grep -c`, always use the `var=$(cmd) || var=default` form instead.

**Verification**: Before: syntax errors on every run with zero-count modes. After: clean output with correct integers.

## 2026-06-04 Apply: Cross-Reference Check (audit-targets.sh)

**Problem identified**: tracking data split across 3 sources (TODO.md Track: items, targets.md depth matrix, wiki/projects/ notes) with zero consistency checking. Example: html-anything tracked actively in TODO.md (5983⭐, 5.5x growth) but absent from targets.md portfolio view. Invisible unless someone manually compares files.

**Fix**: Extended `audit-targets.sh` with cross-reference section:
1. Extracts open Track: items from TODO.md → fuzzy-matches against targets.md Tracking table
2. Reverse check: items in targets.md Tracking table not in TODO.md
3. Reports mismatches with actionable summary

**Result**: First run surfaced 8 mismatches (5 in TODO but not targets, 3 in targets but not TODO). These were previously invisible.

**Behavioral change**: `audit-targets.sh` now surfaces data source divergence during followup prep, enabling synchronization before drift compounds. Before: only TTL/staleness checks. After: full portfolio consistency verification.

Links: [[tracking-due-script]], [[cured-tracking-methodology]], [[self-evolving-observations]]

## 2026-06-15 Fix: tracking-update.sh sed escape bug

**Problem**: 3-time DNA preflight recidivist (`tool-friction-sed-bug`). `tracking-update.sh` failed with noisy stderr when notes contained regex special chars (`/`, `(`, `|`). Pipe chars `|` in notes silently corrupted the markdown table.

**Root cause**: Three issues compounding:
1. `$PROJECT` used unescaped in `grep -P` regex — chars like `.`, `(`, `+` in project names caused match failures
2. No sanitization of `|` in user-provided notes — pipes broke markdown table column alignment
3. Greedy `.*` in name extraction sed `s/.*\[\(.*\)\].*/\1/` — could overcapture with multiple bracket pairs

**Fix**:
1. Added `perl -pe` regex escaping for `$PROJECT` before grep pattern interpolation
2. Pipe chars in notes replaced with `∣` (U+2223, visually identical, table-safe)
3. Changed to non-greedy `[^]]*` in name extraction: `s/.*\[\([^]]*\)\].*/\1/`

**Pattern**: Shell scripts that interpolate user input into regex patterns need an escape layer. Bare variable expansion in `grep -P "...$VAR..."` is a regex injection bug. Either escape with `\Q$VAR\E` (PCRE) or pre-escape with `perl -pe`.

**Lesson**: This was a 3-time recidivist because each occurrence was non-blocking (dates updated correctly, stderr noise ignored). Low-severity bugs that don't crash become invisible to fix-prioritization. The DNA preflight recidivist counter was what finally forced attention.

Links: [[study-workflow]], [[self-evolving-observations]]
