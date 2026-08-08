# Caspian SDK — Cross-Platform Agent Identity Layer

- **Repo**: [TryCaspian/caspian-sdk](https://github.com/TryCaspian/caspian-sdk)
- **Stars**: 351 (2026-07-31, +99% in 7 days)
- **Language**: Python + TypeScript (dual SDK, monorepo)
- **Category**: Agent infrastructure / Channel unification
- **Status**: Rapid growth, multi-contributor (10+ external), daily releases (SDK 0.6.1)

## What It Solves

The "N adapters" problem: every agent framework rebuilds the same Slack/Discord/Telegram/email plumbing. Caspian abstracts this into:
1. A hosted gateway (`api.trycaspianai.com`) handling webhook verification, auth flows, threading
2. Thin SDKs (Python + TS) with one `on_message` handler pattern
3. Channel adapters that normalize inbound messages into a unified shape

Their pitch: "The largest OSS agent frameworks each built 25+ channel adapters and still spend 8-15% of their issue trackers on channel plumbing."

## Architecture

- **Event-sourced polling**: Client polls `/v1/events?after_seq=N` — no websocket, no callback server needed. Simple but adds latency (poll_interval default 1s)
- **Capability negotiation**: Adapters declare what the channel physically supports (text, reactions, typing, send, initiate, backfill). Agent can't exceed transport limits. This is the strongest design pattern.
- **Freemium channel model**: Email/Telegram/Discord/Slack = free. WhatsApp/X/iMessage = paid (requires developer sign-in + credit balance)
- **Blocks system**: Provider-neutral rich message format (heading, text, divider, image, fields, buttons, card) that degrades gracefully per channel
- **`behavior_prompt()`**: Returns per-channel etiquette as system prompt injection — lets the LLM reason about platform conventions without hardcoding. Novel.

## OpenClaw Integration

Ships a first-party OpenClaw channel plugin (`packages/openclaw/`):
- Uses `openclaw/plugin-sdk/channel-core` to register as channel "caspian"
- Session key pattern: `caspian:<sub-channel>:<conversationId>`
- Bridges Caspian conversations directly into OpenClaw sessions
- Message adapter: text-only in v1 (no streaming/media yet)

**Relationship to [[openclaw]]**: Complement, not competitor. Caspian is a channel unification layer; OpenClaw is an agent runtime. For us specifically, OpenClaw already has Discord/Feishu/WhatsApp natively — Caspian's value would be for channels we lack (iMessage, Instagram, X DMs, phone/SMS, RCS).

## Notable Patterns

1. **Capability negotiation** — channels declare capabilities as flags, SDK enforces boundaries. Good API design that prevents "message.react() on SMS" errors.
2. **`behavior_prompt()`** — per-channel etiquette as programmatic system prompt section. We do this manually in AGENTS.md (platform formatting rules); a machine-readable version is cleaner.
3. **Session key from conversation** — `caspian:<channel>:<conversationId>` as deterministic session routing. Clean.
4. **Offline fakes** — every channel has a test fake that consumes real payload shapes. 80 tests, zero network.
5. **One-click installs** — `install_slack()` / `install_discord()` use a shared app (no bot creation needed). Lowers adoption friction dramatically.

## Tradeoffs / Weaknesses

- ~~Polling adds latency for real-time channels~~ → **Addressed**: Slack Socket Mode (07-29) holds WebSocket for real-time delivery
- ~~Solo developer risk~~ → **Addressed**: Internship challenge (#118) brought 10+ external contributors; sustainability post-challenge TBD
- Paid channels create vendor lock-in for the most valuable transports
- No self-hosting documentation for the gateway (just `CASPIAN_BASE_URL` env var)
- Event sequencing is single-node (no multi-node scaling story)
- Community explosion is internship-driven, not organic adoption — may not sustain post-challenge

## Ecosystem Position

Sits between agent frameworks ([[openclaw]], [[agentara]], [[centaur-paradigm]]) and platform APIs. Similar positioning to what [[craft-agents-oss]] attempted with its multi-channel plugin architecture, but Caspian is infrastructure-as-a-service rather than library-only.

Compared to [[agentara]] (Tara): both do multi-channel personal assistant. Tara is opinionated (Claude+Codex runtime built-in). Caspian is a pure transport layer — bring your own agent logic.

## Relevance to Our Direction

- **Applicable now**: `behavior_prompt()` pattern — we could generate per-channel etiquette dynamically in OpenClaw's channel plugins
- **Applicable if needed**: iMessage/Instagram/X DMs via Caspian as an additional OpenClaw channel, without building adapters ourselves
- **Not needed**: Slack/Discord/Telegram/email — we have these natively

## 2026-07-31 Followup: Architectural Evolution

### Atomic Outbox Claims (server/jobs.py)
Prevents double-processing in multi-worker deployments:
- SELECT candidate `seq` → UPDATE with `WHERE status="pending"` → check rowcount
- If rowcount=0, another worker claimed it → skip and continue
- Works identically on SQLite (dev) and Postgres (prod) — no `FOR UPDATE SKIP LOCKED` needed
- Pattern: optimistic CAS (compare-and-swap) via conditional UPDATE

### Slack Socket Mode (server/listeners/slack_socket.py)
Addresses the polling latency weakness:
- BYO app-level token (`xapp-`), no OAuth, no public webhook needed
- `apps.connections.open` → short-lived WSS URL → hold socket
- **ACK-first design**: ack envelope BEFORE processing (Slack redelivers unacked)
- Fatal auth detection: `invalid_auth` → stop entirely, don't reconnect-spin
- Exponential backoff with cap at 60s
- Mirrors Discord gateway pattern (same team likely built both)

### OpenCode Plugin: Reliability Architecture (packages/opencode/)
Most impressive find — production-grade reliability for a plugin:
- **CP (Critical Path) vs NonCP separation**: Hard rule "NonCP ↛ CP" — a failed Telegram send must NEVER open the circuit breaker that protects listen→reply
- **Separate circuit breakers**: `caspianCpCircuit` (inbound/reply) vs `caspianOutboundCircuit` (proactive sends)
- **CapacityLimiter**: per-conversation (default 1 concurrent) + global (8 concurrent) + rate (30/min/conversation). Fail-fast rejection > unbounded queues
- **CircuitBreaker**: standard closed/open/half_open state machine with configurable thresholds
- **SLO targets from day one**: 99.9% inbound success, 99.5% outbound reply, heartbeat <30s
- **Onboarding failover chain**: env → CLI → HTTP mint → persist (non-blocking, never delays listen)

### Community Growth Driver
The contributor explosion is from an **internship challenge** (issue #118):
- "Build an AI agent with Caspian SDK" as hiring evaluation on Unstop
- Candidates submit public repos with live agents
- External adapters (Bluesky, Zulip, Teams, Signal, LinkedIn, Linear) all from interns
- **Smart growth hack** but sustainability unclear after challenge ends
- Stars grew 99% in 7 days — partially intern network effect

### New Channel Adapters (since 07-24)
- **Bluesky** (AT Protocol, merged)
- **Zulip** (PR #74, merged)
- **Slack Socket Mode** (BYO token, no OAuth)
- **MMS** (Twilio SMS provider extension)
- **OpenCode plugin** (coding agent bridge)

### Positioning vs A2A/ACP
Explicit README commit: "name the category in the README lede, and separate us from A2A/ACP"
- They see themselves as **transport layer**, not protocol
- A2A/ACP = agent-to-agent communication
- Caspian = agent-to-human channel unification
- Different layer of the stack, complementary

## Relevance Update (07-31)

- **CP/NonCP circuit pattern** → directly applicable to OpenClaw plugin reliability (our plugins don't have circuit breakers)
- **Fail-fast rejection > queues** → applicable to our Cove channel handling under load
- **Internship-as-growth-strategy** → interesting community engineering pattern (not applicable to us directly)
- **Slack Socket Mode** → if we ever add Slack natively, BYO-token approach is cleaner than OAuth-first

## 2026-08-07 Follow-up — Dropped

The prior 07-31 metrics were stale. GitHub API now reports 215⭐, 4 forks, 3 open issues, and no commits after 2026-02-15; there is no continuing release or contributor signal. The earlier internship-driven expansion therefore did not establish a durable project. **Removed from the active watch list.** The capability-negotiation, CP/non-CP circuit separation, and channel-etiquette patterns remain useful as concepts, but no longer justify monitoring the repository.

## Links

- [[openclaw]], [[agent-harness-landscape]], [[agentara]], [[craft-agents-oss]], [[centaur-paradigm]]
