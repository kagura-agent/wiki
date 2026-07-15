---
title: "OpenClaw Skill 懒加载 PoC 设计"
created: 2026-04-11
source: "study apply — codex-on-use-auth-policy.md + OpenClaw source code analysis"
tags: [openclaw, skills, optimization, context-window]
last_verified: 2026-07-15
---

# OpenClaw Skill 懒加载 PoC

## 问题

当前所有 skill 的 name + description + location 都注入 system prompt。随着 skill 数量增长，context 开销线性增加。我的 15 个 skill 占约 **1,894 tokens**，且每次 API 调用都重复。

## 现有机制

OpenClaw 已有两层应对：
1. **compact mode** — 当 full format 超过 `maxSkillsPromptChars`（默认 30K chars），自动降级为只输出 name + location（去掉 description）
2. **truncation** — compact 仍超预算则二分查找裁剪数量

但这是全有或全无的——要么全 full，要么全 compact。没有按 skill 重要性分级。

## 设计：两级 Skill Catalog

### 核心思想

Skill 分为 `always`（核心）和 `discoverable`（按需）两级：

| 级别 | Prompt 内容 | 何时读 SKILL.md |
|---|---|---|
| **always** | name + description + location（完整） | 匹配 description 就读 |
| **discoverable** | name + location（无 description） | 匹配 name 就读 |

### Frontmatter 声明

```yaml
# SKILL.md frontmatter
last_verified: 2026-07-15
---
name: github
description: GitHub operations via gh CLI
openclaw:
  tier: always    # or "discoverable" (default)
last_verified: 2026-07-15
---
```

### 实现位置

`src/agents/skills/workspace.ts` 的 `applySkillsPromptLimits()` 和 `formatSkillsForPrompt()`：

```typescript
// New: mixed-tier format
function formatSkillsMixedTier(params: {
  always: Skill[];
  discoverable: Skill[];
}): string {
  const lines = [
    "\n\nThe following skills provide specialized instructions.",
    "Use the read tool to load a skill's file when the task matches.",
    "",
    "<available_skills>",
  ];
  // Always: full format
  for (const skill of params.always) {
    lines.push("  <skill>");
    lines.push(`    <name>${escapeXml(skill.name)}</name>`);
    lines.push(`    <description>${escapeXml(skill.description)}</description>`);
    lines.push(`    <location>${escapeXml(skill.filePath)}</location>`);
    lines.push("  </skill>");
  }
  // Discoverable: compact (name + location only)
  if (params.discoverable.length > 0) {
    lines.push("  <!-- More skills available by name: -->");
    for (const skill of params.discoverable) {
      lines.push("  <skill>");
      lines.push(`    <name>${escapeXml(skill.name)}</name>`);
      lines.push(`    <location>${escapeXml(skill.filePath)}</location>`);
      lines.push("  </skill>");
    }
  }
  lines.push("</available_skills>");
  return lines.join("\n");
}
```

### Tier 分配逻辑

```typescript
function resolveSkillTier(entry: SkillEntry): "always" | "discoverable" {
  // Explicit frontmatter wins
  const tier = entry.metadata?.tier;
  if (tier === "always" || tier === "discoverable") return tier;
  
  // Legacy compat: openclaw.always: true → always tier
  if (entry.metadata?.always === true) return "always";
  
  // Default: discoverable
  return "discoverable";
}
```

### Token 节省量化

| 配置 | Chars | Tokens (≈) | 节省 |
|---|---|---|---|
| 现状（15 skill 全 full） | 7,576 | 1,894 | — |
| 两级（4 always + 11 discoverable） | 3,665 | 916 | **51.6%** |
| 全 compact（已有机制） | 2,147 | 537 | 71.6% |

**月度成本影响**（按 50 session/day × 5 turns/session）：
- 节省 ~978 tokens/turn × 250 turns/day × 30 days = **~7.3M input tokens/month**

### always 候选（我的配置）

| Skill | 理由 |
|---|---|
| flowforge | 每个 cron job 必用 |
| github | 打工/PR 高频 |
| coding-agent | 代码任务必用 |
| agent-memes | Luna 要求必须发 |

其余 11 个 skill 降为 discoverable——name 本身已经足够触发识别（如 "weather"、"tmux"）。

## 可行性评估

### 已有的支撑
- `OpenClawSkillMetadata.always` 字段已存在（types.ts），只是当前未用于 prompt 分级
- compact mode 已证明模型能仅凭 name + location 正确选择 skill
- 改动集中在 `workspace.ts` 的 format/limit 逻辑，不影响 skill 加载和 runtime registry

### 风险
1. **discoverable skill 漏选** — 模型只看 name 可能匹配率略降。缓解：name 本身要有语义（"weather" vs "wx"）
2. **向后兼容** — 默认 tier=discoverable，不改任何 SKILL.md 就等于现状 compact mode。只有显式标 always 的才升级为 full
3. **配置复杂度** — 可以通过 config.yaml 的 `skills.alwaysLoaded: [...]` 做全局覆盖，不依赖每个 SKILL.md 的 frontmatter

### 不做什么
- 不做 runtime lazy connection（Phase 2 的 MCP 按需连接是独立项目）
- 不做动态 tier 调整（基于使用频率自动升降级留到以后）

## 实施路径

1. **PR 1: 支持 mixed-tier format** — 读 `metadata.always`，分流到 full/compact 输出
2. **PR 2: frontmatter `openclaw.tier` 字段** — 新增字段解析 + 优先级覆盖 `always` bool
3. **PR 3: config overlay** — `skills.alwaysLoaded: [...]` 用户级覆盖
4. **Dogfood: 自己先用** — 标记 4 个 always skill，观察 1 周 discoverable 漏选率

## 关联

- [[codex-on-use-auth-policy]] — 灵感来源：Codex 的发现-按需授权模式
- strategy.md — 北极星：自进化 + context 效率
