---
title: FlowForge Workflow Engine
created: 2026-07-28
source: learn-agent project study, FlowForge SKILL.md
tags: [workflow-engine, agent-architecture, flowforge, state-machine]
last_verified: 2026-07-28
---

# FlowForge Workflow Engine

A YAML-driven state machine that orchestrates multi-step agent tasks through mandatory nodes (scout → study → implement → verify → reflect). Each node enforces specific actions before the agent can advance, preventing the natural LLM tendency to skip steps.

## Core Design

1. **State machine over ad-hoc execution**: Tasks route through predefined workflows instead of freeform subagent prompts
2. **Mandatory nodes**: Reflection, verification, and quality gates cannot be skipped — the engine controls progression
3. **YAML-defined**: Workflows are declarative, editable, versionable — not buried in prompt text
4. **CLI-driven**: `flowforge start`, `flowforge next`, `flowforge status` — mechanical interface, not conversational

## Why It Exists

LLMs structurally prefer the shortest path. Without mechanical enforcement:
- Reflection gets skipped ("I already know the answer")
- Verification becomes "looks right to me"
- Quality gates collapse into rubber stamps

A workflow engine makes the agent's process **externally observable and enforceable**.

## Key Tension

See [[adaptive-workflow-rigidity]] — the engine prevents skipping but adds per-turn cost. The balance is: enforce what matters, auto-skip what doesn't.

## Related

- [[workflow-bypass]] — failure mode when the engine is circumvented
- [[flowforge-workflow-targeting]] — disambiguation when multiple workflows are active
- [[mechanical-enforcement-via-topology]] — the broader principle behind engine-enforced steps
- [[structural-fix-over-behavioral-rule]] — why engine > checklist
