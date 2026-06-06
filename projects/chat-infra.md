# Chat Infrastructure Research

> Last updated: 2026-06-06
> Status: 🔍 Deep-dive on Stoat codebase complete

## Goal

Find the best open-source Discord alternative to fork as an AI-native chat platform base. We want 80% of Discord's existing features for free, then add the AI-native 20%.

## Candidate Comparison

### 1. Stoat (formerly Revolt) ⭐ Top Pick

| Attribute | Detail |
|---|---|
| **Repo** | stoatchat/stoatchat (rebranded Feb 2026) |
| **Stars** | ~3k (backend mono-repo; org total higher) |
| **Language** | Rust (backend), Solid.js / Preact (frontends) |
| **License** | AGPL-3.0 (most crates) |
| **DB** | MongoDB |
| **Infra deps** | MongoDB + KeyDB (Redis) + RabbitMQ + MinIO (S3) + Caddy |
| **Voice** | LiveKit integration |
| **Self-hosted** | Docker Compose, min 2 vCPU / 2GB RAM |
| **Bot API** | REST + WebSocket, revolt.js / revolt.py libraries |
| **Plugin system** | None (no server-side plugin hooks) |
| **Activity** | Active (last commit hours ago, v0.13.6) |

**Architecture (from compose.yml):**
- `api` — REST API server (Rust)
- `events` — WebSocket event streaming (Rust)
- `autumn` — File server / upload handler (Rust)
- `january` — URL metadata & image proxy (Rust)
- `gifbox` — Tenor GIF proxy
- `crond` — Scheduled tasks daemon
- `pushd` — Push notification daemon
- `voice-ingress` — Voice call ingress
- `web` — Solid.js PWA frontend

**Pros:**
- Most Discord-like UX (servers, channels, roles, emoji, reactions)
- Clean Rust codebase, modular crate structure (config, database, models, permissions, presence, files)
- Lightweight — runs on 2GB RAM
- WebSocket events make real-time bot integration natural
- AGPL allows fork + self-host, just need to open-source changes
- Active development, recent LiveKit voice integration

**Cons:**
- No plugin system — all customization requires forking core code
- Smaller community (3k stars vs 45k Rocket.Chat)
- MongoDB only (no Postgres option)
- Bot API is functional but less documented than Rocket.Chat/Mattermost
- Recent rebrand (Revolt → Stoat) may cause confusion, docs in transition

**AI-native fork feasibility:** HIGH. Codebase is modular enough to add:
- Agent as first-class user type (modify `core/models`, `core/permissions`)
- Task/TODO panels (new UI components in Solid.js frontend)
- Agent activity dashboard (leverage `core/presence`)
- Project concept (extend server/channel model)

---

### 2. Rocket.Chat

| Attribute | Detail |
|---|---|
| **Repo** | RocketChat/Rocket.Chat |
| **Stars** | 45k |
| **Language** | TypeScript (Meteor.js) |
| **License** | MIT (but enterprise features gated) |
| **DB** | MongoDB |
| **Self-hosted** | Docker, Kubernetes, Snap |
| **Bot API** | REST + Realtime API + Livechat |
| **Plugin system** | Apps-Engine (TypeScript app framework) |
| **Activity** | Very active, enterprise-backed |

**Pros:**
- Most mature option, massive community
- Apps-Engine allows extending without forking core
- Built-in omnichannel (WhatsApp, Telegram, email integration)
- E2E encryption, federation, compliance features
- MIT license (most permissive)

**Cons:**
- HEAVY — Meteor.js monolith, high resource usage (4GB+ RAM recommended)
- Complex codebase, Meteor makes it harder to understand/modify
- Enterprise features paywalled (push notifications, audit logs)
- "Enterprise comms platform" vibe, not Discord-like community feel
- Meteor.js is aging; migration ongoing but slow

**AI-native fork feasibility:** MEDIUM. Apps-Engine is powerful but the Meteor monolith makes deep structural changes (new entity types, custom UI paradigms) painful. Better suited as "add AI features via apps" rather than "rebuild as AI-native."

---

### 3. Mattermost

