---
title: Junction — Multi-Backend VS Code Chat Sidebar
slug: junction
created: 2026-06-20
updated: 2026-06-20
status: deep-read
source: https://github.com/Plaer1/junction
stars: 514
last_verified: 2026-06-20
---

# Junction

> VS Code chat sidebar that connects to 7 local AI coding agent backends through a unified bridge interface. Based on Owen-Liuyuxuan's openclaw_vscode (MIT), significantly extended.

## Key Stats

- **514⭐ in 3 days** (single polished drop, not iterative dev — 1 commit)
- ~10K lines TypeScript, 7 bridge adapters (4350 lines combined)
- 0 issues, 0 PRs — brand new, no community engagement yet
- Based on [[openclaw]]_vscode lineage

## Architecture

### Bridge Pattern (core abstraction)

Abstract `ChatBridge` interface (`types.ts`) defines the contract:
- `connect/disconnect/isConnected`
- `sendChatMessage`, `stopRun`, `injectMessage`
- `listSessions`, `createChat`, `getSessionHistory`
- `listModelChoices`, `selectModelChoice`
- `canSteer()` for mid-turn steering support
- `watchSession/unwatchSession` for transport-level event scoping

7 implementations:
| Bridge | Transport | Lines |
|--------|-----------|-------|
| **OpenClaw** | WebSocket (gateway) | 517 |
| Hermes | WebSocket + REST | 633 |
| Souveraine | SSE + HTTP | 584 |
| MiMoCode | HTTP | 805 |
| Goose | HTTP | 381 |
| OpenCode | HTTP | 428 |
| OpenHands | HTTP | 411 |

Each bridge has its own `events.ts` that maps backend wire events into normalized `MappedBridgeEvent` types:
- `agent_lifecycle` (start/end)
- `agent_message` (text deltas)
- `thinking_chunk` (reasoning blocks)
- `tool_event` (tool calls + results)

**Insight**: The bridge registry pattern (register → getAll → setActive) with fallback logic handles the "which runtime is available right now" problem cleanly. BridgeRegistry.active always resolves even when configured bridge isn't registered yet.

### Checkpoint Manager (novel feature)

Shadow git repo (`--git-dir` in extension globalStorage) snapshots workspace at each user-turn boundary. Key design:
- **Never touches user's .git** — separate git-dir
- **Scoped rewind** — only restores tracked files + removes agent-added files; user's untracked files preserved
- **Rewind is undoable** — snapshots current state before restoring
- `recordTouchedPath()` tracks files modified by agent for precise scope

This is genuinely useful — cursor-style "undo turn" for any agent backend. Not seen in other VS Code agent extensions.

### Session Scoping

`GatewayConnection.watchSession(key)` filters the gateway's firehose `sessions.subscribe` events at transport level:
- Only events for watched sessions pass through to views
- Prevents cross-window bleed in multi-window VS Code
- `sessions.changed` list updates always pass through (correct — need folder session list)

### Multi-Folder Binding

`ChatIndex` binds sessions to workspace folder URIs via `bindingIdForUri`. Each folder gets its own active session. `FolderSessions` manages per-folder session lists.

## What's Surprising

1. **Animation system is enormous** — matrix rain, 10 character sets, 9 exit animation modes, per-mode sliders, live preview canvas. This is 2x the effort of the actual chat UX. Developer clearly values polish/experience over utility-first.

2. **OpenClaw is first-class, not bolted on** — the OpenClaw bridge is the most integrated (capabilities: sessions ✅, models ✅, agents ✅, steering ✅, usage ✅, tools ✅, hidesRawThinking ✅). Other bridges lack subsets.

3. **Single commit, 514⭐** — this was dropped as a finished product, not built in public. Suggests a developer with existing audience or good launch positioning.

4. **Test coverage is minimal** — 1 test file testing only event mapping for Hermes/Souveraine/MiMoCode. No tests for OpenClaw bridge, gateway connection, checkpoint manager, or UI.

## Relevance to Us

### Carry Project (direct competitor/reference)

Luna's [[carry]] VS Code extension project wants to do something similar but OpenClaw-focused. Junction is the most direct comparable:
- **Adopt**: checkpoint/rewind concept (shadow git)
- **Differentiate**: carry should go deeper on OpenClaw-specific features (cron, skills, memory) rather than multi-bridge breadth
- **Avoid**: animation bloat — carry should be utility-first

### Bridge Pattern Decision

If carry is OpenClaw-only → skip bridge abstraction, invest in depth.
If carry wants multi-backend → junction's bridge contract is well-designed, study `types.ts` as reference.

### Session Scoping Pattern

`watchSession/unwatchSession` is worth studying for any multi-panel VS Code extension consuming gateway events. Prevents the firehose problem cleanly.

## Ecosystem Position

Junction sits at the "unified frontend" layer — same agent, different UIs. Competes with each runtime's native UI (OpenClaw TUI, Hermes dashboard) but adds VS Code integration depth (file context, model picker, checkpoints).

**Moat question**: Will runtimes build their own VS Code extensions (like openclaw_vscode already exists)? If so, Junction's value is the multi-backend switch. If not, each runtime might adopt Junction as their official VS Code UI.

## Links

- [[openclaw]] — primary backend integration
- [[agent-harness-landscape]] — junction is a "frontend bridge" not a harness
- [[carry]] — Luna's VS Code extension project, direct reference
