# Lucarne — Mobile Agent Control Bridge

- **repo**: tuchg/Lucarne
- **stars**: 158 (created 2026-05-17)
- **lang**: Rust
- **license**: MIT
- **status**: tracking | ✓2026-05-26

## What It Is

Mobile control bridge for AI agent sessions via Telegram/WeChat. Zero-intrusion: no hooks, no skills, no MCP required on the agent side. Lets you approve, resume, and monitor Codex/Pi/Claude Code sessions from your phone.

Core pitch: "Stop babysitting local AI agents. Just notifications, approve, and resume."

## Architecture

Rust daemon (`lucarned`) that:
1. Watches agent session output (filesystem-level, no agent hooks needed)
2. Routes notifications to Telegram/WeChat
3. Relays approval/input back to agent sessions
4. Desktop tray for status (planned, issue #27)

## Community Health (05-26)

- Solo maintainer (tuchg), all PRs self-merged
- But real users: 5+ external issue reporters (zweix123, Michael-py001, Mengdch, thoomi2009)
- Issues are real usage bugs: agent startup failures, WeChat QR recognition, notification routing
- Chinese community engagement (issues in Chinese)
- 14 open issues, 7 forks

## Ecosystem Position

- Competes with: Luna's Tailscale+Termius setup (lower level), future OpenClaw mobile app
- Complements: Any agent runtime (Codex, Pi, Claude Code, OpenClaw)
- Related: [[openclaw]] remote node management, mobile agent supervision problem

## Relevance to Us

1. Validates the problem: humans need mobile agent supervision. Luna already does this manually (SSH via Termius)
2. "Zero-intrusion" approach is different from OpenClaw's integrated approach — tradeoff between depth and ease of setup
3. WeChat integration is notable — covers the Chinese ecosystem gap that most Western agent tools miss
4. If this grows, could become an integration target for OpenClaw (provide richer session metadata for Lucarne to relay)

## Architecture Deep Dive (05-26)

### Crate Structure (Rust workspace, v0.4.1)
- `agent-sessions` — filesystem-level session discovery & parsing for Claude/Codex/Copilot/Cursor/Pi. Feature-gated per provider. Uses `smol_str` for zero-copy parsing. Has benchmarks.
- `lucarne` (core) — agent multiplexer. Composes Launcher + Framer + Dialect into running `Session`. Key: backpressure property (bounded channel → OS pipe fills → agent blocks, no drops).
  - `dialect` — per-agent vendor-specific stdio translation (Claude, Codex, Copilot, Pi dialects)
  - `runtime` — `Session` struct wraps subprocess stdin/stdout, produces canonical `Event` stream
  - `control_plane` — orchestration layer
  - `agent_runtime` — rich type system: `ApprovalRequest`, `InterventionRequest`, `QuestionRequest`, `ToolCallEvent`, etc.
  - `history` — session history retrieval
- `lucarne-channel` — `Channel` trait: platform-agnostic messaging abstraction (send, split, markdown conversion). Current impls: Telegram, WeChat.
- `lucarne-adapter` — config-driven channel management (YAML config, env vars)
- `lucarned` — daemon binary (main + health + onboarding)
- `lucarned-ctl` — CLI control
- `lucarne-telegram` / `lucarne-wechat` — channel implementations
- `lucarne-fakeagent` — test harness

### Key Design Patterns
1. **Dialect pattern**: Each agent vendor is a `Dialect` that translates vendor stdio to canonical `Event`s. Adding new agent = new dialect module. Clean separation.
2. **Backpressure-safe streaming**: Bounded mpsc channels → OS pipe backpressure → agent's write() blocks. No data loss.
3. **Permission mediation**: Rich approval model — `ApprovalRequest`, `ApprovalDecision`, `InterventionRequest/Response`, `QuestionRequest/QuestionAnswer`. This is the core value prop: routing agent permission requests to mobile.
4. **Projection layer**: Parses tool inputs across different agent formats (command, file_path, diff stats) into unified `ParsedToolInput`.
5. **Live recording tests**: Extensive fixture-based testing with recorded real agent sessions (wire.log + session.fixture + effects.json). Covers e2e flows: approve, reject, interrupt, delete, tool failure, multi-turn.

### Feature Requests (from issues)
- Channels: 飞书, Discord, Slack, QQ, 钉钉 (all open, 05-22)
- Agents: Hermes, OpenCode, Cursor, Antigravity (all open)
- Remote environments, message modes (steer/queue), desktop tray

### vs OpenClaw
- **Overlap**: Both solve "mobile agent supervision" — approve, monitor, resume from phone
- **Lucarne advantage**: Zero-intrusion (filesystem watching, no agent hooks). Works with any agent CLI immediately.
- **OpenClaw advantage**: Deep integration (cron, memory, skills, multi-agent, channel ecosystem already built). Lucarne has to build each channel from scratch.
- **Lucarne gap**: No memory, no skills, no cron, no multi-agent coordination. It's pure I/O relay.
- **Interesting for us**: Their `Dialect` pattern for agent normalization is well-designed. Their fixture-based testing with live recordings is a good practice.
- **Possible integration**: Lucarne could be an alternative remote node for OpenClaw, or vice versa.

## Revisit

06-09 — check star growth trajectory, external PR activity, new channel implementations
