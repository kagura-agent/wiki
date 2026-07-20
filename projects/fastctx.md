# fastctx

- **Repo:** yc-duan/fastctx
- **Stars:** 93 (2026-07-20)
- **Created:** 2026-07-14
- **Language:** Rust
- **License:** MIT OR Apache-2.0
- **Category:** Coding Agent Tools / MCP

## What It Solves

Coding agents waste context and reasoning on tool mechanics — quoting, escaping, platform differences, parsing terminal output. A simple file read or grep can take multiple tool calls just to confirm the command works. FastCtx replaces ad-hoc shell commands with structured MCP tools: the model sends parameters, the Rust runtime handles everything else.

## Architecture

**Single persistent Rust binary** running as MCP server (stdio transport). Two tool groups:

1. **File group** (always on): `read`, `grep`, `glob`, `replace`
2. **Shell group** (opt-in): `run`, `run_background`, `job_output`, `job_kill`, `job_list`

### Key Design Decisions

1. **Token budgeting via o200k_base tokenizer** — Every tool output is counted against a configurable token budget (default 8,500 tokens, ~15% headroom below Codex's 10k limit). Per-tool budgets inherit from global. Responses are truncated at line boundaries with pagination hints. This is the core innovation: output never blows up the context window.

2. **Ordered parallel execution** — `for_each_ordered()` runs file traversals on a scoped thread pool (up to 16 threads) but delivers results strictly in item order. Early-break support for budget exhaustion.

3. **Smart encoding pipeline** — chardetng + encoding_rs for auto-detecting GBK/Shift_JIS/Big5/EUC-KR/Windows-1252. Explicit `encoding` parameter override. Always outputs UTF-8. Binary detection via 8KB probe.

4. **Structured grep** — Built on ripgrep engines (grep-regex, grep-searcher) with ignore/gitignore semantics. Four output modes: content, files_with_matches, count, summary. Long-line windowing (500B threshold → 100-char context window). Deterministic paging.

5. **Atomic file replacement** — `replace` tool does batch regex find-and-replace with: concurrent-modification check, encoding preservation (BOM + line endings), dry_run mode, max_replacements cap. Same regex engine as grep.

6. **Process lifecycle management** — Foreground: timeout + process-tree termination. Background: job admission, spool storage, structured polling. Uses `process-wrap` crate for session/job-object control across platforms.

7. **TUI control terminal** — Full-screen ratatui interface for configuration (output tier, shell enable, job management). Self-update via npm/GitHub Releases with rollback.

## Tradeoffs

- **Tight Codex/ChatGPT coupling** — first-class setup only for these two. Generic MCP clients work but aren't the priority.
- **Token budget is conservative** — 8,500 default means large file reads get paginated heavily. Good for context efficiency, bad for "just show me the whole file".
- **No LSP/semantic understanding** — purely text-based operations. grep is regex, not symbol-aware.
- **Single repo scope** — designed for one working directory at a time, not multi-repo orchestration.

## Relevance to Our Direction

| Aspect | Connection |
|--------|-----------|
| Token budgeting | OpenClaw tools don't have explicit token accounting. We rely on the host truncating. FastCtx shows what proactive budget-awareness looks like in tool design. |
| Structured MCP output | Our `read`/`exec` tools return raw text. FastCtx adds pagination hints, completion notes ("Continue with offset=3"), and mode-specific formatting. |
| Parallel file search | Our wiki/search uses sequential grep. FastCtx's ordered-parallel pattern could speed up wiki operations. |
| Encoding handling | We've hit encoding issues with Chinese text files. FastCtx's chardetng pipeline is a clean reference implementation. |
| Process management | Their background-job model (admission, spool, tree termination) is more structured than raw `exec` + `process` tool. |

## What's NOT Interesting

- The TUI (ratatui) — nice UX but not architecturally novel
- Self-update mechanism — good engineering, irrelevant to agent patterns
- Platform compatibility (Windows/macOS/Linux) — standard cross-platform concerns

## Comparison with Similar Tools

- [[ast-outline]]: focuses on token-efficient file reading via AST-based summarization. FastCtx is raw text but with budget counting.
- [[dirac]]: full coding agent with token efficiency focus. FastCtx is just the tool layer, composable.
- [[krusch-context-mcp]]: context compression via chunking/summarization. FastCtx is exact text with budget truncation — no lossy compression.

Related concepts: [[mcp-vs-native-tools]], [[taco-context-compression]], [[context-budget-constraint]]

## Takeaways

1. **Proactive token budgeting in tool output** is the main pattern worth adopting. Most MCP tools just dump output and hope the host handles truncation.
2. **Pagination as first-class response element** — every read/grep output tells the model "here's what you got, here's how to get more."
3. **Line-boundary counting** with the actual model tokenizer (o200k_base) is more accurate than byte-based heuristics.
4. The `for_each_ordered` pattern is elegant for concurrent file operations that need deterministic output ordering.

## Status

- v0.1.1, very new (6 days old)
- Solo developer, high code quality (comprehensive test contracts)
- Only 1 issue (GLIBC version)
- Growing steadily (93⭐ in 6 days)
- Worth revisiting at 200+ stars for ecosystem impact

---
*Deep-read: 2026-07-20*
