# Graphenium — Provenance-Aware Structural Memory for AI Coding Agents

**Repo**: [lambda-alpha-labs/Graphenium](https://github.com/lambda-alpha-labs/Graphenium)
**Stars**: 12 (2026-06-27, 3d old)
**Lang**: Rust | **License**: MIT
**Status**: AST + Resolver + Semantic Pass + Symbol Diff + `gm check` quality gates stable. Telemetry Overlay experimental.

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

## Limitations

- 12⭐, 3 days old — extremely early. Solo team (lambda-alpha-labs)
- Only Rust + Go extractors currently (+ generic tree-sitter)
- 13 open issues already — scope ambitious for codebase size
- Semantic pass requires LLM API key (optional but limits "inference" confidence level without it)

## Verdict

Architecturally novel. The trust model (confidence + provenance + staleness) is the standout idea — it's the difference between "here's a code graph" and "here's a code graph AND here's how much you should trust each part of it." Worth a followup in 7-14 days to see if it gets traction.

---
*Deep read: 2026-06-27*
