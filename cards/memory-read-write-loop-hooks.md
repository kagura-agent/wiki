---
title: Agent Memory Read-Write Loop via Plugin Hooks
created: 2026-03-26
source: Luna 讨论 + MemEvolve 代码分析 + OpenClaw hook 调研
last_verified: 2026-07-15
---

## 核心思路
用 OpenClaw plugin hook 实现记忆的自动读写闭环，不靠 system prompt 文字指令。

## 读：before_prompt_build hook
- 时机：每次 agent 回复前，构建 prompt 之前
- 做法：读 patterns 目录，全量塞进 `prependContext`
- 返回字段：`prependContext`（每轮注入）或 `appendSystemContext`（静态缓存）
- 前提：patterns 总量控制在 30-50 条（~3000 tokens），参考 [[memory-volume-control]]

## 写：agent_end hook（已有，= nudge）
- 时机：agent 回复完成后
- 做法：回顾刚才的对话，提取值得记录的经验
- 已实现：openclaw-plugin-nudge 就是这个

## 闭环
```
before_prompt_build（读 patterns）→ agent 执行 → agent_end（写新 patterns）
         ↑                                              ↓
         └──────────── patterns 目录 ←──────────────────┘
```

对应 MemEvolve 的：
- `provide_memory()` = before_prompt_build
- `take_in_memory()` = agent_end / nudge
- 差异：MemEvolve 区分 BEGIN/IN 两个阶段，我们目前只有一个注入点

## OpenClaw hook 清单（27 个）
```
before_model_resolve, before_prompt_build, before_agent_start,
llm_input, llm_output, agent_end,
before_compaction, after_compaction, before_reset,
inbound_claim, message_received, message_sending, message_sent,
before_tool_call, after_tool_call, tool_result_persist,
before_message_write, session_start, session_end,
subagent_spawning, subagent_delivery_target, subagent_spawned, subagent_ended,
gateway_start, gateway_stop, before_dispatch
```

## before_prompt_build 能力
```typescript
PluginHookBeforePromptBuildResult = {
  systemPrompt?: string;           // 替换系统 prompt
  prependContext?: string;          // 每轮注入（动态）
  prependSystemContext?: string;    // 系统 prompt 前置（静态，可缓存）
  appendSystemContext?: string;     // 系统 prompt 后置（静态，可缓存）
}
```

## 设计决策（待定）
- patterns 用 `prependContext`（动态，每轮可变）还是 `appendSystemContext`（静态，可缓存）？
  - 如果 patterns 不经常变 → appendSystemContext 省 token
  - 如果想按任务类型动态选 → prependContext
- 是否需要 LLM 选择 top-K？还是全量注入？
  - 全量注入更简单可靠（参考 [[memory-volume-control]]）
  - 但需要 manage 机制保证总量可控

## 当前状态
- **暂不实现**（Luna 2026-03-26 决定：先讨论清楚再动手）
- nudge（写端）已在运行
- 读端的 hook 机制已验证可行，等时机成熟再做

## 相关
- [[memory-volume-control]] — manage > retrieve 的优先级
- [[begin-vs-in-phase-memory]] — BEGIN/IN 阶段分离
- [[write-read-gap]] — 这是要解决的根问题
- [[memevolve]] — 学术参考
- [[skill-as-behavior-trigger]] — Skill 触发是另一个读取时机
