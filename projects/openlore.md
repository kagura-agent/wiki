# OpenLore — Deterministic Architectural Memory & Governance for AI Coding Agents

> clay-good/OpenLore | 249⭐ | TypeScript | v2.1.7 | Created 2026-01-31 | Active (pushed daily)
> npm: `openlore` | MCP-ready | 18 languages + 12 IaC ecosystems | 5500+ tests
> 711 source files, 349 test files, 17 deps

## What It Does

Static-analysis-based memory + governance layer for coding agents. **No LLM in the hot path** — same question returns the same deterministic answer every time.

Two halves:
1. **Memory** — persistent architectural knowledge graph (functions, call structure, types, tests, decisions, IaC, spec drift). One-call `orient(task)` replaces multi-file exploratory reads.
2. **Governance** — change-impact certificates, breaking-change verdicts, architecture invariant checks, claim verification. All graph-based, all deterministic.

## Key Architectural Concepts

### Epistemic Lease (Novel)

Models agent understanding as a **temporary, degradable representation** rather than permanent truth. Decay triggers:
- Time (>15min degraded, >30min stale)
- Cognitive load (weighted accumulator >30/60 points)
- Cross-module trajectory density (module switches / window)
- Git divergence from orient baseline

Injected signals are **neutral facts, not imperatives**. "Facts-not-coercion" is an explicit design principle — injecting authoritative commands into tool output is considered a prompt-injection pattern. Fresh → no injection (zero overhead). Degraded → one-line fact appended. Stale → one-line fact prepended.

This is architecturally novel: most memory systems either force re-query or let staleness accumulate silently. OpenLore makes the agent **aware** of confidence decay without mandating behavior.

### Code-Anchored Memory

Decisions/notes bound to code by `StructuralAnchor`s (symbol name + content hash). At recall time, freshness computed against live graph:
- Symbol exists + hash matches → fresh
- Symbol exists + hash changed → drifted
- Symbol gone → orphaned (with rename resolution via stable IDs)

Symbols carry memories across refactors (content-addressed stable IDs). A renamed/moved symbol carries its memory forward at next `analyze` with `carriedAcross` provenance.

### Panic Response System

Beyond epistemic lease: a panic-score system tracks trajectory density, oscillation, and depth. Hysteresis prevents rapid state flapping. Injectable clock for deterministic replay/calibration.

## Design Principles

1. **Deterministic > probabilistic** — no LLM in the hot path, reproducible answers
2. **Facts-not-coercion** — signal degradation as neutral observation, not command
3. **Honest by construction** — publishes both wins and losses in benchmarks
4. **Off-thesis rejection** — external blocking verdicts rejected (cannot be locally recomputed). Composition via hook chaining instead.
5. **Security-first MCP** — repo content treated as untrusted input (indirect prompt injection vector). Hand-written security spec.

## Evolution

Started as `spec-gen` (March 2026, spec generation tool) → evolved into full architectural memory + governance. Package was `spec-gen-cli` on npm, now `openlore`.

## Performance / Benchmarks (Honest)

- `orient()` ~430µs p50 on 15k-node graph
- Agent round-trips: −26% on deep multi-hop tasks (excalidraw: 25→16 round-trips)
- Cost: −7% aggregate
- **Losses published**: adds overhead on small/familiar repos + shallow queries
- OOM fixed for repos up to microsoft/TypeScript scale (80k files, 652 MB) at 2GB heap

## People

- **clay-good** (maintainer): remarkable self-correction discipline. Files issues against own code, openly corrects wrong measurements with full methodology notes.
- **laurentftech** (collaborator): verification engine, drift integration, significant architectural contributions.

## Relevance to Us

| Aspect | OpenLore | Our Approach |
|--------|----------|--------------|
| Memory freshness | Epistemic Lease (time + load decay) | None — we trust files are current |
| Code anchoring | Symbol hash → structural anchors | File-based (MEMORY.md), no code binding |
| Governance | Deterministic graph-based certificates | Manual review |
| Staleness signal | Neutral facts injected into tool output | No equivalent |

**Applicable insights:**
1. **Epistemic Lease pattern** — we could track "how long since last wiki/memory read" and surface freshness signals. Relevant for long sessions where early-read context goes stale.
2. **Facts-not-coercion** — our DNA/preflight system uses imperative reminders ("不要做X"). OpenLore's approach of neutral facts ("15 minutes since last orient, 3 module switches") is less adversarial and may be more effective for self-governing agents.
3. **Honest benchmarking** — their "value scorecard" publishes both where it helps and where it hurts. We should do this for our tools.

## Ecosystem Position

- **Competitors**: Aider (file-editing agent), Cursor (IDE agent), Continue (open-source IDE)
- **Complementary to**: Any coding agent that supports MCP (Claude Code, Cursor, Cline, Continue)
- **Layer**: Infrastructure — sits below the agent, above the codebase. Not an agent itself.
- **Unique niche**: Deterministic memory + governance without LLM dependency. Most alternatives either use LLM for retrieval or have no governance layer.

## Links

[[agent-memory-strategies]], [[coding-agent-ecosystem]], [[agent-harness-landscape]], [[mcp-server]]

---
*Deep read: 2026-08-01 | Scout source: GitHub API + HN (19pts Show HN)*

## 2026-08-14 Follow-up

- **279⭐** (+12% from 249⭐). v2.1.9 released 08-10.
- Notable security-hygiene work this cycle:
  - **Redact repository secrets at output boundaries (#342)** — secrets stripped at the MCP/output boundary, not just at ingestion. Directly applicable to our tooling (we handle API keys/relay tokens in tool output paths).
  - **Disclose stale cited files in MCP (#343)** — memory honesty: tells the agent when a cited file has moved/changed. Aligns with our [[ephemera-retention-primitive]] and "verify before claiming" DNA.
  - Deterministic load-sensitive test suite (#356) — removes flakiness from load tests, matching their "honest benchmarking" ethos.
- Still active team (clay-good + laurentftech), deterministic output boundary discipline improving.

Links: [[agent-memory-strategies]], [[mcp-server]], [[ephemera-retention-primitive]]

## 2026-08-20 Follow-up

- **287⭐** (+3% from 279 in 6d), 35 forks. **v2.2.0 released 08-17.**
- This cycle's work:
  - **Complexity language-aware analyzer (#381)** — complexity metrics now language-aware (per-language weighting instead of one-size-fits-all).
  - **Detect tests across supported languages (#380)** — test discovery generalized beyond a single framework assumption.
  - **Preserve governance config + bound first-turn startup (#379)** — config survives across runs; startup cost bounded (deterministic-hygiene continuity).
  - **CodeQL egress triage docs (#378)** — security posturing documented for CI egress review.
- Steady maintenance pace, but 3 open issues are all dependabot bumps — no external feature/community signal this cycle.
- Security-hygiene patterns (output-boundary redaction, stale-citation disclosure) remain directly applicable to our tooling; nothing new to adopt this round.
- Revisit **2026-08-27** for external contributor signal + epistemic-lease evolution.

## 08-28 Follow-up (289⭐, ⭐ flat)

- ✅ 持续维护: commits 至 08-24, **v3.0.1 release (#408)** + security release-boundary hardening (#404) + overlay language coverage (#403) + watcher edit-breakage verdicts (#402) + mcp standing-context cost bound。
- 3 open issues 全 dependabot — 无外部社区信号但维护纪律稳定。
- Security-hygiene 模式 (output-boundary redaction, stale-citation disclosure) 持续适用。Revisit 09-10。
