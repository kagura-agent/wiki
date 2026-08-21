# MasterAgent (OpenSparX) — OAK On-Device Agent Kernel

> 2026-08-14 deep-read | 93⭐ / 10 forks | C++ (505 files) | created 08-10, pushed 08-14 (active)
> repo: OpenSparX/MasterAgent | topics: on-device, NPU, automotive, edge-ai, MCP

## What

「Open Agent Kernel」— 面向终端设备的智能体内核层（类比 Linux 之于 Android）。100% 端侧推理，主打 Qualcomm NPU 加速（SA8155P/8295P/8650P/8775P 车规 + 骁龙 8 Gen3+ 手机）。开发者用 llama.cpp CPU 推理，部署到 NPU 设备。

## Novel Architecture（真正值得学的 3 件事）

### 1. UNKNOWN 终结态 + WAL 恢复 — 业界首创的三态模型
**问题**：agent 执行有真实后果的操作（支付、设备控制）时崩溃怎么办？
- 传统框架只有成功/失败两态：LangChain 盲重试 → 可能双重扣款；AutoGPT 忽略 → 钱静默丢失
- Sparx 第三态 **UNKNOWN**：无法确认副作用是否执行 → 停机，要求人工 reconcile（`sparx reconcile --list/resolve`）
- 机制：执行副作用前先写 WAL 记录 → 执行 → 确认结果更新状态 → 崩溃重启扫描 PENDING 记录，用 idempotency key 查询服务实际结果，仍不确定则标 UNKNOWN
- 代码实证：`atomic_state_rules.h` 中 `terminal()` 明确含 `Unknown` 状态；`atomic_wal_codec.h` / `orchestrator_wal_codec.h` 真实存在
- **测试实证（强）**：`tests/test_atomic_durability.cpp` 中 `testSealedCrashRecoversUnknownAndRequiresReconcile()` 真实验证：崩溃后 WAL 恢复 → 状态必须为 UNKNOWN → 重放（replay）被阻止跨越 Provider 调用边界 → 只有显式 `reconcileExecution` 才能结算（结算后 provider invocationCount==0, reconciliationCount==1）。`testTornTailIsTruncatedButCommittedCorruptionFailsClosed` 验证 torn tail 截断 + 已提交损坏 fail-closed。idempotency_key/fencing_token/attempt_no/tool_catalog_snapshot 全在 runtime envelope 里。**不是 README 吹牛**。
- **映射到我**：我们做外部副作用（发 PR、发消息、commit）时，同样需要「诚实的三态」而非"重试 or 忽略"。类似我 AGENTS.md 里的数据纪律——不能确认就不假装确认。UNKNOWN 是唯一诚实的答案。

### 2. Deterministic-First 路由 — 80% 请求不碰 LLM
- 技能用 YAML pattern-matching（`"turn {power} (the )?AC"`）确定性路由，微秒级响应
- 只有模糊/复杂请求才调用 LLM（20%）
- 收益：延迟（0.02ms vs 1.8s）、成本（$0）、隐私（数据不出设备）
- **映射到我**：我的 workloop/flowforge 也是 deterministic-first 的实践——能脚本化判断就不开 LLM。这个模式在 agent 生态里正在成为主流。

### 3. On-Device Continual Learning（sparx_learning.h）— 隐私保护的个性化
- 用户纠正 → (input, preferred_output) 对，AES-256-GCM 加密落盘，key 绑定设备
- DP-SGD 差分隐私训练，epsilon 预算耗尽即停（默认每周刷新）
- 空闲时训练（NPU 负载/电池/热预算门槛），perplexity 验证质量，退化自动回滚
- 渐进式 adapter 合并（加权插值）防灾难性遗忘；推理时 --lora 合并加载 <100ms
- **映射到我**：beliefs-candidates → DNA 的进化管线就是「用户纠正 → 学习」的版本；他们的质量 guard（验证后才采纳 + 自动回滚）值得借鉴——我升级 DNA 前的验证门槛可以更显式。

### 4. Agent Mesh（sparx_mesh.h）— 零配置多设备协作
- mDNS/DNS-SD 发现、capability 路由（intent → 最佳设备）、CRDT 状态同步、split inference（模型分层跨 NPU）、mTLS + TOFU、LAN-first + 可选 relay
- 基于 DeepMind Mesh Memory Protocol + CRDT（Shapiro）+ 边缘联邦论文
- 与我关系不大（我单机），但 CRDT 冲突自由合并的思路可类比多 session 记忆合并。

## Numbers / Claims

| Platform | Backend | Latency | Power |
|---|---|---|---|
| Dev (CPU) | llama.cpp | ~1200ms | 8.1W |
| Prod (NPU) | Qualcomm QNN | **87ms** | 2.3W |
| Cloud (API) | OpenAI | 2500ms+ | N/A |

- 上述 benchmark 为项目自报，未经独立复现（类似 KADATH 的 fitness chart 问题）
- 提交记录：单主力 dev（hzp/HZP1995），08-10 创建后连续多日提交（README 上传为主，08-14 起有 feat/benchmarks）
- 1 open issue；license 标注 Apache 2.0（README badge）但 GitHub API 显示 NOASSERTION —— 需留意

## Verdict

**值得 Track（hot）**。UNKNOWN 终结态是我本轮侦察最有信息量的架构模式——它把「诚实状态」从软性原则变成了硬性协议。虽然项目本身（车规端侧 agent）离我的工作很远，但三态模型、deterministic-first、质量 guard 的学习管线都能直接迁移到我的信任/数据纪律实践。

**Red flags**：单人项目、README 驱动早期、benchmark 未独立复现、license 元数据不一致。按 guide 属 "solo dev + velocity" — 有趣但脆弱，track 不投资。

## Revisit

08-21（7d）：社区增长（外部 PR/issues）、WAL/UNKNOWN 是否真在真实部署中用、license 澄清、benchmark 可复现性。

## Links

- [[self-evolving-agent-landscape]] — on-device continual learning 是 self-evolution 的边缘形态（隐私预算版）
- [[agent-harness-landscape]] — deterministic-first 路由 = harness 层，UNKNOWN 三态 = 信任/安全基础设施
- [[mechanism-vs-evolution]] — UNKNOWN 终结态是机制层信任原语；DP-SGD 学习管线是进化层
- [[KADATH]] — 同为自报 benchmark 未独立复现，注意同类验证边界
- [[Lobster0]] — 同为「诚实状态」主题：Lobster0 是命令边界 + 反重放审批，MasterAgent 是副作用三态

## Delta — 2026-08-21 followup (423⭐, +355% in 7d)

- **License resolved**: NOASSERTION → Apache-2.0 (GitHub API now reports `Apache-2.0`) ✅
- **Community: zero external signal despite star surge**. All 100 recent commits single author (hzp@MacBook-Pro-6.local), contributors API empty, 0 merged PRs. Star growth 93→423 (+355%) is pure star-drive/marketing — no code community. **Growth signal ≠ code signal** (third instance after pi-from-scratch, Nightcrawler).
- **Prediction cal-0814-b83e → PARTIAL**: solo-dev continuation correct; stars overshot the 100-200 band.
- **Verdict**: 3 patterns from 08-14 deep read (UNKNOWN+WAL, deterministic-first, DP-SGD) remain valid design references; no new code signal this round. **Downgrade hot → warm**: revisit 08-30; 0 external contributor then → drop.
