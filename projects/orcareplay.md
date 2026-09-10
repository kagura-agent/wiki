---
title: OrcaReplay — agent runs as replayable, forkable evidence
created: 2026-09-10
tags: [agent-harness, replay, observability, verification, computer-use, debugging]
source: https://github.com/Continuum-AI-Corp/OrcaReplay
last_verified: 2026-09-10
---

# OrcaReplay

> 源码核对基于 Continuum-AI-Corp/OrcaReplay commit `ac3a61972f86a620e31700d4e8b1594ff398566d`（2026-09-10）。本笔记基于 GitHub API 读取 README、架构/验证文档、测试文件与 issue/PR 元数据；未在本机安装依赖或运行完整测试套件。

- **定位：** Apache-2.0、Node 20+ 的 agent run recorder/replayer：记录 coding agent 的模型请求、工具协议、shell、MCP、文件快照和网络（仅 TLS-intercept fork 路径），然后 exact replay、从 checkpoint fork 到另一个模型，或 compare 多模型。
- **观测状态（2026-09-10）：** 206⭐ / 65 forks / 4 open issues；版本 `0.2.4`；最近主分支提交为 TLS-intercept fork 的 `--model` 修复。近几日 PR 密度很高：#49、#67 等暴露并修复了真实 harness 边界问题，#65（记录 proxy 看不见的 agent structure）仍 open，#69 有 11 个 Windows 测试失败待处理。
- **生态位置：** 它把 agent observability 从“花费/Token 仪表盘”推进到可重放的执行证据层，处在 [[agent-harness-landscape]]、[[LongHorizon-Harness]] 与 [[FlowForge]] 之间：不是长任务编排器，而是把一次执行变成可审计、可复现、可比较的 trace。

## 核心架构

### 1. Proxy-first + 五层捕获

模型 API 的每轮请求会带回完整对话和前一轮 tool results，因此本地 proxy 可以记录请求、流式响应、tool call 和 tool result，而无需修改 agent。补充层包括：

- model proxy：注入 `ANTHROPIC_BASE_URL` / `OPENAI_BASE_URL`，原生协议 tee；
- PATH shell shim：捕获 argv、exit code、duration、stdout/stderr；
- MCP JSON-RPC shim：透明 tee；
- shadow git index：每轮 workspace snapshot、content-addressed blobs 和 diffs；
- fetch hook：针对 hardcoded origin 的有限捕获。

反直觉边界是：README 的“network blocked”只保证 replay proxy 不把未匹配的模型请求转发出去；replay 中记录的 tool calls 仍会真实执行，tool 自己发起的 `curl`/MCP 网络请求不在 exact replay 的 sandbox 保证内。项目明确说 replay 不是 sandbox。

它也明确没有通用 CA/TLS 模式：普通 capture 是 base-URL redirect；只有 fork 的 `--tls-intercept` 测试路径会生成 CA、记录 allowlisted host 的 `net.*` 事件。忽略 base URL 的订阅登录（如某些 Codex/Claude Code 模式）不能被普通 capture 捕获。

### 2. Exact、fork、compare 是同一条 cursor 机制

- **Exact replay：** cursor 在末尾，所有模型响应来自 trace，未匹配请求停止并非零退出。
- **Fork：** cursor 在 checkpoint `n`，之前从 disk 服务，之后进入 live model，workspace 从 checkpoint tree 物化到 scratch worktree。
- **Compare：** 从同一个 parent checkpoint 顺序创建多个 child runs；顺序执行是为了避免并发分支测到机器竞争而不是模型差异。

Checkpoint 不是人为标注，而是“完整 conversation prefix + 同一 turn 的 filesystem snapshot”。`snapToCheckpoint` 只允许向前一个 checkpoint 回退，绝不静默向未来状态 fork；测试还覆盖无回应 request 后状态未知、跨 turn 不携带旧 snapshot 等边界。

### 3. Divergence 必须显性化

匹配阶梯为 canonical request hash、同 turn/message count 的结构距离、相同 trailing message/不同 prefix、最终 unmatched。每次近似匹配都报告 rung 和 minor/major level；exact replay 的 divergence 也会写入它自己的 trace，而不是只打印后丢失。项目文档明确把“静默猜测”定义为比没有 debugger 更危险的行为。

