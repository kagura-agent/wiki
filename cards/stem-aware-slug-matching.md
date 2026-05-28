---
title: Stem-Aware Slug Matching
status: active
depth: applied
created: 2026-05-28
last_verified: 2026-05-28
---

# Stem-Aware Slug Matching

Enhancement to wiki search.sh keyword ranking: use 4-character prefix stems when checking query words against file slugs.

## Problem

Exact substring matching misses morphological variants:
- "evolve" won't match slug "hermes-self-evolution" (evol**v**e ≠ evol**u**tion)
- "improve" won't match slug "self-improvement" (impr**o**ve ≈ impr**o**vement — this one works but longer stems break)

## Solution

For words ≥5 characters, extract first 4 chars as stem and check against slug:
- "evolve" → stem "evol" → matches "evolution" ✓
- "improve" → stem "impr" → matches "improvement" ✓
- "agents" → stem "agen" → matches "agent-*" slugs ✓

4 chars chosen as sweet spot: enough specificity to avoid false positives, short enough to catch common English morphology (verb→noun suffixes: -tion, -ment, -er, -ing).

## Impact

Benchmark precision: 80% → 100% (10/10 queries, 17/17 items).
Specific fix: `hermes-self-evolution` went from rank 6 to rank 2 for "how do agents evolve and improve themselves".

## Related

- Validated via livecache benchmark suite
- [[temporal-decay-retrieval]] — sister ranking enhancement
- Part of ongoing search ranking improvement effort

## Tags
`#search` `#retrieval` `#stemming` `#ranking`
