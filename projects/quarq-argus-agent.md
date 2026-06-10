# Quarq Argus Agent — Deep Read

**Repo:** quarqlabs/agent-oss (name: "argus")
**Stars:** 248 (06-09, was 180 on 05-30, +38%)
**Created:** 2026-05-24 (16 days old)
**Language:** Python (LangGraph + FAISS + OpenAI)
**License:** Apache-2.0
**Contributors:** 3 (SouravBeraAkaSpeed, zamal-db, Vaibhav20201)
**Community:** 🟡 GROWING (4/6) — 2 PRs total, 3 contributors, no external community yet
**Last push:** 2026-06-08

## What It Is

Memory-first AI agent explicitly positioning against Hermes and OpenClaw. Focus: durable local memory, strict attribution, self-correcting retrieval, and benchmark-grade long-term recall. Targets LongMemEval-S benchmark (claims 98.2% on 500 questions).

## Architecture

Simple LangGraph StateGraph pipeline:
```
START → retrieve_memories → route_tools → generate_response → END
```

Learning happens inside `generate_response`:
- Normal chat: background async (non-blocking)
- Benchmark ingestion: inline sync (deterministic)

## Memory System (3-layer)

| Layer | Stores | Example |
|-------|--------|---------|
| **Semantic** | Durable user facts (identity, preferences, relationships, possessions) | "User owns a crystal chandelier from great-grandmother" |
| **Episodic** | Events with temporal grounding (what, when, who, what changed) | "On March 4, 2023, user received chandelier from aunt" |
| **Procedural** | Behavioral rules (tone, formatting, project instructions) | Tagged and routed per-prompt, not carried globally |

Comparison to our system: We use file-based memory (MEMORY.md, daily logs, wiki). Their 3-layer FAISS approach is more structured for retrieval but less inspectable. Our procedural memory is DNA files (SOUL.md, AGENTS.md) — always loaded, not routed per-query.

## Retrieval Pipeline (Key Innovation)

Not simple embed-and-search. Multi-step:

1. **HyDE query expansion** — lightweight model generates multiple retrieval probes from user prompt
2. **Parallel search** — semantic FAISS + episodic FAISS + semantic keyword + episodic keyword
3. **Dedup + recency sort** — ID-based deduplication
4. **Procedural rule routing** — only relevant rules injected
5. **Dynamic thresholds** — `deep` mode (threshold 0.28) for aggregation/timelines, `standard` mode (0.38) for point facts

### Self-Correcting Retrieval (REQUIRED_DATA fallback)

If first pass evidence is insufficient, model emits `REQUIRED_DATA` flag with targeted hyde_queries → second retrieval pass → regenerate answer with expanded context. If still missing after fallback: "information not available" (no hallucination).

**This is their differentiator.** Most RAG systems do one pass and hope. The fallback loop is aggressive recall + conservative truth.

## Temporal & Quantitative Reasoning

**Temporal Truth Protocol:**
- Separates storage time vs narrative time vs benchmark date vs relative dates
- Prevents: using DB timestamps as event dates, borrowing dates from unrelated memories, assuming discussion date = event date

**Numeric Protocol:**
- Numbers tagged with: actor, property, item, exactness
- Excludes topically-related-but-wrong numbers
- Only sums exact unqualified values for totals

These protocols directly address 4 RAG failure modes:
1. Wrong memory retrieved
2. Right memory, wrong entity
3. Storage time confused with event time
4. Nearby numbers confused for target numbers

## Learning Pipeline

Model extracts ADD/UPDATE/DELETE actions for all 3 memory types. Key behaviors:
- Preserves proper nouns and numbers exactly
- Resolves relative dates at ingestion time
- Deduplicates across semantic/episodic layers
- Benchmark ingestion: splits chunks into user/assistant pairs, stages in RAM, commits after chunk complete

## Tool System

Progressive tool loading — tool docs only injected when skill is selected (not all upfront). Includes:
- Coding agent delegation (Codex integration)
- Cloud tool expansion (Composio-based SaaS actions)
- Agent identity manager
- Channel integrations (Telegram, CLI)

