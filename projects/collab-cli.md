---
title: collab-cli
status: noted
created: 2026-06-09
updated: 2026-06-09
stars: 7
repo: yinsang0910-star/collab-cli
tags: [multi-agent, collaboration, LAN, P2P, protocol]
last_verified: 2026-06-09
---

# collab-cli

> Universal collaboration protocol + CLI for multi-agent LLM teams. Cross-device agent coordination via LAN auto-discovery.

## What It Solves

Multiple AI coding agents (Claude Code, Codex, Cursor, etc.) running on **different machines** need to share state and coordinate without a human relaying messages. collab-cli provides file-based + UDP/HTTP P2P sync with zero cloud dependency.

## Architecture

```
┌─ Machine A ─────────┐         ┌─ Machine B ─────────┐
│ Agent (Claude Code)  │  UDP    │ Agent (Codex)       │
│ collab node :9527    │◄─9528─►│ collab node :9527   │
│ .shared/             │  HTTP   │ .shared/            │
│   SHARD.md (L0)     │◄─sync─►│   SHARD.md (L0)    │
│   memory/ (L1)      │         │   memory/ (L1)      │
│   inbox/ (local!)    │         │   inbox/ (local!)   │
└──────────────────────┘         └──────────────────────┘
```

- **Discovery**: UDP broadcast port 9528, HMAC-signed, 5s heartbeat, 15s timeout
- **Sync**: HTTP push every 10s. SHARD = whole-file replace (versioned). Tasks = per-file status-machine merge. Inbox = NOT synced (local per device)
- **Memory tiering**: SHARD.md ≤80 lines (L0) → memory/ per-topic (L1) → archive/ dated (L2). Auto-compact.
- **Access**: 5 roles (L0 observer → L4 chief engineer), badge-based permissions
- **Orchestrator**: Adapters for Claude/Codex/Cursor/Reasonix/WorkBuddy/Aider. Pipeline execution.
- **Dependencies**: Single (gray-matter). 1160-line CLI entry + src/ modules.

## Key Design Decisions

1. **File-as-protocol** — markdown + YAML frontmatter. Any agent that reads files can participate. No custom binary format.
2. **"Higher status wins" merge** — simple but lossy. No CRDT. Concurrent writes resolved by status progression order (DRAFT < ASSIGNED < IN_PROGRESS < REVIEW < DONE).
3. **Inbox is local** — avoids message routing complexity. Cross-device commands use HTTP API directly.
4. **Badge system** — capabilities & restrictions per role. L0 can only read; L4 manages everything.

## Tradeoffs & Limitations

- LAN-only. No internet-distributed agent teams.
- No real conflict resolution for concurrent SHARD edits (last-write-wins by version number).
- Single-writer assumption for most files. Multiple agents writing the same task simultaneously = race condition.
- No persistence guarantee — UDP discovery is ephemeral, no reconnection state.

## Ecosystem Position

| vs | Comparison |
|---|---|
| [[openclaw]] | Central gateway + session model vs fully P2P/LAN. Different trade-off: decentralized (no SPOF, no internet) vs centralized (richer features) |
| A2A | Cloud-first JSON-RPC vs LAN-first file-based. Different deployment contexts |
| [[universal-memory-protocol]] | UMP = memory format standard. collab-cli = collaboration protocol. Complementary |
| [[agent-identity-protocol]] | Both care about agent auth. collab-cli uses HMAC + badges; AIP proposes cryptographic identity |

## Relevance to Us

- **Validates tiered memory**: Their SHARD ≤80 lines is the same pattern as our compressed context approach
- **Badge/permission system**: Similar to our [[team-lead]] skill's role-based delegation
- **File-as-protocol**: Same philosophy as OpenClaw's AGENTS.md / skill files — agents read markdown, no custom API needed
- **Anti-pattern confirmed**: No CRDT = pain at scale. Our gateway-mediated approach avoids this class of bugs

## Verdict

Well-executed for its niche (LAN dev shop with multiple workstations). Won't scale to internet-distributed agents. Clean code, minimal deps. No groundbreaking patterns for us, but validates several design choices we already made.
