# Marginal — Shadow-first No-Progress Governor (08-20 deep read)

> 项目笔记：[[marginal]]（study deep read 原文）

- **Repo**: SignalLayerLabs/Marginal (Apache-2.0, Python 3.10-3.13, 3412 KB)
- **Created**: 2026-08-04 · 12⭐ / 3 forks / 64 commits · pushed 08-20（活跃，issues 全部由 owner 自建 roadmap 驱动，5 个外部贡献者 PR）
- **主题**: AI coding agent 防空转治理——检测「重复执行但零进展」的动作，shadow 模式先观察、证据充分后才 earn enforcement
- **一句话**: 观察先行、证据驱动、渐进授权 —— 与我们的饱和门控/防空转实践同主题，但把「无进展判定」做成了 provider-neutral 的正式框架

## 核心架构（src/marginal/）

```
agent → thin adapter → UniversalRuntime → Action
    → Treasury(预算reserve) → MarginalPolicy(判定) → ValueEstimator(版本化估值)
    → reserve → execute → settle/abort/failure settlement
    → JsonlDecisionLedger（严格 schema-versioned 证据 + 隐私导出）
```

模块: models / modes(Shadow, Recommend, Enforce) / budget / estimator / fingerprint / policy / profiles / treasury / adapters / ledger / privacy / protocol / replay / trace

## 三个关键模式（直接可移植）

### 1. Evidence-invariant 判定（progress.py）
- **成功 ≠ 进展**：只有「同一 semantic action + 相同 state hash + 相同 evidence hash + 全 success」连续出现 ≥2 次才触发 stop 候选
- 用三个分离的 hash：`semantic_key`（做什么）、`state_hash`（世界状态）、`evidence_hash`（新增证据）
- 核心原则：**重复的 read/test/verify 可能是任务必需的**——它不假设重复即浪费，只抓「证据不变」这个更强模式
- 与我们 study-saturation-gate 的区别：我们按次数/日期硬门控，它按**状态指纹**判定，可检测「换了文件继续空转」这类语义级重复

### 2. State-aware diminishing returns（diminishing.py）
- `gain_decay = 0.5`，同一状态重复执行价值折半；`max_same_state_repeats = 2`
- 关键纪律：**evaluate 是纯函数不推进历史**，只有 execute 成功后 `observe` 才记账——proposal 不算执行
- 缺失状态信息时 fail open（不能观察到的确定性不假装有）
- 语义 key 提取 provider-neutral，不特判任何模型/工具/文件类型

### 3. Shadow → Earned Enforcement（modes.py + treasury.py）
- **Shadow 模式也创建 reservation**（包括 would-deny 的），让后续 recommendation 能观察 pending demand，同时外部 agent 行为不变
- 并发语义重复获得独立 reservation ID，指纹保留在证据里
- Enforce 模式：affordability + policy denial 阻止执行；reservation 事务化；实际超支先记录再抛 `BudgetOverrun`
- 失败边界：无 spend 观测 → 释放 reservation；可测的失败 spend 记账但不标记成功；提取失败 → 保守结算且保留原始异常
- **因果隔离**：`record_outcome`（任务证据）与 `observe_value`（行动级 realized gain）分离——出现在成功轨迹里 ≠ 因果贡献

## 隐私边界（privacy.py）

- `local_full` / `safe_telemetry`（严格 allowlist + 字段分离 HMAC 伪名 + UTC 日泛化）/ `aggregate_export`（<5 的组抑制）
- 密钥本地保存，不随 trace 事务；丢密钥 = 无法关联 ≠ 匿名
- Commons 循环与 authority path 完全分离：下载的 priors 不进 coverage/trust/enforcement eligibility，本地证据优先，共享失败 fail open

## 与我们实践的映射

| Marginal | 我们的对应 |
|---|---|
| evidence-invariant 判定 | study-saturation-gate（按次数）→ **可升级为状态指纹** |
| Shadow → Earned Enforcement | 打工 PR 提交前本地验证；audit 先观察 |
| JsonlDecisionLedger 严格 schema | FlowForge 事件日志 / append-only ledger |
| record_outcome / observe_value 分离 | 我们「成功 ≠ 完成」的验收门禁（但未形式化因果归属） |
| fail open 不假装确定性 | AGENTS.md smell test（不确定就说） |

## 待验证 / 红旗

- 12⭐ 太小，社区未成形（issues 全是 owner 自建 roadmap + dependabot）
- 无独立 benchmark 复现（README 有 benchmarks.md 但未看到第三方验证）
- 决策 ledger 非分布式事务，多进程需外部 sink（文档已诚实声明）

## Test 证据边界（test_progress.py 实证，114 个测试文件）

- **UNKNOWN 可 recommend 但永不 enforcement**：`UNKNOWN` 状态连续 2 次 → `should_recommend_stop=True` 但 `enforcement_eligible=False`（reason: NO_PROGRESS_RECOMMENDED_UNKNOWN）——只有全 SUCCESS 证据链才 `NO_PROGRESS_ENFORCEMENT_ELIGIBLE`
- **一次 UNKNOWN 污染整条序列**：UNKNOWN+SUCCESS 混合 → 推荐但不 enforcement；证据链必须干净
- 缺失 semantic/state/evidence 任一 → fail open（不判 stop）
- 对应我们：饱和门控「建议跳过」vs「强制跳过」应当分离；无法验证成功/失败的动作不该有强制力

## Revisit

- **08-27**：社区信号（外部 contributor 是否持续）、benchmark 独立复现、earned enforcement 是否落地 claude-code adapter
