---
title: "TokenCode — Parallel-Native Agent Runtime in Go"
repo: yzfly/TokenCode
stars: 26
created: 2026-06-09
last_push: 2026-06-11
language: Go
license: CC-BY-NC-4.0
scouted: 2026-06-11
last_verified: 2026-06-11
---

# TokenCode — Parallel-Native Agent Runtime in Go

## What It Is

Go-based terminal coding agent aiming to become a **team agent engine** — not just a personal tool like Claude Code/OpenCode, but a deployment for entire teams with isolated workspaces, shared model access, and usage dashboards. Author: 云中江树 (yzfly).

Current state: single-agent MVP + `/race` competitive parallelism mode (v1 just landed 2026-06-11).

## Key Innovation: /race (Competitive Parallelism)

The killer feature differentiating TokenCode from all other coding agents:

```
/race 8 修复 internal/foo 的并发 bug，跑通全部测试
```

1. **N agents (up to 1000)** each get an isolated git worktree
2. **Windowed concurrency** (default 8) — worktrees created lazily as racers enter window
3. **Judge pipeline** — 3-stage with zero-token-first design:
   - L1: Objective screening (empty diff / check command failure → eliminated, **zero tokens**)
   - L2: Parallel LLM scoring (JSON output, retry once on parse failure)
   - L3: Top-4 final judgment
4. **Human gate**: `/race apply` to accept winner diff, `/race discard` to reject (winner branch always preserved)

### Architecture Insight

The `race` package has **zero internal dependencies** — `SpawnFunc` and `CompleteFunc` are injected closures. This makes it independently testable with fake agents and real git repos. Very clean design.

**Tradeoff noted honestly by author**: racers get auto-approved tools within their worktree. File tools are hard-isolated, but bash only gets `cwd` — no sandbox. For 1000 agents, per-command approval is impractical.

### vs Paragents ([[paragents]])

| Aspect | TokenCode /race | Paragents |
|--------|----------------|-----------|
| Model | Competitive (best-of-N) | Cooperative (parallel tasks) |
| Isolation | Git worktree per racer | Preflight conflict detection |
| Scale | Up to 1000 | Up to 4 |
| Goal | Same task, pick winner | Different tasks, avoid conflicts |
| Philosophy | Tournament / genetic-selection | Team coordination |

Both address "how to parallelize agent work" but from opposite angles. TokenCode's approach is more radical — it's closer to **evolutionary search** than workflow orchestration.

## Heartbeat & Dreaming (internal/pulse)

Three-level token-saving heartbeat:
- **L0**: Local checks (zero tokens). If all checks empty → skip entirely
- **L1**: One LLM call. If agent returns sentinel → prune from history
- **L2**: Full turn (only when L1 finds real work)

**Dreaming** (memory consolidation during idle):
- After 10min idle + 8 new messages since last dream, compress conversation into `memory.md`
- Max 6 dreams/day, min 1h interval
- Memory file capped at 8000 chars — **dreaming is compression**, not accumulation
- Atomic write (temp file + rename) — readers never see half-written memory
- Dream runs in background goroutine with 5min timeout, independent of user turns

This is very similar to our heartbeat/memory architecture but more formalized. Key difference: their dreaming is **automatic memory consolidation** vs our MEMORY.md which is manually curated.

## Model Catalog (internal/catalog)

Embeds models.dev directory (141 providers, 394KB). Chinese coding plans (Kimi, Zhipu GLM, Alibaba, MiniMax, DeepSeek, Tencent) work out of box — just `tokencode auth login kimi-for-coding` and paste key. Three protocol codecs: anthropic, openai (Chat Completions), google (Gemini).

Default: DeepSeek v4-pro via Anthropic-compatible endpoint. Economical choice.

## Team Engine Positioning

The author's strategic insight: **every existing agent tool is "one person + their agent"** (Claude Code, Codex, OpenCode, Pi, OpenClaw). Nobody answers "how does a **team** use agents together?"

Planned: IM channel system (Feishu/DingTalk → WeChat iLink → Web), per-member isolated workspaces, shared model access, usage dashboards. Narrative: "GitLab for git" / "one machine, the whole team's AI programmers."

## Relevance to Us

