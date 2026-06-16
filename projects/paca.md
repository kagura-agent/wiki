---
title: Paca — AI-Native Project Management
status: tracking
created: 2026-06-16
updated: 2026-06-16
revisit: 2026-06-23
stars: 928
repo: Paca-AI/paca
tags: [project-management, scrum, ai-collaboration, mcp, openhands]
last_verified: 2026-06-16
---

# Paca — AI-Native Project Management

> "Jira gives you a backlog. Paca gives your AI agents a seat at the table."

Open-source, self-hosted Scrum platform where AI agents and humans are **equal teammates** — same board, same sprints, same process. 928⭐, Apache-2.0, created 2026-03-20.

## Why It Matters

Most agent-PM integrations bolt a chatbot onto existing tools. Paca inverts this: agents are **first-class Scrum participants** who pick up tasks, write BDD specs, contribute to system design docs, and appear on the Scrumban board alongside humans. This is the [[collaboration-bottleneck]] solution taken seriously — not "AI assists humans" but "AI and humans share a process."

## Architecture (clean, well-documented)

| Service | Stack | Role |
|---|---|---|
| `services/api` | Go (Gin) | Business logic, persistence, event publishing |
| `services/realtime` | Node.js (Socket.IO) | Real-time delivery via Valkey Streams |
| `services/ai-agent` | Python (FastAPI + [[openhands]] SDK) | Agent orchestration, Docker sandbox per agent |
| `apps/web` | React (TanStack Start, shadcn/ui) | UI |
| `apps/mcp` | TypeScript | MCP server with dynamic plugin tool loading |

**Boundary rule**: API owns state, realtime only delivers, ai-agent executes but never writes DB directly. Clean separation.

**Data bus**: Valkey Streams between services. Agent triggers via `paca:agent:triggers`, conversation events via `paca:agent:events`.

## Key Technical Decisions

1. **WASM plugin sandbox** — Backend plugins compile to WebAssembly (Go/Rust/AssemblyScript), run in wazero with capability-based permissions. More secure than JS-based plugin systems. Frontend plugins are standard module bundles.
2. **OpenHands SDK for agent isolation** — Each agent conversation spawns its own Docker container. No shared filesystem. Contrast with our subagent model (shared workspace, JS isolation).
3. **MCP as integration layer** — `@paca-ai/paca-mcp` npm package. Plugin tools registered at runtime. Both user-mode and agent-mode with scoped identity.
4. **Skills distribution** — Ships Claude Code skills (paca, paca-breakdown, paca-clarify, paca-do, paca-doc, paca-epic, paca-estimate, paca-prioritize, paca-setup, paca-sprint, paca-test). This is the SKILL.md format as distribution — similar to [[agentskills-io-standard]].
5. **P-A-C-A cycle** — Plan → Act → Check → Adapt. Explicit formalization of Scrum + scientific method. Similar to our [[flowforge]] but at the project management level.

## Community & Health

- **Solo dev risk**: pikann has 726/866 commits (~84%). Copilot is #2 with 137. Essentially a one-person project with AI assistance.
- **Responsive maintainer**: Issues closed within 24hrs, feature requests acknowledged immediately. 0 open issues.
- **Growth**: 838→928⭐ in 1 day (HN front page effect). 50 forks. Created March 2026.
- **HN reception** (168pts, 60 comments): Positive. People compare to hand-rolled solutions, validate the "agents as team members" model. Key comment: "Where does Jira really sit in a world eaten up by vibecoding?"

## Relevance to Us

**Direct relevance**: Medium. We don't use Scrum/project boards, but the framing is instructive.

**Insights worth internalizing**:
1. **"Same board" framing** is powerful — agents that share the same process/UI as humans feel more like teammates than tools. Our [[team-lead]] skill does something similar but at the GitHub Issue level, not a dedicated PM tool.
2. **WASM plugin sandbox** is more secure than our JS/shell skill system. If OpenClaw ever needs plugin isolation, WASM is the proven path.
3. **Skills-as-distribution** — shipping Claude Code skills alongside the MCP server is a smart distribution strategy. Makes the tool instantly usable from Claude Code without MCP setup.
4. **Docker-per-agent isolation** (via OpenHands) is heavy but secure. Trade-off vs. our lightweight subagent approach.

**What we wouldn't adopt**:
- Full Scrum process overhead — our [[flowforge]] workflows are lighter and don't require a separate UI.
- OpenHands dependency — adds Docker-in-Docker complexity.

## Tradeoffs & Concerns

- Solo dev = bus factor 1. If pikann loses interest, project stalls.
- Phase 1 just completed; Phase 2/3 have RBAC, observability, scaling — basic enterprise features still missing.
- OpenHands SDK is a significant dependency (large, Python, Docker-heavy).
- "0 open issues" can mean great triage or can mean low outside contribution.

## Links

- [[collaboration-bottleneck]] — Paca's direct answer to turn-based AI interfaces
- [[agent-human-collaboration-product]] — agent as teammate, not tool
- [[centaur-loop]] — related human-governed AI feedback loop concept
- [[agentskills-io-standard]] — skill distribution via SKILL.md
- [[flowforge]] — our lighter workflow approach vs. Paca's full PM
