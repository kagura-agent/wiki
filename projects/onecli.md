---
title: OneCLI — Credential Gateway for AI Agents
created: 2026-07-26
last_verified: 2026-07-26
status: deep-read
stars: 2826
---
# OneCLI — Secret Vault for AI Agents

> OSS credential gateway (MITM proxy) that sits between agents and APIs. Agent sends requests through the proxy with a placeholder key; gateway swaps it for the real credential. **Agent never touches secrets.**

- **Repo**: [onecli/onecli](https://github.com/onecli/onecli)
- **Stars**: 2,826 ⭐ | 162 forks
- **License**: Apache-2.0
- **Stack**: Rust (gateway, 13k LOC) + Next.js (dashboard) + PostgreSQL
- **Created**: 2026-03-08 | **Pushed**: 2026-07-26 (active daily)
- **HN**: 105 pts (Show HN, 2026-07-24)

## Architecture

### Core Pattern: MITM Credential Injection
1. Agent sets `HTTP_PROXY`/`HTTPS_PROXY` to the gateway
2. Agent sends `CONNECT` → gateway receives, resolves policy per `(agent_token, host)`
3. Gateway terminates TLS with agent (dynamic leaf cert from local CA), opens TLS to upstream
4. On each HTTP request through the tunnel, gateway:
   - Extracts agent identity from `Proxy-Authorization: Basic base64(x:{token})`
   - Looks up injection rules (cached 60s TTL) by host + path pattern
   - Applies injections: `SetHeader`, `ReplaceHeader`, `RemoveHeader`, `SetParam`, `SetPath` (template mode for token-in-path APIs like Telegram's `/bot{value}/`), `ReplacePathRegex`
   - Strips hop-by-hop headers, forwards to upstream
5. Agent receives response as if it talked directly to the API

### Key Difference from [[agent-credential-security|Fingerprint Model]]
The fingerprint model I documented is conceptual ("agent says I need X, runtime injects"). OneCLI is the **production implementation** — transparent HTTP proxy, no agent-side code changes needed. Agent just makes normal HTTP calls.

### Comparison with Known Approaches
| Approach | Pattern | OneCLI Difference |
|---|---|---|
| [[centaur-paradigm\|Centaur]] iron-control | Centralized token broker, inline delivery | OneCLI IS the proxy (no separate broker + proxy) |
| [[polypore\|Polypore]] Secret Broker | Per-request mediation via `secrets.use` API | OneCLI is transparent — no API call, just HTTP |
| [[clawpatrol\|Claw Patrol]] | Wire-level firewall (block) | Different purpose: blocking vs injecting |
| [[superserve\|Superserve]] Secret Proxy | Credential never enters VM | Same principle, OneCLI works without VMs |

### Vault Integration (Novel Pattern)
- **Bitwarden Agent Access SDK** integration via Noise protocol + WebSocket relay
- Agent request → no server-stored secret matches → gateway asks Bitwarden vault by domain → credential injected → cached 60s → discarded
- **Zero stored secrets mode**: credentials live only in the password manager
- This is the closest I've seen to true "runtime-only" credential injection

### Enterprise (EE) Overlay
- Policy engine (rule-based credential selection: all vs selective mode)
- Approval flows (human-in-the-loop for sensitive operations)
- Budget management (per-agent spend limits)
- AWS STS integration (temporary credentials)
- Granular access, partner access, telemetry
- On-prem hooks

## Issues That Reveal Architecture Limits

1. **"Credential use beyond HTTP"** (tenequm) — MITM proxy only works for HTTP. SSH, local signing, non-HTTP flows need different pattern. **Fundamental limitation of proxy approach.**
2. **"Proxy strips cache_control from Anthropic bodies"** — gateway must be careful not to modify request bodies. MITM is powerful but brittle for body-sensitive APIs.
3. **"API-key vs OAuth preemption on shared hosts"** (googleapis.com) — when host matches multiple credential types, injection priority becomes tricky.
4. **OAuth token refresh bugs** (ChatGPT/Codex) — gateway has to manage OAuth lifecycle, not just static keys.
5. **DNS AAAA SERVFAIL → 502** — production-grade networking concerns.

## Relevance to Our Direction

### Direct Applicability
- OpenClaw already has partial credential isolation ("trust not tech"), OneCLI shows how to make it "tech not trust"
- Could integrate as an outbound proxy for agent exec — set `HTTPS_PROXY` in sandbox environment
- Bitwarden vault pattern could work with `pass` (our current credential store)

### Pattern Worth Adopting
- **InjectionRule with path_pattern** — not just host-level but path-level credential scoping. A GitHub token for `/repos/` but not for `/gists/`
- **ReplaceHeader** (only if exists) — smart for OAuth flows where `Authorization` header exists on token exchange but not on subsequent calls
- **SetPath template mode** — elegant for token-in-path APIs

### What We'd Still Need
- OneCLI requires agents to go through the proxy. Our agents can `cat` config files directly.
- True isolation needs sandbox-level file access restrictions (which OpenClaw sandbox provides)
- OneCLI + sandbox = credible zero-trust agent credential architecture

## Health Assessment
- **THRIVING** (5/6): High stars, active development, real users, real bugs, Apache-2.0
- Growing community (162 forks, external issues from real users)
- Solo-team risk mitigated by star count and enterprise features
- Revisit: 2026-08-02