1. **Competitive parallelism** is a genuinely new approach we haven't seen — not just "run agents in parallel" but "make them compete, judge objectively, pick winner." Could inspire a Claude Code /race equivalent for our workloop
2. **Dreaming = automatic memory compression** — our memory is manual; their approach could reduce MEMORY.md maintenance burden
3. **Team positioning is orthogonal to OpenClaw** — OpenClaw is personal agent infrastructure, TokenCode aims for team infrastructure. Not competitors but different market segments
4. **Zero-token heartbeat L0** is the same pattern we use (local checks before spending tokens)
5. **Chinese developer ecosystem focus** — models.dev catalog with Chinese coding plans is a differentiator we don't have

## CC-Parity Feature Burst (2026-06-11)

Within 24h of initial release, author landed a massive batch of Claude Code-parity features:

1. **Permission rule tables** (allow/ask/deny) — declarative governance layered on top of 4 permission modes. Syntax mirrors CC's `CLAUDE.md` rules
2. **Hooks** (PreToolUse/PostToolUse/SessionStart/Stop) — command-based hooks, CC-compatible subset
3. **`/compact` + `/context`** — conversation compression into structured summary (keeps last 2 turns), auto-triggers at 80k tokens. Context usage visualization
4. **Checkpoint `/rewind`** — file-level checkpointing (shadow files + JSONL manifest, per-user-turn). Known blind spot: bash side-effects can't be captured
5. **`-w` worktree mode** — isolated git worktree for each work session, separate from /race worktrees
6. **WebUI v0** — go:embed zero-framework dashboard: usage charts, chat (SSE streaming), team management, model catalog browser. Bound to loopback only
7. **Go SDK** (`pkg/tokencode`) — 10-line agent instantiation for embedding
8. **IM channels** — Feishu (long-connection), DingTalk (Stream), WeChat iLink Bot (experimental). Each team member gets isolated workspace via pairing code
9. **Headless + HTTP API** — `-p` for CI/scripting, `tokencode serve` for HTTP, SSE streaming
10. **Usage accounting** — JSONL ledger, monthly/daily in/out/cache tracking, WebUI dashboard

### Speed Signal

~30 commits in <12h. This is either one person with superhuman output, or AI-assisted development at extreme velocity. Either way, the codebase grew from basic MVP to near-CC-feature-parity in 2 days.

### Architectural Insight: "Five Lines" Strategy

The author explicitly identified 5 feature lines to match CC, calling them "圈选" (selection):
- Permission governance
- Hooks
- Context management (/compact, /context)
- File safety (/rewind checkpoints)
- Worktree isolation

All 5 landed v1 on 2026-06-11. This is a deliberate "match the incumbent, then differentiate" strategy — build CC parity first, then /race + team engine as the wedge.

## ROADMAP Analysis: Cooperative Parallelism (Phase B)

The roadmap reveals the real long-term ambition — **cooperative multi-agent** (Phase B), which is architecturally harder than /race:

- **Workspace Authority** pattern: single-writer actor serializes all file mutations. Agents send patches, authority does 3-way merge
- No direct filesystem access for agents — only read snapshots + submit patches
- Conflict = signal, not failure → escalate to "reconciliation agent"
- Key insight from author: "a multi-agent shared workspace runtime, stripped to its core, is a version control system — except merge conflicts are resolved by intelligence, not thrown at humans"

This is fundamentally different from [[paragents]]' preflight conflict detection. TokenCode's Phase B is essentially building **git-as-a-coordination-primitive** with AI merge resolution.

## Assessment

- **Stars**: 26 (3 days old, growing)
- **Code quality**: High — clean Go, zero-dep race package, comprehensive tests, honest devlog
- **Author quality**: Serious builder (detailed devlog, architectural thinking, honest tradeoff documentation)
- **Velocity**: Extraordinary — near-CC-parity in 2 days
- **Risk**: CC-BY-NC-4.0 license limits commercial use. Name collision risk ("token" in AI/crypto space)
- **Watch?**: Yes — revisit 06-25. The /race concept, team positioning, and Phase B cooperative architecture are all novel

---
*Initial scout: 2026-06-11 08:50 CST*
*Updated: 2026-06-11 10:05 CST — CC-parity feature burst, ROADMAP Phase B analysis, star count 24→26*
