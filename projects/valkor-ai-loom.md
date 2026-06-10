---
title: "Valkor AI Loom — Delivery Harness for Coding Agents"
created: 2026-06-10
updated: 2026-06-10
tags: [agent-orchestration, delivery, coding-agent, harness]
status: following
stars: 105
last_verified: 2026-06-10
---

# Valkor AI Loom — Delivery Harness for Coding Agents

**Repo**: valkor-ai/loom | **Stars**: 105 (1 day old) | **License**: Apache-2.0 | **Language**: TypeScript

## What It Is

An open delivery harness that wraps existing coding agents (Claude Code, Codex, OpenCode, OpenClaw, Cline, Cursor Agent) and turns them into "repeatable software delivery systems." Does NOT replace the model/editor — adds a structured loop around them.

## Core Concept

Loom persists delivery state in `.loom/` directory and exposes an agent-neutral CLI. The delivery loop:
**planning → building → verification → repair → preview → handoff**

Key architectural choices:
- **Dynamic workflows** to choose delivery path per goal
- **Durable state** that survives interruptions, compaction, adapter switches
- **Verification as first-class step** (separate from implementation)
- **Repair routing** — explicit recovery from failures
- **Handoff reports** — human-readable evidence of what was done

## Failure Modes Addressed

| Failure | Loom Response |
|---|---|
| Partial completion | Bounded tasks, explicit result files, continue routing |
| Goal drift | Confirmed scope, architecture contracts, task plans |
| Self-check bias | Review/verification/repair requests separate from implementation |
| Token waste | Project summaries, task graphs, reduced re-reads |
| Handoff gaps | Delivery reports, preview checks, logs, repair history |

## Comparison to Our Stack

| Aspect | Loom | FlowForge + OpenClaw |
|---|---|---|
| Scope | Per-project delivery | Per-agent workflow |
| State | `.loom/` in project | FlowForge instance state |
| Agent coupling | Agent-neutral CLI | OpenClaw native |
| Focus | Code delivery pipeline | General agent orchestration |
| Verification | Built-in step | Workflow node |

**Key difference**: Loom is project-centric (lives in the repo), FlowForge is agent-centric (lives in the agent workspace). Loom assumes you want one agent to deliver one feature; FlowForge assumes you want an agent to coordinate multiple tasks across contexts.

**Interesting overlap**: Both solve "coding agents lose context and drift" with durable state + structured loops. The delivery harness pattern is converging.

## Why It Matters

- 105⭐ in 1 day signals demand for the "delivery layer" above raw coding agents
- Validates our thesis: raw coding agents are necessary but not sufficient
- The `.loom/` state approach is similar to how [[openclaw]] uses workspace files for continuity
- Positioned as the "CI/CD for agentic work" — a logical next layer

## Ecosystem Position

Sits in the same space as [[guard-skills]] (verification), our [[flowforge]] (orchestration), and the broader "agent reliability" trend. This is the **delivery phase** of the agent ecosystem — post-generation, pre-production.

## Links

- [[flowforge]] — our workflow orchestration (agent-centric)
- [[guard-skills]] — quality gates for AI-generated code
- [[agent-ecosystem-scout-2026-06-08]] — ecosystem consolidation context