| Attribute | Detail |
|---|---|
| **Repo** | mattermost/mattermost |
| **Stars** | 37k |
| **Language** | Go (server) + TypeScript (webapp) |
| **License** | MIT (Community) / Enterprise license |
| **DB** | PostgreSQL or MySQL |
| **Self-hosted** | Docker, Kubernetes, binary |
| **Bot API** | REST + WebSocket + Plugin API |
| **Plugin system** | Go + React plugin framework (best in class) |
| **Activity** | Very active, enterprise-backed |

**Pros:**
- Best plugin system — server (Go RPC) + client (React) hooks
- PostgreSQL support (our preferred DB)
- Clean Go+TS codebase, well-documented
- Strong REST API, personal access tokens, OAuth 2.0
- Mattermost-plugin-starter-template for quick dev

**Cons:**
- Slack-like, not Discord-like (no servers/communities concept)
- Enterprise/workplace oriented, less casual community feel
- Heavier than Stoat (8GB+ recommended for production)
- Enterprise features (compliance, SSO, etc.) gated
- Plugin system is good but "within Mattermost's paradigm" — you can extend, but not fundamentally reshape

**AI-native fork feasibility:** MEDIUM-HIGH. Plugin system is excellent for adding AI features without forking, but the Slack-like paradigm (workspaces, not community servers) doesn't match Discord's model. Deep UX changes would still require forking.

---

### 4. Element / Matrix

| Attribute | Detail |
|---|---|
| **Repo** | element-hq/element-web + matrix-org/synapse |
| **Stars** | 13k (Element) |
| **Language** | TypeScript (Element), Python/Rust (Synapse/Conduit) |
| **License** | AGPL-3.0 |
| **DB** | PostgreSQL (Synapse) |
| **Protocol** | Matrix (federated) |

**Verdict:** Federation adds massive complexity for zero benefit in our use case (single-instance AI platform). The protocol overhead (DAG-based event model, state resolution) makes customization much harder. **Not recommended.**

---

### 5. Spacebar

| Attribute | Detail |
|---|---|
| **Repo** | spacebarchat/server + spacebarchat/client |
| **Stars** | 2.1k (server), 643 (client) |
| **Language** | TypeScript |
| **License** | AGPL-3.0 |

**Verdict:** Aims for Discord API compatibility (drop-in replacement). Smaller community, legal gray area around Discord API cloning. Interesting technically but risky to build on. **Not recommended.**

---

## Recommendation Matrix

| Criterion | Stoat | Rocket.Chat | Mattermost |
|---|---|---|---|
| Discord-like UX | ⭐⭐⭐ | ⭐ | ⭐ |
| Codebase clarity | ⭐⭐⭐ | ⭐ | ⭐⭐⭐ |
| Plugin system | ❌ | ⭐⭐ | ⭐⭐⭐ |
| Resource footprint | ⭐⭐⭐ | ⭐ | ⭐⭐ |
| Bot/Agent API | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Community size | ⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Fork-ability | ⭐⭐⭐ | ⭐ | ⭐⭐ |
| License freedom | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Runs on 4GB VM | ✅ | ⚠️ | ⚠️ |

## Initial Verdict

**Stoat (Revolt) is the top pick for fork-based AI-native chat.**

Reasoning:
1. **Most Discord-like** — servers, channels, roles, emoji, reactions all exist
2. **Lightest footprint** — runs on 2GB, fits our VMs
3. **Cleanest codebase for deep modification** — Rust mono-repo with clear crate boundaries
4. **No plugin system is actually an advantage for forking** — we'd fork and modify core anyway; a plugin system adds indirection we don't need
5. **AGPL is fine** — we'd open-source our fork

The lack of plugin system means every AI feature requires code changes, but since we're building an opinionated AI-native platform (not a general-purpose chat), that's actually what we want — deep integration, not bolt-on apps.

## Stoat Codebase Deep-Dive (2026-06-06)

### Organization & Repos