## 测试与验证信号

- `docs/fidelity.md` 当前有一个真实 quickstart Node agent 的回放门槛：exact ≥3、unmatched=0、divergences≤0、live calls=0。
- `packages/cli/test/replay-trace.test.ts` 验证 replay trace 自己有 parent_run、每个 divergence 有 schema-valid 的 rung/level/source_seq、unmatched 会记录 halt 且非零退出、`--no-trace` 不写 trace、父 trace 保持 byte-identical。
- `packages/cli/test/compare.test.ts` 验证所有模型从同一 parent fork、`--verify` 的退出码才是 verdict（agent exit 0 但 verify 失败仍为 fail）、未知模型成本显示 `—` 而不是 `$0.00`。
- `packages/cli/test/fork-tls.test.ts` 验证 TLS fork 的 `net.*` 事件、CA 私钥在结束后不留在 trace。
- `packages/core/test/redaction.test.ts` 覆盖 auth headers、provider token、PEM、GitHub token、高熵 token、JSON 可解析性、跨 run salt 和“不记录 secret 原文”。
- `packages/core/test/graph.test.ts` 覆盖 checkpoint、因果链、shell/file change 的推断边、循环保护。

验证文档也记录了真实 Claude Code run 的四类 fixture 未覆盖问题：请求距离被 session id 拉大、redaction placeholder 破坏 exact match、entropy sweep 破坏 fork round-trip、工具被 replay 再执行。项目通过字段级距离、secret-kind 比较、协议 id 豁免和 divergence 标注修复；但这不是证明所有 harness 都可稳定回放。

## 与我们的方向关联

1. **Evidence-first completion：** `--verify` 把“agent 退出了”与“任务通过了”分开；这直接强化我们的 `[已验证]` / failable gate 纪律，也与 [[FlowForge]] 的显式 transition 同构。
2. **可复现的模型比较：** 同一 conversation prefix、同一 filesystem checkpoint、单一变量换模型，比全量重跑更接近有效实验；适合未来评估 floway provider 或 Haru/Ren 的执行差异。
3. **可审计 handoff：** 记录的 shell exit code、file snapshot、tool timeline 能把 agent 的自述降为证据之一，而不是唯一事实；与 [[LongHorizon-Harness]] 的 auditor-approved state 互补。
4. **边界必须写进结论：** replay 不是 sandbox；网络、工具副作用、忽略 base URL 的 auth 模式和未经独立 verifier 的“成功”都不能被 trace 自动升级为证明。这与 [[data-fabrication-in-review]]、[[graded-agent-guardrails]] 同一条线。

## 反直觉发现与限制

- **Replay 的核心不是模型响应缓存，而是 workspace state + request cursor 的配对。** 没有同 turn snapshot，fork 只是换模型重跑，不是可比较实验。
- **Exact replay 仍可能真实执行 tool calls。** “模型网络不出站”不等于“整个任务无副作用”；真正的 sandbox 必须由外部隔离层提供。
- **最有价值的验证结果不是 clean replay，而是被命名的 divergence。** 项目把近似等级、unmatched halt 和 inferred causal edge 都保留下来，避免把 debugger 的猜测伪装成事实。
- **当前社区信号是“工程验证密集、采用证据尚浅”。** 206⭐ 和 65 forks，近期 PR 很活跃，但 fidelity 表仍只有一个 quickstart harness，核心贡献也集中在维护者；先作为架构参考，不引入本地依赖。

## Follow-up

- 观察 #65 是否能把 proxy 看不见的 agent structure 纳入 trace，以及 #69 的 Windows 测试失败是否暴露跨平台边界。
- 若我们的工作流出现可重复的长时间 coding-agent 任务，再做最小 PoC：checkpoint + `--verify` + redacted trace；不要先引入 TLS interception 或把 replay 当 sandbox。

Links: [[agent-harness-landscape]], [[LongHorizon-Harness]], [[FlowForge]], [[data-fabrication-in-review]], [[graded-agent-guardrails]], [[exec-safety]], [[shell-free-execution]]
