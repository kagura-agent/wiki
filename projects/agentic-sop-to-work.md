---
title: "agentic-sop-to-work — Deterministic SOP-to-Workflow Engine"
created: 2026-06-15
updated: 2026-06-15
tags: [deep-dive, workflow, agent-safety, claude-code-plugin]
tracking: scout
stars: 178
last_verified: 2026-06-15
---

# agentic-sop-to-work

**Repo**: s0912758806p/agentic-sop-to-work | 178⭐ (06-15, 6 days old) | MIT | Python
**Author**: Taiwanese dev (Traditional Chinese docs), solo maintainer
**What**: Claude Code plugin that converts human SOPs into deterministic, gated agentic workflows. A methodology + portable toolkit, not a chatbot.

## Core Architecture

Three-phase pipeline:
1. **Human SOP** → documented procedure (fixed template, unknowns marked `【待補】`)
2. **Decompose** → N single-tool skills (one tool per skill, explicit deps, parameterized I/O)
3. **Orchestrate** → `flow.json` + `run.py` (deterministic engine, zero LLM in control flow)

### Engine (lib/)

The engine is **completely LLM-free**. The model fills tool outputs but never decides control flow.

- **flow.py**: Forward-only branching with code-decided predicates. Operator whitelist (`== != < > in exists`). No loops possible — structural safety guarantee.
- **engine.py**: Step executor + map_over (per-item iteration, fail-loud). Mutations need explicit `--allow-mutations` flag.
- **gates.py**: Pure deterministic validation functions, no side effects:
  - `cmd_gate` — exit code check
  - `schema_gate` — required fields validation
  - `trace_gate` — **anti-fabrication**: values must be verbatim traceable to input sources
  - `recompute_gate` — numerical re-derivation (sum/count with float tolerance)
- **kit.py**: Artifact system (`{schema, produced_by, data, trace}`) — structured I/O with provenance chain

### Safety Philosophy

Blocks four predictable LLM failures:
1. **Fabrication** → facts only from inputs; gaps marked `【待補】`, never invented
2. **Fake autonomy** → deterministic work in code; gates hermetic & LLM-free
3. **Unaccountable output** → everything is DRAFT; human approval required
4. **Mega-agent rot** → audit skill + Stop-hook regression gate on every change

### Plugin Integration (Claude Code)

- Two auto-trigger skills: `agentic-sop` (methodology entry point) + `agentic-workflow-audit` (read-only auditor)
- Stop-hook: runs project regression tests on every Claude stop. Capped retry loop (`SOPKIT_MAX_FIX_RETRIES`, default 3) — exhausted → stop for human
- SessionStart hook: dep-check at conversation start
- Project-scoped: no-op in projects that haven't adopted the kit

## Key Insights

### trace_gate is the most novel concept
Forces every output value to be verbatim traceable to input sources. This is **anti-hallucination at the data level**, not the prompt level. The gate checks `artifact.trace[]` entries against output values — if a value can't be traced back, it's flagged as potential fabrication. We don't have anything like this in [[flowforge]].

### Comparison with [[flowforge]]

| Aspect | agentic-sop-to-work | FlowForge |
|---|---|---|
| Scope | Claude Code plugin, project-scoped | OpenClaw agent workflow engine |
| Control flow | Forward-only branch, map | Named nodes with arbitrary next |
| Gates | 4 deterministic gate types | Manual checks in node tasks |
| LLM role | Engine is LLM-free | Agent executes each node task |
| Artifact passing | JSON with trace provenance | Node-to-node via prompt context |
| Anti-fabrication | trace_gate | Not explicit |
| Auto-fix | Capped retry on gate failure | Not explicit |
| Target | Teams building regulated workflows | Single agent self-management |

### What validates our direction
- Deterministic orchestration with human gates > free-form agent autonomy — we're already on this path
- Single-tool-per-skill decomposition mirrors our skill design
- Forward-only branching is a safety feature we might want to consider

### What we could learn
- **trace_gate pattern**: Adaptable for subagent verification — when a subagent claims an action, verify the output traces to inputs. Connects to our "verify subagent external operation claims" gradient.
- **Capped auto-fix loop**: More structured than our manual branching. Gate→fix→re-verify with hard retry limit.
- **Stop-hook continuous regression**: Every conversation pause triggers regression tests. This is CI during the conversation, not just at the end.

## Assessment

- 178⭐ in 6 days — strong traction for a niche Claude Code plugin
- Zero issues/PRs — very new, no community pressure-testing yet
- Well-architected: clean separation, comprehensive integration tests, stdlib-only (test_no_third_party.py enforces this)
- **Main novelty**: trace_gate anti-fabrication + Stop-hook continuous regression
- **Limitation**: Python-only, Claude Code-only. No multi-agent support. The "workflow" is a single-session conversation flow.
- **Risk**: Solo maintainer, no community yet. Could stall.

## Ecosystem Position

Part of the emerging "agent discipline" category alongside [[fable-mode]], [[architect-loop]], [[ponytail-yagni-skill]]. But where those are prompt-level behavioral constraints, this is **structural enforcement** — the engine physically prevents the LLM from deciding control flow or fabricating data. Closest to [[skelm]]'s approach (secure workflow framework) but more focused on the SOP→workflow conversion pipeline.
