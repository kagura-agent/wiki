# Skybridge — alpic-ai/skybridge

## Overview
- **语言**: TypeScript
- **结构**: pnpm monorepo（packages/core, packages/devtools, packages/create-skybridge, docs, infrastructure, landing）
- **UI 组件**: `@alpic-ai/ui`（shadcn 风格，本地 first-party 包）
- **DevTools 包名**: `@skybridge/devtools`
- **格式/lint**: biome（`biome check --write` / `biome ci`）
- **测试**: vitest（unit）+ `tsc --noEmit`（types）
- **clone 方式**: partial clone（`--filter=blob:none`），大小 ~28MB（API size 28193 KB）

## 本地环境
- 工作副本: `/tmp/skybridge-dev`（含 fork remote `fork` → kagura-agent/skybridge，分支 feat/devtools-preview-inspect）
- 干净 main 副本: `/tmp/skybridge-full`
- Node 22（`.nvmrc`），pnpm workspace
- 测试命令（在 packages/devtools 下）:
  - `pnpm run test:types` — `tsc --noEmit -p e2e/tsconfig.json`
  - `pnpm run test:format` — `biome ci`
  - `pnpm run test:unit` — `vitest run`
  - 全量 `pnpm run test` = format + types + unit

## 架构要点
- **DevTools UI 布局用 `react-resizable-panels`**：`Group` / `Panel` / `Separator` + `useDefaultLayout({ id, panelIds, storage })`。可拖拽 panel 一律走这套，不要用固定宽度 div。
- **Panel 尺寸约定**：`defaultSize`（像素数字）、`minSize`、`maxSize`；`Separator` 用 `className="w-px shrink-0 bg-border transition-colors hover:bg-ring data-separator-active:bg-ring"`。
- **大输出/大 view-state 警告**：`@/lib/context-warnings.js` 里 `TOOL_OUTPUT_WARNING_TOKENS = 5_000`、`VIEW_STATE_WARNING_TOKENS = 20_000`。UI 层用 `ContextWarningAlert`（可 dismiss，sessionStorage 记忆）+ `ContextWarningBadge`（来自 `tool-panel/context-warning.js`）。**不要自造 "large" 标签** — 复用这两个组件。
- **Preview mode**：`layout/preview/index.tsx` — 桌面用 ChatgptShell/ClaudeShell，移动端用 PhoneFrame（`useIsMobile`）。DevTools 侧栏通过 `showDevTools` state + ToolPanelToolbar 的 `PanelRight` 按钮 toggle。
- **路径别名**: `@/lib/...`、`@/lib/mcp/...`（tsconfig paths）。
- **token 估算**: `getToolOutputTokenCount(response)` 接受 `CallToolResponse`，对 `undefined` 需 guard（`response ? ... : 0`）。

## Reviewer 模式
- **Greptile AI bot（greptile-apps）**：PR 提交后自动 review，输出「Greptile Summary + Confidence Score (N/5) + Files Needing Attention」。建议通常是非阻塞（"non-blocking usability inconsistencies"），但客观问题（fixed-width、缺失标准组件）值得顺手修。
- bot 建议经 triage：非阻塞建议若合理、与 codebase 现有 pattern 对齐，就修；纯风格偏好可回复说明。
- 目前 PR #1053 尚未收到人类 review（reviewDecision=REVIEW_REQUIRED）。

## PR 记录
| PR | 状态 | 备注 |
|---|---|---|
| #1053 feat(devtools): add inspect panel toggle in preview mode | open | Greptile 4/5，已按建议改 resizable panel + 标准 warning |

## 注意事项
- 提交只 add 目标文件：pnpm install 会重写 `pnpm-lock.yaml`（28558 行 diff），**不要**把 lock 文件混进 feature 提交。
- biome 会自动 reformat（`--write`），改完跑一次 format 保证缩进一致。
- 修改接口/组件签名后跑 `pnpm run test:types` 确认所有 caller 同步。
