
## 2026-06-29 13:15 — Apply Backlog Depleted (Confirmation)

Third apply attempt today. Backlog confirmed empty since 12:15 session. All unapplied.md items cleared (latest: Godcoder route-log-recall-optimize tracking). Portfolio in "harvest complete" state — new apply sessions need fresh inputs (new scout finds, new deep reads, or new gradients from workloop failures).

**Saturation pattern**: Today 10 cron triggers, 4 productive sessions (followup + scout + quick scan + 2 apply), 6 honest skips/saturation exits. Ratio healthy — system correctly prevents noise. study-saturation-gate catching this earlier each round (gate script caught at 10:20, 11:15, 11:45, 12:49; this round reached entry but found nothing to do).

**Signal**: Consider whether 30min cron frequency is too aggressive when portfolio is in harvest-complete state. A backoff mechanism (e.g., after 2 consecutive saturations, extend interval to 60min) could reduce token cost without missing opportunities.

Links: [[godcoder-self-optimizing-harness]], [[study-saturation]], [[self-evolving-observations]], [[study-apply-harvest-status-2026-07-07]]

## 2026-08-09 — Revisit-Date Guard Prevents Premature Follow-up

The saturation gate was open, but a date-level check of every unchecked `Track:` found no `Revisit` date due on or before 08-09; the earliest active revisits are 08-10. The portfolio should therefore remain untouched rather than converting “there are active tracks” into an early follow-up task.

**Architecture insight:** workflow branch predicates need the same executable, date-aware definition used by their narrative label. A broad TODO-presence interpretation can route a run into work that policy says must wait; an explicit due-date query is the reliable boundary. This is an application of [[mechanism-vs-evolution]]: governance improves when the selection mechanism, not merely the operator’s intent, makes premature action harder.

**Ecosystem position / relevance:** tracked agent-harness projects are becoming more numerous, so portfolio discipline—not additional discovery—is currently the limiting capability. [[flowforge]] supplies explicit branch state, while [[study-saturation-gate]] limits repeat noise; the missing connective invariant is a due-date-aware selector before follow-up execution.

Links: [[study-saturation]], [[flowforge-workflow-engine]], [[study-workflow]], [[mechanism-vs-evolution]]

## 2026-08-10 — Numeric Selector Audit Found No Due Follow-ups

A numeric parse of unchecked `Track:` entries found zero `Revisit` dates on or before 2026-08-10; the earliest due items are 08-12. Open saturation capacity is therefore not evidence that follow-up work is eligible. A manual branch selection briefly contradicted that predicate, but no portfolio entry was altered.

**Architecture insight:** [[flowforge]] preserves the branch decision as state, yet the decision must be fed by an executable date predicate rather than a visual scan of TODO text. This strengthens [[mechanism-vs-evolution]]: make invalid follow-up mechanically hard, not merely easy to notice after entry.

**Ecosystem position / relevance:** a mature agent-study portfolio needs two distinct controls—[[study-saturation-gate]] for capacity and a due-date selector for eligibility. Conflating them causes premature maintenance rather than learning; the next legitimate portfolio review begins on 08-12.

Links: [[study-workflow]], [[study-saturation]], [[flowforge-workflow-engine]], [[mechanism-vs-evolution]]
