---
title: "FableCut — Agent-Drivable Browser Video Editor"
created: 2026-07-10
status: deep-read
stars: 253
url: https://github.com/ronak-create/FableCut
author: ronak-create (ronak parmar)
last_verified: 2026-07-10
---

# FableCut — Agent-Drivable Browser Video Editor

**What:** Premiere-style NLE (non-linear editor) that runs entirely in browser, exposes its whole timeline as one JSON document. Any process that writes JSON can edit video. Zero npm dependencies. ~3700 lines total.

**Core thesis:** "The project file IS the interface." Instead of hiding edits behind API actions, the timeline JSON *is* the control surface. Agent and human work on the same state simultaneously.

## Architecture (Key Patterns)

### 1. Document-as-Interface
- `project.json` = complete editor state (media registry + clip timeline + keyframes + effects)
- Write JSON → browser hot-reloads in ~150ms via SSE
- Eliminates the "API translation layer" — no mapping between agent intent and tool actions

### 2. Three Equivalent Control Surfaces
| Surface | Best for | Mechanism |
|---------|----------|-----------|
| MCP (stdio) | Claude Code/Desktop, any MCP client | JSON-RPC tools |
| File | Direct writes, any process | Read/modify/write `project.json` |
| REST | Webhooks, web-based agents | GET/PUT /api/project, SSE |

Same underlying state, agent picks most natural access pattern.

### 3. Conflict-Safe Concurrent Editing (Optimistic Concurrency)
- `revision` counter in project.json, bumped on every write
- MCP server tracks `lastReadRevision` — refuses clobber if file moved past it (409)
- UI detects external writes by revision comparison → toast notification
- `fablecut_patch_project` re-reads from disk → inherently merge-safe
- **Pattern worth adopting:** any agent-human shared state should have a revision/generation counter

### 4. Token-Efficient MCP Design
- `fablecut_get_project {compact:true}` → one-line-per-clip summary (~10x smaller)
- `fablecut_patch_project` → ops instead of round-trip (10-100x cheaper)
- `fablecut_docs {section:"..."}` → fetch only needed schema sections
- Duration/dimensions from registered media entries, not ffprobe shells
- **Lesson:** MCP tools should offer "compact" views and incremental mutation, not just CRUD

### 5. Reference Analysis → Blueprint → Rebuild
- `analyze.js` (289 lines): ffmpeg scene detection + PCM onset/beat detection + BPM + energy curve
- Produces "edit blueprint": cut points, beat timestamps, drop location, extracted music track
- Agent then reconstructs same edit rhythm with different footage
- **Pattern:** decompose creative artifact → structural blueprint → reconstruct with new material
- Applies beyond video: could do this for presentations, music arrangements, writing style

## Technical Details
- **server.js** (402 lines): zero-dep HTTP server, REST API, SSE, ffmpeg export pipeline
- **app.js** (2493 lines): full editor UI, Canvas2D compositor, keyframe engine, text engine, SVG rasterizer, chroma key
- **mcp-server.js** (491 lines): stdio MCP server, 7 tools, atomic file writes (tmp+rename)
- **analyze.js** (289 lines): shot detection + beat/BPM extraction + energy curve

## What's Novel vs Known

| Aspect | Novel? | Notes |
|--------|--------|-------|
| Document-as-interface for creative tools | ✅ Yes | Most "AI video" tools hide state behind API |
| Optimistic concurrency for agent-human co-editing | ✅ Yes | Smart adaptation of database pattern to agent UX |
| Token-efficient MCP design (compact/patch/sections) | ✅ Yes | Exemplary — most MCP tools still do full CRUD |
| Browser-rendered export | Partially | WebCodecs-based exporters exist, but combined with agent-driven editing is novel |
| Reference analysis → blueprint | ✅ Yes | "Style transfer for video editing structure" |
| Zero-dependency ethos | Known | Same philosophy as pu.sh, but applied to a complex creative tool |

## Community Assessment (2026-07-10)
- 253⭐ in 4 days, 9 forks
- 90pts on HN (Show HN)
- 6 issues total, 5 self-filed by author, 1 external (security policy)
- Solo dev, burst-publish. Too early for community health assessment.
- Issues show roadmap: AGENTS.md support (non-Claude), vision/frame analysis, auto-captions, WebCodecs export, GitHub Pages demo

## Relevance to Our Direction

1. **MCP tool design principles** — compact views, patch ops, sectioned docs. Should influence how we design any MCP-exposed tool.
2. **Concurrent editing pattern** — revision-based optimistic concurrency for agent-human shared state. Applicable to OpenClaw config, shared project files.
3. **"Spectator mode" trust** — human watches edits appear in real-time (150ms SSE). Psychologically important for agent trust. We could apply this to any agent-driven workflow with a live UI.
4. **Blueprint pattern** — decompose → structure → reconstruct. Applicable to many creative tasks beyond video.

## Tracking
- Revisit: 2026-07-24 (check community formation, external PRs, version milestones)
- Watch for: AGENTS.md support (would make it OpenClaw-compatible), WebCodecs export, vision integration
