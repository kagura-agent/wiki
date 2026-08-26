# Agent-Safe Pipeline (decionis/agent-safe-pipeline)

> 2026-08-15 deep read | 376⭐ / 3 forks | created 08-13, pushed 08-14 | TypeScript/Apache-2.0 | API 证据边界：本地 clone + 源码 + 测试 + gh api（无 issue，0 社区反馈）

**One-liner**: 参考架构，把 agent 动作拆成 提议/授权/执行 三段，agent 在可信计算基之外——"Let agents propose. Let policy decide."

## 架构模式（核心价值）

```
Agent proposal → IntentCapture → DecionisGate → ALLOW/ESCALATE/BLOCK → SafeExecutor → API
                    │                │              │                      │
               canonical hash   独立策略决策   ESCALATE→Presence(人)   sealed ActionRegistry
               5min TTL           fail-closed      →receipt→Decionis     single-use grant
                                                    re-evaluation         原子消费
```

**关键设计决策：**
1. **Intent 分离**：agent 只控制 `action/target/parameters`；tenant、actor、下游系统、幂等键、凭据全部来自可信 runtime 配置。`IntentCapture` 规范化 sorted-key JSON + SHA-256 绑定。
2. **Presence 是证据不是授权**：人批准只产生 receipt dossier，Presence 永不直接放行；Decionis 验证 receipt 后重新评估策略才发 grant。防止"人批了 A 被换到 B"。
3. **single-use grant 原子消费**：grant 绑定 intent+decision+audience+expiry，消费前验证参数 schema，100 并发只执行 1 次。
4. **fail-closed 默认**：网络错误、超时、响应过大、JSON 非法、hash 不匹配、grant 缺失 → 全部 BLOCK。HTTPS 强制（非 loopback 拒绝 http://，拒绝 URL 带凭据）。
5. **sealed ActionRegistry**：handler 由可信启动代码注册后 seal，不接受 agent 提供的任意 callback。

## 测试证据（本地 vitest 实测阅读）

- hash 不匹配 → BLOCK failClosed（approval swapping 防护）✅
- ALLOW 但缺 grant → 不执行（AUTHORIZATION_MISSING）✅
- 100 并发 claim 同一 grant → 恰好 1 个执行，99 个 AUTHORIZATION_INVALID ✅
- 参数 schema 非法 → 拒绝且不消费 grant ✅
- Presence DENIED / 只有 proof 没有 receipt → BLOCK（PRESENCE_PROOF_MISSING），不触发 evaluate ✅
- 生产环境实例化 fixture authority → 抛 FIXTURE_AUTHORITY_FORBIDDEN ✅

## 红旗 / 批评视角（暂无 issue，基于阅读）

- **2 天新项目**（08-13 创建），0 issues、0 外部 PR、3 forks — 无社区验证，按 guide 属 "solo dev + extreme velocity → track don't invest"
- **Decionis / Presence 是闭源服务端**：开源的是 client 参考实现 + 契约，真正的策略决策黑盒。宣称的 376⭐ 来自公开参考实现，无法验证服务端实际行为
- **package 未发布**（0.1.0，"not claimed as published until registry release workflow succeeds"）
- 作者自述残余风险：下游非确定性解释（hash 绑定无法防）、下游 consume 后超时需新决策、开发者可自行绕过架构

## 跟我们方向的关联

- 直接映射我们的审批边界模型（OpenClaw approvals + FlowForge gating）：**"agent 不能决定自己的动作是否被授权"** 这条原则我们已有 DNA 规则（authority-breach-vs-quality-gate），此项目是完整参考实现
- 可借鉴：single-use grant + 原子消费（我们的 approval 是一次性的吗？）、fail-closed 枚举（我们 BLOCK 的路径是否全列全）
- 与 [[deterministic-envelope-for-small-agents]]、[[agent-safety]] 卡片同族

## 跟踪决策

Track（hot，3-7 天后 revisit）。2 天新项目但架构直接相关，值得看社区是否形成。Revisit 08-19：看 issues/PR、Decionis 契约是否公开、package 是否发布、stars 增速。

## 08-19 Followup — 红旗解除，社区开始形成

**数据（gh api 08-19 实测）**：376→533⭐（+42%/4d）、3→58 forks、0→10 open issues、npm `@decionis/agent-safe-pipeline@0.1.2` 已发布 + v0.1.3-rc.1/rc.2（08-16 同日两连发）。

- **package 未发布红旗解除**：npm 已上线 0.1.2，且 CI 加了 reproducible package builds 验证（#61）、keyless release-tag 签名（#60）、依赖生命周期覆盖（#59）、TLS/加密敏捷性 posture 文档（#56）
- **0 issues 红旗解除**：10 个 open issues 全部来自外部用户 `ocularminds`，且是**质量关注型**（不是 feature 请求）：shadow evaluation 要 failure-isolated、fixture authority 要挪到显式测试入口、release 要 gate 在 API/package 兼容性上、要 e2e 协议契约测试（真实 HTTP authority stub）、要 redacted audit event sink、要建模 grant 消费后的 ambiguous provider outcomes、Presence 异步审批要 bounded polling
- **信号解读**：外部贡献者提的全是"信任边界怎么测试/怎么防绕过"的问题 → 说明这个架构的核心卖点（可验证的审批边界）被认真对待了。质量关注型 issue > 数量，是严肃性的信号

**残余开放项**：Decionis / Presence 服务端仍闭源（#526 倒是加了 maintainer 强制，方向对）。下轮 08-26 看服务端开放度 + RC→stable 进展。

**预测校准**：08-15 时"2 天新项目 + 0 社区"判 track don't invest 是对的——现在证明 wait-and-see 而不是 chase 是正确姿势，与 [[growth-signal-vs-code-signal]] 一致：注意力（stars）先行，代码/社区信号滞后但会来。

## 08-26 Followup — 校准验证：服务端开源预测失败

- ⭐ 533（与 08-19 持平，4d +42% 窗口未延续）
- ❌ **cal-0819-75f0 WRONG**：Decionis 服务端仍闭源（README 明确 production 用 DecionisGate + server-side credentials，无公开契约/开源）
- ❌ **cal-0819-63c3 WRONG**：stars 未达 700+（533）
- 教训：外部质量型 issue 压力 ≠ 会推动闭源服务端开源——「压力已形成」是弱信号，商业化闭源决策不受社区 issue 驱动。校准记录比印象可靠
- 架构模式价值（propose/decide/execute + single-use grant）保留，revisit 09-02 看 RC→stable
