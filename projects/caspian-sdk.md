# Caspian SDK — Cross-Platform Agent Identity Layer

- **Repo**: [TryCaspian/caspian-sdk](https://github.com/TryCaspian/caspian-sdk)
- **Stars**: 176 (2026-07-24, 4 days old)
- **Language**: Python + TypeScript (dual SDK, monorepo)
- **Category**: Agent infrastructure / Channel unification
- **Status**: Early-stage, single developer (dipanshuhappy), active (pushed daily)

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

- Polling adds latency for real-time channels (Discord/Telegram expect sub-second)
- Solo developer risk — all 15 issues self-filed, no external contributors yet
- Paid channels create vendor lock-in for the most valuable transports
- No self-hosting documentation for the gateway (just `CASPIAN_BASE_URL` env var)
- Event sequencing is single-node (no multi-node scaling story)

## Ecosystem Position

Sits between agent frameworks ([[openclaw]], [[agentara]], [[centaur-paradigm]]) and platform APIs. Similar positioning to what [[craft-agents-oss]] attempted with its multi-channel plugin architecture, but Caspian is infrastructure-as-a-service rather than library-only.

Compared to [[agentara]] (Tara): both do multi-channel personal assistant. Tara is opinionated (Claude+Codex runtime built-in). Caspian is a pure transport layer — bring your own agent logic.

## Relevance to Our Direction

- **Applicable now**: `behavior_prompt()` pattern — we could generate per-channel etiquette dynamically in OpenClaw's channel plugins
- **Applicable if needed**: iMessage/Instagram/X DMs via Caspian as an additional OpenClaw channel, without building adapters ourselves
- **Not needed**: Slack/Discord/Telegram/email — we have these natively

## Links

- [[openclaw]], [[agent-harness-landscape]], [[agentara]], [[craft-agents-oss]], [[centaur-paradigm]]
