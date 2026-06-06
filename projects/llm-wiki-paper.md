---
title: "LLM-Wiki Paper — Retrieval as Reasoning (Tencent)"
created: 2026-06-06
updated: 2026-06-06
status: noted
tags: [memory, retrieval, wiki, self-evolving, paper]
last_verified: 2026-06-06
---

# LLM-Wiki Paper — Retrieval as Reasoning

> Source: arXiv:2605.25480 (Tencent WeChat) | Code: WeAgentAI/LLM-Wiki (6⭐)
> **Not the same as** [[llm-wiki]] (nashsu/llm_wiki desktop app, 1179⭐). Same name, different project. Both implement Karpathy's wiki pattern but this one is a research paper with formal paradigm + benchmarks.

## What It Is

Academic paper formalizing the **"Retrieval-as-Reasoning"** paradigm. Instead of treating retrieval as one-shot lookup (embed → top-k → answer), the agent treats retrieval as a reasoning process: search → read → follow links → assess sufficiency → repeat or answer.

Three principles:
1. **Compilability** — raw docs → structured wiki pages with bidirectional links
2. **Composability** — retrieval = atomic ops (search, read, link-follow) composed by the agent
3. **Evolvability** — Error Book for persistent self-correction

## Architecture

**Two tools only:**
- `wiki_search(query, limit?)` — returns metadata (names, aliases, tags), NOT page content
- `wiki_read(paths)` — batch-reads pages, returns full content + inter-page wikilinks

**Three traversal strategies:**
- Direct access — known entity → read directly
- Bridge queries (A→B→answer) — follow links through intermediate entities
- Exploratory browsing — read directory indices → selective deep read

**Termination:** Evidence sufficiency assessment after each read. Stops when: all chains traced, tool budget (T_max=15) reached, or consecutive empty searches ≥ patience (3). Must call wiki_read ≥1 before answering.

## Error Book (The Novel Contribution)

Persistent self-correction mechanism for wiki quality. The most interesting part for us.

**How it works:**
1. **Lint detects issues** during ingestion — broken links, index inconsistencies, duplicates, missing sections, type-path mismatches, unseen-page-overwrites
2. **Issues recorded** as structured entries with: category, description, constraint, samples (with fix state)
3. **Constraints injected** into LLM prompts — `## Known Issues (must avoid)` section
4. **Two-layer repair:** code-level (deterministic: delete broken links) + LLM-level (periodic: create missing pages)
5. **Auto-close** after 2 consecutive clean passes (issue didn't recur)
6. **Hard-delete** closed entries after 30 days (prompt hygiene)
7. **Repair ledger** (JSONL) — append-only audit log of every fix attempt

**Issue categories (9 types):**
- broken_link, index_error, duplicate, digest_incomplete, type_path_mismatch, missing_source_article, unseen_page_overwrite, missing_summary, missing_sections

**Fix tracking per sample:**
```yaml
- name: "sources/digests/foo → [[missing_entity]]"
  fixed: false
  context:
    batch_articles: [article1, article2]
    recorded_at: "2026-06-06"
```

## Results

SOTA on multi-hop QA benchmarks:
- HotpotQA, MuSiQue, 2WikiMultiHopQA — beats HippoRAG 2, LightRAG, GraphRAG by **2.0–8.1 F1 points**
- AuthTrace — best overall accuracy, especially on multi-document structured queries
- **Gains scale with hop count** — the more reasoning hops needed, the bigger the advantage

## Relevance to Us

### We Already Do Retrieval-as-Reasoning
Our memex architecture is essentially the same pattern:
- `memex search` ≈ `wiki_search` (semantic + keyword hybrid)
- `read wiki/projects/foo.md` ≈ `wiki_read`
- `memex backlinks <slug>` ≈ link-following
- Our workflow: search → read → follow backlinks → connect → apply

The paper **validates our architectural choice** with empirical evidence. We chose wiki-structured markdown with wikilinks over vector-only RAG, and this paper proves it outperforms GraphRAG/LightRAG/HippoRAG2.

### Error Book ≈ beliefs-candidates.md (but more structured)
Both are persistent self-correction mechanisms:
| Aspect | Error Book | Our beliefs-candidates |
|--------|------------|----------------------|
| Scope | Wiki structure quality | Agent behavior |
| Entry format | Category + constraint + samples + fix state | Free-form bullet with triggers/validation |
| Prompt injection | Automatic `## Known Issues` | Manual check during DNA review |
| Auto-close | After 2 clean passes | Manual graduation via Triple Verification |
| Audit log | JSONL repair ledger | None |

### What We Can Borrow

1. **Per-sample fix tracking for wiki lint** — Our `wiki-lint.py` finds broken wikilinks but doesn't track fix state across runs. Error Book pattern: detect → record → fix → verify → close. Immediate improvement.

2. **Constraint injection into prompts** — When we ingest new knowledge into memex, we could inject known-issues constraints ("don't create orphan pages", "always add backlinks") to reduce repeat errors. Currently our ingest is ad-hoc.

3. **Auto-close logic (2 clean passes)** — For beliefs-candidates.md, we could auto-retire entries that haven't triggered in N consecutive reviews. Prevents belief bloat.

4. **Repair ledger (JSONL audit)** — Append-only log of every correction attempt. We track corrections in daily memory notes but not in a structured, queryable format.

### Key Differences
- Paper is academic benchmark code (Python, no production use). Our system is live.
- They compile static document corpora. We grow a wiki incrementally through daily agent activity.
- Their Error Book is fully automated. Our self-correction is semi-manual (beliefs-candidates → DNA review).
- We operate at **identity layer** (SOUL.md, beliefs); they operate at **knowledge layer** (wiki structure). Different concerns.

## Key Insights

- **"The bottleneck is knowledge organization, not retrieval algorithm"** — This is the paper's core thesis and matches our experience. Better embeddings don't fix bad knowledge structure.
- **Wiki structure >> flat chunks for multi-hop** — Explicit bidirectional links enable compositional traversal that vector similarity can't replicate.
- **Error Book is the "immune system" for compiled knowledge** — Without persistent self-correction, LLM-compiled knowledge bases silently degrade. Our wiki needs one.
- **Two tools are enough** — search + read, composed by the agent through its reasoning loop. No need for complex retrieval APIs. Our memex already provides this.
- **Karpathy's pattern has been operationalized** — This paper is the first rigorous empirical validation of the "compile docs into wiki" approach he proposed.