## Benchmark Results (LongMemEval-S, self-reported)

| Type | Accuracy |
|------|----------|
| Overall | 98.20% (491/500) |
| single-session-user | 100% |
| single-session-assistant | 100% |
| single-session-preference | 100% |
| knowledge-update | 98.72% |
| multi-session | 96.99% |
| temporal-reasoning | 96.99% |

⚠️ Self-reported, not independently verified. Full run costs ~$2,500. "Some answers may change as failing questions are rerun and fixes are added" — suggests iterative tuning on the eval set.

## Ecosystem Position

Positions explicitly against [[Hermes]] and [[OpenClaw]] in the memory-agent space. Closer in spirit to [[brain-git-memory]] (structured local memory) than to [[reasonix]] (cache-first optimization). Memory engineering quality is above average for the ecosystem — most projects do one-shot RAG and call it "memory". The REQUIRED_DATA fallback pattern is reminiscent of [[sentra-rag-failure-modes]] F1/F2 mitigations but implemented at the agent level rather than the retrieval infrastructure level.

Compared to [[buddyme]]'s three-tier skill system or [[mercury-agent]]'s registry approach, Argus is narrowly focused on memory quality rather than skill breadth.

## Transfer Value Assessment

### Worth Adopting
1. **REQUIRED_DATA fallback retrieval** — Two-pass retrieval with explicit "evidence insufficient" signal. Our memory_search does one shot. Could add a "confidence check → retry with expanded query" pattern. Low cost, high impact for recall quality.
2. **Temporal Truth Protocol** — We don't explicitly separate storage time from event time in memory entries. When we write daily logs, the date is in the filename, but temporal queries against memory_search don't have these guardrails. Worth thinking about for memory entries.
3. **Dynamic retrieval thresholds** — Standard vs deep mode depending on query type. Our memory_search uses fixed parameters. Could tune minScore dynamically based on query intent. ✅ **Applied 2026-06-10** — MIN_MATCH now varies by intent: historical=40%, current=80%, default=60%. Benchmark 100% maintained.

### Interesting But Not Actionable Now
4. **Numeric attribution protocol** — Elegant but our use case doesn't involve frequent quantitative recall queries
5. **Progressive tool loading** — Our skill system already does this (read SKILL.md on demand, not upfront)
6. **Structured artifact extractors** — They disabled it themselves for benchmark tuning. Concept of preserving table rows/lists/metrics as discrete memory units is interesting for future
7. **3-layer memory separation** — Our file-based system (daily logs + MEMORY.md + wiki) serves a similar purpose but less formally structured

### Not Relevant
- FAISS local-first approach (we use provider-managed vector store)
- LangGraph orchestration (we use OpenClaw's own session/tool system)
- Benchmark infrastructure (we don't run LongMemEval)

## Competitive Assessment

They explicitly position against OpenClaw, but the comparison is apples-to-oranges:
- Argus is a **memory research project** optimized for benchmark scores
- OpenClaw is a **general agent runtime** with memory as one component
- Argus is single-user local-only; OpenClaw is multi-channel, multi-user
- Their memory system is more rigorous; our tool/skill/session system is more capable

Not a threat, but the memory engineering is genuinely interesting.

## Contribution Potential

Low. 3 contributors, 2 PRs total, no contribution guidelines beyond CONTRIBUTING.md. Solo-team project in benchmark-tuning phase. Not worth contributing to — too early, too focused on internal eval.

## Verdict

**MONITOR (downgrade from TRACK).** Interesting memory engineering, especially REQUIRED_DATA fallback and temporal/numeric protocols. Star growth strong (248 in 16 days) but community is absent. Worth checking back in 2-3 weeks to see if community develops or if it plateaus. Don't invest further.

**Revisit:** 06-23

---
*Deep read: 2026-06-09. Source: README.md + agent.py + repo structure.*
