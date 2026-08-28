# Skill Sunset — 指令老化审计 CLI

- **Repo:** ooocooc/open-skill-sunset | **npm:** skill-sunset v0.2.0 | **License:** MIT
- **Status:** 🟡 watch (08-26 deep_read) | **Created:** 2026-08-26 | **71⭐ / 1 fork**
- **核心命题:** "Your AI evolved. Did your rules?" — 审计累积的 AGENTS.md/CLAUDE.md/SKILL.md，找出随模型与运行时进化而过期/重复/多余的指令

## 架构（deep_read 08-26，clone 源码）

纯 Node.js，**0 依赖**（dependencies/devDependencies 均 undefined），本地只读、不调 AI API、不读 provider 凭据。src/ 6 文件：
- **analyzer.js** — 核心：walk 目录 → parse frontmatter → 分类 scope → 静态+语义发现
- **experiment.js** — A/B 实验模板（验证假设用，不是自动删除）
- **privacy.js** — 路径脱敏（$HOME/...、$ABSOLUTE/...）
- **report.js** — 双语 HTML/Markdown/JSON + Codex/Claude handoff prompts + rollback manifest
- cli.js / i18n.js

## 高价值模式（跟我们方向的关联）

### 1. 分类：domain-excluded vs generic（核心设计）
- **DOMAIN_MARKERS**（medical/legal/finance/中医/医疗/金融…）→ `domain-excluded`，**绝不自动退休**
- **GENERIC_MARKERS**（agent/code/git/mcp/skill/写代码…）→ `generic`，进入检查
- → 对应我们 DNA 分层：领域知识/安全规则/授权门 = 不碰；通用流程 = 可审计。这正是 beliefs-candidates 该有的边界

### 2. verdict 六态 + TEST 立场
KEEP / MERGE / UPDATE / DEMOTE / RETIRE / TEST。**关键哲学：**
> "No finding authorizes deletion. `TEST` means 'evaluate this hypothesis,' not 'a newer model made this rule unnecessary.'"

模型时代补偿规则（chain-of-thought 脚手架 / 角色扮演 / 无条件工具调用 / 强制子代理 / Context7 依赖 / 模型版本耦合）全部标 **TEST** 而非 RETIRE，要求 A/B 验证。→ 直接对治我们「模型变强了所以规则可以删」的懒惰推理（AGENTS.md 反复出现的教训：不要因为讨好/省事删规则）

### 3. 重复检测三级（bundle 指纹）
- `fingerprintSkillBundle` — 对整个 skill bundle（scripts/references/assets）哈希
- **exact-bundle-duplicate-same-name** → RETIRE（完整内容+同名）
- **same-entry-different-bundle** → MERGE（SKILL.md 同但 bundle 不同，不能当重复删）
- **duplicate-skill-name** → MERGE（同名不同内容）
- → 我们的 skills/ 目录同样有同名/近似重复风险，可借鉴 bundle 哈希判重

### 4. progressive-disclosure（上下文税）
- Skill 主文件 >8000 token / 指令文件 >6000 token → **DEMOTE**（下沉到按需 references）
- → 对应我们 context-budget-constraint 主线

### 5. A/B 实验模板（experiment.js）
- schemaVersion 1：baseline vs candidate 命令，bounded root（cwd 必须 stay inside --root）、repetitions 1-10、timeout 上限 30min、acceptance（requireExitCode / maxDurationRegressionPercent / requireStdoutMatch）、SAFE_ENVIRONMENT_KEYS 白名单（PATH/TEMP/LANG…）
- → 这就是「可失败验证」的工程化：不是嘴上说 A/B，是给出带验收条件的实验计划

### 6. 隐私设计
- 0 依赖 + 本地只读 + 路径脱敏 + 安全 env 白名单 → 一个「读你全部配置」的工具，把隐私边界做成默认

## 红旗与评估

- 4 commits（今日创建），solo 作者，但**真实迭代**（Initial → Windows CI 修复 → 跨平台测试稳定 → v0.2.0 release），非上传式
- 71⭐/1 fork 一天内 — 有 npm 发布 + 完整 CI 矩阵（Ubuntu/macOS/Win + Node 20/22/24）+ 双语文档，工程扎实
- 0 issues 0 PRs — 太新，无社区信号
- 与 [[skill-evolution]]（我们的 meta-skill 全生命周期）、[[skill-creator]]、[[agent-skill-survey-2026]] 互补：skill-evolution 管「怎么演进」，skill-sunset 管「什么该退」

## 结论

**参考价值高，值得试用**：`npx skill-sunset audit` 可直接跑在我们的 workspace（AGENTS.md/SKILL.md 一堆）上验证分类与 verdict 是否合理——这是下一个 apply 候选。TEST 立场 + domain-excluded 边界 + bundle 指纹判重是三个可直接借鉴的设计。

## Links

[[skill-evolution]], [[skill-creator]], [[agent-skill-survey-2026]], [[beliefs-candidates]], [[context-budget-constraint]], [[clawhub]]

---
*Tracked: 2026-08-26 quick_scout → deep_read*

## 08-28 Apply — 实测审计我们的 workspace

**执行**：`npx skill-sunset audit . --lang zh-CN`（2026-08-28 20:00 study apply 轮）

**结果**：健康分 **73/100**（部分完成）；扫描 1213 文件（1005 generic / 1 domain-excluded / 207 manual-review）；1962 发现。Verdict 分布：RETIRE 776 / TEST 394 / DEMOTE 393 / MERGE 390 / UPDATE 9。

**发现质量评估**：
- **真实可修**（UPDATE high, invalid-frontmatter）：`skills/seedling/SKILL.md`、`skills/moltbook-community/SKILL.md` 缺 frontmatter → **已修复**（skills repo 07894d4，补 name/description）。这直接影响 OpenClaw skill scanner 加载。
- **噪音为主**：RETIRE 776 几乎全是 `cove/.claude/worktrees/` 下的 worktree 副本（bundle 哈希相同判重）——worktree 本就不在加载范围，误报。扫描根把 `.claude/worktrees`、`node_modules`、`.git` 也扫了，需排除。
- **低价值**：model-version-coupling（spec-review/code-review/code-refactor 里的 GPT-5.5/Opus 4.7 型号名）——属合理描述，不修。
- **TEST 合理**：mandatory-subagent 标了 flowforge/skill 和 gogetajob（策略性用 subagent 是设计意图，不是盲从）。

**工具本身验证**：0 依赖、本地只读、路径脱敏、报告含 rollback manifest + codex/claude handoff prompts + A/B 实验模板——工程完整，实测无副作用。CLI 是 `audit [target]`（不是 `--root`）。

**Gradient**：audit 类工具的价值在「过滤噪音后的真实信号」——1962 条发现里 actionable 只有 2 条。跑审计的姿势应该是先配排除（worktrees/node_modules），否则 99% 是重复副本噪音。→ 对应我们 [[study-saturation-gate]] 的噪音门控哲学。
