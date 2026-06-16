# Oh My Pi (can1357/oh-my-pi)

> AI Coding agent for the terminal — hash-anchored edits, optimized tool harness

## 基本信息
- Repo: can1357/oh-my-pi
- 语言: TypeScript + Rust (native crates)
- Stars: ~3,061
- License: MIT
- Runtime: Bun (1.3+)
- 包管理: bun workspaces (monorepo)

## 架构
- `packages/coding-agent/` — 主 CLI 入口 (`src/cli.ts`)
- `packages/utils/` — 工具库（env loading, dirs, etc.）
- `packages/ai/` — AI provider 层
- `crates/` — Rust native modules (pi-natives, brush-*)
- 入口: `#!/usr/bin/env bun` → `packages/coding-agent/src/cli.ts`

## 维护者
- **can1357**: 主维护者
- Merge rate 待观察
- 最近 merged PR 多来自不同贡献者（开放社区）
- 无 CONTRIBUTING.md

## 开发笔记
- 测试: `bun run test` (并行 TS + Rust)
- **⚠️ 仓库极大**: git clone 会 SIGKILL（OOM），必须用 `--filter=blob:none --depth 1` + sparse checkout
- Bun auto-loads `.env` 文件，omp 自己也在 `packages/utils/src/env.ts` 手动加载（冗余但有 try-catch）
- `.env` loading: `parseEnvFile()` 有 try-catch，graceful failure
- `getConfigRootDir()` / `getAgentDir()` 是纯路径计算，不读文件系统

## 踩过的坑
- 2026-04-16: 尝试修 #709 (.env crash with fence sandbox)
  - 假设是 Bun auto-load 导致 crash → 实测 Bun 对 EPERM .env 处理 graceful（不 crash）
  - omp 自己的 `parseEnvFile` 也有 try-catch
  - 真实 crash 原因可能是 fence 直接 SIGKILL 进程而非返回 EPERM
  - 教训: 远程无法复现的 sandbox 相关 bug 不要轻易接
- 2026-04-18: git clone OOM (SIGKILL)
  - 仓库太大，即使 --filter=blob:none --depth 1 也会 OOM
  - sparse checkout 同样 OOM（fetch 本身就超内存）
  - 解决：改用 GitHub API 直接读写文件，不 clone
  - 教训：超大 repo 必须用 API 方式工作，不要尝试 clone

## 我们的 PR
- PR #740: fix(cli): support --flag=value equals syntax for all CLI flags (Fixes #739) — MERGED
  - 2026-04-18: 通过 GitHub API 直接提交（本地无法 clone，OOM）
- PR #752: fix(auth): let OAuth credentials override keyless provider flag from stale models.yml (#749) — CLOSED
  - 2026-04-20: 3行改动
- PR #1245: fix(tui): add wrap mode to SelectList and HookSelector for long option labels (#1243) — PENDING
  - 2026-05-21: 5 files, +90 -23 lines
  - SelectList 加 wrap layout option，HookSelectorComponent/OutlinedList 重构支持 wrapping
  - ask tool 默认启用 wrap
  - CI 全过（check + test + install_methods）

## 维护者模式
- **can1357**: 主维护者，无 CONTRIBUTING.md
- CI: biome check (formatting + lint) + bun test + install_methods + rust-hash
- **biome 严格要求 trailing newline** — GitHub API 创建 blob 时注意保留
- 社区活跃，多个贡献者的 PR 存在
- PR #740 已 merge — 关系 established

## 开发笔记补充
- TUI 架构: `SelectList` 是通用组件，`HookSelectorComponent` 是 ask tool 专用组件
- ask tool 路径: `ask.ts` → `ui.select()` → `extensionUi.select()` → `showHookSelector()` → `HookSelectorComponent`
- `HookSelectorComponent` 有 outline 和非 outline 两种模式
- outline 模式用 `OutlinedList`（带 box border），非 outline 模式用 `Text` children
- `wrapTextWithAnsi()` 来自 native Rust module，处理 ANSI escape codes
- `ExtensionUIDialogOptions` 在 types.ts 中定义，是跨层传递 UI 选项的接口

## 我们的 PR (续)
- PR #2764: feat(discovery): discover CLAUDE.md alongside AGENTS.md in ancestor walk (#2612) — PENDING
  - 2026-06-16: 2 files changed, +150 -22 lines
  - `agents-md.ts`: iterate ["AGENTS.md", "CLAUDE.md"] in ancestor walk, alphabetical order
  - New test file: 4 tests (solo CLAUDE.md, both files ordering, multi-depth, hidden-dir skip)
  - CI: ALL 10/10 checks green. Codex review: no suggestions.
  - 本地 clone 成功了（与之前 OOM 不同，可能 repo 瘦身或机器内存变了）
  - `bun install` 成功但 native addon 编译需要完整 Rust toolchain，本地测试依赖 native addon
  - `LoadOptions` 类型不含 `repoRoot`/`home`，测试需用 `.git` 目录控制 `findRepoRoot()` 边界

## 开发笔记补充 2
- **本地 clone 可行**（2026-06-16）: `--filter=blob:none --depth 1` 成功，之前 OOM 可能是 LFS 或内存问题
- **本地测试不可行**: 需要 `pi_natives` native addon (Rust + napi-rs)，cargo build 超时/被 kill
- **测试 API**: `loadCapability<T>(capabilityId, options)` — options 是 `LoadOptions`（只有 `cwd`, `providers` 等），不是 `LoadContext`。`repoRoot` 由 `findRepoRoot(cwd)` 自动解析（找 `.git` 目录）
- **CI checks**: biome check (format + lint) + tsgo (type check) + bun test (parallel, multiple buckets) + install methods + native build
- **biome 格式**: multiline callback 参数会被 biome 折叠成单行（如果够短）

## 下次注意
- ~~**必须用 GitHub API 方式工作**~~ → 本地 clone 现在可行（shallow + blob filter）
- 但本地测试仍不可行（native addon 编译需完整 Rust 环境）
- **测试中 repoRoot 控制**: 创建 `.git` 目录，不是传 `repoRoot` 参数
- CI 有 biome 格式检查，提交前 `npx biome check <file>` 验证
- `bun install` 后会修改 `bun.lock` — 记得 `git checkout -- bun.lock` 恢复
- `LoadOptions` vs `LoadContext` 类型区分：前者给 `loadCapability()`，后者给 provider `load()`

Links: [[coding-agent-ecosystem]]
