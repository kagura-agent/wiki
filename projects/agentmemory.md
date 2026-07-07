# agentmemory (rohitg00)

- **Repo**: https://github.com/rohitg00/agentmemory
- **Language**: TypeScript
- **Relationship**: new (first PR pending)
- **Build**: `npm install` → `npm run build` (tsdown) → `npm test` (vitest)
- **Test runner**: vitest v4.1.10

## Contribution Notes

### PR #1028 — fix: unwrap ResilientProvider name in noop summarize check (2026-07-07)
- **Issue**: #1020 — noop provider name mismatch after ResilientProvider wrapping
- **Status**: OPEN (pending review)
- **Fix**: 2 files, +25/-1 — regex unwrap of `resilient(...)` prefix before `=== "noop"` comparison
- **CodeRabbit**: 1 trivial nitpick (remove WHAT-comment) — addressed immediately
- **CI**: No GitHub Actions — Vercel deploy only (needs auth for forks, expected)
- **Pre-existing test failures**: `integration.test.ts` (needs live server), `fs-watcher.test.ts` (flaky `toThrow` assertion)

### Repo Patterns
- **CONTRIBUTING.md**: strict DCO sign-off, conventional commits, no AI attribution headers (no "Generated with Claude Code" etc.)
- **Branch naming**: `fix/<issue-number>-<short-name>`
- **CodeRabbit**: auto-reviews on every PR, "CHILL" profile
- **Provider architecture**: all providers wrapped in `ResilientProvider` (circuit breaker) — any `provider.name` check must account for wrapping
- **Related issue**: #996 reports the same symptom area (zero-LLM failureCount inflation)
- **Dist bundling**: tsdown produces `dist/index.mjs` + secondary chunks — fix source, not dist

### Maintainer Preferences
- Not yet observed (first PR, no human review yet)
- Will update after review feedback
