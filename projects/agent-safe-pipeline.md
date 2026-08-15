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
