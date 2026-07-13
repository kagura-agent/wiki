---
title: "mindwalk — 3D Coding-Agent Session Replay"
repo: cosmtrek/mindwalk
url: https://github.com/cosmtrek/mindwalk
created: 2026-07-09
stars: 317
language: Go + TypeScript (React/Three.js)
author: Ricko Yu (cosmtrek)
license: MIT
studied: 2026-07-13
depth: deep-read
status: new
verdict: hot
last_verified: 2026-07-13
---

## mindwalk - Deep Read Summary

### Problem: What it solves, why now

**Core problem**: Agent session logs (JSONL) tell you *what* an agent did but not *how it understood your codebase*. Reading raw JSONL line-by-line doesn't answer: which parts of the repo did it treat as relevant? Where did it explore before acting? Did its footprint match the scope you had in mind?

**Why now**: Coding agents (Claude Code, Codex) are becoming the primary development interface. As sessions grow longer and more complex (subagents, context compactions, multi-file edits), the gap between "agent did stuff" and "I understand what it did" widens. There's a genuine observability gap — you can't review what you can't see.

**Analogy**: The codebase is drawn as a "night map" (dark terrain), and the session replays as light moving through it — glowing where the agent searched, read, and edited. The agent's understanding becomes a shape you can see at a glance.

### Architecture: Core design, key patterns, tradeoffs

**Two-artifact separation** (the most important design decision):

1. **Trace** — normalized event stream from session logs (`internal/adapter`). Each agent format gets its own adapter (currently Claude Code + Codex). Adapters don't know about rendering.
2. **CityMap** — deterministic layout of the repository (`internal/citymap`). Same tree always produces the same map, making replays comparable across sessions. Citymap generation doesn't depend on playback.

**Stack**:
- **Backend**: Single Go binary, stdlib-only (no dependencies). Local server connects adapters + citymap to the frontend.
- **Frontend**: React 19 + Three.js 0.182 + Zustand (state) + Vite 7. Embedded in the Go binary via `//go:embed`.
- **Visualization**: Two views — radial tree and squarified treemap ("terrain"). Three.js handles 3D rendering with custom attention-height terrain.

**Key patterns**:

- **Squarified treemap layout** (`internal/citymap/builder.go`): Files are weighted by `sqrt(max(lines, bytes/4096, 16))` — the square root prevents large files from dominating. Deterministic placement means same repo = same map, always.
- **Touch state model**: Each file has a deepest-touch state: `hit` (seen, moss green) → `read` (moon white) → `edit` (warm amber). Monotonically increasing — once edited, stays edited.
- **Action classification** (`internal/adapter/adapter.go`): Tool calls are classified into action types: search, read, edit, exec, verify, other. Shell commands are conservatively parsed — `grep`, `rg`, `find` → search; `cat`, `head` → read; `go test`, `pytest` → verify. Unrecognized commands stay "exec".
- **Weak vs strong targets**: File paths from tool inputs (Read, Write) are "strong" targets. Paths extracted from shell commands/output are "weak" — they require filesystem existence check before appearing on the map.
- **Ghost files**: Files referenced in traces but missing from the current repo tree appear as "ghost" tiles on the map.
- **Outside touches**: Files outside the repo root are tracked separately with scope classification (home/tmp/other).
- **Session stats**: Rich derived metrics — fovea (files read or edited), parafovea (files only hit), churn (files edited 3+ times), regression rate (re-reads after no edit), error rate, edits-after-last-verify. Each metric has an observability grade (exact/estimated/unavailable).
- **Concurrent session scanning**: Cold scans use `runtime.NumCPU()` workers to parse session files in parallel.
- **LRU trace cache**: 16 entries max, fingerprinted by file size + mtime, 10-minute TTL.

**Frontend visualization details**:
- **Attention terrain**: Height is earned by attention — touch depth × revisits. Mountains grow where the agent lingered.
- **Playback timeline**: Bucketed histogram with cool/warm spectrum — observation (search, read) stays cool, mutation (edit, verify) glows warm.
- **Timeline marks**: `◇` context compactions, `○` subagent launches, `›` user turns — click-to-jump targets.
- **Inspector**: Click file → pin its visit history → click visit row → jump playhead.
- **Video export**: Client-side recording via MediaRecorder API (WebM/MP4).

