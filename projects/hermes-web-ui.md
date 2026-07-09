# hermes-web-ui

Official-adjacent web dashboard for [[hermes-agent]] by EKKOLearnAI.

- **Repo**: EKKOLearnAI/hermes-web-ui (680★, created 2026-04-11)
- **License**: TBD
- **Language**: TypeScript (Vue3 + Naive UI)

## What It Does

Web dashboard for Hermes Agent — multi-platform AI chat, session management, scheduled jobs, usage analytics & channel configuration (Telegram, Discord, Slack, WhatsApp).

## Ecosystem Position

- Third web UI for Hermes (alongside [[hermes-hudui]] 890★ and hermes-hud TUI)
- 680★ in 6 days — strong adoption signal
- Covers operational concerns: channel config, cron, analytics — more "admin panel" than hudui's "consciousness monitor"
- Topics include `naive-ui`, `vue3`, `i18n`, `web-terminal` — production-grade frontend

## Relevance

- Hermes ecosystem continues to grow rapidly — multiple independent teams building tooling
- Validates demand for agent management UIs beyond CLI/TUI
- Compare with [[rivonclaw]] (OpenClaw GUI, 252★) — Hermes ecosystem producing more UI tools faster
- We contribute to hermes-agent upstream; understanding its tooling ecosystem matters

## Open Questions

- Is this EKKOLearnAI-affiliated or community-built?
- How does it compare feature-wise to hudui? (Both are dashboards but different focus)

## See Also

- [[hermes-hudui]] — consciousness monitor (React, 890★)
- [[hermes-agent]] — the core agent

## Contribution History

### PR #1861 — fix: resolveHermesPath rejects valid absolute paths (2026-06-30)
- **Status**: Pending review
- **Issue**: #1848 (reported bug — file browser breaks on absolute paths)
- **Fix scope**: 2 source files + test file. 1-line logic changes.
- **CI**: Repo has "Aurora Smoke" and "Build" workflows, but they don't trigger automatically on fork PRs (likely need maintainer approval)
- **Review style**: Unknown yet (first PR). Repo accepts external PRs (4/20 recent merges from non-owner observed during study)
- **Testing**: Vitest. node_modules need `fdir` manually installed (may be missing from lockfile). Local tests pass.
- **Gotcha**: `isPathWithin` in `hermes-path.ts` also had the same `startsWith('..')` bug — needed fix in two files
- **Note**: Fork is named `hermes-studio` on GitHub, not `hermes-web-ui`

### PR #2004 — fix: write session ended_at/end_reason when bridge run terminates (2026-07-09)
- **Status**: Pending review
- **Issue**: #1998 — Agent 正常結束後 UI 永久顯示「思考中」
- **Root cause**: `handle-bridge-run.ts` never calls `updateSession()` to write `ended_at`/`end_reason` after run termination
- **Fix scope**: 1 source file (3 insertion points, ~21 lines) + 1 test file (5 tests)
- **Key observation**: `updateSession` is synchronous (uses better-sqlite3), so try-catch correctly catches errors without await
- **CI**: No checks configured for fork PRs (same as #1861)
- **AI disclosure**: Added (first-time repo, no merged PRs yet)
- **Architecture note**: Session controller uses `ended_at == null` for `is_active` check. Queue guard prevents premature session termination when runs are queued.
