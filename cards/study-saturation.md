---
title: Study Saturation
created: 2026-05-31
tags: [tool, study, structural-gate]
last_verified: 2026-08-13
status: active
depth: scout
---
# Study Saturation

A tool (`tools/study-saturation.sh`) for detecting when repeated study sessions on the same dimension show diminishing returns, and recommending mode switching.

## Key Mechanisms

1. **Per-mode capacity caps**: scout 3/day, quick 3/day, apply 3/day, followup 4/day
2. **Consecutive same-mode detection**: 2× yellow, 3× red (from [[genericagent]] diminishing returns signal)
3. **Inter-day scout interval**: warns if last deep scout <3 days ago
4. **Followup due-date gate** (2026-06-22): queries `followup-status.sh` before recommending followup. If 0 items due, locks mode. Prevents capacity ≠ actionability mismatch that was wasting 2 rounds/day.
5. **Apply backlog awareness** (2026-06-26): checks unapplied.md for unchecked items. If 0 unchecked, shows "(backlog empty)" and deprioritizes apply in recommendation. Doesn't lock (other sources exist: preflight gradients, observations), but informs decision. Source: [[self-evolving-observations]] Day 9 UX finding.
6. **Apply empty-backlog auto-lock** (2026-07-07): when backlog is empty AND any apply already happened today, apply is fully locked (not just deprioritized). Fixes 4-day recidivism `study-saturation-apply-empty-misleading`: old logic only checked for `outcome=="empty"` in outcome log, but agents mislabel empty applies as `partial` ("wrote an observation" ≠ real apply). Fix: check for ANY prior apply outcome when backlog depleted. Applied to both study-saturation.sh and study-saturation-gate.sh.
7. **Soft saturation** (2026-08-13): capacity says "open" (scout 2/3, apply 0/3) but no mode is actionable — deep scout already done today (or <3d ago) AND quick scan done AND apply backlog empty AND followup locked. Old logic fell through to "scout (recent, but better than empty-backlog apply)" → empty round re-scanning the same known pi-ecosystem cluster within hours (08-13 09:34 & 10:01 reflects both flagged it). Fix: detect this state → emit "🛑 SOFT SATURATION" skip. Also fixed `SCOUT_DAYS_AGO` to count today's deep scout as 0d ago (previously only scanned prior days i=1,2, so a fresh scout reported "1d ago"). This is the cross-mode generalization of the capacity/actionability principle: not just per-mode, but when ALL remaining open modes are simultaneously non-actionable.

## Design Principle

Capacity ("is there room for another round?") ≠ Actionability ("is there actually something to do?"). The followup gate was the first instance; the apply backlog check is the second. Pattern: every mode recommendation should check if there's actual work to do in that mode, not just count past rounds.

## Links

- [[followup-precheck-aggregation]] — the aggregated status script that saturation.sh now queries
- [[structural-fix-over-behavioral-rule]] — pattern: tool gates > behavioral rules
- [[self-evolving-observations]] — tracked this bug for observation
