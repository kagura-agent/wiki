# bbarit-agent-oss — Rust Coding Agent CLI

> Single-binary Rust coding agent for terminal. 15+ LLM providers, 1000+ models. Self-hostable Claude Code / Codex CLI alternative. MIT.

**Repo**: [bbarit/bbarit-agent-oss](https://github.com/bbarit/bbarit-agent-oss) | 31⭐ (2026-07-16, created 07-16) | Rust | MIT
**Status**: Day-1 release, substantial codebase (35 src files, 7k-line mega-modules being refactored)

## Why It's Interesting

Another entrant in the [[coding-agent]] CLI space, but with distinct architectural choices:

1. **Read-only interop**: loads Claude Code (`~/.claude.json`, `~/.claude/skills`) and Codex (`~/.codex/`) MCP servers and skills as-is, never writes to them. Positioned as a drop-in that inherits your existing setup.
2. **Process-level orchestration**: `--orchestrate` spawns up to 4 parallel sub-agents as fresh OS processes (`--print` mode), each with isolated state. `BBARIT_SUBAGENT=1` env var caps nesting at one level (no fork bombs). Structured `== RESULT ==` block at end of each child output.
3. **Keyword-overlap memory** (no LLM for recall): plain markdown files with frontmatter under `memory/`, scored by term overlap at turn start. Extraction runs as background `--print` sub-agent so main turn isn't blocked.
4. **30+ domain personas**: switchable via `--persona` or env var. Covers engineering, design, marketing, finance, etc. Each is a markdown file.
5. **Provider catalog in Rust**: unified `ProviderCall` object carries request surface for all adapters. Planning to trait-ify (`trait ProviderAdapter`).

## Architecture

```
main.rs → lib.rs::run() → cli.rs (flags) → config.rs (settings/trust)
  ├── orchestrator.rs (parallel sub-agents, max 4)
  ├── commands.rs (~7k lines, agent loop)
  ├── tools.rs (~6k, fs/search/shell/office/image)
  ├── llm.rs (~6k, provider adapters)
  ├── memory.rs (keyword recall + background extraction)
  ├── mcp.rs (lazy spawn, failure tombstones)
  └── tui.rs (~6k, interactive terminal UI)
```

Design rules: pattern objectification, cache-hot-path with explicit invalidation, zero clippy warnings, tests-as-contract (300+ unit tests).

## Relation to Our Work

- **Memory approach**: simpler than ours (keyword overlap vs semantic search). Trade-off: faster recall, no embedding dependency, but less accurate for conceptual similarity. Our [[memex]] hybrid approach (semantic + keyword) is more sophisticated.
- **Orchestrator pattern**: similar to [[openclaw]] subagent spawning but at OS process level. The structured result block (`== RESULT ==`) is a neat convention — we use tool responses instead.
- **Interop philosophy**: reading other tools' configs without writing is a respectful stance. [[openclaw]] does similar with ACP (routing to Claude Code, Codex, etc.) but at protocol level rather than config file level.
- **Personas**: we have [[SOUL.md]] as identity + per-task context. Their approach is more modular (swap entire persona). Trade-off: flexibility vs coherence.

## Observations

- Very early (1 day old), no issues, no external contributors yet
- Codebase is large for a new release — likely developed privately before open-sourcing
- The refactoring roadmap is honest and well-structured (5 clear items, each sized for one PR)
- `.pi`-compatible config discovery suggests lineage from/interop with Pi (another coding agent)
- Topics include "pi" — may be a fork/rewrite of Pi's codebase

## Predictions

- At 31⭐ day 1, if trajectory holds, likely 100-200⭐ by end of month
- The interop angle (read Claude Code + Codex configs) is a smart GTM strategy
- Solo-dev velocity risk: single binary with 7k-line files needs community to refactor

Links: [[coding-agent]], [[agent-harness-landscape]], [[openclaw]], [[memex]], [[acp]]