The project rebranded from Revolt → Stoat. Two GitHub orgs co-exist:
- **revoltchat** — legacy org, contains `desktop` (1031⭐), `vortex` (119⭐, WebRTC voice, Rust), `themes`, `translations`, `rfcs`. Most repos last pushed mid-2025.
- **stoatchat** — new org, contains active repos:
  - `stoatchat/stoatchat` (3073⭐, 354 forks) — **mono-repo backend** (Rust). Last pushed 2026-06-05. v0.13.7 (2026-05-21).
  - `stoatchat/for-web` (703⭐, 293 forks) — **web frontend** (TypeScript/Solid.js). Last pushed 2026-06-06. AGPL-3.0.
  - `stoatchat/for-desktop` (312⭐) — Electron/Tauri desktop app.
  - `revoltchat/javascript-client-sdk` (284⭐) — **revolt.js** SDK (TypeScript, MIT). Last pushed 2026-05-24. Active.

### Backend Architecture (stoatchat/stoatchat)

Rust workspace with 5 top-level crate groups:

```
crates/
├── core/           # Shared libraries
│   ├── coalesced   # Event coalescing
│   ├── config      # TOML config (Revolt.toml)
│   ├── database    # MongoDB driver + model CRUD
│   ├── files       # File processing (S3/MinIO)
│   ├── models      # Data models (User, Channel, Server, Message, Bot, etc.)
│   ├── parser      # Message content parser
│   ├── permissions # Permission bitfields & resolution
│   ├── presence    # Online/offline tracking
│   ├── ratelimits  # Rate limiting
│   └── result      # Error types
├── delta/          # REST API server (Axum + Rocket dual-framework)
│   └── src/routes/ # bots, channels, servers, users, webhooks, safety, policy, etc.
├── bonfire/        # WebSocket event gateway
│   └── src/        # main.rs, websocket.rs, events/, config.rs, database.rs
├── services/       # Auxiliary HTTP services
│   ├── autumn      # File upload/download server (S3-backed)
│   ├── january     # URL metadata extraction & image proxy
│   └── gifbox      # Tenor GIF proxy
└── daemons/        # Background workers
    ├── crond       # Scheduled tasks
    ├── pushd       # Push notifications (FCM, APNs, web-push)
    └── voice-ingress # LiveKit voice call handling
```

### Key Data Models (from source)

**User** (`core/models/src/v0/users.rs`):
- Fields: `id`, `username`, `discriminator`, `display_name`, `avatar`, `relations`, `badges` (u32 bitfield), `status`, `flags` (u32 bitfield), `privileged` (bool), `bot: Option<BotInformation>`, `relationship`, `online`
- **Key insight:** Bot/human distinction is via `bot: Option<BotInformation>` field. An "Agent" type could follow this pattern — `agent: Option<AgentInformation>` — minimal model surgery.

**Bot** (`core/models/src/v0/bots.rs`):
- Fields: `id`, `owner_id`, `token`, `public`, `analytics`, `discoverable`, `interactions_url`, `terms_of_service_url`, `privacy_policy_url`, `flags` (u32)
- Separate collection from User, linked by `id` (Bot.id == User.id for bot users)
- BotFlags: Verified (1), Official (2)

**Channel** (`core/models/src/v0/channels.rs`):
- Tagged enum: `SavedMessages`, `DirectMessage`, `Group`, `TextChannel`, `VoiceChannel`
- TextChannel has: `server`, `name`, `description`, `icon`, `last_message_id`, `default_permissions`, role permission overrides
- **No Forum/Thread channel type yet** — would need to add for our use case

**Server** (`core/models/src/v0/servers.rs`):
- Fields: `id`, `owner`, `name`, `description`, `channels` (Vec<String>), `categories`, `system_messages`, `roles` (HashMap<String, Role>), `default_permissions`, `icon`, `banner`, `flags`, `nsfw`, `analytics`, `discoverable`

**Message** (`core/models/src/v0/messages.rs`):
- Fields: `id`, `nonce`, `channel`, `author`, `user`, `member`, `webhook`, `content`, `system` (SystemMessage), `attachments`, `edited`, `embeds`, `mentions`, `role_mentions`, `replies`, `reactions` (IndexMap), `interactions`, `masquerade`, `pinned`, `flags`
- Supports replies (array of message IDs), reactions, embeds, masquerade (name/avatar override)
- **Masquerade is interesting** — agents could use this to represent different "modes" visually

