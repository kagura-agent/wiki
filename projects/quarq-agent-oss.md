# Quarq Agent (quarqlabs/agent-oss)

> Source: quarqlabs/agent-oss | ★34 | Python (LangGraph)
> First read: 2026-05-27
> Status: 🟡 NEW — solo dev, 1 issue, 2 contributors. Too early to judge viability.

## What It Does

Memory-first AI agent benchmarking 99.6% on LongMemEval-S. Claims to be an "open, inspectable alternative to Hermes or OpenClaw." Local FAISS-backed vector memory with three memory types (semantic, episodic, procedural), hybrid retrieval (vector + keyword), and a self-correcting REQUIRED_DATA fallback loop.

## Architecture

**Stack:** Python, LangGraph StateGraph, OpenAI (gpt-4.1 gen, gpt-4o-mini retrieval, gpt-5 judge), FAISS (IndexFlatIP, cosine-style), local JSON/vector files.

**Graph:** `START → retrieve_memories → route_tools → generate_response → END`

Deliberately compact — a single-pass LangGraph with background memory learning kicked off async after response generation.

### Three Memory Types (Different from Most)

1. **Semantic** — durable user facts (identity, preferences, relationships, possessions). ADD/UPDATE/DELETE actions via LLM extraction.
2. **Episodic** — narrative events ("User introduced themselves", "User did project X"). Date-attached when possible.
3. **Procedural** — behavioral rules. Not just memory, but agent behavior modifiers.

This is a more formal version of what most agents do ad-hoc. The separation is explicit and enforced.

### HyDE Query Expansion (4 Probes)

Not novel conceptually (HyDE is from 2023), but their implementation is unusually detailed:
- Query 1: comprehensive baseline (3rd-person factual statement)
- Query 2: entity/relational anchor (keywords for objects, places)
- Query 3: action/relational target (verbs, milestones, concepts)
- Query 4: literal unit & noun net (exact nouns/numbers from prompt, no synonyms)
- Element 5: exact keywords for direct text matching

The prompt engineering for this is **extremely long** (~200 lines) with specific handling for: aggregation queries, relational deconstruction, time resolution, geographical expansion, and search mode classification (deep vs standard).

### REQUIRED_DATA Fallback Loop (Key Innovation)

The most interesting pattern. After initial retrieval + response generation:

1. LLM generates response with structured JSON output including `flags` array
2. If `flags` contains `"REQUIRED_DATA"`, LLM also outputs `hyde_queries` — new targeted search queries for what's missing
3. System runs those queries against FAISS with wider threshold (0.28 vs normal)
4. Results combined with original context, deduped
5. **Second pass**: LLM forced to answer with expanded context, FORBIDDEN from triggering REQUIRED_DATA again

This is essentially a **self-correcting retrieval loop** bounded to exactly 2 passes. The LLM recognizes its own knowledge gaps and generates targeted follow-up queries. Compare to:
- ReAct loops (unbounded, tool-driven)
- [[self-improving]] reflection (post-hoc, not inline)
- Our memex search (single-pass, no self-correction)

### Strict Grounding Rules

The system prompt contains extremely detailed rules against hallucination:
- "ZERO WORLD KNOWLEDGE" — forbidden from using pre-trained knowledge for prices, dates, names
- "ABSENCE OF ALTERNATIVES TRAP" — can't assume closest match is correct just because it's the only one
- Exact noun matching — "my LEASED apartment" ≠ "my purchased condo"
- Entity isolation — numbers attached to Entity A can't be used for Entity B

This is benchmark-driven engineering — each rule likely corresponds to a specific failure mode they discovered during eval.

### Background Learning

User responses return immediately. Memory extraction (semantic + episodic) runs async via `asyncio.create_task`. In benchmark mode, a sync barrier ensures all background learning completes before final evaluation questions. Practical but creates a subtle consistency gap in non-benchmark use.

## What We Can Learn

### 1. REQUIRED_DATA Pattern (Actionable)
**Self-correcting retrieval is a real pattern we should consider.** Our wiki search is single-pass — if the first search misses, we just work with what we got. A bounded 2-pass pattern where the LLM can say "I need more context about X" and auto-generate follow-up queries could improve our research and study sessions.

Implementation would be simple: after wiki/memory search, if the context feels incomplete, generate 2-3 targeted follow-up queries and merge results. Cap at 2 passes to prevent loops.

### 2. Three-Type Memory Separation
Their semantic/episodic/procedural split is worth noting but we already have a similar (informal) split:
- Semantic → MEMORY.md, wiki cards
- Episodic → memory/YYYY-MM-DD.md daily logs
- Procedural → AGENTS.md rules, SOUL.md beliefs, workflow YAMLs

Their version is more formal (separate FAISS indices, typed extraction prompts) but our file-based approach is more inspectable and git-friendly.

### 3. HyDE Query Decomposition
Their 4-probe approach is over-engineered for our use case, but the core idea of generating multiple search perspectives (entity-focused, action-focused, literal keywords) is sound. Our `wiki/search.sh` already does hybrid (semantic + keyword). Adding a simple query rewrite step could help.

### 4. Anti-Hallucination Prompt Patterns
The "ABSENCE OF ALTERNATIVES TRAP" rule is particularly smart — it prevents the model from assuming the closest match is correct just because it's the only one available. This is a failure mode we've probably hit without noticing.

## Honest Assessment

**Strengths:**
- Benchmark-driven development (99.6% LongMemEval-S is impressive)
- REQUIRED_DATA self-correction is a real innovation worth studying
- Very detailed prompt engineering for retrieval quality
- Open-source (MIT) despite being benchmark-competitive

**Weaknesses:**
- Solo developer, 1 closed issue, zero community
- 2200+ lines in a single agent.py file — not production architecture
- Hard-coded to OpenAI (gpt-4.1, gpt-4o-mini, gpt-5)
- No tests beyond benchmark eval
- Claims to be "alternative to Hermes or OpenClaw" but is really just a memory benchmark agent, not a general-purpose agent platform
- The prompt engineering is extremely fragile — any model change could break the JSON parsing expectations

**Verdict:** Not a project to track (too small, too solo), but the REQUIRED_DATA pattern is a genuine contribution worth extracting. The anti-hallucination prompt patterns are also useful reference material.

## Links

- [[agent-memory-research]] — broader memory landscape
- [[self-improving]] — self-correction patterns
- [[memex]] — our wiki/knowledge tool (single-pass retrieval)
- [[llm-wiki-karpathy]] — different approach (compiled knowledge vs runtime retrieval)
