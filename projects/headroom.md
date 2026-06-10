# Headroom — Context Compression Layer for AI Agents

- **depth**: deep-dive
- **status**: studied (2026-06-07)
- **tags**: compression, context-engineering, tokens, proxy, rust, python
- **repo**: https://github.com/chopratejas/headroom
- **stars**: 20.8K (as of 2026-06-10, was 16.1K on 06-07 — +29% in 3 days!)

## 06-10 Update
- Trending #1 weekly on GitHub (15,060 stars this week)
- New: `headroom learn` — mines failed sessions, writes corrections to CLAUDE.md/AGENTS.md
- New: Cross-agent memory store with auto-dedup (shared across Claude, Codex, Gemini)
- OpenClaw listed as compatible ("installs as ContextEngine plugin")
- **Actionable**: evaluate `headroom wrap openclaw` for integration
- **license**: Apache 2.0
- **author**: Tejas Chopra (chopratejas)

## TL;DR

Headroom is a **proxy/library/MCP server** that compresses tool outputs, logs, files, and RAG chunks before they reach the LLM. Claims 60-95% token savings. Available as Python (`pip install headroom-ai`) and TypeScript (`npm install headroom-ai`). Core is being ported to Rust for the proxy path. 16K stars in ~5 months.

**My verdict**: Genuinely useful engineering, not just hype. The architecture went through a painful but honest self-correction (REALIGNMENT), which is a good sign. However, most individual compressors (SmartCrusher, LogCompressor, DiffCompressor, SearchCompressor) are well-known techniques packaged well — the novel value is in the **orchestration** (ContentRouter + CCR + CacheAligner + live-zone invariants), not in any single algorithm.

## Architecture Overview

### The Pipeline

```
Client Request → CacheAligner → ContentRouter → [Compressor] → CCR → LLM
                 (detect volatile)  (detect type)   (compress)   (store originals)
```

**Key insight**: Headroom compresses only the "live zone" — the latest user message and latest tool results. Everything before (system prompt, tools, conversation history) is **never touched**. This preserves provider KV cache hits (Anthropic's prompt caching, OpenAI's cached prefixes).

### The 7 Invariants (from REALIGNMENT)

The project learned these the hard way after an internal audit found 5 cache-killer bugs:

1. **Byte-faithful passthrough** — unmutated bytes are SHA-256 identical
2. **Cache hot zone never modified** — system, tools, frozen messages untouched
3. **Append-only** — once a message appeared in a prior request, its bytes are frozen
4. **Determinism** — same input → same output, no timestamps/random in compression
5. **Token-aware** — every compression validated post-hoc; if tokens(compressed) >= tokens(original), keep original
6. **Position-preserving** — never reorder blocks within a content array
7. **Tool definitions normalized, not compressed** — alpha-sort tools array, recursive-sort JSON Schema keys

### Components In Detail

#### ContentRouter (Python, ~112K LoC)
The brain. Detects content type via regex-based heuristics (no ML for detection), routes to the right compressor:
- JsonArray → SmartCrusher
- SourceCode → CodeCompressor (AST-aware)
- SearchResults → SearchCompressor
- BuildOutput → LogCompressor
- GitDiff → DiffCompressor
- PlainText → Kompress-base (ML model)
- Mixed content → splits sections, routes each independently

#### SmartCrusher (Rust, 25+ files)
JSON compression. Has a pluggable architecture:
- **Scorer** (HybridScorer) — BM25 + embedding relevance scoring
- **Constraints** (KeepErrors, KeepStructuralOutliers) — force-keep certain rows
- **Compaction** — columnar IR for array-of-dicts compression (classify → compact → format)
- **AnchorSelector** — keep representative rows as "anchors"
- **Builder pattern** for enterprise customization

#### CodeCompressor (Python, 80K LoC)
AST-aware compression for Python, JS, Go, Rust, Java, C++. This is the biggest single file — suspiciously large for what it does.

#### Kompress-base (HuggingFace model)
- Model: `chopratejas/kompress-base`
- Architecture: ModernBERT-based token compressor
- Trained on "agentic traces" (tool outputs from coding agents)
- Inference: ONNX Runtime (CPU default), also supports CoreML and PyTorch MPS
- Loaded on-demand with lazy init + thread-safe singleton
- Environment-configurable: backend, batch size, thread count
- **The genuinely novel piece** — a small ML model specifically trained for agent trace compression

#### CacheAligner (Python)
**NOT what it sounds like.** After the REALIGNMENT, it's a **detector-only** transform:
- Scans system prompt for volatile content (UUIDs, timestamps, JWTs, hex hashes)
- Emits warning logs so users know their cache prefix is unstable
- **Does NOT rewrite anything** — the rewrite path was removed as it violated invariant I2
- So it's really a "cache instability detector", not an "aligner"

