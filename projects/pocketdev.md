---
title: "pocketdev — Mobile-First Remote Coding Agent Infra"
created: 2026-07-04
updated: 2026-07-04
status: following
stars: 92
repo: 0xMassi/pocketdev
lang: Go
license: AGPL-3.0
last_verified: 2026-07-04
---

# pocketdev — Code From Your Phone

One command to provision a Hetzner box, lock it to your Tailscale mesh, install AI coding CLIs (Claude Code, Codex, opencode, Cursor, Gemini, Grok, Aider), and SSH in from a phone or laptop. The "code from anywhere" gap filler.

## Why It Matters

No other tool addresses **mobile access to terminal coding agents** this cleanly. The agents are subscription-based and terminal-only; pocketdev puts the terminal on a cloud box reachable from your phone via Tailscale + Mosh + tmux.

## Architecture Patterns

### 1. Cloud-init as Declarative IaC
Single YAML doc renders entire box: sshd hardening, Tailscale join, agent install, helper scripts. No Ansible, no Terraform — just `#cloud-config`. Generated from typed Go structs, not string templates. ~315 LOC for the full cloud-init generator.

### 2. Zero Public Surface
- Hetzner firewall: no inbound rules (drops ALL public packets)
- Tailscale starts outbound (WireGuard), so it still connects
- UFW allows SSH/Mosh only on `tailscale0` interface
- Nothing listens on the public internet, ever

### 3. Reverse-Tunnel Auth Relay
Elegant solution for headless OAuth: laptop SSH session reverse-forwards port 47654 → local HTTP server. When agent CLI tries to `xdg-open` a URL on the headless box, the `pocketdev-open` script curls `127.0.0.1:47654` which opens the URL in the **laptop's browser**. Allowlisted to known auth domains only (github.com, claude.ai, etc.).

```go
var authHosts = []string{
    "github.com", "claude.ai", "anthropic.com", "chatgpt.com", "openai.com",
    "cursor.com", "x.ai", "google.com", "tailscale.com",
}
```

### 4. No-Sudo Dev User
Agent runs as `dev` with **no sudo**. An agent executing arbitrary shell commands can't escalate to root. Simple blast radius containment. [[agent-security]]

### 5. Agent Registry Pattern
Clean abstraction for multi-agent management:
```go
type Agent struct {
    Key       string   // stable id
    Bins      []string // detect on laptop/box
    Install   string   // shell install command
    LoginCmd  string   // auth command
    SysDeps   []string // apt deps (node, pipx, keyring)
}
```
Currently 7 agents. Each can fail independently without blocking others.

### 6. Adopt Mode
Can bootstrap an existing server without rebuilding — pipes a generated script over SSH. Practical for people with existing VPS/bare metal. `pocketdev destroy` never deletes adopted servers.

### 7. Cloudflare Tunnel Publishing
`pocketdev publish 3000` opens an outbound Cloudflare tunnel → public HTTPS URL without opening any inbound port. Zero account, zero domain for quick URLs. Named tunnel support for persistent domains.

## Tradeoffs

- **Hetzner-only** — could abstract cloud provider, but tight Hetzner integration (firewall API, server types, regions) is why it's clean
- **Tailscale-only** — WireGuard mesh is the security model; alternatives would need a different approach
- **Single-user** — per-seat subscriptions can't back multi-user; "bring your own auth" is the business constraint
- **Reboot kills tmux** — unattended-upgrades can reboot; mitigated by `claude --resume`

## Security Details

- SSH key validation rejects shell metacharacters (`'`, `"`, `\n`, `\`) before the key is interpolated into remote commands — prevents injection
- Tailscale auth key is single-use, tagged, 30-min expiry
- Hetzner token never reaches the box
- Termius SSH ID integration: per-device non-exportable keys, FaceID-bound

## Relevance to Our Direction

1. **Mobile agent access** is a real gap — Luna and I use phones frequently
2. **Reverse-tunnel auth relay** pattern applicable to [[openclaw]] node setups
3. **Agent registry** pattern is a clean multi-agent management abstraction
4. **No-sudo containment** aligns with [[agent-security]] best practices
5. **Cloud-init as IaC** — simpler than Terraform for disposable dev boxes

## Ecosystem Position

Complementary to agent harnesses — doesn't compete with agents themselves. Fills infrastructure gap between "I have a subscription" and "I can code from anywhere." Comparable to GitHub Codespaces but self-hosted, agent-first, and phone-optimized.

## Metadata

- **Codebase**: ~4,500 LOC Go, well-structured (internal/ packages)
- **Dependencies**: bubbletea (TUI), hcloud-go (Hetzner), yaml.v3
- **Community**: 0 issues, 3 forks, 5 days old — too early for community signals
- **Author**: 0xMassi, solo dev, appears to be first public project

---

Links: [[agent-harness-landscape]], [[agent-security]], [[openclaw]], [[remote-development]]
