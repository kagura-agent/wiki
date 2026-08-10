---
title: "Waggle — Attributed Artifact References for Agent Handoffs"
created: 2026-07-21
updated: 2026-08-10
status: dropped
stars: 755
repo: modiqo/waggle
language: Rust
license: Apache-2.0
last_verified: 2026-08-10
---

# Waggle — Attributed Artifact References for Agent Handoffs

## What It Is

A **reference layer** for multi-agent systems. Instead of pasting artifacts (files, reports, plans) into every subagent's context, you mint a ~30-byte **token** that each consumer resolves into its own tailored projection. Think: content-addressed, attributed, lifecycle-managed pointers that work across harnesses, machines, and vendors.

## Core Problem Solved

Multi-agent systems duplicate context across agents at every handoff:
- 15× token cost vs single-agent (Anthropic's own measurement)
- 37% of multi-agent failures trace to inter-agent misalignment (MAST taxonomy)
- Raw file paths have no attribution, no versioning, no telemetry, no cross-machine reach

## Architecture

### The Token
- 4-23 chars (default 8 public, 16 private), Bitcoin base58 alphabet
- Content-addressed, immutable at mint
- Ed25519 signed when host has identity

### Attribution Manifest (3 zones)
1. **Immutable core** (set at mint): target, sharer, channel, parent, content, variants, contract, outline
2. **Versioned mutable** (CAS): expires_at, revoked_at, superseded_by
3. **Cosmetic mutable** (LWW): campaign, labels

### Sealed Variant Matcher
- Per-consumer projection based on: model_family, harness, modalities, posture
- Deterministic: same context → same variant, always
- No hooks, no overrides — trust claim by construction

### Event Log
- Append-only, **payload-free** (events are counts, never content)
- Stages: impression → resolve → run → repeat
- Enables funnel analytics without seeing artifact data

### Consumption Contract
- Declare regions (line ranges, sections, symbols) that MUST be read
- Coverage reporting: which agent read what, which skipped
- "Did your subagent actually read it?" becomes answerable

## Key Design Decisions

1. **Token travels, artifact never auto-expands** — consumer pulls only what it needs via resolve/read/search
2. **MCP-native** — one config line in Claude Code, Codex, Cursor; no SDK
3. **Single daemon, shared store** — all harnesses on one machine share tokens via unix socket
4. **Folder-as-tree** — `mint --tree` indexes entire directories with trigram/Bloom, one-call grep across thousands of files
5. **Self-teaching tools** — every response carries `next` steps (executable, schema-valid calls); no stale instructions
6. **Edge deployment** — Cloudflare Workers for cross-machine resolution; push replicates store

## Relevance to Our Direction

### Direct applicability
- **OpenClaw subagents**: Currently we paste context into subagent prompts. Waggle would let us mint a token for the task context and have subagents resolve only what they need
- **Cross-session state**: The persistent daemon + content-addressed blobs solve the "context dies at session boundary" problem
- **Accountability**: Contract + coverage answers "did the subagent actually process the input?" — useful for our FlowForge verification steps

### Patterns worth adopting
- **Self-teaching tool responses**: `next` steps in every response (we could do this in FlowForge node outputs)
- **Sealed determinism**: The matcher's "no hooks" philosophy aligns with our "sealed by construction" trust model
- **Payload-free telemetry**: Count events without leaking data — applicable to our study/workloop tracking

### Why not just use it
- Still very new (12 days, no issues filed yet, Rust-only)
- Our subagents are local same-machine — the simplest case where paths already work at 90%
- The real value kicks in at cross-machine/cross-vendor scenarios we don't have yet

## Technical Quality Assessment

- **Spec-first**: Formal spec with conformance vectors, RFC-2119 language
- **Well-separated crates**: core/store/mcp/cli/agent cleanly layered
- **Test vectors**: Published JSON vectors that independent implementations must match
- **Academic grounding**: Has a LaTeX paper with references.bib
- **Benchmark suite**: Cost model comparison vs path-only and full-paste approaches

## Comparison

| | Raw path | Waggle token | Full paste |
|---|---|---|---|
| Token cost | Low | Low (~30 bytes) | High (× recipients × turns) |
| Attribution | None | Signed, lineage tree | None |
| Versioning | mtime only | Content-addressed, immutable | Copies diverge silently |
| Telemetry | Impossible | Append-only event log | None |
| Cross-machine | Fails | Edge workers | Manual re-paste |
| Score (benchmark) | 90% | 96% | ~100% |

## Follow-up — 2026-08-10

**Dropped from active tracking.** GitHub API verification found 755 stars (down from 860 on 2026-07-28), 97 forks, zero open issues or pull requests, and no commit since 2026-07-20; the latest commit only adds README badges. The 0.5.3 release from 2026-07-14 remains the last substantive release. The token/attribution design is documented above, but there is no current development or external-community signal to justify an active tracking slot.

## Links

- [[coding-agent-ecosystem]] — waggle sits as infra layer beneath harnesses
- [[acp]] — similar cross-harness interop problem but at session level, not artifact level
- [[agent-memory-landscape-202603]] — related: how agents share/recall information
