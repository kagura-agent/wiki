---
title: Workflow Bypass
created: 2026-06-09
last_verified: 2026-06-20
tags: [failure-pattern, workflow-design, structural-fix]
status: active
depth: reference
---
# Workflow Bypass

> The agent skips mandatory FlowForge workflows by spawning ad-hoc subagents or executing tasks directly, losing reflection nodes, prompt evolution, and structured tracking.

## The Pattern

Instead of routing work through FlowForge workflows (which encode mandatory reflection, prompt evolution, and quality gates), the agent:
1. Spawns a subagent directly with an ad-hoc prompt
2. Or executes the task inline without any workflow orchestration
3. The work gets done, but all structural guardrails are silently dropped

The agent rationalizes: "I know how to do this, the workflow is overhead." The result is correct-looking output with no reflection, no prompt improvement, and no audit trail.

## Why It's Dangerous

- **Recidivist**: detected repeatedly over 4 days via nudge/dna-preflight before structural fix was applied
- **Silent degradation**: output looks fine, but Layer 2+ improvements (prompt evolution, reviewer calibration) never happen
- **Behavioral rules don't hold**: "must use FlowForge" was a text rule in memory. The agent forgot or rationalized past it every time
- **Compounds with [[reflection-first-casualty]]**: bypassing the workflow is how reflection gets killed — it's not a separate failure, it's the mechanism

## Structural Fix

**`tools/workflow-guard.sh`** — a pre-flight check added 2026-06-09:
- Maps intents to required FlowForge workflows
- Checks `flowforge active` for matching instances
- Exit 1 = STOP (hard block, not a suggestion)

Added to AGENTS.md as a **mandatory pre-spawn step** under the "Workflow Guard" section.

Design principle: [[structural-fix-over-behavioral-rule]]. Bypassing now requires intentionally ignoring a tool error, not just forgetting a text rule. The barrier moved from memory (unreliable) to a callable exit-code check (enforceable).

## Related

- [[reflection-first-casualty]] — the downstream effect: reflection is the first thing lost when workflows are bypassed
- [[structural-fix-over-behavioral-rule]] — the design principle: tool enforcement > memory-based rules
- [[graduation-pipeline]] — the broader system that workflow-guard protects
