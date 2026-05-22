---
title: "Dreaming (OpenClaw Memory Consolidation)"
created: 2026-04-16
tags: [memory, openclaw, consolidation]
last_verified: 2026-05-22
---

# Dreaming

OpenClaw's offline memory consolidation system. Runs during low-activity periods (cron 3:30 AM) to strengthen important memories and surface patterns.

## Phases
- **Light Sleep**: Short-term recall scoring — which memories were accessed recently?
- **REM**: Deep consolidation — cross-reference, find themes, promote to long-term

## Reference: GBrain runCycle (v0.17.0)
[[gbrain]] unified all maintenance into `runCycle()` — one primitive, 6 phases in fixed order (lint → backlinks → sync → extract → embed → orphans). Three callers converge. Key insight: **fix files first, then index** — phase order matters. Lock coordination via DB rows with TTL (not session-scoped advisory locks, which break under connection pooling). This is the target architecture for our dreaming.

## Our Setup
- Enabled 04-13, first successful run 04-15
- Config: `openclaw.json → plugins.entries.memory-core.config.dreaming`
- Light: 3-day lookback; REM: 7-day lookback
- Storage: both inline + separate reports

## Status (04-16)
- 197 memory chunks tracked, 194 light hits, 3 REM hits
- 113 events accumulated
- Workaround for quiet-hours skip: triggered via daily-review cron ✅

## Issue #6 Fix: Deep Sleep Threshold Recalibration (2026-05-22)

**Problem**: Deep sleep had **never promoted anything** in 38 days of operation. The `minScore: 0.85` threshold was unreachable — across 35,685 entries, the highest maxScore among frequently-recalled entries was 0.672. The original threshold was set without empirical data.

**Data-driven fix**: Analyzed actual score distributions:
- 14 entries with recall≥5, highest maxScore=0.672
- 6 entries at score≥0.60 + recall≥4 + queries≥2 (0.017% of total — still highly selective)
- All 6 are genuine high-value memories (dreaming mechanism notes, study methodology insights, project tracking patterns)

**New thresholds**: `minScore: 0.60` (was 0.85), `minRecallCount: 4` (was 5), `minUniqueQueries: 2` (was 3), `limit: 5` (was 3)

**Verification plan**: Check `memory/.dreams/` reports after next 3:30 AM run. Success = at least 1 promotion. If too noisy, tighten back to 0.65.

## External Adoption (2026-04-27)
[[hermes-memory-skills]] (nexus9888) explicitly models its memory consolidation on OpenClaw's dreaming metaphor. Adds a formalized **4-dimension scoring rubric** (Novelty, Durability, Specificity, Reduction) that's more rigorous than our "repeated 3+ times" heuristic. Also introduces capacity-aware thresholds (60%/80%) and post-write integrity checks. Worth evaluating whether we should adopt the rubric.

Related: [[dreaming-vs-beliefs-candidates]], [[openclaw-architecture]], [[hermes-memory-skills]]
