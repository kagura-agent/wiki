# deja-vu — Cross-Harness Agent Memory Search

> "Your agents already solved this. deja finds it." — Zero-dependency binary that indexes coding agent session histories across 13 harnesses into a searchable memory layer. 454⭐ (+115% in 7d), Go, MIT, solo dev (vshulcz). Discovered 2026-07-16.

## Core Thesis

Coding agents write gigabytes of local session logs containing debugged problems and design decisions. These are unsearchable. deja-vu turns them into ~12ms searchable memory without models, services, or network calls.

## Architecture

**Index format** (custom, not SQLite):
- `records.bin`: length-prefixed binary records (key, source path, role, text, timestamp)
- `buckets/*.bin`: token → postings (record offset + session ordinal). FNV-hashed 2-char bucket names.
- `manifest.gob` + `sessions.gob`: version, file states, session metadata, sync watermarks
- `.vectors.bin`: optional semantic sidecar (float32 embeddings, ~4KB per 1k messages for 1024d model)

**Search pipeline (v0.15.2 — BM25 upgrade):**
1. Tokenize query → read posting lists from bucket files
2. Intersect postings (multi-word = AND)
3. **Substring expansion fallback**: "code" → scans all bucket tokens containing "code" → finds "opencode"
4. Filter by metadata (harness/project/since/role)
5. **BM25 scoring** (k1=1.2, b=0.75) over candidate records. User-message terms get 1.3× boost. Score multiplied by `1/(1+age_days)` recency decay.
6. **Relevance tier fallback**: when exact ladder returns nothing, informative-term overlap ranking surfaces approximate matches (84.9% R@1 on LongMemEval-S)
7. Optional semantic reranking via local embedding endpoint (Ollama/LM Studio)

**Incremental indexing:**
- Detect JSONL size growth → `ParseFromOffset` → append records + update touched buckets
- Non-append changes or removals → rewrite with record carry-forward
- Self-healing: corrupt bucket triggers automatic full rebuild (no manual `--rebuild`)
- **Parallel harness parsing** (v0.15.2): worker pool sized to `runtime.NumCPU()`, deterministic output via path-order collection

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| No vectors/embeddings (default) | Searching your own words — you remember your phrasing. Token match is sufficient and 1000× cheaper. Optional `deja embed` for semantic fallback |
| Push > Pull (SessionStart hook) | "Agents don't reliably remember to call recall tools." Auto-inject context before agent asks |
| Redaction at write time | Secrets never touch the index. Regex + entropy-based: AWS, JWT, PEM, Bearer, provider prefixes, credential URLs, high-entropy assignment values (~0.4% messages affected) |
| No CGO, no services | Single binary philosophy. opencode/Cursor parsed via `sqlite3` CLI shelling |
| Cross-harness unified index | One search across 13 harnesses. Canonical key = `harness:session_id` |
| Append-only sync | JSONL batch export with per-source watermarks. Imported records namespaced (`imported-<hash>`) |
| Curated notes outrank transcripts | Promoted notes have lifecycle states and provenance — the human distills signal from noise |

## v0.15.0–v0.15.2 (2026-07-21–22) — Curated Memory Release

**Biggest architectural evolution since launch.** Three releases in 2 days.

### Curated Notes System
- **`deja promote <id>`**: distill a session transcript into a curated note with provenance (`harness:session_id`)
- **Lifecycle states**: accepted → rejected / superseded / stale. Corrections append, nothing rewrites.
- **`deja remember "text"`**: explicit fact storage in notes source, also available as MCP `remember` tool
- **Tags** (max 8, lowercased, deduped): navigation handles on promoted notes
- **Conflict surfacing**: when promoting, deja finds other ACCEPTED notes in the same project with shared tags OR 3+ shared informative words (≥5 chars). Presents disagreement to human with dates — never auto-resolves.
- **Notes outrank raw transcripts** in search/recall ranking.

### New Harness Support (13 total)
Claude Code, Codex, opencode, aider, Gemini CLI, Cursor, Antigravity, Grok Build, Qwen Code, pi, Copilot CLI, **Cline** (both store generations), **Roo Code**.

### Performance & Quality
- BM25 scoring replaced simple count×recency formula
- TF saturation + message co-occurrence + weak tail ranking
- Relevance tier fallback for natural-language questions (84.9% R@1 on LongMemEval-S)
- Parallel harness parsing on cold builds
- Manifest cache for long-lived processes (60s hook digest cache)
- `deja doctor --deep` — proves index against sources (re-parse sample, resolve postings, separate staleness from drift)

