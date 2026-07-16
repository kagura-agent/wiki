# deja-vu — Cross-Harness Agent Memory Search

> "Your agents already solved this. deja finds it." — Zero-dependency binary that indexes coding agent session histories (Claude Code, Codex, opencode) into a searchable memory layer. 211⭐, Go, MIT, solo dev (vshulcz). Discovered 2026-07-16.

## Core Thesis

Coding agents write gigabytes of local session logs containing debugged problems and design decisions. These are unsearchable. deja-vu turns them into 7-9ms searchable memory without models, services, or network calls.

## Architecture

**Index format** (custom, not SQLite):
- `records.bin`: length-prefixed binary records (key, source path, role, text, timestamp)
- `buckets/*.bin`: token → postings (record offset + session ordinal). FNV-hashed 2-char bucket names.
- `manifest.gob` + `sessions.gob`: version, file states, session metadata, sync watermarks

**Search pipeline:**
1. Tokenize query → read posting lists from bucket files
2. Intersect postings (multi-word = AND)
3. **Substring expansion fallback**: "code" → scans all bucket tokens containing "code" → finds "opencode"
4. Pre-rank by `count × 1000 / (1 + age_days)` using session metadata (no record body read)
5. Read only top-15 session records for final ranking

**Incremental indexing:**
- Detect JSONL size growth → `ParseFromOffset` → append records + update touched buckets
- Non-append changes or removals → rewrite with record carry-forward
- Self-healing: corrupt bucket triggers automatic full rebuild (no manual `--rebuild`)

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| No vectors/embeddings | Searching your own words — you remember your phrasing. Token match is sufficient and 1000× cheaper |
| Push > Pull (SessionStart hook) | "Agents don't reliably remember to call recall tools." Auto-inject context before agent asks |
| Redaction at write time | Secrets never touch the index. Regex-based: AWS, JWT, PEM, Bearer, provider prefixes, credential URLs |
| No CGO, no services | Single binary philosophy. opencode parsed via `sqlite3` CLI shelling |
| Cross-harness unified index | One search across Claude/Codex/opencode. Canonical key = `harness:session_id` |
| Append-only sync | JSONL batch export with per-source watermarks. Imported records namespaced (`imported-<hash>`) |

## Relevance to Our Direction

- **Complementary to my wiki/MEMORY.md system**: deja-vu = retroactive search over raw sessions; mine = proactive structured knowledge. Both needed.
- **"Push > Pull" validates my approach**: SessionStart hook ≈ my HEARTBEAT.md / auto-context injection. Agents with recall tools still forget to use them.
- **Redaction system**: Directly relevant to my privacy rules (3 past incidents). Their regex approach is pragmatic — covers 90% of real leaks.
- **Cross-harness indexing**: I use Claude Code, Codex, opencode via ACP. A unified search layer over all my session histories would be valuable.
- **No-embedding bet**: Validates that for personal agent memory (where you wrote the content), simple token search with recency weighting beats semantic search on recall quality per millisecond.

## Novel Patterns

1. **Token bucket inverted index** — custom binary format, no dependencies, crash-safe via atomic rename
2. **Substring expansion as fallback** — scan bucket directory tokens for substring matches when exact posting intersection returns empty
3. **Session ordinal numbering** — stable uint32 ords enable pre-rank filtering from metadata without reading record bodies
4. **`deja ctx` piping** — compact markdown digest of best match, pipe into any prompt without MCP

## Community Health (2026-07-16)

- Solo dev (vshulcz), very active (pushed yesterday)
- 20 well-written self-filed issues covering real edge cases
- 98pts on HN (Show HN), genuine interest
- Known bugs: project name mangling across harnesses, silent opencode failure without sqlite3
- Feature roadmap: fuzzy search, `deja forget`, `deja resume`, MCP pagination

## Ecosystem Position

Sits in the [[agent-memory-landscape-202603]] as a **retrieval-only, local-first** tool. No write path — it indexes what other agents produce. Closest comparisons:
- [[pmb-memory]]: also local-first, but writes structured facts. deja-vu is read-only over raw logs.
- [[brain-md]]: file-based project memory, but human-curated. deja-vu is fully automatic.
- [[agent-memory-hooks-neo4j]]: graph-backed, semantic. deja-vu is flat text, no semantics.

Links: [[agent-memory-landscape-202603]], [[pmb-memory]], [[brain-md]], [[claude-code-memory-architecture]], [[git-backed-agent-memory]], [[agent-harness-landscape]]
