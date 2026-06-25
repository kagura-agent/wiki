---
title: "peerd — Browser-Native AI Agent Harness"
created: 2026-06-25
tags: [agent-harness, browser, extension, p2p, webrtc, security, sandbox]
source: https://github.com/NotASithLord/peerd
status: deep-read
last_verified: 2026-06-25
---

# peerd — Browser-Native AI Agent Harness

## What It Is

The first AI agent harness that runs **inside the browser** as a Chrome/Firefox extension. The browser IS the runtime and security model. BYOK, no backend, no telemetry. Apache 2.0, vanilla JS (no build step), Manifest V3.

**Author:** NotASithLord + jonybur (2 active contributors)
**Born:** 2026-06-22 (3 days old as of deep read)
**Stars:** 71⭐ (growing, 6 open issues)
**Status:** 0.x experimental beta

## Architecture (5 Modules)

```
┌─────────────────────────────────────────────────┐
│  peerd-provider (p) — model adapters            │
│  Anthropic, OpenRouter, Ollama, WebGPU (WIP)    │
├─────────────────────────────────────────────────┤
│  peerd-egress (e) — security spine              │
│  Vault (AES-GCM + Argon2id/WebAuthn), SSRF     │
│  guard, denylist, confirm protocol, audit log   │
├─────────────────────────────────────────────────┤
│  peerd-engine (e) — execution sandboxes         │
│  WebVM (CheerpX Linux), JS Notebooks,           │
│  opaque-origin Apps, headless js_run            │
├─────────────────────────────────────────────────┤
│  peerd-runtime (r) — agent loop + tools         │
│  Sessions, memory, skills, tools, runner,       │
│  subagents, goal system, cost tracking          │
├─────────────────────────────────────────────────┤
│  peerd-distributed (d) — P2P dweb (preview)     │
│  did:key identity, WebRTC mesh, CBOR frames,    │
│  signed content addressing, dwapp store         │
└─────────────────────────────────────────────────┘
```

## Key Architectural Insights

### 1. Browser as Security Model (not just runtime)

Leverages decades of browser hardening instead of building custom sandboxing:
- V8 isolates for compute sandboxing
- WebCrypto for the vault (no custom crypto)
- WebAuthn passkeys for vault unlock
- Opaque-origin iframes for app isolation
- Subresource Integrity for content verification

### 2. Trust Separation: Runner as Disposable Agent

**The killer insight.** The main agent (which holds keys, has memory, can do egress) NEVER directly reads untrusted web pages. Instead:

- A **disposable runner sub-agent** is spawned per page interaction
- Runner has NO memory tools, NO egress tools, NO code-exec, NO spawn ability
- Runner can only use DOM-action tools on ONE tab
- Main agent only receives a plain-text summary from the runner
- Even if the page fully prompt-injects the runner → it can do nothing harmful

This is proper privilege separation. The attack surface is: mislead a throwaway agent that holds no secrets. Compare to [[claw-patrol-agent-firewall]] which does wire-level filtering.

### 3. Tool Dispatch Concurrency Model

- `partitionToolBatch` classifies tools as READ (concurrent-safe) or WRITE (serial)
- `spawn_subagent` is always concurrent (independent session)
- Single-writer posture: two clicks/edits must not interleave
- Abort signal checked at loop-top but NOT between stream-end and tool-dispatch (known gap, issue filed)

### 4. MV3 Service Worker Lifecycle

The SW can idle-evict at any time. Recovery machinery:
- `storage.session` (RAM-only, survives SW restart within same browser session)
- Auto-resume for interrupted turns (detect + re-drive)
- DK (data key) mirrors to session storage for seamless unlock-resume
- Known gap: boot-time resume doesn't trigger auto-resume (issue #73)

### 5. Agent Loop Design

Async generator the SW drives forward via `.next()`:
- MAX_STEPS = 100 (raised from 25 — real browser tasks need 30+)
- Turn-slot model: one active turn per session
- Goal-runner for autonomous multi-step goals
- Rolling summary + lineage compaction for context management
- Resume detection for SW-killed turns

### 6. Memory: AGENTS.md Convention

Adopted the AGENTS.md/CLAUDE.md memory standard:
- Three scopes: user → project → subtree
- "Project" = browsing context (origin, WebVM, or App), not just file tree
- Subtree loads on-demand (keeps always-loaded surface lean)
- IDB-backed persistence, human-readable markdown format

### 7. P2P Layer (Preview-only, Research-grade)

- did:key (Ed25519) identity from vault-stored seed
- Content addressing: `peerd://<publisher_did>/<hash>`
- WebRTC mesh (STUN only, no TURN ever) with CBOR-signed frames
- Rooms (cap 16 peers) with mesh-assisted signaling
- Apps ("dwapps") can be shared peer-to-peer
- Inbound/unattended messaging surface deliberately OFF until security model built

## Security Design Decisions

1. **Egress allowlist is hardcoded** — only Anthropic, OpenAI, OpenRouter, Ollama loopback. No wildcards.
2. **Sensitive-site denylist** — 164 patterns across 8 categories (banks, crypto, health, gov, password managers)
3. **Confirmation protocol** — async user-confirm that always settles (auto-deny on broken channel/timeout)
4. **Dweb kill switch** — user can fully shut down all P2P networking (persisted off)
5. **Private-network guard** — blocks loopback, LAN, link-local addresses including obfuscated encodings

## Community Signal

- 2 contributors in 3 days (high activity, coherent codebase)
- Bug reports from jonybur are exceptionally high quality ("verified review passes")
- Uses Claude Code for development (evident from issue comments)
- No external community yet (too early), but code quality suggests sustainable

## Comparison to Existing Landscape

| Project | Approach | peerd Difference |
|---------|----------|-----------------|
| [[byob-chrome-reuse-mcp]] | MCP bridge TO browser | peerd = agent loop INSIDE browser |
| [[claw-patrol-agent-firewall]] | Wire-level MITM proxy | peerd = application-level trust separation |
| [[codex-control-plane-mcp]] | External orchestrator for agents | peerd = self-contained browser agent |
| OpenClaw | Server-side runtime, multi-channel | peerd = client-only, browser-native |
| [[gensee-crate-runtime-safety]] | Sidecar safety layer | peerd = built-in security by architecture |

## Relevance to Our Direction

1. **Trust separation pattern** — runner-as-disposable-agent is a cleaner model than content filtering. Applicable to any agent that processes untrusted input.
2. **Browser security model reuse** — instead of building sandboxing, leverage existing platform. Same philosophy as "use the OS, don't reinvent it."
3. **Memory convention convergence** — another project adopting AGENTS.md-style memory confirms the standard is solidifying.
4. **P2P agent communication** — early but interesting signal for agent-to-agent protocols without centralized servers.

## Predictions

- Will hit 200+ stars within 2 weeks if Chrome Web Store listing goes live
- WebVM/Notebook sandboxes will attract power users but Firefox parity will be a persistent pain point
- P2P layer will remain research-grade for 3+ months (security model is complex)

## Track

- Revisit: 2026-07-02 (check stars growth, Firefox parity progress, dweb progress)
- Watch for: Chrome Web Store approval, first external contributor beyond jonybur
