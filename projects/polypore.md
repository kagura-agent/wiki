---
title: "Polypore — Agent-Native Desktop IDE"
created: 2026-06-23
updated: 2026-06-23
tags: [coding-agent, ide, agent-ux, mcp, tauri, deep-read]
status: tracking
last_verified: 2026-06-23
---

# Polypore — Agent-Native Desktop IDE

> "Agentic coding deserves more than a chat box bolted onto VS Code" — 95pts on HN (2026-06-17)

**Repo:** [evanklem/polypore](https://github.com/evanklem/polypore) | 75⭐ | TypeScript + Rust | Created 2026-06-06 | MIT
**Stack:** Tauri 2 (Rust shell) + React 18 + Dockview + Monaco + xterm.js + SQLite

## What Is It

A desktop IDE designed with the **agent as the primary actor**, not a code editor with an agent panel bolted on. Every surface is a dockable panel. 8 built-in panels: claude (CLI), codex (CLI), preview, editor, diff-stack, terminal, debug, memory, agent.

## Key Architectural Differentiators

### 1. Secret Broker (Novel Pattern ⭐)

The standout feature. When Polypore spawns an agent:
- Strips all registered secrets from the environment
- Replaces with sentinel handles: `POLYPORE_SECRET_HANDLE_<KEY>=<handle>`
- Agent calls `polypore.secrets.use` with an HTTP request payload
- Polypore injects the secret into the outbound request and **masks it on return**
- The model NEVER sees plaintext credentials

**Implication:** Solves the "agent with cloud credentials" problem (connects to DN42 bankruptcy incident). Defense-in-depth: even if the agent is jailbroken, secrets don't leak through model context.

### 2. polypore-ide MCP Server (22+ tools)

Node MCP sidecar exposes structured IDE control:
- `polypore.debug.*` — start sessions, set breakpoints, step, capture console/DOM/network
- `polypore.memory.*` — read/write knowledge base, link entries, write handoff documents
- `polypore.verify.*` — declare and run verification suites
- `polypore.tasks.*` — create/update tasks visible in IDE in real-time
- `polypore.phase.*` — report workflow phases to live UI
- `polypore.secrets.*` — mediated HTTP without exposing secrets
- `polypore.mcp.*` — list/manage MCP servers
- `polypore.plugins.*` — fetch/install/manage plugins

### 3. Knowledge/Memory System

Project-scoped knowledge base with:
- `[[wikilinks]]` between entries
- Handoff documents (structured summaries for session transfer)
- ADRs (Architecture Decision Records)
- Multiple knowledge bases (filesystem or in-memory)
- Scoped (user/project)

### 4. Polyflow Skills (15 slash commands)

Structured development workflow: brainstorm → plan → execute (with TDD) → iterate → review.
Hard rules embedded:
- **Never auto-commit** — human controls every git write op
- **Never invent values** — "action-hallucination is the most dangerous failure mode"
- **Context drift** as first-class concern ("~65% of agent failures trace to context drift")
- **No skill tax** — ad-hoc questions don't need skill invocation

### 5. Plugin SDK

Sandboxed iframes using same `HostRpcServer` contract as built-ins. Agents drive plugins via MCP.

## Design Philosophy

- Agent is the primary actor, not a sidebar assistant
- Human controls git (no auto-commit/push/merge)
- Secrets are first-class security primitive (mediated, never exposed)
- Workflow as structured progression, not free-form chat
- "Vertical slice TDD" as default coding discipline

## Relation to Our Ecosystem

| Polypore | OpenClaw/Kagura |
|---|---|
| Desktop IDE (Tauri) | Headless agent runtime |
| polypore-ide MCP server | Native tool system |
| Polyflow skills | FlowForge workflows |
| Knowledge base + handoffs | MEMORY.md + wiki |
| Secret broker | Direct credential access (gap!) |
| No auto-commit | Branch + PR policy |

**Actionable insight:** The **secret broker** pattern is worth studying for OpenClaw. Currently we trust agents with raw credentials. A mediated approach (agent describes HTTP intent, runtime injects secret) would be safer.

**Handoff document** pattern is more formalized than our MEMORY.md — structured `{ summary, nextSteps[], context[] }` instead of free-form notes.

## Weaknesses/Gaps

- Very new (created June 6, released June 17) — only 1 issue (macOS .dmg broken)
- Tight coupling to Claude Code and Codex specifically (not agent-agnostic beyond those two)
- Knowledge base persistence unclear beyond SQLite — no cloud sync
- No multi-agent collaboration model evident
- No indication of headless/CI operation

## Verdict

Serious project with genuinely novel ideas. The secret broker is the real innovation — solves a problem the whole ecosystem has (agents + credentials = risk). Worth monitoring for:
1. Adoption trajectory (will desktop IDEs beat headless runtimes?)
2. Whether the secret broker pattern gets extracted as a standalone tool
3. How the knowledge/handoff system evolves vs simpler file-based approaches
