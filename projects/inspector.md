# modelcontextprotocol/inspector

## Overview
- MCP Inspector — debugging/inspection tool for Model Context Protocol
- 10K+ stars, 80% merge rate
- Active v2 development on `v2/main` branch (v1 on `main`)

## Contribution Flow
- No special claim required
- PRs should target `v2/main` for v2 work (label `v2`)
- Tests: `npm test` (vitest), `npm run test:e2e`
- Style: prettier (`npm run prettier-check`)
- No CHANGELOG requirement observed

## Local Setup Notes
- Monorepo with `clients/web/`, `core/`, `cli/` directories
- npm workspace (no pnpm)
- **⚠️ npm install requires significant RAM** — may fail on memory-constrained machines
- Node.js 22 compatible

## Maintainer Patterns
- Recent PRs by cliffhall are frequent contributor
- PR titles: `web:`, `tui:`, `fix(...):`  format
- Screenshots encouraged in `pr-screenshots/` dir for UI changes
- Clear, concise PR descriptions

## PRs
- #1758 — fix(test): use non-base36 secret fixtures to prevent flaky redaction assertion (2026-07-24)
