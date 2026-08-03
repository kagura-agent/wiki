# TencentDB-Agent-Memory

## Overview
- **Repo**: Tencent/TencentDB-Agent-Memory (TencentCloud org on GitHub)
- **Stars**: ~11.6K
- **Language**: TypeScript (monorepo: MemoryCore, MemoryPanel, MemoryKnowledge, MemoryProxy, SDK)
- **Default branch**: feat/server_team
- **Relationship**: new (first PR: #729)

## Contribution Flow
- Standard PR template (Description, Related Issue, Change Type, Self-test Checklist)
- No special gates (no CLA, no DCO, no assignment required)
- No CHANGELOG.md
- Bilingual (CN/EN) in PR template

## Test Commands
- `cd MemoryCore && npm install && npm run build` (basic build verification)
- TBD: unit test commands (not yet explored)

## Architecture Notes
- Monorepo with multiple packages (MemoryCore is the kernel)
- Build uses tsdown for plugin, tsc for individual scripts
- `bin/` contains runtime entry points with fallback logic (try dist first, then tsx source)

## Maintainer Patterns
- Yuntong8888 and Rememorio are active mergers
- Recent PRs are mostly README/docs updates
- Last code push: 2026-07-29

## PR History
- #729 (2026-08-03) — fix(build): remove reference to missing scripts/seed-v2 from build chain [OPEN]

## Gotchas
- Git clone/fetch to this repo keeps getting SIGKILL'd on kagura-server (2026-08-03) — had to use GitHub API for PR creation
- Fork is under kagura-agent/TencentDB-Agent-Memory but actual upstream shows as TencentCloud org in URLs
