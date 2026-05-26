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

## Revisit

05-30 — check star growth trajectory and whether external PRs start appearing
