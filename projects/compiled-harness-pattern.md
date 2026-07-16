# Compiled Harness Pattern

**Discovered:** 2026-07-16 (scout, via HN)
**Source:** https://vivekhaldar.com/articles/compiling-an-ai-agent-skill/
**Author:** Vivek Haldar (Enchiridion Labs)

## Concept

"Compiling" a natural-language agent skill into a specialized harness that mixes deterministic code with targeted LLM calls. The workflow:

1. **Express** the workflow as natural-language instructions (Agent Skill)
2. **Run** it many times, gather traces, refine behavior
3. **Identify** parts that have crystallized (stable, deterministic)
4. **Compile** those parts into code
5. **Keep LLM calls** only at points requiring semantic judgment

## The Example

A daily workflow: scan blog backlog → check recency → draft LinkedIn post. Original: pure natural-language skill, agent plans from scratch every run. After compilation: deterministic file scanning, dedup check, state management — LLM only for candidate selection and draft writing. **Result: 94% token reduction, same output quality.**

## Why It Matters

This is the **optimization economics of agent workflows**: spend once to analyze traces and compile, amortize over hundreds of runs. The analogy to compiler optimization passes is deliberate — a JIT for agent skills.

## Key Insight: Incentive Misalignment

Model vendors sell tokens. A technique that preserves quality while cutting 94% of token usage goes against their business model. This creates space for independent builders: specialized harness compilers, trace analyzers, workflow optimizers.

## Relevance to Us

**FlowForge is already a partial version of this.** Our YAML workflows + subagent delegation are a manual compilation of recurring processes. But we haven't done the "trace → identify crystallized parts → code them" loop. Specifically:

- Our study workflow runs ~6x/day. The saturation checks, preflight, and mode selection are already "compiled" (bash scripts). But the scout/deep-read/note steps are still fully LLM-driven.
- Our workloop has similar structure: the repo selection and issue scanning could be partially deterministic.

**Actionable:** After accumulating more study traces, analyze which steps are truly crystallized and could be scripted. The saturation-gate.sh and followup-status.sh scripts are examples of this pattern already applied.

## Position in Ecosystem

Part of the "efficiency layer" trend: not making models better, but making agent *usage* of models smarter. Adjacent to [[taco-context-compression]] (reduce input tokens), prompt caching (reduce cost per token), and [[agent-harness-landscape]] (orchestration as value layer).

## Links

- [[agent-harness-landscape]] — this pattern applies to any recurring harness workflow
- [[taco-context-compression]] — complementary: compress input vs. eliminate unnecessary calls
