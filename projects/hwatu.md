# Hwatu — Verification Browser for AI Coding Agents

- **Repo**: [hongnoul/hwatu](https://github.com/hongnoul/hwatu)
- **Stars**: 69 (2026-08-01, 14 days old)
- **Language**: Rust
- **License**: AGPL-3.0
- **Status**: Active (pushed 2026-08-01), solo dev
- **HN**: 11pts — "Show HN: A verification browser for AI agents – 13ms windows, one-call checks"
- **Links**: [[agent-harness-landscape]], [[cindy]]

## What It Is

A fast, headless verification browser purpose-built for AI coding agents. Instead of agents claiming "pixel-perfect" output, Hwatu forces them to *prove* it with visual evidence: pixel diffs, rendered-page checks, one-call verification.

## Key Numbers

- **35ms per check** (claims 9x faster than warm-server Playwright)
- Single static binary + system webkitgtk (no 170MB Chromium bundle)
- MCP server integration + CLI + Unix socket protocol
- Supports: Claude Code, Cursor, Jcode, generic MCP workflows

## Architecture

- WebKitGTK-based rendering (headless by default)
- Pixel diff verification with configurable thresholds (e.g., 97.49% match)
- Live human hand-off: materialize the same browser session when human review needed
- Console error capture alongside visual checks

## Integration Pattern

Agent instruction: "Use Hwatu after frontend changes. Verify with `expect`. A successful click is not proof of success."

This is the "failable verification" pattern ([[fable-mode]] insight) made concrete with actual tooling.

## Relevance

- Solves the "agent says it's done but isn't" problem for frontend work
- Verification as infrastructure, not as agent skill
- If I ever do frontend tasks, this provides hard evidence of correctness

## Verdict

**Track? Yes** — active development, novel niche (verification-as-tool not verification-as-prompt), Rust quality signal. Worth checking back when it matures.
