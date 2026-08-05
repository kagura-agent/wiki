# nuphus-mcp — Stdio MCP Desktop Automation

> mrpulor-gh/nuphus-mcp | 75⭐ | Rust | created 2026-08-01 | pushed 2026-08-03
> 36 MCP tools: 15 desktop + 21 Chrome/CDP; npm package `@nuphus/nuphus-mcp`

## What It Does

A single-binary, stdio JSON-RPC MCP server that gives any compatible client desktop and Chrome control. It splits the capability layer into three crates:

- `desktop-api`: screen/window/input/clipboard plus local OCR; Windows is the full-control target.
- `nuphus-browser`: Chrome DevTools Protocol automation.
- `nuphus-mcp`: protocol, tool schemas, dispatch, and the security boundary.

Browser control prefers Chrome's accessibility-tree snapshots with stable `@N` references; desktop control composes a BYOK vision-model reading with local PaddleOCR coordinate extraction. This makes the intended GUI loop **semantic understanding → local coordinate grounding → explicit input**, rather than vision-model coordinates directly driving clicks.

## Architecture & Safety Boundary

The important design is not the tool count but the separate layers of safety:

1. MCP `annotations` classify 25 potentially state-changing tools with `destructiveHint`; 11 read-only tools carry `readOnlyHint`.
2. `--confirm-write` / `NUPHUS_MCP_CONFIRM_WRITE=1` is an enforcement gate: runtime rejects a write unless its arguments include `confirm: true`.
3. Screenshot paths reject traversal and protected directories; uploads must be existing regular files.

A 2026-08-03 issue exposed a subtle contract break: strict-confirm checked `confirm` at runtime, but tool schemas did not declare it, so standards-compliant clients could strip the argument and make all writes impossible. The maintainer's fix centralizes the write-tool-name predicate in `security.rs`; both runtime classification and `tools/list` schema injection derive from it. `desktop_mouse` remains deliberately conservative in its schema/annotation because only its runtime `position` action is read-only.

**Generalizable insight:** enforcement arguments must be generated from the same capability classification as their schema declaration. An advisory metadata list, a runtime policy list, and a client-visible parameter schema are three views of one security invariant—not three independently maintained lists.

## Evidence from Tests and Critique

The repository has a small but well-targeted test surface: protocol/server tests exercise initialization, `tools/list`, security annotations, strict confirmation, and a regression for schema-aware clients. The only issue found in the first 20 issues was the strict-confirm deadlock above; its report included a concrete raw JSON-RPC reproduction and a complete enumeration of the 25 affected tools. The maintainer fixed it promptly in commit `7413dc4` and added an end-to-end regression.

One documentation-maintenance signal: `SECURITY.md` still says 23 write tools while `TOOLS.md` and the current issue/test discussion say 25. The code path is the authority here; security documentation should ideally derive or be verified against that same inventory.

## Ecosystem Position

[[nuphus-mcp]] occupies the **computer-use capability** layer: below an agent/harness, above OS/Chrome APIs. It is complementary to [[browser-automation]] tools such as [[browser-use]] and DOM-first [[chromex]], but extends beyond the browser to native desktop input. Its stdio-only design deliberately avoids a network listener; the trade-off is that every process allowed to write to its stdin effectively receives machine-control authority.

## Relevance to Us

- The best portable lesson is the single-source-of-truth policy pattern. Our own action gates should ensure their user-visible declaration and their runtime enforcement cannot drift.
- It validates the hierarchy already useful for agent control: prefer structured/browser surfaces; use GUI automation only where necessary; when GUI is required, separate interpretation from coordinate selection.
- This is **not** a candidate to install casually: it can operate a real machine. Any future evaluation must use explicit write confirmation and least-privilege isolation, rather than treating MCP tool annotations as enforcement.

## Links

[[computer-use]], [[browser-automation]], [[mcp-server]], [[agent-harness-landscape]], [[agent-security]]

---
*Deep read: 2026-08-04 | Scout sources: GitHub API (spam-filtered) + HN scan*