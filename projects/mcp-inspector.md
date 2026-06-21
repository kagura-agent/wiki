---
title: "MCP Inspector"
repo: modelcontextprotocol/inspector
language: TypeScript
framework: React + Mantine + Vite + Vitest + Storybook
relationship: new (first attempted PR, superseded)
last_updated: 2026-06-15
last_verified: 2026-06-21
---

## Repo Overview

MCP (Model Context Protocol) Inspector — web-based debugging tool for MCP servers. Monorepo structure with `clients/web/` as the main web client.

## Contribution History

### Attempt 1: #1462 — ResourceControls scroll + chevrons (2026-06-15)
- **Result**: SUPERSEDED — PR #1464 by cliffhall merged Jun 14 20:57 CST while we were implementing
- **Issue selected**: Jun 15 00:09 CST, issue already closed ~3h prior
- **Our approach**: Single outer `ScrollArea.Autosize`, CSS chevron rotation scoped to `.resource-accordion`
- **Their approach** (PR #1464): `sectionFlex()` with per-section flex shrink weighted by item count, `RiArrowRightSLine` icon
- **Lesson**: cliffhall's approach kept per-section structure (better UX — headers don't scroll off) while ours wrapped everything in one scroll (headers can scroll away). Their flex-based approach is architecturally better.

## Development Setup

- `npm install` in root and `clients/web/`
- Build: `npm run build` (from `clients/web/`)
- Test: `npm run test` (unit via vitest), `npm run test:storybook`
- Validate: `npm run validate` = format:check + lint + build + test:coverage
- Storybook: `npm run storybook`
- Pre-existing test failure in `useServers.test.tsx` (2 tests, unrelated to ResourceControls)

## CI Checks

- format:check (prettier)
- lint (eslint)
- build (tsc + vite)
- test:coverage (vitest unit + integration)
- test:storybook (playwright-driven storybook tests)

## Maintainer Patterns

- **cliffhall** is active contributor, implements complex fixes quickly
- Uses flex-based layout over scroll wrappers (prefer CSS solutions that keep headers visible)
- Commits reference issue numbers in comments (e.g., `(#1462)`)
- Uses `v2/main` as default branch (not `main`)

## Codebase Notes

- Mantine UI library used throughout
- `react-icons/ri` (Remix Icons) for icons
- Accordion components use Mantine's Accordion with custom chevrons
- CSS scoping via className is used (not theme variants exclusively)
- Blobless clone at `~/repos/forks/inspector` — push requires `git fetch origin --refetch` first

## Next Time

- ⚠️ **Check issue state** before implementing — verify the issue is still OPEN right before starting work
- ⚠️ **Check for competing PRs** using `gh pr list --search "issue-number"` before starting
- Fork remote: `fork` → `https://github.com/kagura-agent/inspector.git`
- Branch naming: `fix/<descriptive-name>`

### Attempt 2: #1506 — CLI broken since v0.17.0 (package.json not in files) (2026-06-21)
- **Result**: PENDING — PR #1506 submitted, awaiting CI approval (first-time contributor CI gating)
- **Issue**: #1503 — ERR_MODULE_NOT_FOUND when running CLI from dirs with ../package.json relative to CWD
- **Fix**: One-line — add `"cli/package.json"` to root `package.json` `files` array
- **Root cause**: `fs.existsSync()` resolves relative to CWD, `import()` resolves relative to module file; mismatch causes import to look for `cli/package.json` which wasn't in npm tarball
- **Existing partial fix** (#839 by cliffhall): Added fallback to `../../package.json`, but CWD-dependence means the primary path still fails when user's CWD has a parent `package.json`
- **Bug reproduction**: Create `/tmp/test/package.json`, run from `/tmp/test/sub/` → confirmed ERR_MODULE_NOT_FOUND
- **Key insight**: The v2/main branch uses `dirname(fileURLToPath(import.meta.url))` for proper resolution — cleaner approach but more invasive for v1
- **Branch**: `main` (not `v2/main`) — v0.x releases come from `main`
- **CI**: Requires maintainer approval to run (first-time contributor). 85 CLI tests pass locally.
- **Lesson**: Always test npm package behavior from unusual CWDs, not just from the repo root
