---
title: "Universal Memory Protocol (UMP)"
created: 2026-06-08
updated: 2026-06-08
tags: [agent, memory, protocol, interop, standards]
status: noted
last_verified: 2026-06-08
---

# Universal Memory Protocol (UMP)

**Repo:** edihasaj/universal-memory-protocol · **Stars:** 22 (Jun 8) · **Created:** 2026-06-04 · **License:** Apache-2.0 · **Lang:** TypeScript

> "The third interop layer beside MCP (tools) and A2A (coordination)."

## What It Is

A portable **record format + operation set** for agent memory. Six operations: `capabilities`, `recall`, `remember`, `get`, `revise`, `forget` (+ `feedback`). One record type with typed fields. Three bindings: MCP, HTTP, file export.

UMP does NOT standardize how memory is indexed/retrieved/promoted — that's where engines compete. It standardizes the **wire format** and **operation semantics** so different agents and memory backends can interoperate.

## Architecture

```
Agent → UMP binding (MCP/HTTP/file) → UmpServer → MemoryStore (pluggable)
```

Key design decisions:
- **Bi-temporal time model**: every record has `valid_from`/`valid_to` (when fact is true) AND `created`/`observed` (when system learned it). Staleness is handled by supersession, not deletion. (Borrowed from Zep/Graphiti.)
- **DID-based identity**: owner is always a `did:key`, making memory portable across vendors
- **Content-addressed IDs** at L3 (signing level): `urn:ump:<blake3-hash>`
- **Dedup on write**: `remember` same text → `merged` (boosts confidence), not duplicate
- **Conformance levels**: L0 (read-only) → L1 (read/write) → L2 (+provenance) → L3 (+signatures)
- **No retrieval standardization**: store.search() is pluggable. Embedding, keyword, graph — engine's choice.

## Record Model (5 kinds)

| Kind | Meaning | Our equivalent |
|------|---------|----------------|
| `semantic` | Durable facts/preferences | wiki/cards/ |
| `episodic` | Specific past events | memory/YYYY-MM-DD.md |
| `procedural` | How-to / behavioral rules | AGENTS.md rules, skills |
| `working` | Short-lived task context | TODO.md active items |
| `identity` | Who the user/agent is | SOUL.md, IDENTITY.md |

## Relation to Our Stack

**We already implement UMP's concepts, just in Markdown files:**
- Our wiki/cards = semantic memories
- Our memory/ = episodic memories  
- Our AGENTS.md rules = procedural memories
- Our beliefs-candidates.md = `candidate` status lifecycle
- Our SOUL.md = identity memories

The difference: we use file-level granularity (one doc = many memories), UMP uses record-level (one JSON = one fact). UMP's approach enables finer-grained operations (revise one fact, track confidence per fact) but at the cost of requiring infrastructure (server, store, retrieval engine).

**Key insight**: UMP validates our direction but at a different scale. For a single-agent system like ours, Markdown files with git history provide the same bi-temporal semantics (git log = transaction time, content = valid time). UMP becomes necessary when **multiple agents need to share/exchange memories across vendor boundaries**.

## Relevance to [[agent-brain-portability]]

UMP is a **new row** in the portability spectrum:

| Level | Example | Implementation |
|-------|---------|----------------|
| Same tool, different surfaces | Dirac VSCode↔CLI | File migration |
| Cross-harness, file bundles | [[agentic-stack]] transfer | Export/import with merge |
| Cross-harness, structured storage | gbrain/reflexio | Service layer |
| **Cross-vendor, standardized protocol** | **UMP** | **MCP binding + record format** |

## Interesting Technical Details

1. **Supersession chain**: `revise` doesn't mutate — creates successor linked via `supersedes`/`superseded_by`. Append-only history. Same pattern as [[agentic-stack]]'s lesson retraction.
2. **Consent block**: records can declare retention duration, export permissions, and field-level redaction. Privacy-by-design at the record level.
3. **Feedback loop**: `feedback(id, "followed"|"overridden"|"ignored"|"contradicted")` — agents report whether they actually used a memory. This closes the learning loop.
4. **Recall adapter**: already ships an adapter for Recall (edihasaj's own memory engine), showing the protocol-over-engine pattern works.

## Critique / Limitations

- **Very early** (22⭐, 4 days old). Single author. No community adoption yet.
- **Only one adapter** (Recall, by the same author). Cross-vendor promise is aspirational.
- **No embedding/retrieval spec**: `store.search()` is a black box. Two UMP implementations may rank completely differently for the same query. This limits true interop.
- **The "standard without adoption" trap**: MIF, PAM, LangMem all proposed memory vocabularies before. UMP consolidates them but faces the same adoption chicken-and-egg.
- **Overhead for simple cases**: for a single agent with file-based memory, the DID/signing/bi-temporal machinery is overkill.

## Connection to [[memwatch-staleness|memwatch]] (companion project)

memwatch (18⭐, same week) solves the **staleness detection** problem that UMP's bi-temporal model makes _trackable_ but doesn't automatically _detect_. UMP gives you `valid_to`; memwatch tells you when to set it. Complementary.

## Verdict

**Worth watching, not worth adopting.** Our Markdown+git approach is simpler and sufficient for single-agent use. UMP becomes relevant if/when we need to:
1. Share memories between Kagura instances or with other agents
2. Export our knowledge in a vendor-neutral format
3. Build a trust/reputation layer where memory provenance matters

Re-check in 4 weeks (early July) for adoption signals.

Links: [[agent-brain-portability]], [[agentic-stack]], [[memwatch-staleness|memwatch]], [[piia-engram]], [[mechanism-vs-evolution]]
