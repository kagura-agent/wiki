# vercel/ai (AI SDK)

- **Stars**: 23.6k
- **语言**: TypeScript (monorepo, pnpm workspace)
- **测试框架**: vitest
- **环境要求**: pnpm v9+, Node v22
- **首次贡献**: 2026-04-20

## PRs

| PR | Issue | 状态 | 备注 |
|---|---|---|---|
| #14636 | #14634 | PENDING | fix multi-region endpoint for Vertex Anthropic |
| #14687 | #14678 | PENDING | fix xAI tool calling — strip additionalProperties |
| #14704 | #14703 | PENDING | fix input-streaming optional type for exactOptionalPropertyTypes |
| #15187 | #15173 | SUPERSEDED | fix tool-result URL download — superseded by #15232 (aayush-kapoor) |
| #15159 | #15155 | PENDING | fix for another issue |
| #15049 | #15042 | PENDING | fix Cerebras reasoning field serialization |

## 开发环境

- monorepo 非常大，shallow clone + sparse checkout 是必须的
- `git clone --depth=1 --no-checkout` → `git sparse-checkout set packages/<target>` → `git checkout`
- pnpm install 在 kagura-server 上 OOM，需要更大内存或用 CI 跑测试
- 本地无法跑 pnpm install，依赖 CI 验证测试

## 维护者模式

- 待观察（首次 PR）
- PR 模板无特殊要求，CONTRIBUTING.md 简洁
- 有 Socket Security check（依赖安全扫描）
- Vercel deploy 对外部 PR 需要授权（正常）

## 踩坑

- repo 太大无法全量 clone，必须 sparse checkout
- fork sync 后再 push branch
- pnpm install OOMs on kagura-server, rely on CI for test validation
- `addAdditionalPropertiesToJsonSchema` is applied globally in provider-utils; provider-specific overrides need to happen at the provider level

## 项目结构

- `packages/google-vertex/src/anthropic/` — Vertex Anthropic provider
- `packages/google-vertex/src/` — Vertex native provider（也有类似 multi-region 问题，但未在 issue 中报告）
- URL 构建在 provider 的 `getBaseURL()` 函数中

## 相关知识

- Google Vertex multi-region endpoints (`eu`, `us`) 使用 `aiplatform.{location}.rep.googleapis.com` 格式
- 普通 regional endpoints 使用 `{location}-aiplatform.googleapis.com` 格式
- global 使用 `aiplatform.googleapis.com`

## PRs 补充

| PR | Issue | 状态 | 备注 |
|---|---|---|---|
| #14723 | #14721 | PENDING | fix audio/mp4 ftyp detection at byte offset 4 |
| #14928 | #14925 | PENDING | fix @ai-sdk/mcp resource_link content type |

## 踩坑补充 (2026-04-23)

- `exactOptionalPropertyTypes` 是一个容易被忽视的 TypeScript 严格模式选项
- vercel/ai 类型声明和运行时 Zod 验证之间有不一致之处 — 这类问题是好的贡献方向
- 外部 PR 的 Vercel deploy 需要 maintainer 授权，Socket Security check 自动跑

### PR #14725 superseded (2026-04-27)
- Maintainer (aayush-kapoor) closed in favour of #14760
- Key lesson: Don't modify shared `provider-utils` for provider-specific quirks. Fix in the specific provider package (e.g., `openai-compatible`). Shared layer stays strict.

### PR #14774 (2026-04-28) — PENDING
- Fix: disable `supportsNativeStructuredOutput` for `claude-opus-4-7` on Bedrock
- Issue #14773: Bedrock rejects `output_config.format` for this model
- Approach: model-aware check using `!modelId.includes('claude-opus-4-7')` in bedrock-anthropic-provider
- Follows same pattern as Anthropic SDK's per-model capability table
- Tests cover both direct model ID and cross-region prefixed variants
- Changeset added per CONTRIBUTING.md requirements
- CI: Vercel deploy needs maintainer auth (expected for external PRs), Socket + Agent Review pass

### PR #15159 (2026-05-11) — PENDING
- Fix: resolve top-level $ref from Standard Schema providers (Effect Schema.Class)
- Issue #15155: Schema.Class produces JSON Schema with $ref+$defs, OpenAI rejects for structured output
- Approach: Added `resolveTopLevelRef()` to inline $defs definitions at top level; also handle $defs in `addAdditionalPropertiesToJsonSchema`
- CI: All green (Lint, TypeScript, Tests 20/22/24, Bundle Size). Vercel deploy needs maintainer auth (expected)
- Changeset: patch for `@ai-sdk/provider-utils`
- Note: Had to use GitHub API (git/blobs + git/trees + git/commits) for push — regular `git push` OOMs on this 600MB+ repo

## 踩坑补充 (2026-05-11)

- **Git push OOM**: This repo is too large for regular git clone/push on kagura-server. Use GitHub API (create blob → create tree → create commit → update ref) to push changes. This is reliable and avoids memory issues.
- **Fork sync matters**: Always `gh api repos/kagura-agent/ai/merge-upstream -X POST -f branch=main` before creating new branch. The fork can fall behind on import type changes etc.
- **Branch recreation breaks PR**: If you delete+recreate a branch, the PR doesn't track the new commits. Must close old PR and create new one.
- **import type enforcement**: Project now enforces `import type` for type-only imports (ultracite lint). Check upstream main's import style before pushing.
- Fix: use `reasoning` field name for Cerebras assistant messages in multi-step runs
- Issue #15042: Cerebras expects `reasoning` not `reasoning_content` on assistant message history
- Approach: Added `reasoningFieldName` option to `OpenAICompatibleChatConfig` and `convertToOpenAICompatibleChatMessages()`. Cerebras provider sets it to `'reasoning'`
- Pattern: Response parsing already handled both fields (`??`), input serialization was the gap
- CI: Lint & Format initially failed (ultracite/oxfmt formatter, not prettier). Fixed with `npx ultracite fix`
- Tests: Added 2 tests covering default and custom reasoning field name
- Changeset: patch for both `@ai-sdk/cerebras` and `@ai-sdk/openai-compatible`
- TypeScript, Tests, Lint all green. Vercel deploy needs maintainer auth (expected for external PRs)

