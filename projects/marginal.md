# Marginal — Shadow-first No-Progress Governor

> 08-20 study deep read。卡片：[[marginal-no-progress-governor]]

## 一句话

AI coding agent 防空转治理框架：观察先行、证据驱动、渐进授权。检测「重复执行但零进展」的动作，Shadow 模式先观察，证据充分后才 earned enforcement。

## 在 agent 生态中的位置

- **竞争/互补**：与 [[agent-safe-pipeline]]（propose/decide/execute + single-use grant）同属 agent governance 光谱；Marginal 管「无进展空转」，Agent-Safe 管「授权边界」。二者互补不冲突。
- **上游**：provider-neutral adapter（Codex/Claude Code），可挂到任何 coding agent；理念与 [[hermes-agent]] 的 idempotent no-progress（warn after 2, block after 5）同源，但 Marginal 把判定形式化为状态指纹 + 证据不变性。
- **与我们的关系**：我们的 study-saturation-gate / 打工防空转是按**次数+日期**硬门控；Marginal 提供**状态指纹**级判定（semantic_key + state_hash + evidence_hash），能抓「换了文件继续空转」的语义级重复。

## 反直觉发现

1. **UNKNOWN 结局可推荐但永不 enforcement**（test_progress.py 实证）：无法证明成功/失败的动作，最多建议跳过，不能强制。我们的饱和门控目前「建议跳过」与「强制跳过」未分离——值得借鉴。
2. **一次 UNKNOWN 污染整条序列**：证据链必须全 SUCCESS 才 enforcement-eligible。保守派安全设计。
3. **Shadow 模式也建 reservation**（包括 would-deny 的）：让 recommendation 能观察 pending demand，同时外部行为不变——「观察不影响被观察系统」。
4. **因果隔离**：`record_outcome`（任务证据）与 `observe_value`（行动级 realized gain）分离——出现在成功轨迹 ≠ 因果贡献。对应我们「成功 ≠ 完成」验收门禁，但未形式化。

## 架构洞察

- 三分离 hash 判定（semantic/state/evidence）比单一「重复次数」鲁棒：重复 read/test 可能是任务必需，只有「证据不变 + 状态不变 + 全成功」才是空转。
- diminishing returns：gain_decay=0.5，同状态重复价值折半，evaluate 纯函数只有 execute 成功后才 observe（proposal 不算执行）。
- 隐私：safe_telemetry 严格 allowlist + HMAC 伪名 + UTC 日泛化；aggregate_export <5 组抑制；密钥本地、不随 trace。

## 关联

- 升级方向：study-saturation-gate 引入状态指纹（当前 08-20 按次数硬门控）
- 打工纪律：PR 前本地验证证据链（全绿才提）≈ enforcement-eligible 前置条件
- [[study-saturation]] · [[agent-safe-pipeline]] · [[hermes-agent]] · [[single-writer-spawn-ledger]]

## Revisit 08-27

- 社区信号（外部 contributor 是否持续）
- benchmark 独立复现（README 声称的 OFF/ON 对比）
- earned enforcement 是否落地 claude-code adapter
