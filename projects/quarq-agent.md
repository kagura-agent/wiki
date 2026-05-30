# Quarq Agent — Evidence-Gated Memory Runtime

- **Repo**: [quarqlabs/agent-oss](https://github.com/quarqlabs/agent-oss)
- **Stars**: 180 (2026-05-30, 6 days old)
- **Language**: Python
- **Status**: active (pushed 05-29)
- **Category**: memory-first agent, competitor to Hermes/OpenClaw

## What It Is

A "recursive evidence-gated cognitive runtime" for memory-native AI agents. Explicitly positions itself as an alternative to Hermes/OpenClaw with stronger emphasis on:
- Durable local memory
- Strict attribution
- Self-correcting retrieval
- Benchmark-grade long-term recall (claims 99.6% on LongMemEval-S)

## Architecture

```
retrieve_memories → route_tools → generate_response → END
```

Key components:
- **3 memory types**: semantic facts, episodic events, procedural behavioral rules
- **FAISS-backed retrieval**: normalized OpenAI embeddings with cosine similarity
- **Hybrid search**: vector + keyword matching on every retrieval pass
- **HyDE query optimizer**: rewrites user prompt into multiple retrieval probes
- **Dynamic thresholds**: wide-net deep mode for aggregation vs strict mode for point facts
- **Required-data fallback**: model can request a second retrieval pass when evidence is missing
- **Temporal truth protocol**: separates storage time from narrative event time
- **Quantitative fidelity**: numbers stored with owner, property, item, and exactness
- **Background learning**: async memory extraction while user gets immediate response
- **Progressive tool loading**: tool docs injected only when skill is selected (addresses MCP context bloat)

## What's Interesting

1. **Evidence gating**: not just "retrieve and generate" — the model can say "I don't have enough evidence, search again" which triggers a targeted second pass. This is the self-correcting retrieval pattern.

2. **Temporal truth protocol**: explicitly separates "when was this stored" from "when did this happen". Most memory systems conflate these, causing timeline errors.

3. **Quantitative fidelity**: numbers are attributed to specific entities with exactness tracking. Prevents the common failure of "nearby number contamination" in RAG.

4. **Progressive tool loading**: same insight as Claude Code's deferred tool loading — don't inject all tool schemas into context. Only load when relevant.

## Comparison to Our Approach

| Aspect | Quarq | OpenClaw/Kagura |
|--------|-------|-----------------|
| Memory storage | Local FAISS | Git-backed markdown + memex |
| Memory types | 3 explicit types | Organic (daily logs, wiki, beliefs) |
| Retrieval | Hybrid vector+keyword+HyDE | Hybrid semantic+keyword (memex) |
| Self-correction | Evidence-gated fallback | Manual re-search |
| Temporal | Explicit protocol | Implicit via file dates |
| Learning | Async background | Post-turn hooks (nudge) |

## Deep Read Findings (05-30)

### Code Quality Assessment
- **Single-file architecture**: All core logic in `agent.py` (~2100+ lines). No modular separation.
- **No unit tests**: Only LongMemEval-S evaluation scripts. No test coverage for individual components.
- **No issues filed yet**: Too new for community criticism.
- **Version archaeology**: `agent_v1.py`, `agent_v2.py`, `agent_v3.py` exist alongside `agent.py` — suggests rapid iteration without cleanup.
- **Hardcoded models**: `gpt-4o-mini` for retrieval, `gpt-4.1` for generation/learning. No model abstraction.

### REQUIRED_DATA Protocol (the most interesting pattern)
The generation prompt includes an elaborate protocol where the LLM outputs structured JSON:
```json
{"agent_response": "...", "flags": ["REQUIRED_DATA"], "hyde_queries": ["..."]}
```
When REQUIRED_DATA flag is set, the system generates HyDE queries and does a second retrieval pass. This is essentially **LLM-driven retrieval self-correction** — the model recognizes its own knowledge gaps and requests specific follow-up searches.

Key design details:
- Extremely detailed prompting (~200 lines of rules) to prevent hallucination from "nearby" but wrong evidence
- Explicit rules against cross-contamination between different entities/storylines
- Entity-preservation rules to never drop proper nouns

### Memory Learning (Background Extraction)
- Fire-and-forget async tasks with semaphore (max 4 concurrent)
- Semantic extraction: atomic facts about user identity/preferences
- Episodic extraction: conversation events with entity preservation
- Procedural extraction: behavioral rules
- Each type has detailed prompts guiding what to extract vs ignore

### Honest Assessment
- The 99.6% LongMemEval-S claim is **unverifiable** — checkpoint shows only a cursor, no results
- The architecture is straightforward LangGraph + FAISS, not novel
- The real innovation is in the **prompting discipline** — extremely detailed rules preventing common RAG failure modes
- No community, no issues, no tests — high risk of abandonware
- **Worth watching for**: the REQUIRED_DATA pattern and the failure mode taxonomy in their prompts

## Takeaways

1. **Evidence-gated retrieval (REQUIRED_DATA fallback)**: Worth considering for memex. The pattern of LLM recognizing "I don't have enough evidence" and generating targeted follow-up queries is powerful. Could implement as a memex search mode.
2. **Temporal truth protocol**: A real gap in our system — we rely on file dates but don't explicitly track "when did this happen" vs "when was this recorded".
3. **Failure mode taxonomy**: Their prompt catalogs specific RAG failures (cross-entity contamination, nearby-number pollution, temporal confusion). This taxonomy is useful even without adopting their architecture.
4. **Progressive tool loading**: Aligns with MCP context bloat problem. OpenClaw already does lazy tool loading but the pattern is validated.
5. **Single-file monolith warning**: 2100+ lines in one file = will become unmaintainable. Architecture doesn't scale.

## Links

- [[self-evolving-agent-landscape]]
- [[agent-memory-taxonomy]]
- [[git-backed-agent-memory]]
- [[retrieval-is-the-bottleneck]]
