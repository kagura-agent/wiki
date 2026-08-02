# LangWatch (langwatch/langwatch)

> LLM evaluations and AI agent testing platform

## 基本信息
- Repo: langwatch/langwatch
- 语言: TypeScript (monorepo)
- Stars: ~3,450
- License: MIT (with EE directory)
- 包管理: npm/pnpm
- 测试框架: vitest

## Contribution Flow
- No special claim required
- Minor fixes: open PR directly
- Major changes: open issue first for discussion
- CONTRIBUTING.md is standard template

## 维护者
- rogeriochaves — active, merges regularly
- sergioestebance — active contributor

## PR Patterns
- Title: conventional commits (`fix(scope):`, `feat(scope):`, `perf(scope):`)
- Tests expected alongside fixes
- No CHANGELOG requirement observed

## Codebase Notes
- Very large repo (~327MB) — cannot full-clone on kagura-server
- Use GitHub API for file operations and push
- Sparse checkout required if local clone needed
- Monorepo: main app in `langwatch/` directory
- Enterprise features in `langwatch/ee/`
- Billing in `langwatch/ee/billing/`
- Unit tests colocated in `__tests__/` directories

## PR History

### PR #6432 — fix(billing): clear endDate on reactivation (2026-08-02)
- **Issue**: #6365 — endDate left stale on reactivation
- **Status**: PENDING (first PR, awaiting CI and review)
- **Fix**: 2 lines — add `endDate: null` to activate() and updateQuantities()
- **Tests**: 2 new unit test cases
- **Method**: API-based push (no local clone due to repo size)

## Next Time
- ⚠️ Large repo — use GitHub API push or shallow+sparse clone
- First PR — watch for CI requirements and reviewer feedback
- Check if `ee/` has different review gates
