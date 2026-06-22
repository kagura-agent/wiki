---
title: "Anthropic launch-your-agent — CMA Reference Skill"
created: 2026-06-22
updated: 2026-06-22
stars: 363
repo: anthropics/launch-your-agent
status: reference-implementation
last_verified: 2026-06-22
---

# launch-your-agent (Anthropic)

Official reference Claude Code skill from Anthropic that guides a technical founder through building a **Claude Managed Agent (CMA)** in a single pairing session. 4 phases: Interview → Stage & Launch → Grade & Iterate → Schedule.

- **Repo**: [anthropics/launch-your-agent](https://github.com/anthropics/launch-your-agent)
- **Created**: 2026-06-16, 363⭐, 76 forks (as of 06-22)
- **Language**: HTML (overview template) + Markdown (skill + references)
- **Status**: Reference implementation, not maintained, not accepting contributions

## What It Teaches

### 1. CMA Architecture (Brain / Hands / Session)

Anthropic's own framing of their hosted agent harness:
- **Brain** = Agent primitive (model + system prompt + tools + skills + MCP servers)
- **Hands** = Environment primitive (sandboxed Linux container, packages, networking)
- **Session** = Persistent event log, one running instance

Core primitives: Agent (versioned) → Environment → Session → Events. Minimal launch is 4 API calls.

### 2. Outcome Grader (the "definition of done" loop)

`user.define_outcome` event type bakes DoD into the protocol:
- Rubric is markdown with binary per-criterion checks
- Grader runs in **separate context window** (isolated from agent's own reasoning)
- Results: satisfied / needs_revision / max_iterations_reached / failed
- Default 3 iterations, max 20

This is infrastructure-level verification — conceptually similar to [[flowforge]]'s terminal-node checks but at the platform layer. The isolation (separate context) is a design choice we don't have.

### 3. Skill Structure as Gold Standard

The repo IS the canonical example of a production Claude Code skill:
```
.claude/skills/launch-your-agent/
  SKILL.md (comprehensive, 400+ lines)
  references/
    cma-api.md (verified curl shapes)
    interview.md (interview-to-primitive mapping)
    examples-bank.md (archetypes)
    mock-connectors.md (connector mocking patterns)
    overview-template.html (visual artifact)
    build-sheet.example.json (config schema)
```

Key patterns: references/ directory for verified docs, explicit voice/tone section in SKILL.md, "ground rules" for behavior constraints, fallback ladder (4 rungs from retry → Console UI → archetype config → local fallback).

### 4. Scheduled Deployments (native cron)

`POST /v1/deployments` with cron expression + timezone. Each firing creates a new session. `initial_events` are replayed verbatim (must use relative dates). Manual `run` endpoint for testing. Up to 1000/org.

Directly comparable to [[openclaw]]'s cron system but baked into the managed platform.

### 5. Memory Stores (cross-session persistence)

Workspace-scoped text doc collections, mounted at `/mnt/memory/`. Limits: 100KB/memory, 2000/store, 8 stores/session. Plus "Dreams" (async memory reorganization job — research preview). Compare to our daily memory files + MEMORY.md distillation.

### 6. Interview-to-Config Mapping

8 question clusters that map founder answers directly to CMA primitives. Key principle: "start from defaults, build what the job needs" — no gatekeeping primitives, scope into versions (v0/v1/v2). Echoes our [[ponytail-yagni-skill]] ladder.

## Architectural Observations

| CMA Primitive | OpenClaw Equivalent | Gap/Difference |
|---|---|---|
| Agent (versioned config) | agent config (YAML) | CMA versions automatically, we use git |
| Environment (container) | workspace + host OS | CMA is sandboxed/isolated per-session |
| Session | session | Equivalent |
| Outcome (grader) | FlowForge verify nodes | CMA grader is isolated; ours is same-context |
| Scheduled Deployment | cron jobs | Equivalent functionality |
| Memory Store | memory/*.md + MEMORY.md | CMA has size limits, ours is unbounded |
| Vault | pass + sops | CMA handles OAuth refresh automatically |
| Skills | .claude/skills/ ≈ OpenClaw skills | Same pattern, different packaging |
| Dreams | daily-review + study reflect | CMA automates memory consolidation |

## Key Insights

1. **Isolated grader pattern**: Putting the evaluator in a separate context window from the executor prevents self-justification. Our goal-drift-check is Jaccard-based (zero LLM cost) but lacks semantic depth. An isolated LLM grader with structured rubric would be more powerful for complex tasks.

2. **"Not maintained" reference implementations**: Anthropic publishes skills as reference code, not living projects. The value is in the patterns and API documentation, not ongoing development.

3. **Connector mocking pattern**: Default is mock in v0, real connector in v1. The outbox pattern (schema-true payloads without actual delivery) is good for development velocity — same as our Discord/messaging testing patterns.

4. **Overview page as living schema**: The HTML overview page isn't documentation — it's a visual state machine showing trigger → worker → output with live IDs. Architecture diagrams that auto-update from actual config.

## Relevance

- **Skill quality benchmark**: Best available example of what Anthropic considers a production-quality Claude Code skill. Reference for [[skill-creator]] and [[clawhub]] quality standards.
- **CMA is the hosted competitor**: For users who don't need self-hosting, CMA offers a simpler path. OpenClaw's advantages: self-hosted control, multi-model, multi-channel, unrestricted tools.
- **Outcome grader idea**: Could inspire a `flowforge verify --isolated` mode that uses a separate LLM call to grade task completion against a rubric.

## Predictions

None checkable this round — reference implementation, won't grow or change.
