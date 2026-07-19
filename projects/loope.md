---
title: loope
repo: ngthluu/loope
category: Coding Agents
status: tracking
stars: 7
first_seen: 2026-07-19
last_verified: 2026-07-19
---

# loope — Event-Driven Issue→PR Daemon

> Stateless Go daemon that watches a GitHub repo for labeled issues, triages them via LLM, and drives each to a PR using headless Claude Code sessions in isolated git worktrees. All state lives in GitHub labels.

- **Repo**: [ngthluu/loope](https://github.com/ngthluu/loope)
- **Stars**: 7 (2026-07-19, brand new — created 07-16)
- **Language**: Go 1.25+
- **License**: MIT
- **Author**: ngthluu (solo dev)
- **Community**: 0 issues, 0 PRs, 0 forks — untested outside author

## Architecture

### Label-Driven State Machine

All state lives in GitHub labels — the daemon itself is **stateless and safe to restart**:

```
ai-agent → ai-wip → ai-done (PR created)
                  → ai-rework (failure, preserved for resume)
                  → ai-needs-info (under-specified, escalated to human)
```

This is cleaner than file-based state tracking (cf. [[GoGetAJob]]'s gogetajob.json + TODO.md + memory files). GitHub labels are the single source of truth, visible to humans, and survive daemon restarts.

### Dual Pipeline (Bug vs Feature)

**Bug pipeline**: Single Claude Code session — reproduce with failing test → fix → verify → commit.

**Feature pipeline**: Three isolated sessions:
1. **Session A (architect)**: Brainstorm with confidence gate → Q&A with answerer agent (product-owner proxy) → committed spec (`SPEC_READY:`)
2. **Session B (plan)**: Fresh session turns spec into committed implementation plan (`PIPELINE_READY`)
3. **Session C (execute)**: Fresh session implements the plan

Session isolation between phases prevents context contamination. The architect→answerer Q&A loop is bounded by `maxQARounds`.

### Confidence Gate

Before implementing features, the architect scores confidence 0-100 on the first brainstorm turn. Below `confidenceThreshold` (default 70) → escalate to `ai-needs-info` with specific questions. No guessing on under-specified issues.

This is something [[GoGetAJob]] lacks — our preflight checks assess the *repo* (size, test suite, maintainer activity) but not the *issue itself*.

### Session Persistence & Auto-Resume

**Key pattern we don't have**: On failure, loope preserves the worktree AND the Claude Code session ID. `classifyCause()` categorizes failures:
- **Resumable**: rate limits (429), max_turns, network outages, daemon restart → auto-resume with exponential backoff (5min → 60min cap)
- **Non-resumable**: panics, permission errors → parked for human `loope -rework <N>`

When gogetajob fails mid-work, we start from scratch. loope resumes exactly where it stopped. For expensive pipelines, this is significant cost savings.

### Always-On Daemon

- PID lock (one daemon per workDir, atomic with stale detection)
- `SweepOrphans()` on startup: stale ai-wip + surviving worktree/session → park for auto-resume; no resumable state → clean up and re-queue
- Panic containment: per-issue goroutines recover panics, park issue, sibling pipelines continue
- `ticketsPerCycle` > 1 fans out pipelines concurrently

### Test Architecture

All process execution goes through `Runner` interface. Tests inject `fakeRunner` — **entire test suite runs without git/gh/claude installed**. This is exemplary for a tool that wraps CLIs.

Comprehensive logging: every Claude call saves prompt (.prompt.md), output (.output.md), raw JSON (.json), and stream transcript (.stream.jsonl).

## Comparison with GoGetAJob

| Aspect | loope | gogetajob |
|--------|-------|-----------|
| Language | Go binary | Bash/shell scripts |
| State | GitHub labels (stateless) | Files (gogetajob.json, TODO.md) |
| Scope | Single repo | Multi-repo roaming |
| Issue selection | LLM triage | Heuristic scoring |
| Pipeline | Dual path (bug/feature) | Single path + preflight gates |
| Recovery | Auto-resume with session persistence | Start from scratch |
| Confidence gate | Yes (0-100) | No |
| Agent | Headless Claude Code | OpenClaw subagent or Claude Code |

## Insights

1. **Session persistence for resume** is the biggest architectural gap in gogetajob. Saving session IDs to resume failed pipelines would dramatically reduce wasted compute on rate-limited or interrupted runs.

2. **Label-as-state** is simpler and more transparent than file-based state. But it couples the daemon to a single repo — gogetajob's multi-repo roaming wouldn't work with this pattern.

3. **Confidence gate before implementation** is a quality lever we should consider. Asking "can this issue be implemented as written?" before investing in code prevents wasted effort on ambiguous specs.

4. **Runner interface for testability** — wrapping all CLI calls behind an interface and testing with fakes is the right pattern. Our shell scripts are harder to test in isolation.

5. **`--dangerously-skip-permissions`** is required for headless operation. Security trade-off acknowledged in docs but unavoidable for the architecture.

## Weaknesses

- 7⭐, 0 community — no external validation
- Single-repo only — can't roam
- Requires Go 1.25+ (cutting edge)
- No issue quality/spam filtering — relies entirely on human label curation
- No cost aggregation across runs (only per-session Claude stats)
- `PIPELINE_ALREADY_DONE` detection via string sentinel is fragile

## Ecosystem Position

Occupies a niche between manual issue-fixing and full-stack platforms like [[nanobot]] or [[AgentSpace]]. Closest to [[claude-code-routines]] (Anthropic's hosted scheduled runs) but self-hosted and issue-driven. Complements rather than competes with gogetajob — different design philosophy (single-repo depth vs multi-repo breadth).

## Direction Relevance

The session-persistence-for-resume and confidence-gate patterns are directly applicable to improving gogetajob. The label-as-state pattern is elegant but incompatible with our multi-repo model. The Runner-interface testing pattern is worth adopting if we ever rewrite gogetajob tools in a compiled language.

---

*Deep read: 2026-07-19 | Source: GitHub API search (coding-agent topic, created >07-12)*
