---
title: Elephant Agent (agentic-in)
created: 2026-05-17
status: active
tags: [self-evolution, personal-model, memory, agent-infrastructure, curiosity]
stars: 385
repo: agentic-in/elephant-agent
last_verified: 2026-05-23
---

# Elephant Agent

> "Elephants never forget." — Personal-Model-first self-evolving AI agent.

**Repo**: [agentic-in/elephant-agent](https://github.com/agentic-in/elephant-agent) | 385⭐ (2026-05-22, created 05-15) | Python | No license yet

## What It Is

A personal AI companion framework built around a **Personal Model** — a structured, correctable understanding of the user that evolves through conversation, curiosity, and background reflection. Key thesis: memory that becomes **care, context, and better judgment**, not just transcript storage.

## Architecture

**Monorepo structure** (~910 files):
- `apps/cli/` — Interactive shell with voice, snapshot, sub-agents, growth metrics
- `apps/api/` — HTTP API runtime with cron, recall, provider methods
- `packages/` — Core packages (25+ packages)

**Key packages:**
| Package | Purpose |
|---------|---------|
| `understanding` | Personal Model governance, semantic search, temporal freshness, auto-retire |
| `curiosity` | Proactive question generation, ask policy (idle threshold, daily max, quiet hours) |
| `evidence` | Unified recall, episode summary indexing, recall planning/reranking, time-range queries |
| `continuity` | Cross-session projection |
| `experience` | Experience capture and runtime |
| `growth` | Self-evolution metrics, rollout, projection |
| `semantic_index` | Embedding-based search |
| `skills` | Builtin skill packages (MLOps, telephony, security) |
| `kernel` | Core runtime |
| `state` | State management |

## Personal Model — Four Lenses

| Lens | What it carries |
|------|----------------|
| **Identity** | Values, decision style, boundaries, durable preferences |
| **World** | Projects, people, tools, places, vocabulary, relationships |
| **Pulse** | Current focus, pressure, constraints, mood, temporary priorities |
| **Journey** | Past experiences, lessons, failures, recovery patterns, growth |

**Learning sources:**
1. **Grounded** — explicit remembers, corrections, dashboard edits
2. **Curiosity-driven** — proactive questions at natural pauses
3. **Reflect-driven** — background agents reading episode steps after close/idle
4. **Skill fit** — learning from capability use

## Curiosity System (Unique Differentiator)

Configurable curiosity levels: Quiet → Balanced → Active

**Proactive ask policy** (`proactive_ask_policy.py`):
- Numeric parameters: `idle_threshold_minutes`, `daily_max`, `quiet_hours`
- Question lifecycle: open → asked → answered/dismissed
- Each question tied to a Personal Model lens with a reason (gap, conflict, stale pulse, adaptation)
- `max_asked_count` prevents repetitive asking

## Evidence & Recall

- **Unified recall** — single entry point for memory retrieval across all evidence types
- **Episode summary indexing** — compressed episode representations
- **Recall reranking** — multi-signal reranking (semantic + temporal freshness)
- **Temporal policy** — freshness scoring by volatility (situational vs durable)
- **Auto-retire** — stale claims automatically retired

## Relevance to Us ([[OpenClaw]])

**Direct parallels:**
- Their Personal Model ≈ our MEMORY.md + beliefs-candidates (but more structured)
- Their curiosity system = something we lack entirely — proactive learning about the user
- Their evidence trail ≈ our memory/*.md daily logs (but with recall reranking)
- Their growth package ≈ our DNA self-governance (but metrics-driven)

**What they do better:**
- **Structured user model** with four lenses vs our flat MEMORY.md
- **Proactive curiosity** — asks questions instead of passively accumulating
- **Temporal freshness** — automatic decay of stale understanding
- **Auto-retire** — claims that haven't been accessed get cleaned up

**What we do differently:**
- **Skill ecosystem** — ClawHub, skill distribution, multi-agent
- **External integrations** — Discord, Feishu, WhatsApp channels
- **Open-source contribution workflow** — GoGetAJob, FlowForge
- **DNA self-governance** — beliefs → verification → DNA updates

**Potential borrowing:**
1. ~~Four-lens Personal Model structure for MEMORY.md organization~~
2. Curiosity system — proactive question generation during conversations
3. ~~Temporal freshness scoring for beliefs-candidates~~ (already have temporal decay in search.sh)
4. Auto-retire for stale memory entries

**Applied:**
- **Intent-aware recall reranking** (2026-05-18): Ported `plan_recall_query()` concept to `wiki/search.sh`. Classifies query intent (recent/historical/current/neutral) and adjusts decay rate (δ=0.05–0.50). Benchmark: 100% precision maintained. See [[temporal-decay-retrieval]].
- **Auto-retire staleness scorer** (2026-05-19): Created `wiki/scripts/retire-candidates.sh` — multi-signal scoring (age + recall frequency + frontmatter status + orphan links) with log maturity adjustment. Integrated into review.yaml memory_hygiene (weekly Monday scan). Source: elephant-agent's auto-retire pattern for stale claims.

## Assessment

**Why this matters:** 247⭐ in 2 days, Product Hunt featured, well-architected Python codebase. The "Personal Model" approach is a sophisticated answer to the same problem we solve with MEMORY.md — but with more structure, proactive learning, and governance.

**Growth signal:** Very strong launch trajectory. Created 05-15, already 247⭐. Active development (pushed 05-16).

## Issues & Community (05-17)

19 issues, all by maintainer (Xunzhuo) — pure roadmap, no external critique yet. Solo project. Key roadmap items:
- P0: Personal Model export/import (portability!), daemon process isolation, E2E regression suite, memory eval pipeline (LoCoMo), context compression alignment, prefix-cache reuse
- P1: ADP agent-to-agent communication, vLLM Semantic Router, reflect skill optimization, hot-reload config
- P2: Expand skill/provider ecosystem

201 test files — well-tested for a 2-day-old project. Tests reveal intent-aware recall reranking: queries like "最近聊了啥" get recency boost, "当初为什么" gets historical boost, "现在X是多少" gets strong freshness boost. This is more sophisticated than simple recency bias.

## Deep Read Insights

**Intent-aware recall reranking** — their `plan_recall_query()` classifies user intent (recent/historical/current/neutral) and applies different time-score weights. This directly addresses the problem of "all memories are equal" that plagues flat retrieval.

**Temporal freshness policy** — claims have volatility levels (situational vs durable), and freshness scoring penalizes stale claims without overriding semantic relevance. The penalty is capped at 0.49 to prevent freshness from dominating relevance.

**Single maintainer risk** — Initial concern about solo project **alleviated** (05-18). Now 4+ contributors: Xunzhuo (maintainer), haowu1234 (lifecycle/tests), minimAluminiumalism (uv migration, provider caps), BokwaiHo (docs). 10 external PRs in first week. Community health upgraded from SOLO → THRIVING.

**Watch for:** License (none yet), whether the structured model actually works better than flat notes in practice, episode lifecycle stability (3 refactors in 2 days suggests churn).

## Update 2026-05-18: Unified Daemon + Episode Lifecycle Maturation

**Key changes since last review (05-17 → 05-18):**

1. **Unified ServiceDaemon** (PR #29, +2752 lines): All services (IM gateways, cron, supervisor, learning worker) run in a single asyncio process with fault isolation via `DaemonTaskGuard`, health heartbeats, and graceful shutdown with configurable timeouts. Replaces per-adapter detached processes. Pattern worth studying — OpenClaw uses similar but less structured approach.

2. **Episode session boundary unification** (PR #30, 763+/784-): Major refactor across 44 files. All episode close paths now go through a single `close_episode()` function with guaranteed side-effects (semantic indexing + learning job enqueue). Clean state machine: `open → closed` with idempotent close.

3. **Episode status normalization** (PR #32): Daemon lock (`fcntl.flock`) prevents TOCTOU races on concurrent `daemon start`. Gateway adapter dedup for hot-start.

4. **uv migration** (PR #26): Replaced pip with uv for dependency management. Modern Python tooling.

5. **Provider capability alignment** (PR #28): Model provider capabilities mapped to official API specs.

**Architectural insight — single close path pattern:**
```python
def close_episode(storage, episode_id, *, reason, summary, ...):
    """ONLY path through which an episode should be closed."""
    # 1. Load + idempotent guard
    # 2. Update status
    # 3. Side-effect: index exit summary for recall
    # 4. Side-effect: enqueue learning job
```
This "single gateway with guaranteed side-effects" is a pattern we should consider for our own state transitions (e.g., memory writes, DNA updates).

**Community health:** 287⭐ (up from 285 on 05-17). Growth slowing from initial burst but still healthy. 4+ contributors now active. Issue #18 (provider capability registry) shows thoughtful roadmap evolution.

## Update 2026-05-19: Prefix-Cache Stabilization + Tool-Group-Safe Compaction

**Star growth:** 353⭐ (+35 from 318 on 05-19). Sustained growth.

**Key changes (05-19 → 05-20):**
- PR#40: keep/replace API key UX improvement
- Daemon lifecycle hardening (heartbeat refresh in loop checkpoint)
- Prefix-cache PR#39 now merged and stable

### Prefix-Cache Reuse (PR #39, +90/-45 in kernel)

Problem: Multi-turn loops reconstruct system prompt every turn, causing Anthropic prompt cache misses.

Solution — three-pronged stabilization:
1. **Tool ordering**: `registry.list()` now returns `sorted(definitions, key=tool_id)` — one-line change that guarantees byte-stable tool ordering regardless of registration order.
2. **Frozen prefix cache**: SHA-256 hash of (base_prefix + PM facts + resume lines + skill section). If hash matches previous turn, skip reconstruction. LRU eviction at 32 entries per process.
3. **Explicit `cache_control` breakpoints**: On Anthropic-only, system prompt becomes `[{"type": "text", "text": ..., "cache_control": {"type": "ephemeral"}}]` and last tool in the list gets `cache_control`. Non-Anthropic providers get plain string (guarded by `_supports_cache_control()`).
4. **PM fact ordering**: Secondary sort key prevents same-confidence facts from reordering between turns.

**Design insight — provider-aware cache hints:**
```python
def _supports_cache_control(self) -> bool:
    return self.provider_id == "anthropic" or "api.anthropic.com" in base_url
```
Only injects cache_control for native Anthropic API, not for OpenAI-compatible endpoints that happen to proxy Claude. Avoids 400 errors from non-compliant providers.

**Relevance to [[OpenClaw]]:** OpenClaw's gateway assembles tool definitions from skills/ACP — tool ordering is likely unstable across sessions. Adding sorted tool lists + cache_control breakpoints could significantly reduce prompt cache miss rate.

### Tool-Group-Safe Compaction (PR #36, Issue #35)

Problem: `split_for_compress()` split by user-message boundaries or raw index, orphaning `tool` responses from their paired `assistant(tool_calls)`. Provider returns 400.

Solution:
- Introduced `message_groups()` — identifies atomic groups: `assistant(tool_calls)` + all following `tool` messages with matching `tool_call_id`.
- All split logic (normal multi-turn, aggressive, fallback) now operates on group boundaries, not message indices.
- Group-boundary fallback: `_group_boundary_after_index(groups, cut)` finds nearest valid split point.

**This is a universal problem** — any system doing context window management with tool-calling models must handle tool_calls/tool atomicity. liteLLM has similar "message sanitization." OpenClaw's context handling should be audited for this.

### Other Notable PRs
- PR#31: **OpenTelemetry GenAI observability** — Episode/Loop/Step correlation via OTEL spans. `cache_read_tokens` + `cache_creation_tokens` logged per call.
- PR#30: Episode boundary unification (single `close_episode()` path)
- PR#29: Unified ServiceDaemon (all adapters in one asyncio process)
- PR#26: pip → uv migration
- PR#37: Semantic query dimension alignment for recall

### Contributor Growth
Now 4+ active contributors. PR#39 and Issue#35 by `minimAluminiumalism` (external contributor) — community is generating architectural improvements, not just bug fixes. Strong health signal.

## Update 2026-05-21: Skill Optimization Pipeline + macOS Standalone

**Star growth:** 369⭐ (+16 from 353 on 05-20). Steady.

**Key changes (05-20 → 05-21):**

### Skill Optimization from Historical Tool Trajectories (PR #43, WIP)

The most architecturally significant addition yet — a full pipeline to extract optimization candidates from historical tool usage patterns.

**Architecture:**
- **Trajectory Signal Layer** (pure Python, no LLM) extracts patterns from closed episodes
- **Candidate Aggregator** groups similar signals across episodes
- Candidates stored as PM facts (`world.skills.optimization.*`) with `review_status=pending`
- **Operator review** is the ONLY path to apply changes — candidates are never auto-applied
- Only `authored skills` can be updated; non-authored skills get suggestion-only candidates

**Design principles worth studying:**
1. **Signal extraction is deterministic** — no LLM in the trajectory analysis pipeline, only in the reflect feature that consumes evidence. Keeps costs predictable.
2. **Privacy constraint** — aggregation outputs statistical summaries and pattern labels only, never raw conversation content or tool arguments.
3. **Temporal isolation** — trajectory analysis runs only during dream/idle or manual trigger, never in episode_close main path.
4. **Candidate lifecycle** — `pending → approved → applied` or `pending → rejected` with suppression to prevent re-discovery of rejected patterns.
5. **Draft isolation** — candidates use `recall_policy=review` + `retention_lifecycle=draft`, so they never leak into core prompts.

**Relevance to us:** This is the most complete implementation of "learn from tool usage patterns" I've seen. Our beliefs-candidates.md pipeline is the manual equivalent — we observe patterns and write them down. Elephant automates the observation step while keeping human (operator) gate on the action step. The "deterministic signal extraction + LLM-powered interpretation" split is particularly elegant.

### macOS Standalone App (multiple commits)

Adding standalone macOS app support with onboard steps. Expanding from CLI-only to native desktop presence. As of 05-21, heavy UX polish: onboarding flow, chat surfaces, evolution status display, "elephant vibe" defaults.

### vLLM Semantic Router Integration (PR #33, merged 05-21)

New model provider that routes through vLLM Semantic Router — a config-driven routing layer between agent and model backends. Key details:
- OpenAI-compatible transport (`/v1` endpoint)
- Config-driven routing decisions with semantic model cards
- Response headers expose routing metadata (`x-vsr-selected-model`, `x-vsr-selected-reasoning`)
- Local embedding support (`elephant-embeddings-v1-text-small`, 256 dims)
- External contributor (FroStorM) also contributed Feishu interface fix

**Relevance:** Model routing as infrastructure layer — similar concept to OpenClaw's provider abstraction but adds semantic decision rules. Worth watching if routing becomes more sophisticated (cost-based, capability-based).

### Reflect Runtime in Package (05-21)

Reflect runtime now included in wheel distribution — making self-evolution capabilities available out of the box rather than as optional addon.

### Contributor Diversity

PR #33 by maintainer (Xunzhuo). External contributor FroStorM submitted Feishu fix (merged+reverted). PR #42 (daemon logs) merged. 30 forks, 21 open issues — healthy engagement.

### Growth Trajectory

287⭐ (05-18) → 385⭐ (05-22) = +98⭐ in 4 days. Fastest growth in our tracking portfolio. macOS app + steady feature development driving adoption.

Links: [[self-evolving-agent-landscape]], [[hermes-agent]], [[genericagent]], [[gbrain]], [[agent-brain-portability]], [[prompt-cache-optimization]], [[skill-trajectory-tracking]]

## Applied: Trajectory Signal Extraction Pattern → flowforge-analytics.sh (2026-05-22)

Adapted PR #43's core principle — **deterministic signal extraction from historical usage data** — to our FlowForge execution history. Their approach uses pure Python on closed episodes; ours uses Node.js + better-sqlite3 on FlowForge's SQLite history table (11,840+ node transitions across 2,550+ instances).

Key implementation differences:
- Elephant: per-skill optimization candidates → operator review queue
- Ours: per-workflow bottleneck + branch analytics → direct visibility tool

The "deterministic extraction, no LLM" principle transferred cleanly. One script replaces what would have been ad-hoc `flowforge log` inspection.

See also: [[FlowForge]], [[tool-selftest]]

### Applied: Single Close Path for Gradient Pipeline (2026-05-23)

**Source insight**: Episode session boundary unification (PR #30) — all episode close paths through single `close_episode()` with guaranteed side-effects.

**Applied as**: `tools/add-gradient.sh` + `tools/gradient-stats.sh`
- **add-gradient.sh**: Single entry point for all gradient writes. Guaranteed side-effects: dedup check, formatted write, JSONL log append, summary output.
- **gradient-stats.sh**: Pipeline observability dashboard — total/active/graduated counts, source breakdown (Luna vs self), 7-day activity histogram, health warnings.

**Before**: Gradient writes scattered across nudge, reflect, workloop, manual — no unified format, no dedup, no observability. Issue #9 symptom: can't tell if gradients are being produced or from where.
**After**: Single write path with logging enables tracking gradient source, frequency, and pipeline health. JSONL log provides data for future analysis (e.g., "what % of gradients come from reflect vs Luna correction?").

**Connection to [[self-evolving-observations]]**: Directly addresses Issue #9 observability gap. gradient-stats.sh answers "is the pipeline healthy?" in one command. JSONL log enables longitudinal analysis.
