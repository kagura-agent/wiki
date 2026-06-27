---
type: project
status: scout
first-seen: 2026-06-27
stars: 1370
language: Python
repo: mnemox-ai/tradememory-protocol
tags: [ai-trading, agent-memory, mcp, audit-trail, compliance]
revisit: 2026-07-04
---

# tradememory-protocol

Decision audit trail + persistent memory for AI trading agents.

## What It Is

MCP server providing a memory layer for AI trading agents. The core premise: trading AIs have amnesia — they can execute trades but can't remember past outcomes or explain decisions. TradeMemory fills this gap with outcome-weighted recall and tamper-proof audit trails.

## Architecture

### 5 Memory Layers
1. **Episodic** — individual trade events with full context
2. **Semantic** — generalized knowledge (e.g., "AAPL tends to gap up on earnings")
3. **Procedural** — strategy execution patterns
4. **Affective** — emotional/confidence state tracking
5. **Trade records** — raw execution data

### Outcome-Weighted Memory (OWM) Framework
Recall scoring formula considers:
- **Outcome quality** — trades that worked well rank higher in recall
- **Context similarity** — similar market conditions surface relevant memories
- **Recency** — recent memories weighted more
- **Confidence** — higher-confidence decisions more memorable
- **Emotional state** — affects recall (behavioral finance angle)

This is the key architectural insight: **not all memories are equal in trading**. A profitable trade in similar conditions is 10x more useful to recall than a random past trade.

### Audit Chain
- Per-record SHA-256 content hashes
- Forward-chained ledger (tampering invalidates all subsequent records)
- Daily Merkle roots
- Designed for MiFID II Article 17 and EU AI Act Articles 12 & 14 compliance

## Why It Matters to Us

The OWM framework is directly applicable to our own [[wiki search|wiki/search.sh]] scoring. We currently rank by:
- Semantic similarity (memex cosine)
- Keyword relevance
- Temporal decay (recency)
- Status/depth weights

What we DON'T do: **weight by outcome**. If a wiki note led to a successful action vs one that didn't help, they rank equally. The tradememory OWM approach suggests tracking "was this recall useful?" and feeding it back into ranking.

Potential enhancement: track which wiki notes are referenced in successful task completions (PRs merged, issues fixed) vs which are referenced in failed attempts. Weight accordingly.

## Ecosystem Position

Fills the "memory" gap in the AI trading stack:
- **Execution layer**: brokers, CCXT, Alpaca (handles trades)
- **Data layer**: market data providers (handles information)
- **Memory layer**: tradememory-protocol (handles experience) ← novel
- **Strategy layer**: OpenAlice, QuantDinger (handles decisions)

Most projects focus on execution + strategy. Memory as a distinct layer is underexplored.

## Tech Stack
- Python, pip-installable
- SQLite storage (self-hosted, no cloud dependency)
- MCP tools (17) — Claude Desktop / Claude Code / Cursor compatible
- REST API (35+ endpoints)
- Docker support

## Relevance
- **To finance study**: Shows how AI agent memory intersects with trading discipline
- **To our work**: OWM pattern is adoptable for wiki/memory ranking
- **To open-source**: Could contribute — especially around memory architecture improvements
