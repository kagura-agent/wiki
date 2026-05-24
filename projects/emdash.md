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
| #2212 | #2155 | pending | fix SSH worktree POSIX path separators on Windows |

## Learnings
- Repo is 138MB — git fetch can be slow/timeout; use GitHub API for branch creation as fallback
- `WorktreeService` is shared between local and SSH — path operations must be platform-aware
- `SshWorktreeHost.validateAbsolute()` is the single boundary check for all SSH path ops
- Repo has active contributor base (janburzinski is a frequent contributor)

## Code Style
- Uses oxfmt formatter (not prettier)
- Imports from path aliases like `@main/`, `@shared/`
- Result type pattern: `ok(value)` / `err({ type: 'error-name' })`
