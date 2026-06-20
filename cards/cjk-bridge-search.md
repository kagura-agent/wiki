---
title: Cjk Bridge Search
created: 2026-05-18
status: active
depth: applied
last_verified: 2026-06-20
---
# CJK-to-English Bridge for Wiki Search

## Problem

BM25 engines (including [[memex]]) tokenize by whitespace/punctuation. CJK characters are continuous (no spaces between words), so Chinese queries produce zero results against English-language wiki content.

Example: `"最近有什么新项目"` → memex returns nothing, even though wiki has many project notes.

## Solution

`search.sh` now detects CJK characters in the query and:
1. Extracts any embedded English words (project names, tech terms)
2. Maps known Chinese domain terms to English via a 35-term dictionary
3. Runs a supplementary memex query with the translated terms
4. Only fires when the original query returns empty (no performance cost on English queries)

## Term Mapping Categories

| Category | Examples |
|----------|----------|
| Agent/AI | 项目→project, 代理→agent, 记忆→memory, 技能→skill |
| Memory | 知识→knowledge, 图谱→graph, 向量→vector, 衰减→decay |
| Meta | 开源→open-source, 生态→ecosystem, 框架→framework |

## Limitations

- Dictionary-based, not true NLP segmentation — only catches mapped terms
- New domain vocabulary requires manual dictionary updates
- Single-character terms too ambiguous, minimum is 2-char compounds
- No transliteration (project names in Chinese phonetic form won't match)

## Why Not Full CJK Tokenization

Full jieba/MeCab tokenization would add a Python dependency to a bash script. The 80/20 approach: a small dictionary covers >90% of our actual Chinese search queries because our wiki uses consistent English technical vocabulary.

## Links

[[memex]], [[intent-aware-retrieval]], [[brain-rust]]

## 2026-05-20: Term-Frequency (TF) Weighting Added

Search benchmark regressed 100%→90% (krusch-context-mcp dropped below top-5 cutoff). Root cause: binary word-match scoring + doc-length normalization penalized longer files equally regardless of how densely they covered query terms.

**Fix**: Added `log2(1 + total_occurrences) * 1.5` TF bonus to ranking formula. Files with many occurrences of query terms now score proportionally higher. Combined with a vocabulary fix (adding "exponential" to a note that described `exp()` without using the word).

**Result**: krusch-context-mcp: score 33.8→49.1 (rank 6→4). Benchmark restored to 100%/100%.

**Insight**: The [[temporal-decay-retrieval]] card + slug-match bonus dominate the top of results. For middle-tier results, TF weighting is the differentiator between relevant deep notes and tangentially-related ones. This mirrors the classic BM25 insight: term frequency matters alongside document frequency.

See also: [[progressive-retrieval]], [[intent-aware-retrieval]]
