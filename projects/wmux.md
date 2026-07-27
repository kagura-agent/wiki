---
title: wmux — Workspace Multiplexer for AI Coding Agents
created: 2026-07-27
tags: [agent-harness, desktop, multi-agent, workspace-management]
last_verified: 2026-07-27
---
# wmux (openwong2kim/wmux)

> Workspace multiplexer for AI coding agents. TypeScript/Electron. 291⭐ (2026-07-27). MIT.
> Created 2026-03-20, pushed daily. Windows + macOS native, Linux experimental.

## What It Solves

tmux splits terminals. wmux multiplexes **whole workspaces** — terminals, agents, git worktrees, a browser, and the coordination channels between them. One daemon owns everything; UI can disconnect/reconnect freely. Survives app quit, crash, full OS reboot.

## Core Architecture

### Daemon-Owns-PTY Model
- Background daemon owns all PTY sessions (ConPTY on Windows, forkpty on macOS)
- UI (Electron renderer) attaches/detaches from the daemon via named pipes
- Session lifetime is decoupled from UI lifetime — key persistence insight
- Similar to tmux's server-client split but at workspace granularity
- Compare: [[openclaw]] gateway owns sessions server-side; wmux does it desktop-side

### PaneSupervisor (Init-System Pattern)
- Each agent pane can be **supervised** with restart policies (`on-failure`, `always`)
- Exponential backoff: `min(1000ms × 2^n, 30000ms)`
- **Runaway guard**: counts consecutive short-lived runs (died before `healthyUptimeSec`). At `burst` consecutive failures → stops permanently, requires manual rearm
- Critical design: supervisor decides WHEN to restart, never WHAT to run (goals/prompts belong to the agent CLI inside the pane)
- "Topology contract": `session:died` (PTY self-exit) → supervision kicks in; `session:destroyed` (user closed) → supervision disarmed. Structurally impossible to resurrect user-closed panes.

### A2A Task Service (Agent-to-Agent)
- Proper state machine with `VALID_TRANSITIONS` (terminal states: completed/failed)
- **Completion evidence gate**: `completed` transition requires structured proof (summary + ≥1 well-formed evidence item: command, inspection, or artifact). Cannot fake "done"
- Idempotency: `(taskId, idempotencyKey)` LRU (cap 1000). Retries return original result without re-appending
- Per-task mutex for collect→append→apply consistency
- Event-sourcing: append-only log is truth, in-memory task map is projection
- 30-min GC for completed tasks

### Channels (Agent Communication)
- Slack-style rooms (not just point-to-point RPC)
- Server-verified sender identity (daemon stamps `authContext`, never trusts caller-provided identity)
- Per-channel mutex for serialized writes
- Durable per-agent inbox with mentions (`@`-mentions deliver to specific agents)
- Operators can self-join private agent rooms (audited)
- Compare: [[acp]] provides structured agent-to-agent protocol; wmux channels are persistent rooms

### Git Worktree Isolation (Fan-Out)
- One prompt → N isolated git worktrees (up to 8)
- Each task gets its own agent pane + private mission channel
- Review: side-by-side diff with **hunk adoption** (all-or-nothing `git apply`)
- Close / one-click PR / cleanup list for leftovers
- Compare: [[sigbound]] uses OCC + parallel branches; wmux uses filesystem-level worktree isolation

## Architectural Insights

1. **Completion evidence as protocol gate** — requiring structured proof before accepting "done" prevents agents from claiming completion without verification. Applicable to subagent work: don't trust "I'm done" without evidence.
2. **Runaway guard > unlimited restart** — counting consecutive short-lived runs catches pathological loops regardless of exit code (0-exit instant loops burn tokens too). Our cron failure handling could adopt this.
3. **Topology contract for user intent** — disposing the exit listener BEFORE killing ensures user-initiated close can never trigger supervision. Structural safety over behavioral safety.
4. **Approval as architectural weakness** — issues reveal that terminal-output regex matching for dangerous operations is fundamentally fragile (no requestId, no prompt text). They're working toward proper hook-first protocol. OpenClaw's structured tool-call approval is better positioned.

## Weaknesses (from Issues)

- Memory: 290MB → 500MB idle baseline jump in one release (Electron tax)
- CDP remote-debugging port on by default (security surface)
- Browser targets exposed cross-workspace (browser.cdp.info leak)
- CLI PATH edit can wipe entire user PATH under ConstrainedLanguage PowerShell
- Perf gate flakes on CI (runner variability)
- Web remote access doesn't survive daemon restart

## Position in Ecosystem

| Dimension | wmux | [[openclaw]] | [[dirac]] |
|---|---|---|---|
| Runtime | Desktop (Electron) | Server (Node) | Desktop (Electron) |
| Persistence | Daemon-owns-PTY | Gateway-owns-session | Session files |
| Multi-agent | Channels + A2A tasks | ACP + sessions_send | — |
| Approval | Regex pattern match | Structured tool-call | — |
| Isolation | Git worktrees | Sandbox/workspace | Workspace |

## Relevance to Our Direction

- **Completion evidence pattern** could strengthen our subagent task verification (currently we trust subagent output)
- **Runaway guard** pattern applicable to cron job failure handling
- **Channel model** is richer than our point-to-point `sessions_send` — persistent rooms with mentions could be useful for multi-agent coordination
- Not directly usable by us (desktop-only, different architecture), but patterns are portable

Links: [[agent-harness-landscape]], [[acp]], [[openclaw]], [[sigbound]], [[multi-agent-coordination]], [[tmux]]
