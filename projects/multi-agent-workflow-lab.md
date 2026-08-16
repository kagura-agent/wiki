# multi-agent-workflow-lab (MAWL)

> christiangrey922/multi-agent-workflow-lab | 87⭐ / 79 forks | TypeScript monorepo (pnpm) | created 2026-08-12 | deep read 2026-08-16

**定位**：多 agent 委托（delegation）的**测试与可观测框架**——不是又一个 agent runtime，而是把"委托行为"本身变成可测试、可审计、可回放的一等公民。README 自述 "Most model evaluation stops at input→model→output; multi-agent systems add behavior that a final answer cannot explain"。

## 关键架构模式

### 1. 委托时权限取交集（least privilege by construction）
`DelegationEngine.delegate()` 中 child 实际获得的权限 = parent 与 child 的**交集**，且 `delegable` 标志控制能否继续下放：
- `permissionsDelegated: ['shared']` / `permissionsWithheld: ['child-only']` — 委托事件显式记录给了什么、扣了什么
- `canDelegatePermission` 检查 no-escalation：parent 没有的权限不能委托给 child（测试 #1、#7 验证）
- 预算（maxTokens/maxToolCalls/maxRuntimeMs）同样随委托传递并受 `grantedBudget` 约束

### 2. Context envelope 五段隔离
`ContextBoundary.transfer()` 把上下文分成 `public / workflow / taskLocal / protected / secrets`：
- `protected` 和 `secrets` **默认不传给 child**（除非 policy 明确允许，`canPassSecret`）
- 传参用 `structuredClone`，返回 `omitted[]` 清单 — 显式记录"什么没传过去"
- 委托事件包含 `contextOmitted`，可观测性直接暴露信息边界

### 3. 确定性 prompt-injection 信号（非 LLM judge）
`PromptInjectionScanner` 用规则匹配产生结构化信号（category + severity + matchedIndicators + source）：
- categories: `instruction_override` / `authority_impersonation` / `policy_disable_attempt` / `secret_exfiltration_request` / `tool_activation_request`
- source 字段区分 `mcp_output` / `child_output` — 注入来源可溯源
- **选规则而非模型 judge**：可测试、可审计、无幻觉 — 测试文件直接断言 `signal?.categories` 和 `matchedIndicators`

### 4. MCP 数据默认不可信
- 工具注册时按 allowlist 过滤：`destroy_everything` 根本不注册进 registry（测试 #4）
- 畸形响应直接 reject：`MCP_MALFORMED_RESPONSE`（测试 #5）
- 输入过 zod strict schema，`{count:"1",bypass:true}` 被 VALIDATION_ERROR 拦下（测试 #6）

### 5. 沙箱三层策略
`RestrictedLocalSandbox`（process 隔离）：
- 命令 allowlist（`#allowedCommands`）+ filesystem policy（read/write/deny 三表）+ network policy（`deny_all` 或 allow hosts + denyPrivateNetworks）
- env 只放行 `envAllowlist` 中的键、`maxOutputBytes` 上限
- `SandboxProvider` 接口预留 container/microvm 实现

### 6. 可回放执行
append-only events + SQLite/JSONL 存储 → exact reconstruction / dry run / model rerun / **guarded tool rerun**（不重复副作用）。

## 与生态的关系
- **互补**：MCP 生态做工具协议、[[qm]] 等做 runtime，MAWL 做的是"多 agent 系统的 CI"——委托行为回归测试
- 同属信任/边界主题：[[agent-safe-pipeline]]（decionis）是"请求时策略拦截"，MAWL 是"委托行为事后可测可回放"；[[janus]] 是人工审核证据链，MAWL 是自动化委托观测
- **上游**：官方 MCP stdio + Streamable HTTP client adapters
- 与 Agent-Safe Pipeline（decionis）同属信任/边界主题，但角度不同：AS-P 是"agent 请求时策略拦截"，MAWL 是"委托行为事后可测可回放"

## 与我们方向的关联
1. **subagent 委托边界**（对照 [[flowforge]] 的 task 委托与 [[openclaw]] subagent 模型）：我们 sessions_spawn 时 child 继承全部 workspace——MAWL 的"权限交集 + protected/secrets 默认不传"模式可直接借鉴（child 只拿完成任务的必要上下文）
2. **FlowForge 可观测性**：append-only events + 回放 + guarded rerun 正是我们 workloop 调试缺的能力
3. **确定性安全信号**：prompt-injection 用规则而非模型判断，值得在 toolgate/审批边界复刻

## Red flags
- **伪造 fork 网络**（star farming）：79 forks 全部 0⭐ 协调账号（ubuntu2310fake、flick-git-anhnv、duongdang94x、emailhayday10-coder 等），且作者 christiangrey922 自己 fork 了同批的 repo-context-mcp — 星数不可信，代码真实度需独立验证（本次已 clone 验证 10k LOC 真实）
- 0 issues / 0 PRs，无外部社区信号
- Experimental v0.1.0，明确 "not production-hardened"
- demo URL 未发布（"added after the maintainer chooses and publishes"）— 宣传大于交付

## 验证证据
- 属于 [[agent-harness-landscape]] 的观测/测试层新成员；与 [[mechanism-vs-evolution]] 的关联：把"委托行为"从演化黑箱变成可测机制
- 本地 clone（depth 1）验证：17 packages，10,055 LOC TS，550 行 security.test.ts
- 测试断言全部来自实际运行过的 test 文件阅读（未运行 test suite — 证据边界：行为断言基于代码阅读，非执行）
- 星数/fork 数据：gh api 2026-08-16

## 状态
- Revisit 08-22：外部社区信号（真 PR/issue）、是否发布 demo 与 package、fork 网络是否持续膨胀
- 若仍 0 外部信号 → drop；架构模式已提取完毕
