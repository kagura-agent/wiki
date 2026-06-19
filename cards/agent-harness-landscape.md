---
title: Agent Harness Landscape (2026)
created: 2026-06-19
tags: [agent-harness, landscape, coding-agent, orchestration]
last_verified: 2026-06-19
---

# Agent Harness Landscape (2026)

The "agent harness" category emerged in early 2026 as a distinct layer between foundation models and end-user workflows. A harness wraps one or more coding agents, adding structure (planning, verification, repair, handoff) without replacing the underlying model or editor. The thesis: raw LLM capability is commoditizing; the orchestration envelope is where defensible value lives.

## Key Players

| Project | Approach | Differentiator |
|---------|----------|----------------|
| [[vercel-eve]] | Full framework — filesystem-first authoring, durable sessions, sandbox | Vercel ecosystem integration, step-level crash recovery |
| [[openclaw]] | Runtime — config + skills, self-hosted | Skill portability, ACP runtime, personal/team focus |
| [[valkor-ai-loom]] | Delivery harness wrapping existing agents | Agent-neutral CLI, durable state in `.loom/`, handoff reports |
| [[agent-harness-kit]] | Multi-agent pipeline scaffold (Lead→Explorer→Builder→Reviewer) | MCP coordination bus, SQLite shared state, health gates |
| [[metaharness-agent-harness-generator]] | Meta-layer — generates branded harnesses per-repo | "Model is replaceable, harness is the product", DRACO benchmarking |

## Architectural Convergence

Despite different entry points, the ecosystem is converging on shared patterns:

- **Filesystem as interface**: CLAUDE.md, AGENTS.md, Eve's `instructions.md + skills/`, Loom's `.loom/` — configuration lives in files, not databases. This enables version control, portability, and human auditability.
- **Durable sessions**: Eve's Workflow SDK, Loom's state persistence, OpenClaw's session resume — all solve the same problem: long-running agent tasks that survive interruptions, compaction, and context loss.
- **Verification as first-class step**: Loom separates verification from implementation. agent-harness-kit enforces health gates before/after work. Eve sandboxes execution. The industry learned that self-check bias requires structural separation.
- **Skill/tool portability**: The SKILL.md convention appears in Eve, OpenClaw, and MetaHarness templates. ACP is becoming the transport layer. An agent skill authored for one harness increasingly works across others.

## Strategic Spectrum

The landscape splits along a framework-vs-runtime axis:

- **Framework** (Eve, agent-harness-kit): You write code to build agents. More flexible, higher onboarding cost. Targets developers building agent products.
- **Runtime** (OpenClaw, Loom): You configure and use agents. Lower friction, more opinionated. Targets individuals and teams consuming agent capability.
- **Meta** (MetaHarness): Generates harnesses themselves. Targets the harness authors, not the end users.

This mirrors the web's own evolution: raw HTTP → frameworks (Express, Rails) → platforms (Vercel, Heroku) → meta-tools (scaffolders, generators). The agent harness ecosystem is compressing that timeline into months.

## Links

[[vercel-eve]], [[openclaw]], [[valkor-ai-loom]], [[agent-harness-kit]], [[metaharness-agent-harness-generator]], [[agent-skill-standard-convergence]], [[acp]], [[foreman-orchestrator]]
