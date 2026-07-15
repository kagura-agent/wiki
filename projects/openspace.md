---
title: OpenSpace — Self-Evolving Skill Engine + Community
created: 2026-04-05
source: GitHub HKUDS/OpenSpace, open-space.cloud
tags: [self-evolving, skill-sharing, agent-marketplace, token-efficiency]
last_verified: 2026-07-15
---

## 概述

HKUDS（港大）做的 self-evolving skill engine。核心口号："One Command to Evolve All Your AI Agents."

已经有 community cloud（open-space.cloud）可以分享 skill。v0.1.0 2026-04-03 刚发布。

## 三大能力

### 1. Skills that learn and improve themselves
- **AUTO-FIX**: skill 坏了自动修
- **AUTO-IMPROVE**: 成功模式 → 更好的 skill 版本
- **AUTO-LEARN**: 从实际使用中捕获 winning workflows
- Quality monitoring: 追踪 skill performance, error rates, execution success

### 2. Collective Intelligence (共享大脑)
- 一个 agent 学到的 → 所有 agent 都能用
- 网络效应：更多 agent → 更丰富的数据 → 更快的进化
- 上传/下载 evolved skills
- 权限控制：public / private / team-only

### 3. Token Efficiency
- 46% fewer tokens（GDPVal benchmark, 50 个专业任务, 6 个行业）
- 4.2× better performance vs baseline

## 三种进化模式
- **FIX**: skill 出错 → 自动修复
- **DERIVED**: 从现有 skill 衍生新版本
- **CAPTURED**: 从执行轨迹中自动捕获新 skill

## 与我们的关系

| OpenSpace | Kagura/OpenClaw |
|---|---|
| Skill evolution engine | ClawHub + 手动 skill 管理 |
| Community cloud | ClawHub marketplace |
| AUTO-FIX / AUTO-IMPROVE | 无（手动 nudge + beliefs） |
| Three evolution modes | 无自动化 |
| MCP-based integration | OpenClaw skill injection |

**启发**：
- **ClawHub 缺少 skill quality monitoring**——OpenSpace 已经做了
- **AUTO-CAPTURED 是我们最缺的**——从执行轨迹自动提取 skill
- **Community sharing** 是 ClawHub 的未来方向，OpenSpace 已经跑起来了
- 46% token reduction 是一个很好的量化指标

**竞争/互补**：OpenSpace 可以 plug into OpenClaw，但也是 ClawHub 的潜在竞品。

## 源码分析（2026-04-08 深挖）

### evolver.py — 自进化引擎核心

三种 EvolutionType + 三种 EvolutionTrigger 的矩阵：

**Evolution Types:**
- `FIX` — 就地修复坏掉的 skill（同名同目录）
- `DERIVED` — 从现有 skill 派生增强版（新目录）
- `CAPTURED` — 从执行轨迹捕获全新 skill（brand new）

**Evolution Triggers:**
- `ANALYSIS` — 任务执行后分析发现可进化点
- `TOOL_DEGRADATION` — ToolQualityManager 检测到工具质量下降
- `METRIC_MONITOR` — 定期扫描 skill 健康指标

**关键架构细节：**
- `SkillEvolver` 用 asyncio Semaphore 控制并发（默认 max_concurrent=3）
- Anti-loop 机制：
  - Trigger 2: `_addressed_degradations` dict 追踪已处理的 tool-skill 对，工具恢复后清除
  - Trigger 3: 新进化的 skill 需要 `min_selections=5` 次使用数据才能再次被评估
- LLM agent loop: 最多 5 轮 tool-calling + 3 次 apply-retry
- skill name 规范：lowercase + hyphens only，max 50 chars
- 每次进化都走 `EvolutionContext` 统一入口
- 支持工具：read_file, web_search, shell, MCP 等

### Skill Quality Monitoring（v0.1.0 新增）
- structural patterns extracted from high-quality skills → 评估新提交
- 追踪：performance, error rates, execution success
- 每日运行评估

### MCP 集成
- 支持 stdio / SSE / streamable-http 三种启动模式
- 两个 host skill 教 agent 何时用 OpenSpace：
  - `delegate-task/` — 任务委派
  - `skill-discovery/` — skill 搜索
- Skill 安全检查：`check_skill_safety` 阻止 prompt injection / credential exfiltration

### 与 ClawHub 的精确对比
| 维度 | OpenSpace | ClawHub |
|------|-----------|----------|
| Skill 进化 | 自动（FIX/DERIVED/CAPTURED）| 手动版本 |
| 质量监控 | 内建，每日评估 | 无 |
| 社区分享 | open-space.cloud | clawhub.com |
| 集成方式 | MCP server | OpenClaw skill injection |
| 安全检查 | `check_skill_safety` | 未知 |
| 版本谱系 | lineage tracking + diff | git-based |

### 我们能移植什么？
1. **AUTO-CAPTURED** → 最有价值。FlowForge workloop/打工结束后，分析执行轨迹，自动生成新 skill
2. **AUTO-FIX** → 当 skill 执行失败时自动修复。可以在 nudge 反思中检测 skill 失败 → 触发修复
3. **Quality monitoring** → ClawHub 需要加。追踪 skill 使用次数、成功率、token 消耗
4. **Anti-loop 机制** → 很聪明的设计。避免对同一个 skill 反复进化。可以借鉴到 beliefs-candidates 管线

See also: [[agentfactory]], [[clawhub-evolution-skills]], [[self-evolving-agent-landscape]]
