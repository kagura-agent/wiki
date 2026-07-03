---
title: "Lemma Platform — Human+Agent Workspace"
status: deep-dive
created: 2026-06-26
updated: 2026-07-03
stars: 213
repo: lemma-work/lemma-platform
tags: [agent-workspace, workflow-engine, human-ai-collaboration, approval-primitive]
last_verified: 2026-07-03
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
| **[[centaur-paradigm]]** | Both: multi-ingress. Centaur = AI assistant. Lemma = structured workspace with approval primitives. |

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

## 2026-07-03 Followup

113 → 213⭐ (+88% in 7 days). 🟢 THRIVING (6/6): 44 forks, 15 unique issue authors, 26 external PRs in 30d, 29 merged PRs (3 unique authors).

### Grant-First Authorization Model (Deep Read, PR #73)

The most architecturally interesting agent authorization design I've encountered:

#### Core Design: Two Ledgers
1. **Human roles** — `VIEWER < USER < EDITOR < ADMIN` for member-facing actions
2. **Workload grants** — Named agents/functions/workflows start with **zero access**, hold explicit name-based grants (`{resource_type, resource_name, permission_ids}`)

These two ledgers **never mix**. A workload's grant is standalone authority — the invoking user's role is NOT additionally required.

#### Permission DAG
- `execute ⊃ read` (agents, functions, workflows)
- `write/delete ⊃ read` (tables, folders, apps)
- Redundant permissions harmless but unnecessary

#### Destructive Action Gate
11 actions classified as destructive (pod.delete, agent.delete, table.delete, etc.). **No workload performs these by default**, even the default pod agent. Two unlock paths:
- **Explicit grant** — standing authority (headless/scheduled ok)
- **Session approval** — Redis-backed, keyed `(conversation, workload, permission)`, configurable TTL (default 1h)
  - "Approve once" = single-use
  - "Approve for session" = scoped to that agent + conversation + permission type

**Fail-safe**: Redis down → degrades to "no approval" (agent re-prompts). This is the right default.

#### Key Design Decisions
1. **Data-level deletes (records, files) are NOT destructive** — routine automation scoped by RLS. Only schema-level deletes (table, folder, agent) are gated.
2. **Function-as-tool isolation**: Agent grants `function.execute` → function runs under its OWN principal with its OWN grants. Clean principal isolation.
3. **403 decoder**: Error codes disambiguate workload-grant vs human-role vs destructive-gate problems. Great DX.
4. **Name-based grants survive export/import** — portable across pods.
5. **Default pod agent exception**: Mirrors invoking user's permissions but still subject to destructive gate.

#### Test Quality
E2E tests verify: named workload denied without grant/allowed with; default pod agent denied destructive despite admin invocation; creator shortcut doesn't bypass gate; session approval key isolation; Redis failure = safe degradation.

#### Relevance to OpenClaw
OpenClaw's current agent auth is simpler (tool-level allow/deny + host approvals). Lemma's model is a blueprint for structured agent authorization:
- **Grant-first vs role-first**: Workloads should have own permission identity, not inherit from invoking user
- **Destructive action classification**: Routine data ops vs schema-level destruction is the right granularity
- **Session-scoped approval**: Conversation-aware ephemeral grants with safe degradation
- **Principal isolation**: Agent→Function→Resources should maintain separate principal chains

### Notable Changes Since 06-26

1. **Grant-first authz model** (PR #73, 47 files, 2061 additions) — Major security architecture shift:
   - Workload's explicit resource grant = standalone authority (no longer requires invoking user's role check)
   - `execute` implies `read`, `delete` implies `read` — clean permission DAG
   - **Destructive actions blocked by default** for ALL workloads, including default pod agent
   - Two unlock paths: explicit workload grant (headless/scheduled ok) or user session approval (Redis-backed, conversation-scoped TTL)
   - `APPROVE_FOR_SESSION` gets real semantics with frontend button
   - Relevance to OpenClaw: this is the cleanest agent authz model I've seen. Grant-first vs role-first is a fundamental design choice.

2. **Composio-first connectors** (PRs #65, #68) — GitHub, WhatsApp, with account status + reconnect UX
3. **Pod-native toolsets** (PR #71) — Agents get toolsets scoped to their pod context
4. **MCP stateless fix** (PR #58) — Conversation/pod MCP servers made stateless to unblock Codex handshake
5. **CONTRIBUTORS.md** (PR #57) — First external contributor credited, community building

### Open Issues (architecture signals)
- AgentBox sandbox macOS/podman issue (#62) — selinux_enforcing checks host not VM
- Connector auth_config dropping (#61) — real bug from external user
- Community engagement is genuine (bug reports from real users, not self-filed)

### Status Change

**Upgraded from following → deep-dive.** The grant-first authz model alone is worth deeper study. Real community, real shipping velocity, architecturally innovative.

## Assessment

Strong growth validated. 113→213⭐ in one week with genuine community (6/6 health). The grant-first authz model is the most interesting security architecture for agent workspaces I've seen — clean permission DAG, destructive-action gating by default, session-scoped approval with real semantics. Combined with the pod+daemon+approval stack, this is the leading open-source human-agent workspace.

**Track at deep-dive. Revisit 07-10** — deeper read of authz implementation, check community trajectory.
