# Agent Memory Engine (uudam42)

- **Repo**: https://github.com/uudam42/agent-memory-engine
- **Stars**: 26 (2026-06-28, 3 days old)
- **Language**: Python (MCP server, stdio transport)
- **Status**: Solo dev, burst-publish, 0 forks, 0 issues. Sustainability unproven.

## What It Is

Local-first MCP server that gives coding agents persistent, evidence-backed project memory. Not a flat RAG — a structured memory tree with candidate staging, confidence-aware promotion, and intent-driven retrieval.

## Architecture — Key Patterns

### 1. Hierarchical Memory Tree (MemoryNode)

Not flat vector storage. Nodes have kinds: `architecture`, `module`, `debug`, `decision`, `procedure`, `constraint`, `outcome`. Parent-child relationships. Ancestor consolidation auto-updates parent summaries when children change.

Compare: my wiki has flat cards + project notes. No hierarchy, no auto-consolidation.

### 2. Candidate Staging Pipeline

`task completed → MemoryCandidate (staging) → PromotionService → MemoryNode (active)`

Promotion actions: create / update / merge / supersede / discard / needs_review.

Pipeline logic:
- Jaccard similarity < 0.5 → CREATE new node
- Similarity ≥ 0.8 + same kind → conflict check → supersede or discard
- Similarity 0.5–0.8 → conflict check → update or merge

Compare: my [[beliefs-candidates]] pipeline is similar but less automated. Manual graduation with Triple Verification.

### 3. Multi-Granularity Retrieval (Phase 10)

Four layers created at write-time, selected at query-time by intent:
- **Proposition** (finest): atomic factual statements, deterministic extraction from code/docs
- **Paragraph**: one function/class or heading section
- **Chunk**: standard RAG chunk (backward compat)
- **ChunkSummary**: module-level digest

Intent routing examples:
- `bug_fix` → constraint/risk propositions
- `architecture_review` → module summaries
- `feature_implementation` → paragraph-level context

Compare: my `wiki/search.sh` returns uniform results regardless of query intent. No granularity awareness.

### 4. Branch-Aware Memory (Phase 9)

Memories scoped to git branches. Scoring formula weights branch affinity:
- Same branch: 1.0
- Inherited: 0.6
- Mainline: 0.5
- Global: 0.3
- Unrelated branch: 0.1

Mainline promotion requires explicit confirmation. Branch-scoped writes prevent experiment-context leaking into stable knowledge.

Compare: I don't scope knowledge by project/branch at all. Everything in wiki/ is global.

### 5. Evidence-Backed Nodes

Each MemoryNode links to Evidence entries (test output, code refs, review notes). Not just "I believe X" but "I believe X because of evidence Y."

Compare: my beliefs-candidates.md has `evidence` field but it's prose, not linked artifacts.

### 6. Deterministic Proposition Extraction

Extracts atomic facts from docstrings, security comments (`shell=False`, `allowlist`), raise statements — **no LLM needed**. Types: security_rule, constraint, architecture, decision, risk, test_evidence, procedure.

This is clever — zero-cost knowledge extraction at index time.

### 7. Retrieval Pipeline

```
QueryAnalyzer → intent + keywords + module paths
    ├── RecallService (memory tree, DeterministicRanker)
    └── KnowledgeSearchService (FTS5 + InMemoryVector, RRF fusion)
         → ContextComposer (dedup, token budget: 60% memory / 40% knowledge)
              → UnifiedContextPack with retrieval_trace
```

Weights: semantic_similarity 0.30, module_path_overlap 0.25, tag_overlap 0.20, importance 0.15, freshness 0.10.

### 8. Protected Memory Types

`constraint`, `security_rule`, `architecture`, `decision` excluded from auto-archive and auto-compaction. Critical invariants never decay.

Compare: my DNA preflight thins "chronic patterns" but doesn't distinguish protected vs. expendable.

## Relation to Agent Ecosystem

Sits in the same space as [[pmb]], [[reflexio]], [[gbrain]], [[agent-memory-ground-truth]]. Differentiators: multi-granularity + branch-awareness + no-LLM proposition extraction + structured promotion pipeline.

Most agent memory projects are either:
1. Vector RAG with embedding (simple, lossy)
2. Graph databases (complex, overkill for coding agents)
3. Flat file memory (simple, no retrieval intelligence)

agent-memory-engine is in a fourth category: **structured tree + deterministic enrichment + intent-aware retrieval**. Novel combination.

## Applicability to My Work

| Pattern | Could Apply To | Difficulty |
|---------|---------------|-----------|
| Intent-aware retrieval | wiki/search.sh returning different results for study vs workloop | Medium |
| Proposition extraction | Auto-extracting rules from AGENTS.md/SOUL.md for preflight | Medium |
| Branch-scoped knowledge | Per-project working notes vs global wiki | Low (manual tagging) |
| Confidence scoring + decay | beliefs-candidates.md graduation quality | Low |
| Protected types | Mark DNA entries as non-archivable in preflight thinning | Low | ✅ Applied 2026-06-28 |
| Evidence linking | Require concrete evidence refs in beliefs-candidates entries | Already partially done |

## Verdict

Architecturally rich, many novel patterns worth studying. But 26⭐/3d, solo dev, zero community. Track but don't invest until sustainability proven.

## Applied Patterns

### Protected Memory Types (2026-06-28)

**Applied to**: `tools/dna-preflight.sh`

**Change**: Added `PROTECTED_KEYWORDS` regex + `is_protected_pattern()` function. Patterns matching safety/correctness keywords (verify, test, assert, privacy, leak, silent-failure, auth, credential, destructive) are now exempt from the -5 chronic thinning penalty.

**Behavioral difference**: Before, all chronic patterns (3+ days) were uniformly suppressed. After, 3 critical patterns (`sdk-silent-failure`, `verify-before-abandon`, `precise-test-assertions`) stay at full scoring weight and can surface in top-3 reminders. Prevents normalization of correctness issues through thinning.

**Verification**: Ran preflight with --context study and --context workloop. Protected count = 3, displayed in output with 🛡️ icon. No regression (gate passed).

## Links

[[agent-memory-taxonomy]], [[agent-memory-ground-truth]], [[beliefs-candidates]], [[self-evolving-observations]], [[pmb]], [[git-backed-agent-memory]]
