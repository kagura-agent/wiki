---
title: Hitch — Terminal Sharing for Coding Agents
created: 2026-05-29
updated: 2026-05-29
status: scout
last_verified: 2026-05-29
---

# Hitch — Terminal Sharing for Coding Agents

**Repo**: [maxktz/hitch](https://github.com/maxktz/hitch) | 77⭐ (2026-05-29, created 05-24) | Rust | MIT
**Distribution**: `npm install -g hitch-cli` + `npx skills add` ecosystem

## What It Does

Lightweight Rust PTY proxy that lets coding agents inspect and control the user's *actual* terminals. User runs `hitch`, their shell wraps in a transparent proxy. Agent gets structured commands: `context`, `send-keys`, `capture`.

Not a terminal multiplexer — the user's shell feels normal. Hitch just intercepts I/O, records output, tracks process state, and exposes an agent-friendly API.

## Architecture

### PTY Proxy + Unix Socket Server

- Forks child shell, intercepts I/O via PTY
- Unix socket for client connections (agent commands)
- Binary protocol: MSG_PUSH (input), MSG_ATTACH/DETACH, MSG_WINCH

### Structured Terminal State (Key Insight)

`CommandTracker` automatically monitors foreground process groups (`foreground_pgrp`) to detect:
- What command is actively running (`active_command`)
- When it started/finished (`command_started_at/finished_at`)
- Current working directory (`current_dir` via `/proc/{pid}/cwd`)
- Whether the shell is idle vs running a command

This transforms raw terminal bytes into **structured metadata** — agents know "npm test has been running for 12s" without parsing output.

### ANSI Filter Pipeline

- `TitleFilter`: strips or rewrites terminal title sequences (avoids polluting agent context)
- `AltScreenLogFilter`: handles alt-screen programs (vim, less) — doesn't log their output
- `AltScreenTracker`: tracks alt-screen state for context rendering

Filters run byte-by-byte through a state machine — no regex, just ANSI escape sequence parsing.

### Smart Wait Modes

`send-keys --wait` eliminates agent sleep/poll loops:
- `--wait finish` — wait until foreground command exits
- `--wait quiet:2s` — wait until output stops for 2s
- `--wait output` — wait until any new output appears
- `--wait time:5s` — fixed wait
- `--timeout 30s` — max wait cap

Returns only *new* output produced after the send. This is cleaner than our `process(action=poll)` pattern.

## Connection to Our Work

- OpenClaw already has a [[tmux]] skill and `process` tool for terminal interaction
- Hitch offers a *cleaner abstraction*: automatic process state tracking vs our manual output parsing
- The `send-keys --wait` pattern mirrors OpenClaw's `process(action=poll, timeout=...)` but with more granular modes
- The planned **per-agent read cursors** (stateful-context-idea.md) would eliminate redundant output re-reads — a real problem for our agents too
- Could potentially be integrated as an alternative terminal backend for OpenClaw's exec/process flow

## Ecosystem Position

- Competes with [[tmux]]-based agent integration (what we use)
- Complementary to [[ccglass]] (observability proxy — sees API traffic; hitch sees terminal state)
- Part of the `npx skills add` distribution ecosystem (same channel as [[adhd-divergent-ideation]])

## Verdict

Clean, focused implementation. Not revolutionary but well-executed. The **structured terminal state** pattern (process group tracking → automatic command awareness) is the main architectural takeaway. Worth monitoring if it gains traction.

**Transfer value**: The process-group-based command tracking pattern could improve our tmux skill's output parsing.

---
*First read: 2026-05-29*
