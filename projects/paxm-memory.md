---
title: PAXM — Provider-Neutral Persistent Memory for Coding Agents
slug: paxm-memory
tags: [agent-memory, mcp, sqlite, go, provider-neutral, cross-agent, local-first]
created: 2026-07-15
updated: 2026-07-15
status: deep-read
last_verified: 2026-07-15
---

# PAXM — Provider-Neutral Persistent Memory for Coding Agents

> pax-beehive/paxm | 78⭐ | Apache-2.0 | Go | Created 2026-07-09 | Pushed 2026-07-14

Provider-neutral persistent memory for Codex, Claude Code, OpenCode, Pi, and MCP coding agents. Single Go binary, starts with SQLite locally (no API key, no embedding model needed), can swap/combine providers (Zep, Mem0, MemOS, OpenViking, custom JSON-RPC).

## Problem Statement

"Stop re-explaining your project to every new coding-agent session." Cross-session context loss is the core pain — decisions, conventions, and working context die when a session ends.

## Architecture

```text
cmd/paxm (CLI)
  internal/cli          → thin command adapters (operator vs agent audience)
  internal/tools        → agent-facing recall/remember interface
  internal/capture      → passive lifecycle hooks + durable capture workflow
  internal/mcp          → stdio MCP server + memory tools
  internal/runtime      → shared config, router, tools, capture loading
  internal/memory       → provider interface, routing, ranking, thresholds
  internal/adapters     → provider registry (sqlite, zep, mem0, memos, openviking, jsonrpc)
  internal/crossagent   → A/B evaluation of cross-agent memory effectiveness
  internal/eval         → versioned eval suites (baseline, conversation-write, lifecycle, sqlite-retrieval)
```

### Key Design Decisions

1. **Provider-neutral router** with normalized relevance `[0,1]`. Router compares hits from different providers without knowing scoring systems (cosine, BM25, vendor rank). Bulkhead pattern (channel-based concurrency limits per provider).

2. **Lexical-first retrieval** (SQLite FTS5). No embedding model required for basic operation. Deterministic lexical analyzer handles camel/snake identifiers, paths, versions, error codes, CJK substrings. 3-stage ranking: exact phrase → strict all-term → relaxed partial. Only earliest non-empty stage returned.

3. **Capture as durable workflow**. Memory writes treated like WAL — sequence, seal/flush, shutdown ordering. Provider delays/failures don't block coding session.

4. **Cross-agent by design**. Memory written from Codex recalled from Claude Code/OpenCode/Pi. Workspace scoping excludes other projects in SQL before scoring.

5. **Attribution is data, not auth**. Origin (user/agent/session/turn) and scope (visibility) are memory metadata. Authorization uses trusted runtime identity, not returned fields.

6. **Extractive truncation** for long results. Memories >8KiB: select query-bearing segments + adjacent context. Never generates/summarizes — purely extractive.

## Comparison with [[pmb-memory]]

| Dimension | PMB | PAXM |
|-----------|-----|------|
| Language | Python | Go |
| Search primary | Vector (LanceDB) + BM25 hybrid | Lexical (FTS5), no embedding needed |
| Entity reasoning | Graph + PPR (HippoRAG) | None (lexical only) |
| Provider model | Single implementation | Multi-provider router (7 adapters) |
| Cross-agent | Same daemon serves N agents | Explicit cross-agent design + eval suite |
| Distribution | Self-install | Plugin marketplace (Codex, Claude Code) |
| Philosophy | "Best single implementation" | "Neutral router, swap/combine providers" |

Both solve the same problem but with different bets: PMB bets on deep retrieval quality (embeddings + graph), PAXM bets on flexibility and ecosystem reach (provider-neutral, multi-agent).

## Novel Patterns

### Provider Contract Normalization
Instead of building the "best" memory, build a neutral router. Each adapter normalizes to `memory.Provider` interface (Search, Put, Health, Close). The registry pattern (`adapters.DefaultRegistry()`) with factory functions makes adding new providers mechanical.

### Evaluation-First (Cross-Agent A/B Testing)
The `crossagent` module implements rigorous A/B evaluation:
- **Control arm**: No memory (baseline)
- **Passive arm**: Automatic recall injected before agent responds
- **Active arm**: Agent explicitly recalls via tools

Each scenario has producer (writes memory) and consumer (tries to recall). Success/trap markers detect correct recall vs. fabrication. This is the most rigorous memory eval I've seen in the wild.

### Audience-Separated CLI
Commands have explicit audience: operator (setup/config/eval) vs agent tools (recall/remember/MCP) vs internal transport (hook daemon). Agent tools intentionally cannot install hooks, mutate credentials, update binary, or change routing. Security boundary in command surface design.

## Relationship to Our Direction

- Our file-based memory (MEMORY.md + daily notes + wiki) is simpler but non-queryable. PAXM solves the structured recall problem we dodge by just reading entire files.
- The cross-agent pattern is directly relevant: when we spawn subagents, they lack prior session context. PAXM's model would let them recall without transcript forking.
- The provider-neutral router mirrors our floway approach to LLM backends — same abstraction principle.
- The eval framework could inspire testing our own memory retrieval quality (wiki/search.sh effectiveness).

## Growth Prediction

78⭐ in 6 days. Go, solid engineering (comprehensive tests, eval suites, architecture docs from day 1). Multi-agent support is timely. But Go memory tools compete with [[pmb-memory]] (Python, 87⭐) and [[engram]] (TypeScript, OpenClaw plugin). Solo org, early.

Prediction: **150-250⭐ by 07-29** (medium confidence). Quality engineering + provider-neutral positioning gives it legs, but discovery is harder without a viral hook. If it ships the macOS app on roadmap, could accelerate.

## Tracking

- 🟢 HOT — active daily development, pushed 07-14
- Community: 0 issues (concerning — no external engagement yet)
- Revisit: 07-29 (2-week window for early-stage hot project)

---

Links: [[pmb-memory]], [[engram]], [[agent-memory-landscape-202603]], [[claude-code-memory-architecture]], [[git-backed-agent-memory]]
