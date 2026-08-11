# QwenPaw (agentscope-ai/QwenPaw)

**Repo**: https://github.com/agentscope-ai/QwenPaw
**Language**: Python (backend) + TypeScript/React (console/website)
**Stars**: ~24K
**关系状态**: new (first PR: #6331, 2026-07-22)

## Contribution Flow
- Comment on issue first per CONTRIBUTING.md §1
- Conventional Commits required (type(scope): subject)
- PR title same format as commit
- pre-commit + pytest for Python changes
- `cd console && npm run format` for frontend changes

## CI/Gates
- **Real behavior proof**: Fork-origin PRs get `triage: needs-pr-context` label but the action fails with permissions error on forks. Known fork CI limitation — not a code issue
- **AI Review Approval**: Async AI review (pending on first PR)
- **pre-commit**: Python lint/format CI check
- **npm-format**: Frontend formatting check

## 测试命令
- Python: `pip install -e ".[dev,full]" && pre-commit run --all-files && pytest`
- Frontend: `cd console && npm run format:check`

## Clone 方式
- Sparse checkout (tree:0 filter) — repo is ~93MB
- Full checkout gets OOM killed on this machine; use GitHub API for small branch repairs (create blob → tree → commit → ref) rather than retrying full clone.
- Never commit local-path pointer text (for example `@/tmp/...`) in place of file contents; validate remote blobs after API-based push with JSON/YAML/plain-text parsers.

## 维护者
- Bot: github-actions welcome, AI review bot
- Human reviewers: TBD (first PR pending)

## 注意事项
- Website requires Node.js 22+: `@supabase/supabase-js@2.110.4` in `website/pnpm-lock.yaml` declares `>=22.0.0`; website deploy CI and docs must match. Console retains its independent `>=20` declaration.
- Python version: check .python-version file
- Website uses pnpm, console uses npm
- Fork PRs can't push labels (permission limitation)

## PR History
| # | Title | Status | Notes |
|---|-------|--------|-------|
| 6331 | chore(website): declare Node 22 requirement | pending | First PR; website and deploy requirements aligned to Node 22. Human review found the required website format workflow still used Node 20; fixed in `2b945feb` (`npm-format.yml` website job only). Node 22.23.2 + pnpm 9.15.9 strict frozen install, format check, YAML parse, and diff check passed; remote workflow content re-verified. |
