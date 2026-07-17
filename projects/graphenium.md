# Graphenium — Architecture Gate & Linter for AI Coding Agents

**Repo**: [lambda-alpha-labs/Graphenium](https://github.com/lambda-alpha-labs/Graphenium)
**Stars**: 21 (2026-07-17, +75% from 12)
**Lang**: Rust | **License**: MIT
**Status**: v0.19.3 stable. MCP tool support (Gemini/Vertex compat). Datalog rules engine. Active solo dev.

## ⚠️ PIVOT (discovered 2026-07-17)

Project **completely repositioned** between 06-27 and 07-17:
- **Before**: "Provenance-aware structural memory for AI coding agents" (trust model, staleness detection, surprise scoring)
- **After**: "Local pre-flight linter and architecture gate for AI agents. Uses tree-sitter, Stack Graphs, and Datalog to mechanically block structural drift, layering bypasses, and scope creep on virtual ASTs before code changes land."

The trust/provenance/surprise concepts from the original deep-read may still be in the codebase but the **public framing** shifted entirely to enforcement/gating. Now competes more with linters and CI gates than with memory systems.

Recent commits (07-12~13): Datalog EDB fact cap fix (v0.19.3), MCP tool schema sanitization for Gemini/Vertex, rustfmt cleanup. Active iteration.

**Reclassified**: from Agent Memory → Coding Agents & Context Efficiency in targets.md.

## What It Is

MCP-native repo knowledge graph that gives AI coding agents persistent structural memory with **trust and provenance on every relationship**. Instead of agents re-navigating repos from scratch each session via grep-and-trace, they query a durable graph.

## Key Architectural Ideas

### 1. Three-Level Confidence Model

Every edge carries explicit confidence:

| Level | Score | Meaning | Agent treatment |
|-------|-------|---------|-----------------|
| EXTRACTED | 1.0 | Explicit in source (import, call, AST-parsed) | Source-backed fact |
| INFERRED | 0.5 | LLM/heuristic reasoning with documentation | High-probability hint |
| AMBIGUOUS | 0.2 | Uncertain or conflicting evidence | Lead to investigate |

**Key insight**: Most tools give you "A connects to B" without saying how confident they are. Graphenium makes agents explicitly aware of trust boundaries.

### 2. Evidence Spans with Staleness Detection

Each fact is backed by `EvidenceSpan`:
- Exact byte range + line numbers in source
- SHA256 of span text AND full file at extraction time
- `validate()` checks if file changed since extraction → marks stale

This means after code changes, the graph knows which facts might be outdated.

### 3. Surprise Scoring (Counter-Intuitive)

`surprise.rs` scores edges inversely to expected-ness:
```
score = conf_bonus(AMBIGUOUS=3, INFERRED=2, EXTRACTED=1)
      + cross_file_type(2) + cross_repo(2) + cross_community(1)
      × semantic_similar_boost(1.5)
      + peripheral_to_hub(1)
```

**AMBIGUOUS edges score HIGHEST** because unexpected/uncertain connections are more worth investigating than obvious explicit ones. This inverts the usual "show me the most certain stuff first" approach.

### 4. MCP Server (ArcSwap Hot-Reload)

Tools exposed:
- `query_graph`, `get_node`, `get_neighbors`, `shortest_path`
- `architecture_summary` — compact overview for cold-start sessions
- `god_nodes` — find high-coupling "god objects"
- `add_node`, `add_edge`, `remove_edge` — agent can write back to graph
- `reload_graph` — hot-reload via ArcSwap (lock-free atomic swap)
- `resolution_report`, `ambiguous_symbols`, `unresolved_references` — trust diagnostics

### 5. CI Quality Gates (`gm check`)

Enforces minimum graph trust thresholds:
- `--min-resolution 80` — require 80%+ resolved symbols
- `--max-ambiguous 10` — cap ambiguous edges

Repository trust doesn't silently degrade over time.

### 6. Louvain Community Detection

Groups code into communities (modules/domains). Used for:
- Focused navigation (show me this community's architecture)
- Cross-community edge detection (surprising connections)
- Drift detection between communities

## Architecture

```
src/
├── extract/     # Tree-sitter AST parsing (Rust, Go, generic)
├── resolver.rs  # Import/call resolution
├── semantic/    # LLM-assisted inference (optional, needs API key)
├── model/       # Graph, Node, Edge, Confidence, EvidenceSpan
├── trust.rs     # Evidence validation, staleness detection
├── cluster/     # Louvain community detection + drift
├── analyze/     # Surprise, impact, diff, god-node detection
├── serve/       # MCP server (rmcp crate)
├── cache/       # Semantic cache for LLM calls
├── detect/      # Sensitive file detection, paper detection
└── export/      # JSON, HTML visualization
```

**Dependencies**: petgraph (graph), tree-sitter (AST), rmcp (MCP), arc-swap (hot-reload), sha2 (hashing)

## Relevance to Us

1. **Confidence on knowledge links**: Our wiki/memory system links notes but doesn't track how sure we are. Could add EXTRACTED/INFERRED levels. See [[agent-brain-portability]], [[git-backed-agent-memory]].
2. **Staleness detection via hash**: Our followup tracking is manual. Hash-based "is this still current?" would be more reliable.
3. **Surprise scoring inversion**: "What's most uncertain is most worth investigating" — applicable to study scout (prioritize unexpected signals over confirmed patterns). Relates to [[mechanism-vs-evolution]] — mechanism predicts; surprise reveals.
4. **MCP-first for agent consumption**: Good validation that graph-as-MCP-server is the right interface pattern. Compare [[codex-control-plane-mcp]], [[beads]].
5. **CI trust gates**: Automated quality enforcement of structural knowledge. Related concept to [[foreman-orchestrator]] test-ratchet pattern.

## Applied Patterns

### Surprise Inversion → scout-precheck.sh (2026-06-27)

Applied the "AMBIGUOUS scores highest" principle to study scout workflow:
- Created `portfolio-themes.txt` (19 domain categories from 485 wiki notes)
- Enhanced `scout-precheck.sh` with `--desc` mode and novelty scoring
- New candidates scored NOVEL/MODERATE/EXPECTED based on portfolio theme overlap
- NOVEL candidates get explicit deep-read priority recommendation
- Behavioral change: instead of treating all NEW candidates equally, the tool now surfaces which ones are outside known territory (highest information value)

Verification: tested with 3 scenarios — pure novel (quantum computing), moderate (memory+retrieval), expected (7-keyword hit on agent-memory theme). Correct tiering in all cases.

## Limitations

- 21⭐ — still small. Solo dev (lambda-alpha-labs, 195 commits, 0 external contributors)
- Only Rust + Go extractors currently (+ generic tree-sitter)
- 0 PRs from community — bus factor 1
- Rapid pivots in positioning suggest still finding product-market fit

## Verdict

The enforcement/gating angle ("mechanically block structural drift") is more actionable than passive memory. If agents routinely violate architecture constraints, a pre-flight check that catches violations before code lands is valuable. Compare [[foreman-orchestrator]] test-ratchet. The Datalog rules engine is the interesting new piece — declarative architecture rules that agents can't circumvent.

Still tiny and solo-dev. Track for architectural evolution, not community growth.

---
*Deep read: 2026-06-27*
*Followup: 2026-07-17 — pivot discovered, reclassified*