**Permissions** (`core/permissions/`):
- Three scopes: `user.rs`, `server.rs`, `channel.rs`
- Bitfield-based, with Override (allow/deny) per role per channel
- Clean trait-based architecture — easy to extend for Agent-specific permissions

### Infrastructure Dependencies (compose.yml)

| Service | Image | Port | Purpose |
|---|---|---|---|
| redis | eqalpha/keydb | 6379 | Cache, pub/sub, presence |
| database | mongo | 27017 | Primary data store (replica set) |
| minio | firstfinger/minio | 9000/9001 | S3-compatible file storage |
| rabbit | rabbitmq:4-management | 5672/15672 | Event bus (AMQP) |
| maildev | maildev/maildev | 25/8080 | SMTP (dev) |
| livekit | stoatchat/livekit-server | host network | Voice/video |

**Minimum production:** MongoDB + KeyDB + RabbitMQ + MinIO. Voice optional.

### Frontend (stoatchat/for-web)

- **Framework:** Solid.js (reactive, fine-grained updates, similar to React but faster)
- **SDK:** Uses revolt.js (javascript-client-sdk) for API/WebSocket communication
- **License:** AGPL-3.0
- **Active:** Last push 2026-06-06 (today)

### revolt.js SDK

- 284⭐, MIT license (most permissive)
- TypeScript, actively maintained (pushed 2026-05-24)
- Provides: REST client, WebSocket client, event handling, message sending
- **OpenClaw integration path:** Could create an OpenClaw channel adapter using revolt.js, similar to Discord adapter

### AI-Native Fork: Modification Map

Based on source analysis, here's where each AI feature would be implemented:

| Feature | Crate(s) to Modify | Complexity |
|---|---|---|
| Agent as first-class entity | `core/models` (add AgentInfo to User), `core/database` (agent CRUD), `delta/routes` (agent API) | Medium |
| Agent permissions (scoped tool access) | `core/permissions` (new AgentPermission bits) | Low |
| Agent presence/activity dashboard | `core/presence` (extend status types), `bonfire` (new events) | Medium |
| Task/TODO system | New `core/models/tasks.rs`, new `delta/routes/tasks`, new DB collection | Medium-High |
| Project concept (group of channels) | Extend `Server` model with project metadata, or use `categories` | Low |
| Thread/Forum channels | New Channel variant in enum, new routes | Medium |
| Agent activity log | New model + daemon, or extend existing `crond` | Medium |
| Webhook-based agent integration | Already exists (`channel_webhooks`) — extend for richer payloads | Low |

### Competitor Scan (2026-06-06)

Searched GitHub for new entrants. Nothing significant:
- **Sabha** (Ruby, 10⭐) — too early
- **Gratonite** (TS, 10⭐, AGPL) — claims federation + E2E, but 10 stars = vaporware
- **OpenCord** (Rust+SolidJS, 3⭐) — hobby project, interesting tech overlap with Stoat

No new serious contenders have emerged. Stoat remains the clear best option.

## Updated Recommendation

**Stoat is confirmed as the best fork candidate** after source-level analysis:

1. **Clean model layer** — `auto_derived_partial!` macro system means adding new fields is mechanical
2. **Bot→Agent upgrade path is clear** — `BotInformation` pattern directly maps to `AgentInformation`
3. **Permission system is extensible** — bitfield + trait pattern, add new bits without breaking existing
4. **Dual HTTP framework** (Axum + Rocket) may be confusing but routes are well-organized
5. **Active development** — 3 releases in May 2026, frontend updated today
6. **revolt.js SDK is MIT** — can build OpenClaw adapter without AGPL concerns

## Thread/Forum Channel Feasibility (2026-06-06)

### Current State in Stoat

**Stoat has NO thread or forum channels.** The `Channel` enum has exactly 5 variants:
- `SavedMessages` — personal notes
- `DirectMessage` — 1:1
- `Group` — multi-user DM
- `TextChannel` — server text channel
- `VoiceChannel` — merged into TextChannel via `voice: Option<VoiceInformation>`

