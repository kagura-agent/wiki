---
title: "Superlog — Agentic Telemetry System"
created: 2026-06-16
updated: 2026-06-16
tags: [deep-read, agent-ecosystem, observability, self-healing]
status: tracking
last_verified: 2026-06-16
revisit: 2026-06-23
---

# Superlog — Agentic Telemetry System

**Repo**: superloglabs/superlog | **Stars**: 826 (2026-06-16, created 06-02) | **License**: Apache-2.0
**Lang**: TypeScript (monorepo: Vite/React frontend, Hono API, OTLP proxy, worker/agent orchestration)
**Origin**: YC P26 batch. Founder: arseniycodes. Self-hosted + cloud edition.

## What It Does

Open-source observability workspace that ingests OpenTelemetry data (traces, logs, metrics), groups noisy signals into incidents via fingerprinting, and dispatches AI agents to investigate and fix production bugs — including opening PRs.

## Architecture

```
OTLP → Proxy (ingest+fingerprint) → Postgres+ClickHouse → Incident Grouping
  → Agent Runner (queued→repo_discovery→running→awaiting_human→complete/failed)
    → PR Delivery (branch→commit→open PR→follow-up on review feedback)
    → Slack Integration (thread-based incident comms)
    → MCP Server (expose telemetry back to any agent)
```

### Key Components

1. **Fingerprinting** (`packages/fingerprint`): SHA-256 hash of exception type + message bucket + normalized top-5 user frames. Strips `node_modules/`, `node:internal/`. Smart message bucketing prevents per-request IDs from creating duplicate incidents.

2. **Agent Run Lifecycle**: 9-state FSM — `queued → repo_discovery → running → awaiting_human → resuming → pr_retry_queued → blocked_no_github → complete → failed`. The `awaiting_human` and `resuming` states enable **"talk to investigation"** — humans can continue a completed investigation by sending messages, which reactivates the agent session.

3. **Agent Memory** (`agent-memory-tools.ts`): 4 kinds — `feedback` (lessons from human corrections), `terminology` (team-specific naming), `infra` (deployment facts), `project` (codebase structure). Project-scoped, injected into every future run's prompt. Save/update/list/archive via custom tools exposed to the agent. Max 200-char title + 4000-char body per memory.

4. **PR Delivery**: Agents produce patches → system opens PRs → on review feedback, a follow-up investigation is triggered that inherits prior context (summary, root cause, handoff notes, validation) plus the reviewer's comments. Updates the same PR branch.

5. **MCP Server**: Exposes `get_incident`, `search_incidents`, and telemetry query tools. Org-scoped tokens enforce project boundaries.

## What's Novel

- **"Talk to investigation"** (`resuming` state): Completed investigations aren't dead. Humans can send follow-up messages that reactivate the agent with full prior context. This is the "conversational debugging" pattern — not just one-shot investigation.

- **Incident-triggered vs issue-triggered**: Unlike [[gogetajob]] (which picks open GitHub issues), Superlog agents are triggered by production incidents — the telemetry itself is the work order. The agent gets stack traces, trace context, and span attributes as input, not just issue descriptions.

- **Follow-up PR loop**: When a human reviews the agent's PR, the review feedback triggers a new investigation that pushes updates to the same branch. This is a closed loop: incident → investigation → PR → review → follow-up → updated PR.

- **Project-scoped agent memory**: Simple but effective cross-run learning. Lessons from human corrections persist and improve future investigations of the same project. Similar intent to our [[beliefs-candidates]] pipeline but scoped per-project rather than globally.

## Relation to Our Direction

| Superlog Pattern | Our Equivalent | Delta |
|---|---|---|
| Agent memory (feedback/terminology/infra/project) | [[beliefs-candidates]] + wiki | Theirs is project-scoped + auto-injected; ours is global + manually referenced |
| Investigation lifecycle FSM | [[flowforge]] workflow nodes | Same pattern: state machine with human pause points |
| PR delivery + follow-up | [[gogetajob]] submit + review handling | They trigger from incidents not issues; follow-up is structural not ad-hoc |
| MCP for telemetry access | Our wiki/search.sh + tools | They expose production data; we expose knowledge base |
| "Talk to investigation" | No direct equivalent | Gap worth noting — our completed subagent runs are dead, not resumable |

**Key insight**: The "agents as SRE team members" model is different from "agents as open-source contributors." Superlog agents have much richer context (production telemetry, stack traces, span attributes) than issue-based agents. The tradeoff: they need GitHub App installation + OTLP setup (higher barrier) but produce higher-signal investigations.

## Community Health

- 52 forks, 15 open issues in 14 days
- 3 external contributors (57hemanth, Digvijay-x1, Nainish-Rai) with merged PRs
- Active daily commits from founder (arseniycodes)
- Discord + X presence
- Rating: 🟢 THRIVING (external PRs, active development, YC backing)

## Critique / Gaps

- **Single agent runtime**: The `community` runner records local summaries. Cloud edition likely uses Claude/proprietary. The pluggable backend interface is clean but no alternative open-source runner ships.
- **GitHub-centric**: `blocked_no_github` state exists because the entire fix delivery depends on GitHub App. No GitLab/Bitbucket path visible.
- **No issue auto-triage**: Issues from #68 (AI code audit dumping 23 issues) suggest the project itself could use better triage tooling.
- **Solo maintainer risk**: 20/30 PRs from arseniycodes. YC backing mitigates but doesn't eliminate.

Links: [[gogetajob]], [[flowforge]], [[beliefs-candidates]], [[agent-skill-ecosystem]], [[ccglass]], [[clawpatrol]]
