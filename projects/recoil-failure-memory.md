# Recoil (EclipseElips)

- **Repo**: https://github.com/EclipseElips/recoil
- **Stars**: 16 (2026-06-28, 3 days old)
- **Language**: Go (stdlib only)
- **Status**: Solo dev, tiny, early. Concept project.

## What It Is

Failure memory for AI coding agents. Plain text (TSV), no embeddings, keyword matching. Remembers what went wrong, reminds before it happens again.

## Key Patterns

1. **Situation-triggered recall** — match by keyword overlap, not categories
2. **Auto-capture** — `recoil watch -- <cmd>` records non-zero exits; post-commit hook records git reverts
3. **Pre-commit guard** — `recoil guard` checks staged files against past failures (≥2 keyword overlap)
4. **Strength decay** — halves every 30 unused days. Recall resets clock + bumps count. High-surprise weight survives longer.
5. **Trigger weighting** — correction(3) > revert(2.5) > test-fail(2) > error(1.5) > manual(1)

## Comparison to My System

| Recoil | My System |
|--------|-----------|
| `recoil encode` | beliefs-candidates.md entry |
| `recoil guard` (pre-commit) | DNA preflight (per-session) |
| Strength decay (30d half-life) | Preflight thinning (14d age limit) |
| Auto-capture (watch + hook) | Manual logging only |
| Keyword overlap matching | Grep + semantic search |

Key insight: their auto-capture from failures (`watch`) is something I don't have. I rely on manual entry of lessons.

## Links

[[agent-memory-ground-truth]], [[beliefs-candidates]], [[self-evolving-observations]]
