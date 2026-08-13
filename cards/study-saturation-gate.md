---
title: Study Saturation Gate
created: 2026-06-16
tags: [tool, study, structural-gate, workflow-node]
last_verified: 2026-08-13
status: active
depth: scout
---
# Study Saturation Gate

A pre-workflow gate (`tools/study-saturation-gate.sh`) that blocks study workflow entry when saturation is already detected. Integrated as the `saturation_gate` node in `study.yaml`, positioned before the `align` node.

## Purpose

Prevent wasted workflow cycles by catching saturation at the earliest possible point — before the full study workflow even starts. Each false-positive study entry costs 5-10 tool calls; the gate blocks in ~10ms.

## Layers

1. **Layer 1 — Daily memory count**: If today's memory already contains ≥2 full-mode saturation records, exit immediately
2. **Layer 2 — Mode availability**: Check each mode's capacity (via `study-saturation.sh`) and whether any mode has actionable work. Added 2026-06-18 (from `saturation-gate-mode-availability` gradient)
3. **Layer 3 — Effective saturation** (2026-07-25): When apply is the only remaining open mode AND `unapplied.md` has no unchecked items, treat as saturated. Also checks followup-due items consistently
4. **Layer 4 — Soft saturation** (2026-08-13): Mirrors `study-saturation.sh` SOFT_SATURATED logic — deep scout done today (or within 2d) + quick scan done today + apply backlog empty + followup locked → SATURATED. Prevents the gate from letting the workflow run to re-discover soft saturation (~30min cycles). Requires `SCOUT_DAYS_AGO`/`SCOUT_RECENT` (today's deep scout = 0d) and `APPLY_BACKLOG_EMPTY` (set before the apply auto-lock flips state)

## Design Decisions

- **行首锚定 regex**: Avoids matching saturation text in quoted/referenced lines (only matches actual status records)
- **10ms bash check**: Near-zero overhead per cron cycle
- **Layered detection**: Each layer is independently testable; later layers catch edge cases earlier layers miss

## Relationship to study-saturation.sh

| Component | Role |
|-----------|------|
| `study-saturation.sh` | In-workflow tool: recommends mode switching during active sessions |
| `study-saturation-gate.sh` | Pre-workflow gate: blocks entry entirely when saturated |

The gate calls `study-saturation.sh` internally for mode availability checks but adds pre-entry blocking logic that the in-session tool doesn't provide.

## Evolution

- **2026-06-16**: Created (from `study-cron-saturation-noise` gradient). Layer 1 only
- **2026-06-18**: Layer 2 added (mode availability check)
- **2026-07-07**: Apply empty-backlog auto-lock fix (agents mislabeling `partial` outcomes)
- **2026-07-25**: Layer 3 "effective saturation" detection (deterministic fix from [[AgentSmith]] pattern)
- **2026-08-13**: Layer 4 soft-saturation detection (from `saturation-gate-soft-saturation-gap` gradient, study #8083). Closes the loop: `study-saturation.sh` gained SOFT_SATURATED in its recommendation layer, the gate now mirrors it for pre-entry blocking

## Links

- [[study-saturation]] — the in-session saturation detection tool
- [[structural-fix-over-behavioral-rule]] — design principle: tool gates > behavioral rules
- [[self-evolving-observations]] — tracked gate evolution across observation reports
- [[flowforge]] — workflow engine where the gate node executes
