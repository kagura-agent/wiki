# Skill Compilation — From Natural Language to Specialized Harness

> Pattern: after a natural-language skill runs enough times, compile the stable/deterministic parts into code, keeping LLM calls only where semantic judgment is needed. Result: 94% token reduction, 87% latency reduction.

**Source**: [Vivek Haldar](https://vivekhaldar.com/articles/compiling-an-ai-agent-skill/) (2026-07-12) + [Token Shrinker](https://tokenshrinker.com/)
**Related**: [[harness-engineering-openai]], [[taco-context-compression]], [[flowforge]]

## Core Idea

Natural language skills are great for **discovery** (figuring out what the workflow should be). But after many runs, most of the workflow crystallizes — it always does the same thing. At that point, paying a frontier model to re-discover the same plan every run is wasteful.

**The compilation process:**
1. Express workflow as natural-language skill
2. Run it repeatedly, gather execution traces
3. Identify which steps are deterministic (always same) vs need LLM (semantic judgment)
4. Move deterministic parts to code (Python/shell/etc.)
5. Keep LLM calls at the 2-3 points requiring actual intelligence

**Result**: skill becomes a "thin bootloader" that invokes a program. Program handles fetching, filtering, state management. LLM handles selection and generation only.

## Why Model Vendors Won't Push This

Key insight: reducing token consumption by 94% goes directly against the business model of companies whose revenue rises with token usage. It's up to users and independent builders to find these optimizations.

> "It's very hard to convince someone of something when their salary depends on not understanding it."

## Relation to Our Work

**FlowForge is already partially compiled:**
- Workflow nodes are code (bash scripts, tools) + LLM calls at decision points
- `study-saturation.sh`, `dna-preflight.sh`, `spam-filter.sh` — these are all "compiled" steps that don't need LLM
- But the agent loop itself (reading node instructions, making decisions) is still LLM-driven

**Opportunity**: identify which FlowForge nodes have fully crystallized and could become pure code:
- Saturation gate → already a bash script ✓
- Followup tracking → mostly code, LLM only for signal assessment
- Scout spam filter → already code ✓
- Note-writing → still needs LLM (semantic generation)

**Difference from TACO**: TACO compresses output (less tokens in context). Skill compilation removes entire LLM calls (no tokens at all for those steps). Complementary approaches.

**Token Shrinker prompt**: a meta-tool that analyzes your skill traces and produces compiled versions. Could apply to our own workflows.

## Anti-Pattern Warning

Premature compilation is premature optimization. The article emphasizes: you need enough traces first. A skill that's still evolving (changing criteria, new edge cases) should stay in natural language until it stabilizes.

Links: [[flowforge]], [[taco-context-compression]], [[harness-engineering-openai]], [[agent-harness-landscape]], [[tokenomics-paper]]
