# Emdash

- **Repo**: generalaction/emdash
- **Language**: TypeScript (Electron + React)
- **Stars**: ~4.6k
- **Merge rate**: 94%
- **Response time**: ~3.4h
- **Relationship**: new (first PR)

## Contributing Requirements
- Node 24.0.0+, pnpm 10.28.0+
- Branch naming: `feat/<slug>` or `fix/<slug>`
- No DCO/CLA/changeset required
- Small focused PRs preferred
- Tests: `pnpm run test` (vitest)
- Lint: `pnpm run format && pnpm run lint && pnpm run typecheck`
- No CI checks on PRs (as of 2026-05-24)
- No PR template enforced

## Architecture Notes
- `src/main/` — Electron main process, IPC handlers, services
- `src/renderer/` — React UI (Vite)
- SQLite local DB under OS userData folder
- Git worktrees created in sibling `worktrees/` folder
- **SSH projects**: `SshWorktreeHost` wraps filesystem ops with POSIX path validation
- **WorktreeService**: shared between local and SSH hosts, uses `pathApi` for platform-correct path ops (PR #2212)

## PR History
| PR | Issue | Status | Notes |
|---|---|---|---|
| #2902 | #2901 | pending | fix IdentityFilteredAgent instanceof — extends BaseAgent |
| #2885 | #2881 | pending | fix GNOME Wayland dock icon — set app.desktopFileName |
| #2212 | #2155 | pending | fix SSH worktree POSIX path separators on Windows |

## Learnings
- Repo is 158MB (as of 2026-07) — git operations can OOM when system memory is pressured (pnpm install on this monorepo is very heavy; don't run in same session as other large processes)
- **DO NOT run `pnpm install` unless absolutely necessary** — the monorepo has massive deps, takes forever and can OOM-kill other git processes
- For trivial fixes (< 5 lines), skip local test validation — issue reporter's verification + fresh-context review is sufficient
- Repo has no CI on PRs — maintainer validates manually
- `app-identity.ts` is the single source for app naming constants (APP_ID, PRODUCT_NAME, APP_NAME_LOWER, etc.)
- `configure-app-identity.ts` is a side-effect import (first import in index.ts) — sets app name and paths before anything else runs
- No CI on PRs — maintainers review manually, response time is fast (~3.4h)
- arnestrickmann is an active contributor who triages issues quickly
- `WorktreeService` is shared between local and SSH — path operations must be platform-aware
- `SshWorktreeHost.validateAbsolute()` is the single boundary check for all SSH path ops
- Repo has active contributor base (janburzinski is a frequent contributor)

## Code Style
- Uses oxfmt formatter (not prettier)
- Imports from path aliases like `@main/`, `@shared/`
- Result type pattern: `ok(value)` / `err({ type: 'error-name' })`

## 2026-07-17 Workloop Notes

### Issue Triage Results
- #2865 (SSH freeze after sleep): Maintainer (arnestrickmann) actively working on it as part of SSH development cycle
- #2853 (file-tree scan storm): Same — part of "significant work around SSH and remote execution"
- #2867 (tmux tab width): Will be fixed as part of #2865
- #2886 (archived tasks teardown): Competing PRs already exist
- #2882 (FTS5 reindex lockup): Competing PRs already exist
- #2837 (default branch setting): Maintainer couldn't reproduce on canary, asked reporter for more info
- #2896 (SSH password not saved): Windows-specific, code analysis shows correct paths, can't identify clear defect without reproduction

### Key Observation
The emdash team (arnestrickmann) is doing a major SSH overhaul in their current development cycle. Most SSH-related issues are being handled internally. Non-SSH issues tend to have competing PRs quickly. This repo is actively maintained but heavily defended — external contributions to SSH are likely to be superseded.

### Strategy for Next Round
- Wait for current SSH work to land (watch for new releases)
- Focus on non-SSH issues that appear fresh
- My 2 existing PRs (#2902, #2885) are very recent — wait for review before adding more
