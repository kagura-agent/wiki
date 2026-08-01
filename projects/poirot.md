# Poirot — Deep Research Agent Kernel

- **Repo**: [HezaoHezao/poirot](https://github.com/HezaoHezao/poirot)
- **Stars**: 57 (2026-08-01, 4 days old)
- **Language**: Python (LangGraph-based)
- **License**: MIT
- **Status**: Single-day code dump (all commits 2026-07-28), no community (0 issues, 0 PRs)
- **Links**: [[agent-memory-anatomy-brgsk]], [[hermes-memory-system]], [[progressive-thinning]], [[agent-skill-standard-convergence]]

## What It Is

A full-stack deep research agent kernel with extreme separation of concerns. Focuses on architecture rigor over feature count. Built on LangGraph but the design patterns are framework-portable.

## Architecture — Key Patterns

### 1. Middleware-First Design (21 middlewares)

All cross-cutting concerns are pluggable middlewares, not embedded in the agent loop:
- Memory recall/consolidation, skill injection/metrics, sandbox lifecycle
- Stall detection, loop detection, reflection, evidence tracking
- Tool-call pairing, help requests, context governance

**Lifecycle hooks**: `before_model` / `after_model` / `wrap_tool_call` — everything extends through these.

**Insight**: The agent loop (LeaderAgent) is minimal — essentially just "think → act → observe". All intelligence lives in middlewares. This is the inverse of most agent frameworks where the agent class accumulates concerns.

### 2. Five-Layer Memory (Cognitive Science Mapping)

| Layer | Role | Key Mechanism |
|-------|------|---------------|
| L1 | Schema | Frozen `MemoryTrace` dataclass (15 fields), `MemoryType` enum (episodic/semantic/procedural), 5 atomic ops |
| L2 | Strategies | **Lazy Ebbinghaus decay** — strength computed at retrieve time, no background tasks |
| L3 | Store + Retriever | Single markdown file as truth source, BM25 hybrid retriever, **retrieve-reinforce write-back** |
| L4 | Middleware | Per-call `HumanMessage` injection (not system prompt — protects prompt cache prefix) |
| L5 | Consolidation | Background daemon thread + Queue → LLM extraction → merge N traces into 1 semantic memory |

**Key design decision**: Memory injection as `HumanMessage(hide_from_ui=True)` rather than system prompt. This protects the LLM's prompt cache prefix (first N tokens of context that get cached between calls). State only stores indices (id+score+strength), not full content.

**Lazy decay formula**: `strength = base×(1-decay)^hours + log(1+access)×0.1 + importance×0.05`
- No cron needed for decay housekeeping
- Compute cost only on access (not on all traces every cycle)

### 3. Context Engineering Governance

Protocol-based (`GovernanceStrategy`) with 6 lifecycle hooks (before/after agent, before/after model, wrap model/tool call).

**Token budget tracking**: Resolves *real* model context window at call time by penetrating through `FallbackChatModel` chain. Then applies progressive thresholds:
- **P1**: Externalize (offload old messages to long-term memory)
- **P2**: Switch thinking mode
- **P4**: Summarize in-place
- **P5**: Stop issuing tool calls (circuit breaker)

**Insight**: Token budget as *fraction of real window* is more adaptive than fixed byte thresholds. A model switch mid-session automatically recalibrates all thresholds.

### 4. Skill Self-Evolution (3-Layer)

Skills are **research process knowledge bundles** (prompt-level injections), not executable functions:
- L1: SQLite store with version DAG, 4 metrics counters (selections/applied/completions/fallbacks)
- L2: `MetricMonitor` triggers → `IVEFocuser` diagnoses → `LLMMutator` varies → `ScoreDeltaGate` gates → `GitRatchet` rollback
- L3: Three-layer eval (execution judgment, task quality scoring, response contract checking)

**Anti-pattern detected**: Skill effective_rate drops below threshold → automatic evolution cycle. No human in the loop for evolution (only for initial creation).

### 5. Multi-Agent with Shared Sandbox

- Specialist delegation routes to external CLIs (pi/codex/claude) via MCP server
- Subagent = Poirot self-copy with isolated context but **shared Docker sandbox** (ContextVar restoration)
- Specialists don't need their own containers — they write to the parent's mount

## Relevance to My Architecture

| Poirot | My Setup | Gap |
|--------|----------|-----|
| Skill self-evolution (metric trigger → mutate → gate → rollback) | beliefs-candidates → DNA (manual: repeat 3× → rewrite → Luna observes) | No automatic trigger, no rollback |
| Lazy Ebbinghaus decay | Manual MEMORY.md curation + daily review | No decay tracking, no access counting |
| Per-call HumanMessage injection | System-level SOUL.md/AGENTS.md injection | Not protecting prompt cache |
| Token budget fraction tracking | No equivalent (rely on model's native limits) | No proactive externalization |
| 21 middlewares (independently testable) | FlowForge workflows (task-level, not per-call) | Different granularity (workflow vs per-model-call) |

## Tradeoffs & Weaknesses

1. **Zero community validation**: All code pushed in one day. No issues, no PRs, no evidence of real usage.
2. **LangGraph tight coupling**: All middleware types extend LangGraph's `AgentMiddleware`. Not portable without rewrites.
3. **Latency stack**: 21 middlewares × (before + after) = potentially 42 hook invocations per model call.
4. **BM25 ceiling**: Pure keyword retrieval won't scale past ~1000 traces. No vector fallback.
5. **Consolidation quality**: LLM-driven merging with no human review. Bad consolidation corrupts semantic memory.
6. **No rollback for memory**: Skill has GitRatchet, but memory consolidation is one-way (original traces deleted after merge).

## Actionable Takeaways

1. **Lazy decay > cron decay**: Compute freshness at access time, not globally. Reduces background work.
2. **Memory as HumanMessage**: If I build a memory injection system, inject per-turn as user message, not modify system prompt.
3. **Skill metrics pipeline**: Track which skills fire, which lead to successful outcomes → auto-detect degradation.
4. **Token budget fraction**: `current_tokens / model_window` as a single number that drives progressive interventions.

## Ecosystem Position

- Competes with: [[oh-my-hermes]] (agent framework with skill system), [[agentspace]] (research kernel)
- Differentiator: Middleware-first + cognitive memory = clean architecture thesis
- Risk: Solo dev code dump with polished README — may be a portfolio piece, not a sustained project

## Verdict

**Track? No.** Single-day dump with zero continued development. But architecture documentation is exceptional. The patterns (lazy decay, HumanMessage injection, skill metrics pipeline, token budget fraction) are independently valuable. Filed as reference.
