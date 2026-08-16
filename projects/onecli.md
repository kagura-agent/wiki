---
title: OneCLI — Credential Gateway for AI Agents
created: 2026-07-26
last_verified: 2026-08-16
status: following
stars: 3094
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

## Update 2026-08-02: Agent Grants System

v1.44.0 introduces **per-agent credential grants** — the most significant architectural change since initial deep read:

- Old model: project-level policy → agents inherit broad access
- New model: **zero-access default** → explicit per-agent grants with per-tool allow/ask/never
- API: `PUT /v1/agents/{agentId}/grants/connections/{connId}` with `{access: "full"|"custom", allow:[...], ask:[...]}`
- Gateway evaluates grants per-connection (same host, different accounts can have different permissions via `x-onecli-connection-id`)
- Boot-time idempotent converter materializes existing access as explicit grants
- Retired endpoints return `410 Gone` naming replacements

**Architectural insights**:
- The allow/ask split per-tool is the credential equivalent of Unix file permissions — routine ops (read) don't require approval, sensitive ops (delete) do. This is exactly the "graduated trust" pattern.
- **Tri-state model invariants** (enforced at validation via Zod discriminated union):
  - "All-blocked grant is a detach" — if allow∪ask = ∅, you're removing access entirely
  - "Tool can't be both allowed and approval-gated" — clean partition
- **Stack compilation is pure**: `grants-compile.ts` has zero I/O — pure computation over rule shapes. Used by both the runtime service and the one-shot migration converter, ensuring one canonical definition.
- **Evaluation order**: compiled rules are positional (allow → ask → blocked → default). Gateway evaluates first-match per matching allow row.
- **Session policy on every allow row** (not just first): because gateway's `inject_select` is last-match-wins, a condition-less ask-row after a conditioned allow-row would clobber restrictions. Subtle correctness concern.
- **CORS vulnerability** (#472, ben564885): local-admin mode + `alloworigin::mirror_request()` + `allow_credentials(true)` = any website can approve agent gated requests. Reveals tension between "local mode easy" and "local mode secure".

**Pattern comparison with [[clawpatrol]]**: ClawPatrol blocks (deny-list firewall), OneCLI injects (allow-list credential scoping). Complementary — ClawPatrol at the outer boundary, OneCLI at the credential layer.

## Health Assessment
- **THRIVING** (6/6): 2,955⭐, 172 forks, 37 external PRs/30d, 46 unique issue authors
- 7 merged PR authors (healthy multi-contributor base)
- 3 releases in 5 days (v1.43.2→v1.45.0) — very active
- Revisit: 2026-08-16

## Follow-up 2026-08-09 — Grants Need Production Proof

GitHub API reports **3,007⭐ / 178 forks / 111 open issues**. The code line is quiet after v1.45.0 (last push 2026-07-31), but the issue stream remains active and is more informative than the star growth:

- [#482](https://github.com/onecli/onecli/issues/482) reports that a correctly published `policy_rules_v2` grant returns `credential_not_found`, directly challenging the new grant path described above.
- [#484](https://github.com/onecli/onecli/issues/484) reports gateway file-descriptor exhaustion after days of operation; [#485](https://github.com/onecli/onecli/issues/485) reports host-pattern port matching is lost before evaluation.

This is a valuable counterweight to the earlier architecture assessment: **zero-default grants are only a security boundary once policy publication, lookup, and injection have an end-to-end regression suite.** Keep following until a release or reproducible fix closes #482; do not treat the design as production-ready merely because its pure compilation layer is well structured.

## Follow-up 2026-08-16 — Tracked Fix Appears, Core Dev Paused

**3,094⭐ / 184 forks / 117 open issues** (+2.9% stars since 08-09). Repo `pushed_at` 08-15 is misleading — it reflects old side branches (May–Jun); `main` is still at v1.45.0 (07-31), zero new main commits in 2+ weeks. **Core dev paused; issue flow is the only signal.**

- **#482 (credential_not_found for published grants) now has an external fix PR**: [#487](https://github.com/onecli/onecli/pull/487) (Adityakk9031, 08-09, mergeable, still OPEN). Root cause: Anthropic OAuth tokens (`sk-ant-oat…`) were injected with `Injection::ReplaceHeader`, which only applies if the header already exists — so first use 401s. The exact enforcement-path bug last round flagged as unverified now has a concrete, reviewable fix. This validates the earlier caution: the design wasn't broken at the pure-compilation layer, it broke in the injection runtime.
- **#485 got a downstream adoption signal**: [NanoClaw](https://github.com/nanocoai/nanoclaw) (multi-agent host) fronts all agent egress with OneCLI and cites the port-matching bug as blocking (chiptoe-svg, 08-11). First hard evidence of production usage beyond the project's own claims.
- **#484 (FD exhaustion)** still unanswered by maintainers. New **#490**: OpenAI API-key injection breaks fresh Codex OAuth login (`invalid_client`) — another injection-path regression, same family as #482/#485: **the MITM injection layer is the reliability bottleneck**, not the policy model.

**Assessment**: warm tier, not hot — core dev paused but tracked fix PR + real downstream usage keep it worth watching. The pattern across #482/#485/#490 (all injection-runtime bugs, all from the same runtime layer, all with thin maintainer response) suggests the grant/policy architecture is ahead of its runtime hardening. Revisit 08-30 for #487 merge status and any main-branch activity.
