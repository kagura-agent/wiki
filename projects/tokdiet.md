# tokdiet — Context Virtual Memory for AI Agents

- **Repo**: [agiwhitelist/tokdiet](https://github.com/agiwhitelist/tokdiet)
- **Stars**: 69 (2026-06-21)
- **License**: MIT
- **Language**: TypeScript
- **Created**: 2026-06-16
- **Status**: 🔬 deep-read
- **Dependencies**: better-sqlite3, tiktoken, undici, commander (minimal, no framework)

## Problem

AI coding agents (Claude Code, Cursor, Codex) send the same file dumps and tool results repeatedly across a conversation. Context fills up → tokens wasted → cost inflates → quality can't be proven. Existing solutions either just *count* tokens (ccusage) or blindly truncate (`/compact`), but nobody *proves* the model didn't get dumber after compression.

## Core Thesis: Context = Virtual Memory

The key metaphor: **context window is RAM, SQLite is disk.** Don't delete pages — evict to backing store with recoverable stubs. Three residency tiers:

| Tier | Contents | Policy |
|------|----------|--------|
| **Hot** | Recent turns, pinned content, relevance-protected | Untouched, resident |
| **Warm** | Older but potentially relevant | Compressed in-place (signal-preserving stub) |
| **Cold** | Stale/redundant | Evicted to `elided_blobs` store, recoverable by content-addressed id |

## Architecture

Local loopback-only streaming reverse proxy. Request lifecycle:

```
Agent → HTTP POST → tokdiet (127.0.0.1:7787) → detect provider → meter tokens →
budget gate → compact (dedup→elision→midSummarize) → forward upstream → stream back →
record to SQLite → shadow-eval (async, post-response)
```

### Compaction Pipeline (safest-first ordering)

1. **Dedup** (loss-free): Near-duplicate collapse via Jaccard over normalized line-shingles (≥0.85 threshold). Keeps freshest copy verbatim, replaces earlier copies with pointer. Even catches files re-pasted with 1-line diffs (the original exact-equality approach scored 0/5).

2. **Elision** (recoverable, signal-preserving): Pages out large, old tool results. Marker format preserves:
   - Head preview (`elisionPreviewChars`, default 240)
   - Salient lines (errors, ids, KEY=VALUE, URLs, paths, ports — up to 12)
   - Tail (last 80 chars)
   - Content-addressed `id=cg-<sha1[0..10]>` pointing at full blob in SQLite

3. **MidSummarize** (most aggressive, disabled by default): LLM-summarizes middle-of-history messages. Protects first 2 / last 4.

### Protection Layers (what's NOT compacted)

- **Relevance protection**: Blocks scoring ≥0.34 on lexical overlap with latest user question
- **Cache-prefix protection**: Anthropic `cache_control` boundaries are never rewritten (would invalidate prompt cache → cost MORE)
- **Thinking-safe**: Signed/extended-thinking blocks excluded from editable refs
- **Pinned content**: `<!--ctxgov:pin-->` marker or auto-detected durable config-like facts (`looksDurable`)
- **Recent tool results**: Last 4 always kept intact (configurable `keepRecentToolResults`)

### Page-Fault Recovery

When the model's answer signals it needed paged-out content:
- Echoes a `cg-...` id from a marker, OR
- Contains complaint phrases ("was elided", "cannot find", "not present")

→ Clone compacted body, restore blob(s) from store, re-send once. Non-streaming only.

### Quality Guard (the differentiator)

- **Shadow-eval**: 5% sample rate (configurable). After serving client, re-sends UNCOMPACTED body → baseline answer → judge comparison
- **Judge**: Heuristic (Jaccard + bigram-Dice + length-ratio blend → 0-100) or LLM-based
- **Per-strategy safe-mode**: Rolling average per strategy; trip individual strategy (not all) when degradation > budget (default 2%)
- **Per-repo/per-strategy persistence**: Backoff state survives restarts via SQLite

## Benchmark Results

66-task A/B, MiniMax-M3, each ×3 majority-voted:
- Input tokens: 5.07M → 1.46M (**−71%**)
- Quality: 64/66 → 63/66 (≈ parity, 95-97%)
- Confirmed on M2.5: −72%

## Relevance to Our Direction

### Direct Applicability
- We use Claude Code constantly. Token costs are real. Could deploy as local proxy immediately.
- The "context virtual memory" framing matches our own [[taco-context-compression]] approach but goes further (recoverable paging vs TACO's regex-based compression).
- Could chain with our existing `compress-output.sh` — tokdiet at the API layer, TACO-style at the terminal output layer.

### Architectural Patterns Worth Adopting
1. **Fail-open everywhere**: Any internal error → transparent passthrough. Never break the user's workflow. This is the right design for any proxy/middleware.
2. **Prove, don't assert**: The shadow-eval + quality ledger pattern — measure quality impact continuously, not just claim savings. Applicable to FlowForge quality gates.
3. **Per-strategy backoff**: Don't shut everything down when one strategy degrades — isolate the bad actor. Applicable to our multi-strategy study/workloop decisions.
4. **Content-addressed recoverable eviction**: Don't delete, page out. Applicable to memory management, wiki pruning, any "compress but don't lose" problem.
5. **Salient-line extraction** as a general-purpose signal-preservation technique: extract errors, IDs, URLs, paths, numbers from any text block. Could improve our `compress-output.sh`.

### Ecosystem Position
- **Competes with**: Manual `/compact`, ccusage (metering only), Caveman (token compression)
- **Complements**: Any coding agent (sits transparently between agent and API)
- **Unique angle**: "Proof of quality" via shadow-eval. Nobody else does A/B benchmarking at the proxy layer.
- Ships as both CLI tool (`npx tokdiet start`) and Claude Code plugin

### Limitations / Critiques
- 0 issues, 0 PRs from community — very early, solo project
- Benchmark on MiniMax-M3 (not Claude/GPT) — transferability uncertain
- midSummarize disabled by default (acknowledged risk)
- Shadow-eval adds 5% cost overhead (the "cost of the guarantee")
- Page-fault recovery only works for non-streaming responses (streaming is too late)
- No handling of multi-turn accumulated context growth (compresses per-request, doesn't address session-level bloat strategy)

## Anti-Intuitive Findings
1. The "safe" dedup op was actually **scoring 0/5** with exact-equality — near-dup (Jaccard ≥0.85) was needed
2. Cache-prefix protection means sometimes you CANNOT compact — compacting cached content costs MORE (invalidates 90% discount)
3. Head-only previews (the naive approach) caused 0/4 on "needle buried in junk" tasks — salient-line extraction was the fix
4. The quality guard's per-strategy rolling average means each strategy earns its own right to run — elegant decoupling

## Follow-up (06-28) — DROPPED

**Status**: Stars 69→63 (declined!), no commits since 06-18 (10 days). Last commits were all docs/marketing (GitHub Pages landing, dev.to article, integration guide). 0 issues, 2 forks.

**Assessment**: Solo dev shifted from building to marketing, then went silent. Star decline (rare) suggests the initial burst was promotion-driven without organic retention. Core patterns (shadow-eval quality proof, fail-open proxy, content-addressed eviction, salient-line extraction) already extracted and applied to our `compress-output.sh` and `competing-pr-check.sh`.

**Drop triggers met**: Star decline + no feature commits 10d + all patterns already applied + 0 community.

**Validated prediction**: Deep-read noted "too early to evaluate execution quality" and "0 issues, 0 PRs from community — very early, solo project." The lack of community engagement predicted correctly. The "context virtual memory" concept is sound but this implementation won't be the one that wins.

## Links
- [[taco-context-compression]] — our simpler approach that benefited from tokdiet's patterns
- [[caveman]] — the space remains fragmented with no clear winner
- [[secondwind]] — lossless proxy-based compression with blake3 proofs (different layer: model input vs command output)

## Applied (2026-06-22)

**Pattern adopted: heuristic shadow-eval for compress-output.sh**

Added `signal_preservation_check()` to `tools/compress-output.sh` — after compression, extracts critical signals (errors, warnings, test failure names, aggregate summaries) from raw content and verifies they appear in compressed output. Logs `signal_preserved_pct` to JSONL metrics alongside compression ratio. Emits stderr warning when preservation drops below 80%.

Key differences from tokdiet's implementation:
- Ours is fully heuristic (regex extraction), no LLM judge call (zero cost overhead vs tokdiet's 5%)
- Per-invocation measurement rather than sampling (our volumes are low enough to check every time)
- No per-strategy backoff yet (only one compression pipeline, not tiered like tokdiet's dedup→elision→midSummarize)

**Immediate payoff**: The quality check exposed 2 pre-existing bugs on first run:
1. Test compression regex was case-sensitive (`ERROR|error` but not `Error`) — mixed-case error messages were being silently dropped
2. Build compression used PCRE lookahead `(?!...)` in ERE mode — grep warnings on every build compression

This validates tokdiet's core thesis: **you don't know your compression is safe until you measure it**. We were dropping error messages for months without noticing.

### Applied: Fail-open gate design (2026-06-25)

**Pattern**: "Fail-open everywhere" — any internal infrastructure error → transparent passthrough, never block work because the gate itself broke.

**Applied to**: `tools/competing-pr-check.sh` — previously, API failures (rate limit, network timeout) caused `ISSUE_STATE=UNKNOWN` which triggered "Issue is UNKNOWN (not OPEN)" → BLOCKED. This was a false negative that blocked valid work.

**Implementation**:
- Removed `set -e` (handle errors explicitly per-call with success/failure tracking)
- `API_SUCCESSES=0 && API_FAILURES>0` → exit 0 + warning (fail-open)
- Partial failure: assume open for unknown state, only block on verified competing PR evidence
- `--strict` flag available when fail-closed behavior is explicitly needed

**Behavioral change**: Workloop no longer abandons valid issues when GitHub API is slow/rate-limited. Addresses `verify-before-abandon` gradient directly.

**Design principle validated**: Gate scripts should be fail-open by default. Their job is to *prevent known-bad* states, not to *require verified-good* states. Unknown ≠ bad.
