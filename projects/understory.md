---
title: "understory — Self-Wiring Markdown Memory for AI Agents"
type: deep-read
status: new
created: 2026-07-14
source: https://github.com/thecodacus/understory
stars: 101
language: TypeScript
license: (not specified in README)
tags: [agent-memory, okf, mcp, knowledge-graph, markdown, local-models]
last_verified: 2026-07-14
---

# understory — Self-Wiring Markdown Memory for AI Agents

**What:** MCP-based knowledge base for AI agents using plain markdown files with YAML frontmatter, conforming to Google Cloud's [Open Knowledge Format (OKF) v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md). Self-wiring graph, lint-based health, query-path replay, local model support.

**Author:** thecodacus (YouTube creator). 101⭐, created 2026-07-09, active (pushed 07-12). 12 forks, 3 issues.

## Architecture

pnpm monorepo: `core` (OKF bundle + agent) → `server` (Express: MCP + REST + web) → `web` (React force-directed graph UI).

### Key Design Decisions

1. **Conformance-in-code, not prompts.** Deterministic validation enforces OKF spec (type required in frontmatter, reserved filenames rejected, paths sandboxed to bundle root). LLM decides *what*, code guarantees *correctness*. ← Strong pattern; prompt-compliance is fragile.

2. **Enrich-over-create.** System prompt rule: "A fact that is an attribute of an existing concept gets patched INTO it — not filed as its own concept." Fights the universal "pile of notes" anti-pattern in memory systems.

3. **Keyword search, not semantic.** Naive file scan, scored: title match (10) > path (6) > description/tag (5) > body (2). Compensated by retrieval protocol in system prompt: retry synonyms → browse layout → read plausible concepts. Pragmatic — no embedding model dependency, works with local models.

4. **Graph-as-memory.** Inter-concept links form a knowledge graph. `scanGraph()` builds nodes+edges from markdown link regex `[text](/path.md)`. `lintBundle()` detects orphans (0 inbound links) and broken links. `memory_maintain` tool drives an LLM agent to wire orphans and fix dangling links. Mirrors Karpathy's LLM Wiki pattern.

5. **Query-path replay (Traces).** Every agent run records its tool traversal as `TraceStep[]`: search→read→write with concept paths. Persisted as JSON under `.traces/`. Web UI replays paths as numbered directed hops over the force-directed graph — visited concepts ringed, search hits dotted. Novel observability feature.

6. **Seed memory injection.** At session start, MCP `instructions` field + `memory_query` tool description get a dynamic overview of bundle contents (directories, concept types/descriptions, recent activity). Regenerates fresh per session. Solves cold-start problem.

### Stack
- Providers: Anthropic (default), OpenRouter, llama.cpp (auto-discovered model), any OpenAI-compatible endpoint
- MCP: streamable HTTP at `/mcp` + stdio binary
- Web UI: force-directed graph (d3?), concept viewer, update log, chat interface
- Tools: `memory_query`, `memory_add`, `memory_update`, `memory_status`, `memory_maintain` (each drives internal LLM agent)
- GIT_AUTOCOMMIT: optional auto-commit on every mutation

## Relationship to Agent Ecosystem

- Sits in the [[agent-memory-landscape-202603]] as a structured-markdown approach
- Shares design lineage with [[llm-wiki-karpathy]] (index.md + log.md + lint pattern)
- Complementary with [[dreamer]] (Dreamer does periodic "dream" consolidation, understory does on-write graph wiring)
- More structured than [[engram]] (which is an MCP memory plugin without graph enforcement)
- Less complex than [[gbrain]] (which builds a self-wiring graph with typed entity extraction)
- OKF spec positioning is similar to how [[agentskills-io-standard]] tries to standardize agent skills — a specification play for interoperability

## Comparison to Our Wiki/Memex

| Aspect | understory | Our wiki + memex |
|--------|-----------|-----------------|
| Format | OKF v0.1 (YAML frontmatter + markdown) | Wikilinks + markdown (custom frontmatter) |
| Search | Keyword-only (naive scan) | Hybrid semantic + keyword (memex) |
| Scale | "Fine into low thousands" | 950+ cards, battle-tested |
| Graph | Built-in graph scan + lint + visualization | wiki-lint exists, no visualization |
| Observability | Query-path replay traces | No trace replay |
| Seed/bootstrap | Dynamic MCP instructions per session | Static AGENTS.md/SOUL.md reads |
| Maintenance | `memory_maintain` tool (agent-driven) | Manual + wiki-lint |
| Auth | None | N/A (local) |

## What We Can Learn

1. **Trace replay** — recording and replaying the agent's knowledge retrieval path is valuable for debugging memory misses. We don't have this. Worth considering for memex.

2. **Graph health as a first-class concern** — orphan detection + automated repair is cleaner than our current wiki-lint approach. The "feed lint results to an agent" pattern could improve our maintenance.

3. **Dynamic seed injection** — regenerating a bundle overview per session is more maintainable than our static startup reads. As wiki grows, static reads become stale.

4. **Conformance-in-code** — our wiki doesn't enforce frontmatter schema. OKF's approach of code-level validation prevents garbage accumulation.

## Issues Reveal

- **Timeout issues** (#3): MCP tool calls timeout at 180s with slow local inference. Needs configurable timeout.
- **Multi-context request** (#2): Users want isolated memory bundles per project. Not implemented.
- **No auth** (#1): MCP endpoint exposed without authentication.

## Verdict

Well-designed, opinionated memory system. OKF spec gives portability, deterministic validation gives reliability, trace replay gives observability. Main limitations (keyword-only search, single-agent, no auth) are reasonable for current scale.

For us: complementary implementation, not replacement. Trace replay and graph health patterns are the highest-value takeaways. Our semantic search and battle-tested scale (950+ cards) are advantages understory doesn't match.

## Patterns Worth Extracting

- **[[conformance-in-code]]** (potential memex card): The principle that format compliance should be enforced by code validation, not prompt instructions. Applicable beyond memory systems — any agent output that must conform to a schema.
- **Query-path tracing**: Recording retrieval paths as structured data for replay/debugging. Our [[memex]] doesn't have this.
- **Dynamic seed**: Auto-generating context overview per session rather than relying on static startup files.

**Track?** Yes — memory systems are portfolio core. Revisit 07-28 (2-week warm cycle, solo dev project).
