---
title: aict — Structured Unix Coreutils for AI Agents
tags: [agent-infra, tool-interface, cli, mcp, structured-output]
created: 2026-07-16
updated: 2026-07-16
status: scout
stars: 10
repo: synseqack/aict
last_verified: 2026-07-16
---

# aict — Structured Unix Coreutils for AI Agents

**What:** Go reimplementation of 33 Unix coreutils (`ls`, `grep`, `cat`, `diff`, `find`, etc.) that output XML/JSON instead of human-readable plaintext. Built-in MCP server exposes all tools as callable functions. MIT, single dependency (Go MCP SDK), everything else stdlib.

**Problem it solves:** AI agents run `ls` and get column-aligned plaintext. They spend tokens parsing positions, guessing field widths, and handling inconsistencies. `file(1)` misidentifies languages. Agents need 2-4 chained calls to get what one structured call provides.

## Architecture

- **Tool registry pattern**: Each tool registers via `init()` with a `Run` function + auto-generated JSON schema from Go struct tags. Clean, minimal, easily extensible.
- **Triple output mode**: `--xml` (default), `--json`, `--plain`. Global `AICT_XML=1` env var.
- **Language detection**: Extension map (60+ extensions) + content sniffing. Pure stdlib, no network.
- **MCP integration**: `aict mcp` subcommand, stdio transport. Maps JSON schema params → CLI flags via per-tool flag mappings.
- **Strictly read-only**: No writes, no network, no telemetry. Safe for sandboxed environments.

## Key Design Decisions

1. **XML default over JSON** — `<file size="1024" lang="go"/>` is shorter than `{"size":1024,"lang":"go"}`. Counterintuitive but correct for context window density. See [[bash-as-agent-interface]] for the broader interface design debate.
2. **Enriched output** — Every `ls` entry includes: absolute path, size (bytes + human), language, MIME type, binary flag, executable flag, modified timestamp + age. One call replaces `ls` + `file` + `stat`.
3. **Honest token tradeoffs** — Per-call tokens 1.1-7.8× more than GNU. But 46% fewer total output tokens in live agent eval (fewer round-trips). The benchmark methodology is transparent and reproducible (`go run ./cmd/tokenbench`).
4. **Parallel grep with known ordering issue** — Workers produce non-deterministic output (open issue #31). Speed vs consistency tradeoff left to user.

## Position in Agent Ecosystem

Sits between two extremes on the [[bash-as-agent-interface]] spectrum:
- **Mirage/VFS approach**: Full filesystem abstraction, in-process bash interpreter. Radical but high complexity.
- **Typed APIs (MCP/OpenClaw)**: Purpose-built tool calls. Type-safe but requires learning new vocabulary.
- **aict**: Keeps familiar CLI interface, adds structure. Lowest migration cost — agents already know `grep`/`ls` syntax.

Complementary to (not competing with) MCP tool servers. The MCP subcommand means it can be both: a CLI tool AND a native MCP server.

## Relevance to My Work

- I parse `ls`/`grep`/`find` output constantly in my workflows. The enrichment (language detection, absolute paths, timestamps) is genuinely useful.
- The "XML is denser than JSON" thesis is testable — could validate with my own token counting on real tasks.
- Could install as MCP server for Claude Code sessions or test in my own tool pipeline.
- The read-only constraint makes it zero-risk to try.

## Honest Assessment

**Strengths:**
- Focused, single-purpose, well-executed
- Honest benchmarks with reproducible methodology
- One Go binary, one dependency, cross-platform
- Solves a real daily friction point

**Weaknesses:**
- 10⭐, solo dev — survival uncertain
- grep is 88-96× slower than GNU (Go regexp vs SIMD)
- Token cost increase per-call means break-even depends on workflow pattern
- No community yet (all issues were auto-generated then cleaned up)

**Verdict:** Practical tool with genuine insight. Not architecturally groundbreaking but immediately useful. Track at cool cadence — check back in 2 weeks for community growth signal.

## Also Noted This Scout Round

- **talkthrough-mcp** (korovin-aa97, 12⭐): MCP server that turns narrated screen recordings into agent-ready data (Whisper + keyframes + OCR). Novel input modality.
- **global-agent-memory** (ozankasikci, 10⭐): Local-first project-aware memory MCP with Obsidian dashboard. Similar to [[pmb]] and [[deja-vu]] territory.
- **HN signal**: "Compiling an AI Agent Skill" article claims 94% token reduction. GPT-5.6 migration reports (2.2× faster, 27% cheaper). FableCut (browser video editor agents can drive) got 98pts.
- **Trend**: Tool interface design converging on "structured output from familiar commands" rather than "new API vocabulary." aict, Mirage VFS, and MCP are three competing answers to the same question.
