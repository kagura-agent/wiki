# keephq/keep

- **方向**: AIOps / alert management 平台（可观测性方向，与 agent 运维/告警对齐）— 2026-08-20 discover 加入关注列表
- **语言**: Python (backend) + TypeScript (frontend) + Mako templates；lint 用 black + isort (PEP8)
- **活跃度**: 极高（2026-08-19 仍有 commit），外部 PR 稳定 merge（#6705/#6698/#6697/#6680/#6678 均为外部贡献者，最近一周内 merge）
- **规模**: 12.2K⭐ | gogetajob scan: 70% merge rate (50 PRs analyzed) | 50 issues discovered
- **License**: MIT
- **无 DCO/CLA**，CONTRIBUTING 是标准 GitHub Flow（fork → branch from main → test → lint → PR）

## Contribution Flow

- 无 claim issue 流程要求；无 PR template 强制项迹象（需首次 PR 时再确认）
- PR 要求: 加了代码要加测试、改 API 要更新文档、test suite 过、lint 过
- 首次 PR 需 AI disclosure（见 guide）

## 2026-08-20 扫描时的候选 issue（feed 中排名靠后，尚未被 finder 检查）

- [#6712] bug: openai provider 默认 model gpt-3.5-turbo 不支持 json_schema response format
- [#6709] bug: grok provider 默认 model grok-1 不被 xAI API 提供
- [#6708] bug: grok provider 在空 choices 时崩溃（raise_for_status 后直接读 [0]）
- [#6707] bug: Manual "Run Workflow" modal 快速点击多次触发（无 debounce/in-flight guard）
- [#6704] feature: 支持对多个 alert 运行 workflow
- [#6703] bug: extraction rule 执行页包含 mapping rule 引用

**注意**: 这些 bug 与 unsloth 的 provider 默认模型问题模式相似（默认模型过时/不再服务）——如果做，参考 [[unsloth]] 的 #6697 先例（"default to a model Google still serves" 已被 merge）。

## 踩过的坑 / 观察

- discover 发现：该 repo 是 2026-08-20 之前未跟踪的新项目，加入后 feed 有 51 条候选，但 finder MAX_CHECK=15 预算被 OpenHands/deer-flow 高优先候选耗尽，新 repo 候选未被评估（feed 排序局限，见 workloop-finder 观察）
- 与 METR/vivaria（评测方向，141⭐，2026-02 后 dormant）对比后选中 keep——活跃度是硬门槛