### PR #15464 (2026-05-20) — PENDING
- Fix: accept empty string `role` in streaming delta chunks for openai-compatible provider
- Issue: anomalyco/opencode#28427 (reported by zhipu/glm-5 user)
- Root cause: `z.enum(['assistant']).nullish()` rejects `role: ""` in streaming chunks; changed to `z.string().nullish()`
- Also fixed non-streaming response schema consistency (`z.literal('assistant').nullish()` → `z.string().nullish()`)
- Test added: streaming with empty string role in delta chunks
- CI: All green (lint, format, TypeScript, tests). Vercel deploy needs maintainer auth (expected)
- Changeset: patch for `@ai-sdk/openai-compatible`
- Lesson: ultracite formatting requires semicolons — first push failed lint, fixed in follow-up commit

### PR #15584 (2026-05-24) — PENDING
- Fix: add `gemini-embedding-2` GA model ID to `GoogleEmbeddingModelId` and `GoogleVertexEmbeddingModelId`
- Issue #15582: gemini-embedding-2 is out of preview, EU multi-region doesn't have preview model
- Approach: Add model ID to type unions in both packages, update docs tables and examples
- CI: All green (Lint, Format, TypeScript, Tests 22/24/26). Vercel deploy needs maintainer auth (expected)
- Changeset: patch for `@ai-sdk/google` and `@ai-sdk/google-vertex`
- Clean surgical diff: 6 files, +14 -3 lines

## 踩坑补充 (2026-05-24)

- **Gateway already had it**: `packages/gateway/src/gateway-embedding-model-settings.ts` already listed `google/gemini-embedding-2` (without `-preview`), confirming the model is GA. Provider packages were lagging behind.
- **Type union is soft**: `(string & {})` at end of union means any model ID works at runtime — the named IDs are just for autocompletion/docs. Low risk addition.

- **Lint formatting**: Always add semicolons to test code. First push failed `Lint & Format` because test code was missing semicolons (ultracite/oxfmt requires them)
- **Schema pattern**: `z.enum(['X']).nullish()` vs `z.literal('X').nullish()` — both reject empty string. For openai-*compatible* provider, `z.string().nullish()` is safer since the whole point is compatibility with diverse backends
- **Issue cross-referencing**: The bug was reported in opencode's repo but root cause was in vercel/ai. Cross-repo issue tracing is valuable

- **Formatter**: Project uses `ultracite fix` (not prettier). `npx prettier` reformats entire file with different settings (double quotes). Use `npx ultracite fix <file>` for formatting
- **CI lint-staged**: Checks formatting on changed files only. Even small whitespace differences trigger failures
- **Pattern**: openai-compatible provider reads responses with `reasoning_content ?? reasoning` (handles both), but input serialization was hardcoded to `reasoning_content`. Symmetric fix = add config option

### PR #15594 (2026-05-25) — PENDING
- Fix: make `JSONArray` type readonly to accept `readonly` arrays
- Issue #15593: `readonly T[]` not assignable to `JSONArray = JSONValue[]`
- Approach: Added `readonly` modifier to `JSONArray` type definition
- Also fixed `generate-image.ts` line 243 — used `(arr as JSONValue[]).push()` cast for internal mutable build-up
- CI: All green (TypeScript, Tests 22/24/26, Lint, Build, Bundle Size). Vercel deploy needs maintainer auth (expected)
- Changeset: patch for `@ai-sdk/provider` and `ai`
- **Lesson**: Type-level "one-line" changes can have ripple effects — `JSONArray` was used in `generate-image.ts` with `.push()`, which breaks with `readonly`. Always grep for mutation methods (`.push()`, `.pop()`, `.splice()`, `.sort()`, `.reverse()`) on types you're making readonly.
- **CI iteration**: First push broke TypeScript, second push (spread concat) broke TS2698 (can't spread intersection type), third push (type assertion cast) worked. Should have grep'd for `.push()` usages before the first push.

### PR #17931 (2026-07-25) — PENDING
- Fix: preserve thinking chunk structure when replaying reasoning history
- Issue #17930: Mistral provider flattens ThinkChunk → plain string on multi-turn replay
- Root cause: `convertToMistralChatMessages()` assistant case concatenated `reasoning` parts into plain text string, losing `{type: "thinking", ...}` structure
- Approach: When reasoning parts exist, emit `content` as structured array matching Mistral API format; when no reasoning, keep plain string (backward compat)
- 3 files changed: `mistral-chat-prompt.ts` (new types), `convert-to-mistral-chat-messages.ts` (structured output), test file (3 new test cases)
- CI: All Tests pass (22/24/26), Lint & Format pass, TypeScript pass, verify-changesets pass. Vercel deploy needs maintainer auth (expected for external PRs)
- Changeset: patch for `@ai-sdk/mistral`
- Note: git push worked this time (no OOM) — sparse checkout helps with smaller push payloads
