---
title: Co-Activation Boost
type: card
created: 2026-06-11
status: active
last_verified: 2026-06-11
depth: applied
---

# Co-Activation Boost

Documents frequently surfaced together in past searches get a ranking boost in future searches. Exploits the signal that co-retrieval implies topical relatedness.

## Principle

If doc A and doc B consistently appear together across many different queries, they share a latent topical relationship. When one is a candidate in a new search, the other should get a small boost — even if the direct term-match is weaker.

## Risk: Echo Chamber

Co-activated docs reinforce each other → they always appear together → never get displaced. Mitigations:
1. **Log-scaled** — `log2(1 + sum_cooccurrence) * 0.5` — diminishing returns
2. **Hard cap** — max +2.0 points (vs term-match ~10-200, slug-match ~20+)
3. **Minimum threshold** — only pairs with ≥3 co-occurrences count (noise filter)
4. **Top-10 per slug** — adjacency list capped at strongest 10 partners
5. **Candidate-gated** — only boosts when partner is *also* a candidate in current query (not unconditional)

## Our Implementation

In `wiki/search.sh` (applied 2026-06-11):

### Index Build (`wiki/scripts/build-coactivation-index.py`)
- Source: `.recall-log` (778+ search sessions)
- Extracts doc pairs from each search result, counts co-occurrences
- Normalizes slugs (strips `projects/`, `cards/` prefixes, deduplicates)
- Output: `.coactivation-index` — `slug<TAB>partner1:count,partner2:count,...`
- Stats: 202 slugs, 1236 pairs (count ≥ 3)
- Rebuilt periodically via review.yaml memory_hygiene

### Search Integration
- Two-pass approach:
  1. Collect all candidate slugs from grep matches into temp file
  2. For each candidate, look up co-activation partners; if any partner is also a candidate, sum their counts
- Boost formula: `log2(1 + sum) * 0.5`, capped at 2.0
- Benchmark: 100%/100% maintained (10 queries, 17 items)

## Calibration

- Initial cap 2.0 appropriate: with base scores in 10-200 range, co-activation contributes ~1-10% — a gentle tiebreaker
- Distribution: ~134 candidates get 0.00 (no co-activation), ~8 get 2.00 (max), ~1 get intermediate values per query

## Origin

[[ClawMem]] co-activation pattern: `score = (search×0.50 + recency×0.25 + confidence×0.25) × quality × co-activation` — up to 15% boost for frequently co-surfaced docs.

## Links

- [[recall-frequency-boost]] — complementary signal (individual popularity vs pair co-occurrence)
- [[temporal-decay-retrieval]] — another ranking modifier (recency)
- [[intent-aware-retrieval]] — query-intent-based ranking adjustment
- [[search-engineering]] — umbrella for all search improvements
