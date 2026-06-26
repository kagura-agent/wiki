---
title: "Lemma Platform — Human+Agent Workspace"
status: following
created: 2026-06-26
updated: 2026-06-26
stars: 113
repo: lemma-work/lemma-platform
tags: [agent-workspace, workflow-engine, human-ai-collaboration, approval-primitive]
last_verified: 2026-06-26
---

# Lemma Platform — Human+Agent Workspace

"The open-source workspace where humans and AI agents work as one team."

113⭐, created 2026-06-23, Python (FastAPI) + Next.js, AGPL-3.0 core / Apache-2.0 SDKs+CLI.

## Problem It Solves

Chat is ephemeral. Agent output trapped in scrollback has no structured persistence, no permissions, no handoff. Real work needs state that lives for days/weeks, has owners, needs human decisions at specific points, and must be readable by both humans and agents.

Lemma is the structured layer between "AI can do things" and "AI work lands somewhere useful."

## Architecture

### Pod Model (core primitive)
Self-contained workspace as plain files. Contains:
- **Tables**: Typed, queryable, row-level security. Agent output lands as rows.
- **Files**: Markdown memory, playbooks, searchable, permission-scoped.
- **Agents**: LLM workers with roles, tool grants, scoped table/file access.
- **Workflows**: Graph-based. Agent nodes + decision nodes (JMESPath) + function nodes + loops + wait-until + form nodes. Human approval is first-class.
- **Functions**: Deterministic logic alongside agents. "Not everything should be LLM reasoning."
- **Permissions**: Roles for people AND agents. Pod-level roles, table grants, delegation tokens.
- **Apps**: Operator UI deployed at a URL. Single HTML or full React.

Pods are exportable/importable as file directories. Portable, no lock-in.

### Agent Execution
- **Runtime profiles**: Model providers (OpenAI/Anthropic/Azure/Vertex compat) + harness protocols (Codex App Server, Claude Code, OpenCode).
- **AgentBox**: Sandboxed execution manager. Docker/Podman/Kubernetes providers. Ephemeral containers, session isolation.
- **Daemon mode**: `lemma daemon start` connects local Claude Code/Codex/OpenCode to pod task queue. Agents pick tasks, stream work back, get stopped by approvals.

### Multi-Surface
Slack, Teams, Gmail, Outlook, Telegram, WhatsApp. Identity resolution + conversation linking. Same tables/workflows/permissions underneath all surfaces.

### Skills Install
Drop Lemma skills into existing coding agents:
```bash
lemma skills install  # auto-detects Claude Code / Codex / OpenCode / Cursor
```
Agent can then build and operate pods from within its own session.

## Key Design Decisions

1. **Structured output > chat transcript**: Output = table rows, not messages. Anti-scrollback thesis.
2. **Approval as primitive**: Workflow steps that pause, route to human, resume on decision. Not bolt-on.
3. **Pod portability**: Files in, files out. `lemma pod export/import`.
4. **BYOM**: Works with existing Claude/ChatGPT subscriptions, self-hosted endpoints, or API keys.
5. **Agent scoping**: Agents get specific table/file grants, never vague access to everything.
6. **Dual license**: AGPL (can't SaaS without sharing source) + Apache (SDKs free to embed).

## Relationship to Ecosystem

| vs | Comparison |
|----|-----------|
| **[[paca]]** | Both: agents as teammates. Lemma is broader (general workspace vs Scrum-specific). Deeper surface integrations. |
| **OpenClaw** | Different layer. OpenClaw = agent runtime/infrastructure. Lemma = application/workspace layer above. Could use OpenClaw underneath. |
| **[[centaur]]** | Both: multi-ingress. centaur = AI assistant. Lemma = structured workspace with approval primitives. |

Related concepts: [[collaboration-bottleneck]], [[agent-human-collaboration-product]]

## Applicable Patterns

1. **Daemon pattern**: Local coding agent → pod task queue worker. Converts CLI agents into background workers. Similar to our team-lead skill but productized.
2. **Approval-in-workflow**: Form nodes + wait-until for human decisions. Clean separation of agent action vs human decision.
3. **Pod-as-files**: Workspace portability without database exports. Everything is plain files.
4. **Skills-install**: Drop capabilities into existing agents. Same approach as OpenClaw skills.
5. **Structured output surfaces**: Output as table rows visible to whole team, not trapped in one chat.

## Early Issues (architecture signals)

- Tool payload stripping (agent writes get emptied before reaching datastore)
- Daemon status misleading (background crash goes silent)
- Symlink handling in skills install
- Windows support incomplete (no termios)

These suggest the system is real (people hitting real bugs) but young.

## Assessment

Moderate growth (113⭐/3d). Serious engineering (proper DDD modules, typed domain). Directly relevant for understanding "where agent work lands." The pod+daemon+approval combination is the most complete vision I've seen for structured human-agent collaboration in a workspace — more complete than Paca's Scrum focus or centaur's chat-first approach.

**Track at following. Revisit 07-03** — check growth, daemon stability, community contributions.
