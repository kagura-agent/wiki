---
title: OneWill / Wally — WAL for Agent Actions
created: 2026-07-02
last_verified: 2026-07-02
---
# OneWill / Wally — WAL for Agent Actions

> Database write-ahead logging architecture applied to agent action management. System-level interposition (FUSE + VPN/MITM) provides undo/redo for agent actions without modifying the agent itself.

- **Authors**: Wan Lim, Will Zhang (CMU DB background)
- **Reviewed by**: Andy Pavlo (CMU Databaseologist)
- **Status**: Public demo available, open-source coming
- **URL**: https://onewill.ai/blog/2026/stealing-50-years-of-database-ideas-for-ai-agents/

## Core Thesis

The binary choice between "babysit with approval-in-the-loop" vs "YOLO auto mode" is broken. Database systems solved analogous problems 50 years ago — apply WAL (Write-Ahead Logging) to agent actions: record recovery metadata **before** an action's effects persist. Either the action is reversible (proceed automatically) or irreversible (require explicit approval).

## Three-Tier Action Classification

This is the novel framework — classifying actions by their reversibility:

| Type | Example | Agent Strategy |
|------|---------|---------------|
| **Perfectly Reversible** | Git-tracked file edit | Auto-execute, WAL records undo |
| **Compensable** | Calendar event (can cancel, can't unsend invite) | Execute, WAL records compensating action |
| **Irreversible** | Email send, API mutation | Block until human approval |

Key insight: most existing agent safety is binary (allow/deny). This adds a middle tier — compensable actions can proceed with recorded rollback capability.

## Architecture: System-Level Interposition

The breakthrough design decision: interpose at the **world** level, not the **agent** level.

- **FUSE**: Filesystem interposition — every file read/write goes through the WAL layer
- **VPN/MITM**: Network interposition — API calls captured and classified
- **Frame buffers**: UI interposition for computer-use agents
- **No agent modification**: Works with any agent (Claude Code, Codex, etc.) as drop-in

Contrast with existing approaches:
- Agent-side permissions ([[openclaw]] tool policy) — requires agent cooperation
- Network firewalls ([[clawpatrol]]) — network-only, no filesystem coverage
- Sandboxing (code-airlock, Docker) — nuclear option, "blow away entire system" rollback
- Session-level WAL ([[write-ahead-session-persistence]]) — much narrower (crash recovery for session messages, not action-level undo)

## Relevance to Our Direction

1. **OpenClaw's approval flow** treats `ls` and `rm -rf` in the same UX — OneWill's article specifically calls this out as a design flaw. Their action classification would let reversible actions auto-proceed while blocking irreversible ones.

2. **The interposition point matters**: OpenClaw controls at the agent-tool boundary. OneWill controls at the OS-system boundary. Complementary layers. Defense in depth.

3. **"Speculative agent work vs durable world mutations"** — this framing is powerful. Long-running agents (hours/days) need the ability to accumulate speculative work that can be reviewed/committed as a batch, not just individual tool approvals.

4. **Compensating actions** concept extends beyond crash recovery — it's a design principle for any system that lets agents touch real state. "You can cancel the meeting but you can't unsend the invite" is a useful mental model for API-level permissions.

## Prediction

- They'll open-source core WAL primitives within 2-3 months (they said "coming weeks")
- The three-tier action classification will become an industry pattern — it's cleaner than binary allow/deny
- FUSE-based interposition will hit performance issues at scale (filesystem overhead) but the concept will be adopted at higher levels of abstraction

## See Also
- [[write-ahead-session-persistence]] — nanobot's narrower WAL (session messages, not actions)
- [[clawpatrol]] — Deno's agent security firewall (network-level MITM, similar interposition philosophy)
- [[agent-trust-hierarchy]] — Trust model for agent actions
- [[openclaw]] — Agent-side tool permissions