#### CCR (Compress-Cache-Retrieve) (Rust + Python)
The reversibility mechanism:
- When content is compressed with row-drops, the **original** is stashed in a local store
- Key: BLAKE3 hash → first 24 hex chars
- Marker: `<<ccr:HASH>>` injected into compressed output
- LLM can call `headroom_retrieve(hash)` MCP tool to get originals back
- **Backends**: InMemory (test), SQLite (production default, WAL-mode), Redis (multi-worker)
- **Default TTL: 5 minutes** — ⚠️ this is a known issue (#714: "CCR originals expire after 5 minutes, breaking long-running agent jobs")
- **Practical?** Yes, for short tasks. For 30+ minute agent sessions, the 5-min TTL is a real problem.

#### Cross-Agent Memory / SharedContext
- In-memory key-value store with compressed+original versions
- `ctx.put("key", data)` → stores both compressed and original
- `ctx.get("key")` → returns compressed; `ctx.get("key", full=True)` → returns original
- Auto-dedup: same content → same hash → deduped
- **Not a distributed store** — it's process-local. "Cross-agent" means agents within the same process/proxy instance.
- TTL: 1 hour default, max 100 entries
- **Honest assessment**: More of a compressed caching layer than true cross-agent memory. The marketing oversells this.

#### `headroom learn`
Mines failed agent sessions and writes corrections to CLAUDE.md / AGENTS.md / GEMINI.md:
- Plugin architecture: claude, codex, gemini scanners
- Uses LLM to analyze sessions (via LiteLLM or CLI backends like `claude -p`)
- Scanner extracts events → Digest builder → LLM analysis → Structured recommendations → Writer
- **Real and functional** — not vaporware. But it's an LLM-calls-LLM pattern (uses API credits)

### The REALIGNMENT Story

The most interesting part of Headroom is its public self-audit. They found their core mental model was wrong:

- **Wrong**: "Compression means choosing what to drop from conversation history"
- **Right**: "Passthrough is sacred; compress only the live zone"

The original `IntelligentContextManager` tokenized the entire message array, scored messages for importance, and dropped old ones — **destroying the provider's KV cache every time**. The REALIGNMENT deleted ~25K LoC and rebuilt around live-zone-only compression.

This is a mature response to a fundamental design error. It shows the project has good technical leadership.

### Rust Port Status

The proxy is being ported from Python (FastAPI) to Rust (axum):
- `headroom-core`: transforms, CCR backends, tokenizer, signals, relevance
- `headroom-proxy`: HTTP handling, SSE parsing, cache control
- Python retained for: CLI wrappers, evals, learn, memory writers, tokenizers

### OpenClaw Integration

Real but thin. The `headroom/providers/openclaw/` module:
- `wrap.py`: Builds a plugin config entry for OpenClaw's gateway
- `install.py`: Uses `openclaw config` CLI to register/deregister
- Intercepts OpenClaw's provider traffic (default: `openai-codex` provider)
- Routes through local Headroom proxy for compression

It's basically "set OpenClaw's provider to proxy through us" — not a deep integration.

## Comparison Table

| Feature | Headroom | TACO | Our compress-output.sh | MineEcho TokenLess |
|---|---|---|---|---|
| **Approach** | ContentRouter + type-specific compressors | Self-evolving regex rules from feedback | Hand-written regex rules | 15 built-in reducer rules |
| **Content Detection** | Regex-based ContentType enum | Pattern matching per domain | `--type` flag (manual) | Fixed rule matching |
| **JSON** | SmartCrusher (relevance scoring, columnar IR, anchor selection) | Not specialized | Not specialized | Basic minification |
| **Code** | AST-aware multi-language (Python/JS/Go/Rust/Java/C++) | Not specialized | Not specialized | Unknown |
| **Prose/Text** | Kompress-base ML model (ModernBERT on HF) | None | None | None |
| **Logs** | LogCompressor (template extraction, level-aware) | Regex rules (self-evolving) | Regex rules (static) | Fixed rules |
| **Diffs** | DiffCompressor (hunk-aware) | None | None | None |
| **Reversibility** | CCR (store originals, retrieve on demand) | None | None | None |
| **Cache Awareness** | CacheAligner + live-zone invariants | None | None | None |
| **Self-Evolution** | `headroom learn` (LLM-based session mining) | Evolutionary rules from agent feedback | Manual | None |
| **Compression %** | 47-92% (varies by type) | ~50% on terminal output | 71-84% on terminal output | Unknown |
| **Accuracy Impact** | Benchmarked: GSM8K ±0%, TruthfulQA +3% | Paper-backed evaluation | Not evaluated | Not evaluated |
| **Dependencies** | Heavy (Python + Rust + ONNX + HF models) | Light (Python, regex) | Zero (bash) | Part of MineEcho |
| **Integration** | Library/Proxy/MCP/Wrap CLI | Standalone | Pipe (stdin/stdout) | Built into agent |

## Key Architectural Decisions & Tradeoffs

### Good Decisions
1. **Live-zone-only compression** — correct fundamental insight after painful learning
2. **CCR reversibility** — elegant: lossy on the wire, lossless end-to-end
3. **Type-aware routing** — JSON needs different compression than logs, diffs, or code
4. **Builder pattern for SmartCrusher** — enterprise extensibility without core complexity
5. **7 invariants as test gates** — each invariant has a named test that gates PRs
6. **Rust port of hot path** — Python proxy was too slow for production traffic

### Questionable Decisions
1. **80K LoC single file for CodeCompressor** — smells like over-engineering or AI-generated bloat
2. **112K LoC ContentRouter** — same concern; hard to maintain
3. **CacheAligner is a misnomer** — it doesn't align caches, it detects volatility
4. **5-minute CCR TTL** — too short for real agent sessions (already a reported bug)
5. **Kompress-base model details opaque** — training data, architecture size, evaluation methodology not published in detail

### Risks
1. **Provider API changes** — tight coupling to Anthropic/OpenAI message formats
2. **Compression might confuse the LLM** — the benchmarks show accuracy preserved, but on academic benchmarks, not on real agentic tasks
3. **CCR tool injection** — adding `headroom_retrieve` to the tools array on every request adds tokens
4. **Process leak bug** (#615) — `headroom init persistent-task` spawns hundreds of orphaned proxy processes

## Relevance to OpenClaw / Our Direction

### What We Could Learn
1. **Live-zone principle** — only compress what's new, never touch cached prefix. Our compress-output.sh doesn't have this concept because it operates on individual tool outputs, not conversation history. But if we ever build conversation-level compression, this is the right architecture.

2. **Type-aware routing** — our compress-output.sh uses `--type` flags; Headroom auto-detects. We could add auto-detection to compress-output.sh without the full Headroom stack.

3. **CCR concept** — store originals and let the LLM retrieve them. We could implement this lightweight: hash the original, store in a temp file, inject a `[full output: hash]` marker that our agent knows how to retrieve.

4. **Benchmark methodology** — they test on GSM8K, TruthfulQA, SQuAD, BFCL. We should benchmark our compression too.

### What We Don't Need
1. **The full Headroom proxy** — we don't proxy LLM traffic; OpenClaw has its own gateway. Adding a middleman proxy adds latency and complexity.

2. **Kompress-base model** — requires ONNX runtime, ~100MB model download. Our regex approach is fast and sufficient for terminal output. The ML model helps for prose, which isn't our main use case.

3. **The wrap CLI** — `headroom wrap claude` is for users who don't control their agent's code. We control ours.

4. **SharedContext** — process-local key-value store with compression. We already have our own context management.

### Actionable Ideas
1. **Improve compress-output.sh auto-detection** — steal their ContentType detection regex patterns for JSON, diffs, search results, build output. Low effort, high value.

2. **Add CCR-lite to our compress-output.sh** — when compressing, write original to `/tmp/ccr-<hash>` and inject `[original: hash]`. Our agent can `cat /tmp/ccr-<hash>` if needed.

3. **Consider CacheAligner concept** — scan our system prompts for volatile content (timestamps, session IDs) that bust Anthropic's prompt cache. This is free money.

4. **Benchmark our compression** — compare compress-output.sh output quality on real agent tasks against Headroom's benchmarks.

## Notable Issues & Discussions

- [#714](https://github.com/chopratejas/headroom/issues/714) — CCR originals expire after 5 min, breaking long-running agent jobs
- [#709](https://github.com/chopratejas/headroom/issues/709) — Proactive context expansion injects stale CCR contexts
- [#715](https://github.com/chopratejas/headroom/issues/715) — Windows: POST /v1/compress hangs on large payloads
- [#638](https://github.com/chopratejas/headroom/issues/638) — Proxy breaks OpenClaw (reported by user)
- [#615](https://github.com/chopratejas/headroom/issues/615) — Process leak: hundreds of orphaned proxy processes
- [#637](https://github.com/chopratejas/headroom/issues/637) — Claude Code says 25% usage eaten by headroom MCP (overhead concern)
- [REALIGNMENT/00-overview.md](https://github.com/chopratejas/headroom/blob/main/REALIGNMENT/00-overview.md) — The self-audit that triggered the architecture rebuild

## Final Assessment

**Genuinely novel?** The individual compressors are well-known techniques (JSON minification, AST compression, log template extraction, diff summarization). The **orchestration** is where the value lies: type-aware routing, live-zone invariants, CCR reversibility, and cache alignment. The Kompress-base ML model is somewhat novel (ModernBERT trained on agent traces) but details are sparse.

**Well-packaged collection of known techniques?** Mostly yes, but with genuinely good architectural thinking around cache safety and reversibility that most alternatives don't have. The REALIGNMENT docs show honest self-assessment and willingness to delete bad code.

**For us?** We should steal ideas (auto-detection, CCR-lite, cache volatility detection) rather than adopt the full stack. Our compress-output.sh + OpenClaw gateway is simpler, lighter, and sufficient for our use case. Headroom's value proposition is strongest for users who can't control their agent's code and need a drop-in proxy — that's not us.
