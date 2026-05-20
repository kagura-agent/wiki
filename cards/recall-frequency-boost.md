---
title: Recall-Frequency Boost
type: card
created: 2026-05-20
status: active
last_verified: 2026-05-20
depth: applied
---

# Recall-Frequency Boost

Using search analytics (which notes get returned) as a ranking signal, analogous to click-through rate (CTR) boosting in web search.

## Principle

Notes that are frequently recalled in past searches are more likely to be useful for new queries. A small popularity boost reinforces genuinely useful notes.

## Risk: Rich-Get-Richer

High-ranked notes get recalled → boost increases → rank even higher. Mitigations:
1. **Log-scaled** — `log2(1 + count) * weight` — diminishing returns
2. **Hard cap** — max +1.5 points (vs term-match ~10-30+, slug-match ~20+)
3. **Index exclusion** — generic index files excluded (recalled due to breadth, not topical relevance)
4. **Small weight** — recall boost is a tiebreaker, not a primary signal

## Our Implementation

In `wiki/search.sh` (applied 2026-05-20):
- Source data: `.recall-log` (timestamp|intent|query|slugs per line)
- Aggregation: count slug occurrences across all logged queries
- Formula: `log2(1 + recall_count) * 0.75`, capped at 1.5
- Temp file approach (subshell-safe): counts written to `$RECALL_FREQ_FILE`
- Benchmark: 100%/100% maintained

## Calibration History

- First attempt: weight=1.5, cap=3.0 → regressed benchmark from 100% to 90% (popular but generic notes outranked specific ones)
- Final: weight=0.75, cap=1.5 → 100% benchmark, gentle tiebreaking

## Origin

[[Orb]] v0.6.0 telemetry-backed skill lifecycle — tracks which skills are actually used to inform staleness decisions. We adapted the concept from staleness detection to ranking.

## Links

- [[temporal-decay-retrieval]] — complementary signal (recency vs popularity)
- [[auto-retire-pattern]] — uses recall frequency for staleness, not ranking
- [[intent-aware-retrieval]] — another ranking modifier based on query analysis