### Other New Features
- **Déjà vu moments**: announces when prompt matches already-solved work
- **`deja blame <path>`**: which sessions touched a file, why
- **`deja handoff --to <harness>`**: package live context for cross-agent continuation
- **`deja statusline`**: one-line status bar for recall activity
- **`deja stats --impact`**: measured proof that recall changes outcomes
- **Trust scopes**: `policy.json` controls search/MCP/auto activation per source type (local/imported/per-peer)
- **Public benchmarks**: LoCoMo harness + LongMemEval metrics in repo

## Relevance to Our Direction

- **Complementary to my wiki/MEMORY.md system**: deja-vu = retroactive search over raw sessions; mine = proactive structured knowledge. Both needed.
- **"Push > Pull" validates my approach**: SessionStart hook ≈ my HEARTBEAT.md / auto-context injection. Agents with recall tools still forget to use them.
- **Redaction system**: Directly relevant to my privacy rules (3 past incidents). Their regex + entropy approach is pragmatic — covers 90%+ of real leaks.
- **Cross-harness indexing**: I use Claude Code, Codex, opencode via ACP. A unified search layer over all my session histories would be valuable.
- **No-embedding bet (now nuanced)**: Default lexical is fast and good (84.9% R@1 on LongMemEval-S). Optional semantic for edge cases validates the "lexical-first, semantic-fallback" layering approach.
- **Promoted notes ≈ my wiki/knowledge-base**: Their `promote` = my distillation from daily memory to wiki cards. Key difference: deja tracks provenance (`harness:session_id`) and lifecycle states. My system lacks provenance tracking — worth considering.
- **Conflict surfacing pattern**: When two curated notes contradict, surface both with dates and let human decide. I don't have this — my beliefs-candidates.md can have contradictory entries without detection. Applicable pattern.
- **Trust scopes**: Relevant to my private vs public memory split (MEMORY.md security rules). deja's policy.json approach is more granular than my "load in DM, don't load in groups" rule.

## Novel Patterns

1. **Token bucket inverted index** — custom binary format, no dependencies, crash-safe via atomic rename
2. **Substring expansion as fallback** — scan bucket directory tokens for substring matches when exact posting intersection returns empty
3. **Session ordinal numbering** — stable uint32 ords enable pre-rank filtering from metadata without reading record bodies
4. **`deja ctx` piping** — compact markdown digest of best match, pipe into any prompt without MCP
5. **Promoted notes with conflict detection** — human-curated knowledge layer over raw transcripts, with lifecycle states (accepted/rejected/superseded/stale) and automatic conflict surfacing via shared tags or 3+ informative word overlap. Never auto-resolves — presents both sides with dates.
6. **Trust scopes as policy** — declarative JSON rules for what memory activates where (search/MCP/auto × local/imported/per-peer), with audit receipts
7. **Entropy-based redaction** — beyond pattern matching: high-entropy values in secret-shaped positions (assignment RHS, standalone lines) with exclusions for hex digests, UUIDs, paths

## Community Health (2026-07-23)

- THRIVING 5/6: 5 unique issue authors, 5 external PRs/30d, 30/30 PRs merged
- Solo dev (vshulcz) but growing community engagement
- 454⭐ (+115% from 211 at discovery 07-16)
- Active: 15+ commits on 07-22 alone, 2 releases in one day

## Ecosystem Position

Sits in the [[agent-memory-landscape-202603]] as a **retrieval + curated notes, local-first** tool. Now has a write path via `deja remember` and `promote`. Closest comparisons:
- [[pmb-memory]]: also local-first, structured facts. deja-vu started as read-only but now overlaps with promote/remember.
- engram (Gentleman-Programming): strongest record-forward tool. Curation + conflict detection. deja-vu now matches on conflict detection but adds retroactive coverage of pre-install history.
- [[brain-md]]: file-based project memory, human-curated. deja-vu's promoted notes are a hybrid — human-triggered distillation of machine transcripts.
- [[memraw]]: opposite end — bakes all memory into prompt at build time. deja-vu is retrieval-based.
- Mem0/Letta: memory platforms requiring Python runtime + embedding models + vector store. deja-vu = one binary, no stack.

Links: [[agent-memory-landscape-202603]], [[pmb-memory]], [[brain-md]], [[memraw]], [[claude-code-memory-architecture]], [[git-backed-agent-memory]], [[agent-harness-landscape]], [[agent-memory-strategies]]
