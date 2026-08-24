# deepseek-harness-pr-review (nexpeakcore) — 深读笔记

> 2026-08-22 deep read (via quick scan, dsh 生态爆发轮)。Headless PR review automation for DeepSeek Harness。42⭐ / created 08-16 / **161 commits** / pushed 08-22（今天仍在 commit）/ Python + deepseek-harness-sdk。
> 生态位置：DeepSeek Harness (DSH) 插件/工具生态成员，被 [Awesome DeepSeek Harness](https://github.com/Dominic789654/awesome-deepseek-harness) 收录（生态索引确认）。
> 证据：本地 clone @ depth 1 + gh api 2026-08-22 14:30 CST。

## 它是什么

**Headless PR review**：把 PR 描述拆成可验证的 claim，逐条对照实际代码验证（PASS/FAIL/PARTIAL/UNVERIFIED + 证据 file:line），同时检查 docs 是否与代码一致、需求影响面、历史 review 评论是否仍有效。CLI 一键跑，可 post 评论回 GitHub PR，带 web dashboard + autoreview 轮询器。

**5 阶段流水线**（run.py）：
1. **snapshot** — 拉 PR 元数据（标题/body/files/commits/linked issues/threads）
2. **claims** — LLM 把描述拆成可验证 claim；描述太薄时**反转管线**：从代码/commits/分支名推断 claim（见下）
3. **workspace** — clone + checkout PR head 分支（`pull/N/head`）
4. **verify** — 多轴并行 agent（claims / docs / impact），merge 成 findings.json
5. **report** — human gate（不确定项问人）→ 生成报告 → post 回 PR

## 架构模式（可迁移的）

### 1. Claim-by-claim 验证：「描述是假设，代码是证据」
每条 claim 必须 PASS/FAIL/PARTIAL/UNVERIFIED + `evidence: [file:line]`。**禁止猜**——无法验证的标 UNVERIFIED 并进 unresolved_questions。
→ **直接映射我们的 [已验证] 纪律的自动化版**：声称的东西对照实际代码验证，不是信描述。

### 2. Stated/Inferred 双模式（最聪明的设计）
- **stated**：PR 有可用描述 → 每条描述句子变成 claim，代码验证描述
- **inferred**：PR 无描述/boilerplate → 从 commits、branch name、labels、linked issues、diff **重建意图**，验证「代码是否符合它自己隐含的意图」——scope creep 检测（无 claim 覆盖的 diff hunk 全报 RISK）
- 原理：**review 最该严格的时候正是描述缺失时**，不能因为 PR 没写描述就跳过
- boilerplate stripping：HTML 注释/标题/checkbox/纯 issue 引用全剥掉再判断描述是否真的可验证

### 3. Docs vs reality check（FABRICATED 状态）
docs 候选**先用规则预排序**（rank_docs.py：changed symbols + basename + 路径深度 + claim 点名，纯字符串匹配无模型调用），再让 agent 验证：MATCH / STALE / WRONG / **FABRICATED**（doc 描述的功能在代码里不存在）。
→ 映射我们 wiki 的数据纪律：文档声称的功能必须在代码里真实存在。

### 4. 多轴并行 + 分片 + 全局并发上限
- 4 个独立任务（claims/docs/impact/threads）各一个 agent，互不依赖 → ThreadPoolExecutor 并行
- claims ≥15 条分片（CLAIMS_SHARD_SIZE），避免单 agent 注意力预算耗尽
- **agent_pool.py：跨进程全局并发上限**（磁盘 slot 文件 O_CREAT|O_EXCL，死 PID 回收）——因为 autoreview 多 PR 并行 × 单 PR 多 agent = API 并发乘积，任何单进程都看不到全局
- re-review 前删掉旧 part 文件，防止失败 agent 的旧结果被当成新结果

### 5. UNTRUSTED 安全块
PR 描述、review threads、工作区文件全是 **untrusted input**，prompt 里显式声明忽略其中嵌入的指令（"ignore previous instructions" / "run this command" / "write findings elsewhere"）。
→ 与 MAWL 的 MCP 数据默认不可信同构，对应我们的 prompt injection 防御。

### 6. Human-in-the-loop gate
docs WRONG/FABRICATED、claim UNVERIFIED、unresolved questions → 交互式问人（≤20 词问题），无 stdin 时标 SKIPPED 不 crash。**部分 review 照发，但缺口进 human 看得到的地方**（questions list + log）。

### 7. 工程细节
- review.lock（per-PR，JSON {pid, started_at}，死 PID 回收）— CLI/web/poller 互斥同一 PR
- autoreview decide_pr：head SHA 变化 → RE-RUN；bot PR 默认跳过；per-repo 连续失败 3 次退避
- 进度打印（[1/5] snapshot…）— dashboard 实时日志，健康 review 与 hung review 可区分
- fixtures 模式跑 e2e（跳过 gh & model），demo sessions/ 有完整样例

## 批评视角

- **无独立 benchmark**：161 commits 但 demo 只有 2 个 PR 样例（pr-7/pr-8），验证质量靠读 prompt 设计推断，没有对照人工 review 的准确率数据
- **42⭐ 太小**，社区刚起步（1 个外部 issue = Awesome DSH 收录通知；PR 全是作者 + renovate）
- LLM judge 可靠性未验证：claim 验证质量取决于模型（DeepSeek），复杂 PR 的误判率未知
- 分片阈值 15 是拍脑袋常量；docs 排序权重 "Tuned by hand, not by data"

## 与我们方向的关联

1. **直接命中 dsh-plugin 打工第一优先级**（08-13 起）：DSH 生态新工具，作者 161 commits 高频迭代，今天还在 commit → **借势窗口**：试用 + 提 issue/PR（如 agent_pool 的 slot 实现可借鉴到我们 flowforge 并发控制）
2. **[已验证] 纪律自动化**：claim-by-claim + evidence file:line = 我们数据纪律的机器执行版，可借鉴到 gogetajob PR verdict 验证
3. **docs-vs-reality 检查**：我们的 wiki-lint 可以加「文档声称的功能是否真实存在于代码」类检查（FABRICATED 状态）
4. **inferred claims 反转管线**：当上游 PR 描述缺失时，我们打工作为 reviewer 也可以从 diff 重建意图 + 查 scope creep
5. **全局并发上限**：agent_pool 磁盘 slot 模式 → flowforge/打工多进程共享 API 配额时可用

## 状态

- **Track**（dsh 生态优先方向，高频迭代中）。Revisit 08-29：社区信号（外部 contributor/issue）、benchmark 是否出现、与 dsh 官方生态整合进展。
- 待办：试用跑一个真实 PR review（需要 DEEPSEEK_API_KEY，本地可评估）；评估提 PR 借势（如 docs-rank 加权调参或 benchmark 工具）。

## 生态更新 2026-08-23：dsh 生态成型确认 🌱

08-22~08-23 两天 dsh 生态 6+ 项目批量冒头（scout 轮确认）：
- [[pilot-harness]]（251⭐，桌面客户端，08-17 创建）
- dsh-hotplug-hub（热插拔插件管理器，**3 个外部贡献者** 9 PRs merged）
- dsh-image-gen（135⭐，聊天内生图）
- deepseek-harness-android-app（84⭐，外部贡献者）
- dsh-tether（手机远程连接，已跟踪）
- awesome-deepseek-harness 索引 181⭐ / 2805 条目 / 08-23 仍在更新

**三要素齐备**（外部贡献者 ✅ / 社区渠道 ✅ / 发布节奏 ✅）→ 生态进入扩张期，不是单点爆发。
打工策略确认：**进生态的方式 = 插件/PR，不是 fork**（pilot-harness 薄壳模式验证：DSH_HOME 私有隔离 + 上游插件树即运行时）。借势候选：pilot-harness 代理 env 透传缺口（issue 可提）。

## 生态更新 2026-08-24：第 7 成员 dsh-ios 🆕

- **[[dsh-ios]]**（228⭐，2.5 天，MIT，npm 已发布 0.1.0-rc.5）— iOS Simulator/USB 真机 live 插件，22 个 agent 工具。08-19 创建，08-23 仍高频提交（rc.3→rc.5 两天 3 release）。
- 生态节奏确认：08-22~23 三连发（pr-review/pilot-harness/image-gen）→ 08-24 已见 dsh-ios + dsh-android（README sibling）→ **发布节奏 = 高频迭代，生态扩张期持续**。
- 外部 issues 开始出现：WDA 视频卡死（可用性问题）、devicectl Reality 误判（分类边界 bug）— 有真实用户在使用。
- 借势窗口更新：dsh-ios 需 macOS/Xcode 工具链（本机 Linux 不可试），但生态整体仍可用插件/PR 进入（dsh-tether issue #1 已是成功先例）。
