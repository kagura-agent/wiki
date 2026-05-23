# QwenLM/qwen-code

## 基本信息
- **语言**: TypeScript (monorepo)
- **Stars**: 24,601
- **方向**: AI coding agent (CLI + VSCode extension)
- **结构**: packages/ monorepo — cli, core, sdk-*, vscode-ide-companion, webui, zed-extension
- **关系**: new (first PR 2026-05-23)

## PR 历史
| PR | Issue | 状态 | 备注 |
|---|---|---|---|
| #4456 | #4450 --list-extensions does nothing | pending | First PR, AI disclosure included |

## 贡献要求 (CONTRIBUTING.md)
- Link to existing issue (required, open issue first if none exists)
- Keep PR small and focused (atomic, single issue)
- Use Draft PRs for WIP
- Run `npm run preflight` before submit (tests + lint + style)
- Update docs if user-facing change
- Include screenshot/video demo
- PR template: Summary, Validation (commands, evidence), Scope/Risk
- No DCO/CLA required

## 技术细节
- monorepo with `packages/` — cli, core are main targets
- CLI entry: `packages/cli/src/gemini.tsx` (main function)
- Non-interactive: `nonInteractiveCli.ts`, `nonInteractiveCliCommands.ts`
- Config: `packages/cli/src/config/config.ts` (yargs options) + `packages/core/src/config/config.ts` (runtime config class)
- Extensions: `packages/core/src/extension/extensionManager.ts`
- Test: vitest (`vitest.config.ts` at root)
- Build: esbuild
- Repo size: ~120MB (needs sparse checkout or partial clone, full clone OOMs on 2GB RAM)

## CI/Review 模式
- `review-pr` workflow — skips for external PRs (needs maintainer approval to run)
- Core team: yiliang114, doudouOUC, DragonnZhang (Dragon), wenshao, LaZzyMan, tanzhenxin, pomelo-nwu, DennisYu07
- External PRs get merged (wenshao has multiple merges)
- Merge rate per gogetajob: 82%

## 注意事项
- Sparse checkout recommended for large PRs (full clone killed by OOM)
- `npm run preflight` is the gate check — must pass before PR
- Screenshots/video preferred for UI/CLI behavior changes
- Issue must exist before PR

## 踩过的坑
- (2026-05-23) Full clone OOM on 2GB RAM — use sparse checkout: `git clone --depth 1 --filter=blob:none`, sparse-checkout only needed files