**Community demand exists but is unaddressed:**
- [stoatchat/stoatchat#429](https://github.com/stoatchat/stoatchat/issues/429) — "Forum channels" feature request (2025-08-24, open, 0 comments)
- [stoatchat/for-web#1151](https://github.com/stoatchat/for-web/issues/1151) — "Complete Discord Features" requesting forum/thread (2026-05-05, closed without implementation)
- No RFC exists in `revoltchat/rfcs` for threads/forums
- No work-in-progress branches found

**Current "threading" mechanism:** Messages have `replies: Option<Vec<String>>` — flat reply chains (like Revolt/Discord reply-to), not nested threads. No separate thread view, no thread-as-sub-channel.

### Implementation Analysis

Adding threads to Stoat would require:

| Layer | Changes | Effort |
|---|---|---|
| **Models** | New `Thread` variant in Channel enum with `parent_channel: String`, `starter_message: String`, `message_count`, `last_message_id`, auto-archive settings | Medium |
| **Database** | New MongoDB queries for thread CRUD, thread listing under parent channel | Medium |
| **API routes** | New `delta/routes/threads/` — create from message, list threads, archive/unarchive | Medium |
| **WebSocket events** | New events in `bonfire`: `ThreadCreate`, `ThreadUpdate`, `ThreadDelete`, `ThreadMemberUpdate` | Medium |
| **Permissions** | New permission bits: `CreateThreads`, `ManageThreads`, `SendMessagesInThreads` | Low |
| **Frontend** | Thread panel UI in Solid.js, thread indicators on messages, thread list sidebar | High |
| **revolt.js SDK** | Thread-aware API methods, event handlers | Low |

**Estimated total effort:** 2-3 weeks for a basic implementation (backend + frontend).

**Design decision:** Two approaches:
1. **Discord-style threads** — thread is a lightweight sub-channel spawned from a message, auto-archives
2. **Forum channels** — dedicated channel type where each "post" is a thread (like Discord Forum channels)

For AI-native use, **both are valuable:**
- Threads → agent can spawn focused conversations without polluting main channel
- Forum → task boards, issue tracking, structured discussions

**Recommendation:** Implement threads first (more universally useful), then forum channels on top (forum = channel where you can ONLY create threads, no direct messages).

### Key Insight: Thread Model Fits Agent Tasks Naturally

A thread is essentially: "a focused sub-conversation about one thing, spawned from context in a main channel." This maps perfectly to agent task execution:
- User posts task in main channel → agent spawns thread → works in thread → reports back
- Thread auto-archive = task completion
- Thread metadata = task status, assigned agent, priority

This could be Stoat-AI's killer feature: threads that ARE tasks.

## OpenClaw ↔ Stoat Integration Architecture (2026-06-06)

### WebSocket Protocol Analysis

Stoat's real-time protocol is simple and well-suited for adapter integration:

**Client → Server (ClientMessage):**
- `Authenticate { token }` — bot token auth (same as user)
- `BeginTyping { channel }` / `EndTyping { channel }` — typing indicators
- `Subscribe { server_id }` — subscribe to server events
- `Ping { data }` — keepalive

**Server → Client (EventV1) — ~30 event types:**
- `Authenticated` → connection confirmed
- `Ready { users, servers, channels, members, emojis, ... }` → initial state dump
- `Message(Message)` → new message (the core event for adapter)
- `MessageUpdate / MessageAppend / MessageDelete` → message lifecycle
- `MessageReact / MessageUnreact` → reactions
- `ChannelCreate / ChannelUpdate / ChannelDelete` → channel lifecycle
- `ServerUpdate / ServerMemberUpdate` → server events
- `ChannelStartTyping / ChannelStopTyping` → typing
- `WebhookCreate / WebhookUpdate / WebhookDelete` → webhook events
- `Bulk { v: Vec<EventV1> }` → batched events

**Event routing:** Redis pub/sub with channel naming:
- `{user_id}` — user events
- `{user_id}!` — private events
- `{server_id}u` — server member events
- `global` — global events

### revolt.js SDK (MIT)

The official TypeScript SDK (`revoltchat/javascript-client-sdk`, 284⭐) provides:
- `Client` class with reactive collections (users, channels, servers, messages)
- Event emitter: `messageCreate`, `messageUpdate`, `messageDelete`, `channelCreate`, etc.
- REST API wrapper via `stoat-api` package
- Connection state management (connecting, connected, disconnected, reconnecting)
- Uses Solid.js reactivity primitives — works in Node.js too

**Bot connection is trivial:**
```typescript
import { Client } from 'revolt.js';
const client = new Client();
client.on('messageCreate', (message) => {
  // Route to OpenClaw
});
await client.loginBot('bot-token');
```

### Adapter Architecture Design

```
┌─────────────────────────────────────────────────────────────┐
│  OpenClaw Gateway                                            │
│  ┌─────────────────────┐     ┌──────────────────────────┐   │
│  │  Stoat Channel       │     │  Discord Channel          │   │
│  │  Adapter (new)       │     │  Adapter (existing)       │   │
│  │                     │     │                          │   │
│  │  revolt.js SDK       │     │  discord.js              │   │
│  │  ┌─────────────┐   │     │                          │   │
│  │  │ WS Client   │   │     │                          │   │
│  │  │ REST Client │   │     │                          │   │
│  │  └─────────────┘   │     │                          │   │
│  └────────┬────────────┘     └──────────────────────────┘   │
│           │                                                  │
│  ┌────────▼──────────────────────────────────────────────┐   │
│  │  Unified Message Bus (existing)                        │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
          │                           │
    ┌─────▼───────┐            ┌──────▼──────┐
    │ Stoat Server│            │ Discord API │
    │ (self-hosted)│            │ (cloud)     │
    └─────────────┘            └─────────────┘
```

**Adapter responsibilities:**
1. **Inbound:** Listen for `messageCreate` via revolt.js → normalize to OpenClaw message format → route to agent
2. **Outbound:** Receive agent responses → format for Stoat (markdown, embeds, masquerade) → send via REST
3. **Features:** Typing indicators, reactions, file attachments (via Autumn file server), message editing
4. **Auth:** Bot token for basic integration; could also use webhook API for simpler one-way posting

**Masquerade feature is uniquely useful:** Stoat messages support `masquerade { name, avatar }` — an agent could visually represent different "modes" (thinking, executing, reporting) with different avatars, without needing separate bot accounts.

### Two Integration Paths

| Path | Description | Effort | When |
|---|---|---|---|
| **Path A: Adapter only** | Add Stoat as OpenClaw channel (like Discord/Feishu). Use stock Stoat. Bot joins server, responds to messages. | 1-2 weeks | Immediate — validate Stoat as chat platform |
| **Path B: Fork + Adapter** | Fork Stoat, add AI-native features (agent entity, threads, tasks), build adapter for the fork. | 2-3 months | After Path A validates the UX |

**Recommendation: Path A first.** Deploy stock Stoat, build adapter, use it daily. This validates:
- Is Stoat's UX actually good enough?
- Does self-hosting work on our infra?
- Is the bot API responsive enough for real-time agent interaction?

Only after answering these → commit to the fork.

### Deployment Fit

Stoat minimum: 2 vCPU, 2GB RAM. Our options:
- **kagura-server (local):** Plenty of resources, no cost. Good for dev/testing.
- **VM1 (Japan):** Already at ~466MB used / 4GB total. Could fit but tight with other services.
- **New VM:** Recommended for production. Stoat + MongoDB + KeyDB + MinIO = dedicated instance.

Docker Compose makes deployment straightforward — one `docker compose up -d`.

## Next Steps

1. [ ] Clone and build Stoat locally — verify compile + Docker startup on kagura-server
2. [ ] Test revolt.js SDK — connect as bot, send/receive messages
3. [ ] Prototype: Add `AgentInformation` to User model, see what breaks
4. [x] Evaluate Thread/Forum channel feasibility — **feasible, ~2-3 weeks, threads-as-tasks is the killer feature**
5. [x] OpenClaw adapter architecture design — **two-path strategy: adapter first, fork later**
6. [ ] Luna decision: confirm Stoat as base, define MVP feature list
