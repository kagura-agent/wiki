# Omnigent — Meta-Harness for AI Agents

> "A common layer over Claude Code, Codex, Pi, and the agents you write yourself." — Python meta-harness for multi-agent orchestration with policies, collaboration, and cross-device sessions.

## Quick Facts
- **Repo**: omnigent-ai/omnigent
- **Stars**: 545 (3 days old, as of 2026-06-14)
- **Language**: Python 3.12+
- **License**: Apache 2.0
- **Status**: Alpha
- **Created**: 2026-06-11

## What It Does

Omnigent wraps multiple coding agent harnesses (Claude Code, Codex, Pi, custom YAML agents) under a unified layer:

1. **Multi-harness orchestration** — Run different agents (Claude Code, Codex, Pi) in the same session. Sub-agents can review each other's work cross-vendor.
2. **Cross-device sessions** — Start in terminal, continue in browser, pick up on phone. Local web UI at `localhost:6767`.
3. **Multi-user collaboration** — Share sessions, co-drive (teammate attaches to your running session), fork conversations.
4. **Policy engine** — Stackable policies (server → agent → session): approve-before-shell, tool call caps, cost budgets. Builtins + custom Python handlers.
5. **Cloud sandboxes** — Run sessions in disposable Modal/Daytona sandboxes. Managed hosts = no laptop required.
6. **Agent-as-YAML** — Define agents in short YAML: prompt + tools + sub-agents. Agents can build agents.

## Architecture Comparison with OpenClaw

| Dimension | Omnigent | OpenClaw |
|---|---|---|
| Core concept | Meta-harness (wraps CLI agents) | Gateway + plugin architecture |
| Agent definition | YAML (prompt + tools + sub-agents) | Agent config + SKILL.md + DNA |
| Multi-agent | Sub-agents in same session | ACP runtime + subagent spawning |
| Policies | Python handler functions, 3 levels | Tool policy, exec security, approval flow |
| Collaboration | Session sharing, co-drive, fork | Multi-channel (Discord/Feishu/WhatsApp) |
| Device access | Web UI + mobile | CLI + chat platforms + nodes |
| Sandboxing | Modal/Daytona containers | Sandbox exec, node isolation |
| Memory | Not explicit (session-based) | MEMORY.md + wiki + memory files |
| Identity/DNA | Not present | SOUL.md + IDENTITY.md + beliefs |

## Example Agents

- **🐙 Polly** — Multi-agent orchestrator/tech lead. Plans, delegates to coding sub-agents in parallel git worktrees, routes diffs to cross-vendor reviewers. Never codes herself. (Similar to our team-lead skill concept.)
- **🟠🔵 Debby** — Dual-headed brainstormer (Claude + GPT). Every question goes to both, answers side-by-side. `/debate` mode for convergence.

## Key Differentiators vs OpenClaw

**Omnigent advantages:**
- Native multi-user auth + collaboration (invite links, OIDC)
- Mobile-first web UI for on-the-go
- Session forking as first-class concept
- Cloud sandbox provisioning per session
- Polished "tech lead" agent pattern (Polly) as reference

**OpenClaw advantages:**
- Identity/memory/DNA system (agent personhood, not just task execution)
- Deep chat platform integration (Discord, Feishu, WhatsApp — not just web UI)
- Cron/heartbeat/scheduling for autonomous operation
- Wiki/knowledge management as persistent agent memory
- Skill ecosystem (ClawHub, skill workshop, proposals)
- ACP protocol for structured agent-to-agent communication

## Transferable Ideas

1. **Session forking** — `omnigent run --fork <session_id>` is elegant. OpenClaw could benefit from conversation branching.
2. **Cross-vendor review** — Polly's pattern (write with vendor A, review with vendor B) is formalized. We do this ad-hoc with code-review skill.
3. **Policy YAML** — Declarative per-agent/per-session policy stacking. OpenClaw's tool policy is similar but less granular per-session.
4. **Managed hosts** — Cloud sandbox provisioning per session removes the "laptop must be online" constraint.
5. **Co-drive** — Teammate attaching to your running agent session. Novel collaboration primitive.

## Market Signal

545⭐ in 3 days signals strong demand for agent unification. The "too many agent CLIs" problem is real — developers want one place to manage Claude Code + Codex + Pi rather than switching between terminals. This validates OpenClaw's multi-agent approach but from a different angle (developer-focused CLI orchestration vs personality-first agent platform).

## Links
- [[architect-loop]] — cross-vendor agent collaboration pattern
- [[OpenClaw]] — our agent platform
- [[self-evolving-agent-landscape]] — industry trends

---
*Scout: 2026-06-14 | Status: following*
