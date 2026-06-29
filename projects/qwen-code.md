# QwenLM/qwen-code

## 基本信息
- **语言**: TypeScript (monorepo)
- **Stars**: 24,601
- **方向**: AI coding agent (CLI + VSCode extension)
- **结构**: packages/ monorepo — cli, core, sdk-*, vscode-ide-companion, webui, zed-extension
- **关系**: established (wenshao approved 2 PRs, fast review cadence)

## Review 风格
- **wenshao**: 主要 reviewer，使用多层 AI review bot:
  - **qwen3.7-max** via `/review` — 架构层面的问题（如 hard threshold 遗漏）
  - **claude-opus-4-8** via `/qreview` — 深度 trace 分析（如追踪 params.config.maxOutputTokens 的实际赋值链路）
  - 人工 CHANGES_REQUESTED 通常跟在 bot 分析之后，表示认可 bot 的判断
- Review 特点：关注 **完整性**（"只修了一半"）和 **sourcing 正确性**（"这个字段在真实路径里有值吗？"）
- 不接受只回 comment 说"会改" — 必须 push 代码。第二轮 review 会验证代码确实解决问题
- external PR 只触发 `review-pr` check（skipped），主 CI 需 maintainer 手动触发
- merge rate 高，对 AI PR 友好

## PR 历史
| PR | Issue | 状态 | 备注 |
|---|---|---|---|
| #4456 | #4450 --list-extensions does nothing | pending | First PR, AI disclosure included |
| #4459 | #4452 Claude plugin install broken for complex plugins | APPROVED | wenshao approved, waiting merge |
| #4461 | #4448 invalid settings.json silently reset | APPROVED | wenshao approved, waiting merge |
| #4474 | #4466 env var substitution from .env files | pending | Ordering fix in loadSettings() |
| #5957 | #5950 compression threshold ignores output budget | pending | v2: source effectiveReservedOutput from model limits; 2-round review |

## 贡献要求 (CONTRIBUTING.md)
- Link to existing issue (required, open issue first if none exists)
- Keep PR small and focused (atomic, single issue)
- Use Draft PRs for WIP
- Run `npm run preflight` before submit (tests + lint + style)
- Update docs if user-facing change
- Include screenshot/video demo
- PR template: Summary, Validation (commands, evidence), Scope/Risk
- No DCO/CLA required
- External PRs only get `review-pr` check (skips, needs maintainer approval to run)
- Main CI (Lint, Test, CodeQL) only runs after maintainer triggers

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
- (2026-05-23) node_modules on NTFS data disk: vitest works but `npm install` for full monorepo gets OOM-killed. Workaround: don't reinstall, use existing node_modules
- (2026-05-23) `collectResources()` skip-logic bug: tests already worked around it (line 392 comment). When fixing similar skip/cache bugs, check test workarounds for prior art
- (2026-05-23) esbuild ETXTBSY on NTFS: retry after brief sleep resolves it

## Extension 系统架构笔记
- Extensions installed to `~/.qwen/extensions/<name>/`
- Claude plugins converted via `claude-converter.ts`: marketplace.json → resolvePluginSource → copyDirectory → collectResources → convertClaudeToQwenConfig
- `qwen-extension.json` intentionally only has name/version/mcpServers/hooks — commands/skills/agents are loaded from directory structure
- Key files: `packages/core/src/extension/` (extensionManager, claude-converter, gemini-converter, storage, marketplace)

## 踩过的坑 (2026-05-24)
- Sparse checkout + shallow clone cannot push to GitHub (missing objects). Use `gh repo sync` + GitHub Contents API for file uploads, or do a full clone if disk allows
- Large test files (3600+ lines) exceed CLI arg limit for `gh api` — use `--input` with JSON file instead

## 2026-05-31 workloop notes
- qwen-code was **missing from gogetajob watchlist** despite 2 open PRs (#4456, #4474). Fixed: `gogetajob scan QwenLM/qwen-code`
- Both PRs APPROVED by wenshao, merge-pinged, ball on maintainer
- 82% merge rate (high), 24775 stars
- Lesson: always cross-verify with `gh search prs` — gogetajob sync is not exhaustive (guide #42)

## 2026-06-28 workloop notes
- PR #5957 (fix: subtract reserved output tokens from compression threshold) submitted
- Issue #5950: auto-compression fails when max_tokens escalates to 64K — computeThresholds() used raw 131K window instead of effective 67K input budget
- Fix: 3 files, ~146 lines (mostly tests), surgical — additive only, backward compatible
- Earlier workloop session had already implemented the fix but stalled at plan_review node without advancing. Cron resume recovered the instance correctly
- Claude Code `--print` mode stuck with no output for 3+ minutes — fell back to manual implementation (the change was small enough: ~20 LOC production code)
- External PRs only get `review-pr` check (skips), normal behavior — don't wait for CI to go green
- Fresh-context review caught a HIGH issue (negative contextLimit when reservedOutputTokens >= window) — added Math.max(0, ...) clamp and edge case test
- Stars: 25604 (up from 24775 on 05-31)
