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
- Full checkout gets OOM killed on this machine
- Used GitHub API for push (create blob → tree → commit → ref)

## 维护者
- Bot: github-actions welcome, AI review bot
- Human reviewers: TBD (first PR pending)

## 注意事项
- Node.js 20 for all frontend (CI pins it)
- Python version: check .python-version file
- Website uses pnpm, console uses npm
- Fork PRs can't push labels (permission limitation)

## PR History
| # | Title | Status | Notes |
|---|-------|--------|-------|
| 6331 | chore(console): specify Node.js version requirement | pending | First PR, config-only |
