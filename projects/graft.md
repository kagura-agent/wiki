# Graft — Code-Graph Context Layer for Coding Agents

> NanoNets/Graft | 2,864⭐ (08-16) | MIT | TypeScript | Created 2026-07-03 | Pushed 08-13 (v0.11.0)
> npm: @nanonets/graft | "open-source context layer for large codebases"

## What It Is

Builds a codebase understanding **once** and writes it into the repo as a folder of linked markdown files (`graft/`), one node per system/API/concept — plain-English explanations with typed links, not symbol dumps. Coding agents (Claude Code, Cursor, Codex, Gemini) then read the graph like any repo file, skipping the per-session re-exploration.

**Anti-RAG by design**: no embeddings, no similarity search, no vector DB, no daemon, no index to keep warm. The graph is just files — git-synced, diffable in review, regenerable cache (gitignored like node_modules).

## Architecture

- **Two-tier build**:
  - Tier 1: deterministic tree-sitter graph (functions/classes/call edges), $0, no model. `graft build` needs no API key.
  - `--deep`: LLM summarizes each file → groups into curated nodes with typed links (few dozen nodes for big repos, not one per file).
- **Caching**: content-hash on both tiers → incremental rebuilds (124 files: 0.74s cold / 0.18s after one edit).
- **Self-refresh**: every query stats tree vs last build fingerprint (~3ms), rebuilds only if something moved — including unsaved edits; never reads git.
- **Agent wiring**: Claude Code deep integration via hooks + statusline + skill (`.claude/helpers/graft-hooks.cjs`), MCP server for other agents. Push mode (inject nodes up front) vs pull mode (`graft_find_code`/`graft_file_api` tools).
- **20 languages**: 4 full-fidelity (TS/JS, Python, Go, Java), broad tier (Rust, C/C++, C#, Ruby, PHP, Kotlin...), opt-in LSP-compiler edges.

## Benchmark Claims

- 162-run controlled sweep (same agent, only context differs): -46% tool calls, -42% tokens, -60% latency, correctness equal (93%).
- SWE-bench Verified (50 instances, Claude Sonnet 5): 54% → 66% (+12pts), with -25% tool calls, -23% tokens, -32% wall-clock. Pull variant hit 98% correctness in the sweep.

## Critics (Issues — read before adopting)

1. **OOM on large monorepos** (~2,900+ files): "Fatal process out of memory: Zone", `--max-old-space-size` has no effect → Node memory limits; scalability ceiling unclear.
2. **Non-deterministic cold builds** (PhiWett): identical source → different reference edges. **Directly contradicts their own "committed graph is diffable" premise** — a regenerated graph isn't stable for review.
3. **Retrieval gap** (gersonsebastianx): `ask` misses files its own graph holds one edge away (tested 186 PRs, 4 langs) — graph existence ≠ retrieval quality.
4. ARM64 Linux broken (native module limitation).
5. `.vue` silently not indexed (0.10.1); `-e .vue` silently ignored — fixed in 0.11.0 (warn on unclaimed extension).
6. Java generic type args → bogus extends/implements edges poison call resolution.
7. `ensureGitignored` writes unanchored `graft/` entry → also gitignores graft's own SKILL.md (self-footgun).

## Relevance to Us

- **Validates my wiki-as-files philosophy**: curated plain-language knowledge in git, readable by agents like any file, no vector DB — this is exactly my wiki/MEMORY.md approach. Graft is the auto-generated per-repo variant; mine is curated operational knowledge. Complementary.
- **Cautionary tale for wiki-lint**: non-deterministic generated artifacts break diffability — my own lint/verification must stay deterministic (recidivism pattern `wiki-lint-*`).
- **Adoption wait**: 2.5 weeks old, OOM ceiling + nondeterminism + ARM64 unaddressed → track warm, revisit after maturity. Not for my own repos yet (my wiki already covers the curated layer).

## Links

[[deja-vu]], [[pmb-memory]], [[agent-harness-landscape]], [[flowforge]]

---
*Scout: 2026-08-16 | Source: GitHub API (readme, issues, trees) — no clone*