**Tradeoffs**:
- Go 1.25 requirement limits immediate adoption (bleeding edge toolchain)
- Only supports Claude Code and Codex — no Cursor, Copilot, Cline adapters yet
- Requires local repo checkout for citymap building (git ls-files)
- No remote/hosted mode — fully local, which is a feature for privacy but limits shareability

### Code Quality: Test coverage, activity signals, community health

- **Test coverage**: Go tests for adapter parsing (action classification, target extraction, exec command parsing, session key stability), citymap builder (empty/single/deep repos, ghost files), stats computation, and server integration. ~340 lines of adapter tests covering edge cases thoroughly.
- **Commit history**: 34 commits, all from a single author. Clean, conventional-commit-style messages. Project is 4 days old but shows disciplined development.
- **Code structure**: Well-separated packages, clean interfaces (`Source` interface for adapters), no God files. The adapter.go is the largest file (~600 lines) but handles genuinely complex parsing.
- **Schema discipline**: JSON schemas in `schema/` mirror the Go types — contracts are documented and versioned.
- **Release pipeline**: goreleaser config, install script with checksum verification.
- **Frontend**: TypeScript throughout, Zustand for state management, clean component separation (scene/ui/playback/state).

### Ecosystem Position

**Competitors/Comparisons**:
- **City metaphors for code**: CodeCity, code_swarm, Gource — but those visualize *git history*, not agent sessions. Mindwalk visualizes agent *attention*, which is a different signal entirely.
- **Agent observability**: LangSmith, Weights & Biases Traces, AgentOps — but those are cloud-based, generic LLM tracing tools. Mindwalk is purpose-built for coding-agent spatial understanding.
- **Session replay**: No direct competitor for "replay agent session on codebase map" exists.

**Complements**: Works directly with Claude Code and Codex logs. Could complement Ditto (see below) — Ditto mines *what you said*, Mindwalk shows *where the agent went*.

**Community signals**: Issue #2 requests a git/fs adapter (someone already has a PR). Still very early but the 317 stars in 4 days suggests genuine interest.

### Relevance to Us

**Directly applicable patterns**:

1. **Action classification taxonomy** (search/read/edit/exec/verify/other): Our OpenClaw sessions produce similar tool-call patterns. The conservative approach to classifying shell commands is well-thought-out and could inform session analysis.

2. **Touch state model** (hit → read → edit): Clean abstraction for "how deeply did the agent engage with this file." Could be useful for our own session analytics.

3. **Observability grading** (exact/estimated/unavailable): Honest about what the adapter can actually measure vs. what it infers. This is a pattern worth stealing for any metric system.

4. **Squarified treemap with sqrt weighting**: If we ever want to visualize our own workspace/session coverage, this is a proven layout algorithm.

5. **The "outside touch" concept**: Tracking when agents reach outside the repo boundary — useful for security/scope monitoring.

**For our agent sessions**: Our sessions produce JSONL too. An OpenClaw adapter for mindwalk would let us visualize our own agent behavior. The adapter interface is clean — implementing `Harness()`, `SessionDir()`, `ListSessions()`, `Summarize()`, `Parse()`.

**Meta-observation**: This is the kind of tool that becomes more valuable as agents do more. If agents are writing 80% of code, "understanding what the agent understood" becomes critical for code review.

### Verdict: Hot 🔥

**Track level**: Hot — worth active monitoring and potential contribution.

**Reasons**:
- Novel category: no one else is doing spatial agent session replay
- Clean architecture with deliberate separation of concerns
- Practical: one binary, fully local, zero config
- The adapter pattern makes it extensible (OpenClaw adapter feasible)
- Only 4 days old but already 317 stars — momentum signal
- The problem it solves (agent observability) will only grow

**Watch for**: Whether community contributes adapters (git/fs PR already in progress), whether the author adds support for more agent formats, and whether the 3D visualization proves genuinely useful vs. a novelty.

### Issue Insights

- **Issue #2 — "Add git/fs adapter"**: Someone wants to use the same visualization for regular git history (not agent sessions). A contributor already has a stacked PR ready. This suggests the treemap visualization has standalone value beyond agent replay.
- Only 1 issue total — project is brand new. Community engagement is happening through stars and the one feature request.
