---
title: Remote Development
created: 2026-07-04
tags: [remote-dev, infrastructure, pocketdev, wireguard]
last_verified: 2026-07-04
---

# Remote Development

Infrastructure for coding from anywhere, especially with AI coding agents. Fills the gap between "I have a subscription to an AI coding tool" and "I can actually code from anywhere."

## Key Pattern (pocketdev)

Cloud VM + WireGuard mesh (Tailscale) + terminal multiplexer (tmux) + Mosh for mobile access. The defining property: **zero public attack surface** — all traffic flows over the encrypted mesh network. No exposed ports, no public SSH.

## Architecture Decisions

- **Reverse-tunnel auth relay** solves headless OAuth. When a cloud VM has no browser, the auth flow tunnels back to a device that does.
- **No-sudo dev user** for blast radius containment. The agent runs as an unprivileged user; a compromised session cannot escalate.
- **Mosh over SSH** for mobile. Mosh handles roaming, high latency, and intermittent connectivity that breaks traditional SSH sessions.

## Relationship to Agent Harnesses

Remote dev infrastructure is complementary to agent harnesses, not competitive. A harness orchestrates what the agent does; remote dev infrastructure provides the environment where it runs. The combination enables persistent, always-available agent sessions accessible from any device.

## Links

[[agent-harness-landscape]], [[agent-security]], [[mobile-agent]]
