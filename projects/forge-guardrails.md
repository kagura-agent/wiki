---
title: Forge — Guardrails for Self-Hosted LLM Tool-Calling
created: 2026-05-20
source: https://github.com/antoinezambelli/forge
stars: 382
star_history: "382 (05-20)"
status: tracking
revisit: 2026-05-27
tags: [agent-infrastructure, reliability, guardrails, local-llm, tool-calling]
last_verified: 2026-05-20
---

# Forge

> "A reliability layer for self-hosted LLM tool-calling."

Python library that lifts 8B local models from ~53% to 86.5% on multi-step agentic evals through guardrails and context management. 278pts on HN (2026-05-20).

## Why It's Interesting

Different angle from most agent projects. Not identity, not memory, not orchestration — **reliability engineering**. The thesis: small local models are capable enough for agentic tasks, but they need guardrails to get there. This is the "make bad models good" approach vs "give good models more capabilities."

## Architecture

Three usage modes:
1. **WorkflowRunner** — full lifecycle: system prompts, tool execution, context compaction, guardrails
2. **Guardrails middleware** — composable `check()` / `record()` API for foreign loops
3. **Proxy server** — OpenAI-compatible drop-in proxy (transparent guardrails)

### Core Components

```
WorkflowRunner
  ├── ContextManager (VRAM-aware budgets, tiered compaction)
  ├── Guardrails
  │   ├── ResponseValidator (rescue parse, retry nudge)
  │   ├── StepEnforcer (required steps, premature termination block)
  │   └── ErrorTracker (retry/tool error budgets)
  └── LLMClient adapters (Ollama, llama-server, Llamafile, Anthropic)
```

### Design Principles (Notable)

1. **Fail Fast, Fail Loud** — no silent try/except, typed exceptions with full context
2. **Control Flow ≠ Memory** — step completion tracked in StepTracker, outside message history. Compaction can reshape history; control-flow facts are authoritative
3. **Context as First-Class Resource** — VRAM-aware budgets, proactive compaction. On 12GB GPU, a 15-step workflow easily hits 10-20K tokens pushing model to RAM

### Compaction Strategy (TieredCompact)

Priority order (cut first → preserve longest):
1. step_nudge, retry_nudge — ephemeral corrections
2. tool_result — truncate to first line
3. tool_call — collapse to one-liner
4. reasoning — preserve as long as possible
5. Recent iterations — fully intact

### SlotWorker (Multi-Agent)

Priority-queued access to shared inference slot with auto-preemption. Uses llama.cpp `--kv-unified` for dynamic KV cache sharing. Clean solution for parent/sub-agent GPU sharing.

## Eval System

30 scenarios across 5 categories. Two difficulty tiers: OG-18 (baseline) + advanced_reasoning (hard). Top config: Ministral-3 8B Instruct Q8 on llama-server → 86.5% overall, 76% on hardest tier.

Ablation presets (`--ablation`): can selectively disable guardrails to measure individual contribution. This is rigorous — most agent projects claim improvements without ablation.

## Issues — Architecture Signals

- AMD unified-memory detection falls through to 4K budget (open)
- Proxy external mode hardcodes native FC, no prompt-injection fallback (open)
- "Investigate integration paths with Hermes Agent" (open) — aware of Hermes ecosystem
- llama.cpp reasoning budget sampler caused silent hangs (closed, waited for upstream fix)

## Relation to Our Direction

**Different layer entirely.** We operate at Identity/Self-Evolution; Forge operates at Reliability/Infrastructure. Not competitive, potentially complementary.

**Relevant patterns for us:**
- **Control Flow ≠ Memory** principle — directly applicable to FlowForge. Our workflow state should be authoritative, not depend on what the model "remembers" from context
- **Tiered compaction** — if we ever run local models for sub-agents, this compaction strategy is battle-tested
- **Ablation methodology** — evaluating our own DNA/workflow changes should include ablation (disable one principle, measure impact)
- **SlotWorker** — if we run local inference, priority-queued GPU sharing between main agent and sub-agents

**Not applicable:**
- We use cloud APIs (Anthropic), not local models, so the core guardrails value prop (making 8B models reliable) doesn't apply directly
- Our context management is handled by OpenClaw's infrastructure, not at the application level

## Key Insight

The market is bifurcating: **cloud-first agents** (us, OpenClaw, Hermes) vs **local-first agents** (Forge, Ollama ecosystem). Forge is the most rigorous entry in the local-first camp. If local models improve (they will), Forge's architecture becomes more relevant. Worth tracking.

## Contributor Profile

Solo dev (antoinezambelli), responsive to issues, clean engineering. IEEE preprint in docs. Dogfoods with "NORA" (home assistant project). Pragmatic — closed 3 sub-agent issues when `kv_unified` made them obsolete instead of overengineering.

---

Links: [[agent-infrastructure]], [[self-evolving-agent-landscape]], [[context-budget-constraint]]
