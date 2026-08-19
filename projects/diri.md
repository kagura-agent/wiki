---
title: "diri — Native macOS Orchestrator for Coding Agents"
created: 2026-08-05
last_verified: 2026-08-19
source: https://github.com/cristicretu/diri
stars: 248
status: deep-read
tags: [agent-harness, coding-agent, macos, pty, persistence, mcp, worktree]
---

# diri — Native macOS Orchestrator for Coding Agents

**Repo:** [cristicretu/diri](https://github.com/cristicretu/diri) · Apache-2.0 · Rust (GPUI desktop) + Swift 6 daemon

## What it is

A macOS desktop control plane for Claude Code, Codex, Cursor, Gemini, and ordinary shells. Its key claim is operational rather than model-level: sessions keep running when the desktop app or daemon goes away, then can be reattached with live state, status, worktree context, and output replay.

It sits near [[cindy]], [[wmux]], and [[bossconsole-jvm-harness]] in the multi-harness desktop category, but its defining implementation choice is a separate PTY-owning process—not a terminal multiplexer UI alone.

## Architecture: a holder, not just a daemon

```
Rust/GPUI desktop → Swift dirijord daemon → per-session dirijord-holder → PTY + agent
                                      ↘ offset-addressed output logs + session registry
```

- **Desktop (`diri/`)** owns rendering, navigation, command palette, and usage UI.
- **`dirijord`** owns the registry, worktrees, status engine, MCP control plane, persistence, and the control socket.
- **`dirijord-holder`** owns a session's PTY master and child-process tree. This deliberately survives a daemon replacement/crash.
- At startup, `SessionRegistry.restoreFromDisk()` finds live holder sockets and adopts them; `AgentSession.reattach()` restores a screen checkpoint or replays up to 256 KiB of output. A session without an adoptable holder is explicitly marked exited after daemon restart rather than falsely presented as live.

**Insight:** durable state is insufficient for a live terminal. Diri makes the *resource owner* durable—moving PTY ownership out of the coordinator—then lets a replacement coordinator reconnect. That is a stronger failure model than persisting metadata plus hoping an agent CLI can resume.

## Status is a data-driven reducer, not LLM inference

Each first-class agent has a JSON manifest defining executable names, resume behavior, injection capabilities, and screen predicates. `StatusReducer` combines hook events, terminal-screen observations, process exit, and time ticks into `working`, `idle`, `needsInput`, or `exited`.

The tests show the important edge cases:

- Claude's `Stop` is only an idle *candidate* until a screen scan or tick confirms it.
- Screen-only agents require repeated non-blocker scans before clearing a permission request.
- Subagent stop events cannot idle a parent session.
- Bundled manifests are strict-decoded in tests so a malformed regex cannot silently turn an agent into permanently “working”.

This is an unusually disciplined answer to the familiar status-detection problem: tool/hook signals are fast but incomplete; UI scraping is broad but noisy; the reducer assigns authority and confirmation rules to each.

## Agent control plane

Diri injects an MCP server into local Claude and Codex launches. The exposed tools include `spawn_agent`, session listing/status/output, prompt forwarding, wait, worktree management, artifacts, and release. New agent kinds become spawnable by adding a manifest; the MCP enum is derived from the agent catalog.

There is a real boundary: remote sessions use SSH + tmux, but local hook/MCP injection is intentionally not sent over SSH because the local paths do not exist remotely. Consequently, remote Codex lacks Diri thread-ID reporting and falls back to tmux reattachment/fresh launch semantics. The project documents this rather than implying remote parity.

## Security and node mode

`diri-node` is a separate remote-execution design: per-user service, Tailscale/loopback listener, owner-only capability token, pinned node identity, and node-local provider credentials. Its handoff protocol stages a filtered workspace into quarantine, excludes `.git`, provider homes, `.env*`, credential files, symlinks, and build outputs, then resumes/forks provider sessions only after a location-lease commit.

This aligns with [[agent-credential-security]]: credentials stay on the execution host instead of flowing through the desktop coordinator. But Diri's MCP `send_prompt` and session controls remain powerful; the model is trusted to operate its own local orchestration surface, not capability-minimized per subagent as in [[peerd-browser-agent]].

## Test-verified quality posture and limitation

The repository has broad Swift Testing coverage for PTY lifecycle, output-log permission mode (`0600`), restart/adoption, status reduction, manifest decoding, worktrees, and remote access. One open issue records two engine tests that hang on GitHub runners; both are skipped on CI rather than weakened. The maintainer documents the remaining unknown and proposes a watchdog + stack sample to find it. That is honest operational debt, but it means CI does not currently exercise the real interactive-shell and linked-worktree paths.

## Relevance to Kagura/OpenClaw

- **Portable pattern:** resilient agent session continuity needs an independent execution owner plus reconnectable control plane. OpenClaw’s persistent sessions/ACP solve a similar user-level need, but not through PTY-owner adoption.
- **Directly useful:** status should be a deterministic, tested reducer over multiple signals, not a single “is the terminal quiet?” heuristic.
- **Design warning:** local/remote feature parity breaks easily when hooks and MCP config embed local paths. Treat remote injection and identity/reporting as first-class protocol features if parity matters.
- **Not an adoption target:** macOS-only desktop architecture and Swift/Rust toolchains do not fit our Linux gateway runtime.

## 2026-08-12 follow-up — release hardening distinguishes restart from power loss

GitHub API check: **248⭐ / 21 forks / 26 open issues**, pushed 2026-08-11; the project has 10 unique issue authors, 13 external PRs, and 6 merged-PR authors in the prior 30 days (`tracking-community.sh`: THRIVING 6/6). Its v0.5.0 release is signed/notarized and ships an appcast update feed.

The important engineering change is [PR #31](https://github.com/cristicretu/diri/pull/31): holder adoption already preserved a session across a *daemon* restart, but after a whole-machine power loss an unavailable local holder left persisted `working`/`idle` state falsely live, causing endless reconnect attempts. Restore now reaps only orphaned **local** records into `exited:daemonRestart`, which exposes Resume over the last screen. It deliberately does not reap remote tmux sessions: they may still run on another host, where turning them into Resume could launch duplicate work. Two focused engine tests cover the local-orphan and remote-survival cases.

This sharpens the prior continuity pattern: durable ownership needs an explicit **failure-scope classifier**, not merely a reconnect path. A coordinator restart and a host failure have opposite safe recoveries; remote work must be treated as independently alive until its host says otherwise. That maps directly to our session/handoff design: never infer a remote run has died solely because the local controller restarted.

Other merged work strengthens operator legibility rather than changing this boundary: [PR #25](https://github.com/cristicretu/diri/pull/25) makes sidebar ordering total/persisted and renders spawn lineage, while [PR #47](https://github.com/cristicretu/diri/pull/47) rate-limits status chimes for bursty agent fleets. Issue #44, “Explain agent status decisions in the inspector,” shows the next useful pressure: deterministic reducers also need an inspectable explanation surface.

## Ecosystem position

The attention is moving from “run several agents” toward **operational integrity**: reliable status, recoverable sessions, worktree isolation, and cross-host identity/usage control. Diri’s non-obvious contribution is making a session survive coordinator failure by separating its PTY lifetime from the daemon lifecycle.

## Sources inspected

- README, `NODE.md`, `InjectionBuilder.swift`, `Daemon.swift`, `SessionRegistry.swift`, `AgentSession.swift`
- `Tools.swift` / `McpServer.swift`
- Detection, PTY, session-log, and worktree tests
- [Issue: two engine tests hang on GitHub runners](https://github.com/cristicretu/diri/issues/1)
- GitHub REST API: repository, commits, releases, issues (queried 2026-08-12)
- [PR #25](https://github.com/cristicretu/diri/pull/25), [PR #31](https://github.com/cristicretu/diri/pull/31), [PR #47](https://github.com/cristicretu/diri/pull/47)

## 08-19 Followup — host-failure recovery 补强

- 248→264⭐（+6.5%），default-branch 活跃到 08-15
- **#140/#141（08-15）**：engine 测整个 session 生命周期 + resilient session recovery/activity history — 上轮问的"host 故障后恢复是否覆盖"得到正面回答：会话存活现在不依赖 daemon 生命周期
- **#143**：MCP session authorization 加固（信任边界继续收）
- **#144**：remote PTY 输出按 batch 帧化而非每 read 一帧（降 overhead）
- #44（status-decision inspection 变 provenance surface）仍未动，继续观察
