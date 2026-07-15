---
title: "peerd — Browser-Native AI Agent Harness"
created: 2026-06-25
tags: [agent-harness, browser, extension, p2p, webrtc, security, sandbox, actor-model, heap-isolation]
source: https://github.com/NotASithLord/peerd
status: deep-read
last_verified: 2026-07-15
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

This is proper privilege separation. The attack surface is: mislead a throwaway agent that holds no secrets. Compare to [[clawpatrol]] which does wire-level filtering.

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

### 8. Actor Heap Split — Memory Boundary Isolation (v0.2.2)

The leap from **prompt boundary** to **memory boundary** for actor isolation:
- Every non-orchestrator actor runs in its own offscreen Worker heap
- Worker holds NO vault key, NO chrome.* APIs, NO engine clients
- Only 2 outward edges: SW-gated relay for model calls + tool calls
- **SW re-validates every relayed call** — nothing the worker sends is trusted
- `offscreen-actor-client.js` rebuilds caller context server-side on every dispatch
- Bound actors: instance-pinned tool calls
- Subagents: checked against persisted `grantedTools` set + `restrictCtxCapabilities`
- Tool surface filtering: subagents can NEVER be granted DOM/page tools (foreground-tab escalation closed)
- Stop cascades transitively: abort parent → abort entire subtree
- Chrome-only (offscreen API); Firefox degrades to keyless in-SW loop

**Key insight:** "Even if a page fully prompt-injects the actor → it can do nothing harmful." The attack surface is: mislead a throwaway agent that holds no secrets. This is [[clawpatrol]]-class protection achieved through architecture, not wire filtering.

### 9. Dweb Actor — Agent-to-Agent Envoy (v0.2.2)

First "daemon" actor — persistent, opt-in, mesh operator:
- `actorType: 'dweb'`, global singleton per profile
- Positive allow-set of exactly 7 dweb tools (no egress, no DOM, no engine mutation, no delegation)
- Inbound path: peer message → rate-cap (3/min per did, 30/hr global) → fenced untrusted turn in keyless Worker → trickle-up notable findings to chat via `runWhenIdle`
- **Unifying insight:** "After heap split, 'an agent you don't fully trust, reachable only by message, whose reply re-enters fenced' describes both a local actor and a peer's agent — the same sentence."
- Preview-only (store build prunes the dweb module)
- Adversarial cynical-review swarm development methodology: multi-pass security review before merge

**Relevance:** The same isolation model handles both local untrusted computation AND remote untrusted peers. This is architecturally elegant — one security primitive for two threat models.

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
| [[clawpatrol]] | Wire-level MITM proxy | peerd = application-level trust separation |
| [[codex-control-plane-mcp]] | External orchestrator for agents | peerd = self-contained browser agent |
| OpenClaw | Server-side runtime, multi-channel | peerd = client-only, browser-native |
| [[gensee-crate-runtime-safety]] | Sidecar safety layer | peerd = built-in security by architecture |

## Relevance to Our Direction

1. **Trust separation pattern** — runner-as-disposable-agent is a cleaner model than content filtering. Applicable to any agent that processes untrusted input.
2. **Browser security model reuse** — instead of building sandboxing, leverage existing platform. Same philosophy as "use the OS, don't reinvent it."
3. **Memory convention convergence** — another project adopting AGENTS.md-style memory confirms the standard is solidifying.
4. **P2P agent communication** — early but interesting signal for agent-to-agent protocols without centralized servers.
5. **Runtime vs fleet separation** (07-02): AgentOS feasibility PR crystallized this — runtime emits+executes (85% done), fleet provisions+collects (20% done). Similar to OpenClaw gateway/node split. Clean architectural boundary.
6. **Invariant ceiling framing** (07-02): Documenting what the platform *can never do* (Chrome extension CPU/RAM caps, corp SSO without moat sacrifice) is disciplined scope management worth adopting.
7. **Memory boundary > prompt boundary** (07-05): For untrusted content isolation, process-level separation (Worker heaps) beats instruction-level separation (system prompts). Even full prompt injection of an isolated process does nothing if that process has no keys/tools. Applicable to OpenClaw's subagent model — similar to how isolated cron runs have restricted tool grants.
8. **Unified local/remote security primitive** (07-05): "Fenced agent reachable only by message" is the same abstraction for local actors and remote peers. One isolation model, two threat surfaces. Elegant.
9. **SW as centralized policy enforcement** (07-05): All tool/model calls route through one validation layer that rebuilds context server-side. Similar to OpenClaw gateway's role as trust boundary between agents and external world.

## Followup Log

- **2026-06-26**: Initial deep-read. 141⭐, 2 contributors, 4 sandboxes, P2P dweb preview.
- **2026-07-02**: 274⭐ (+94%). THRIVING 6/6. Major runtime refactor (web actor direct page driving), remote Ollama. AgentOS feasibility assessment PR #129 — runtime 85%/fleet 20%, 3-wave enterprise plan, 6 fork decisions. 4 unique PR authors, 53 ext PRs/30d.
- **2026-07-05**: 300⭐ (+9.5%/3d). v0.2.2 released (07-04). **Major: actor model + heap split** — every actor/subagent now runs in its own keyless Worker heap (PR#138), formal Erlang-style isolation. Dweb actor (#141) as opt-in persistent P2P mesh envoy. Unified actor vocabulary across subagents+actors (#137). AgentOS PR#129 still OPEN (draft). Community still THRIVING 6/6, 48 ext PRs/30d, 5 unique issue authors.
- **2026-07-11**: 342⭐ (+14%/6d). Pushed 07-10. Full-300 eval results (31.0% pass rate) + failure taxonomy (#193). Post-merge review-swarm findings (#194). Z.ai GLM provider added (#170). Web thread measured (OM2W + A/B) (#188). DCO sign-off dropped from PR template (#190). Still THRIVING 6/6.

## Predictions

- ~~Will hit 200+ stars within 2 weeks if Chrome Web Store listing goes live~~ ✅ Hit 274 by 07-02
- WebVM/Notebook sandboxes will attract power users but Firefox parity will be a persistent pain point
- P2P layer will remain research-grade for 3+ months (security model is complex)
- (07-02) AgentOS direction will attract enterprise interest but SaaS-vs-extension fork decision will delay it 2+ months
- (07-05) Actor heap-split pattern will become their default isolation primitive; expect all new tool sandboxing to use this model

## Track

- Revisit: 2026-07-12 (check AgentOS PR ratification, dweb actor maturity, v0.3 direction)
- Watch for: AgentOS fork decision, dweb actor security model (#35), control plane repo creation
- **2026-07-15**: 352⭐ (+3%/4d). Pushed TODAY. v0.2.7 released (07-12). **Key new features**: BM25 query-relevant excerpting for oversized fetched pages (#200) — classic IR technique applied to web browsing context; actor-aware settle window for evaluation (#199) — their 31.0% pass rate was undercounted due to timing; emulated focus pattern (#209) — web actor no longer steals OS focus, emulates it instead. Community: 5 unique issue authors (last 14d), 8 open + 5 closed issues. Still THRIVING.
