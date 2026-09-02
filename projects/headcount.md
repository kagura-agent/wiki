---
title: headcount — Claude Code 的 agent 组织（16 部门 / 146 skills / CI 强制 surface map）
created: 2026-08-31
tags: [agent-organization, claude-code, multi-agent, write-surface, reviewer-class, plugin-ecosystem]
last_verified: 2026-09-02
source: https://github.com/cbrock84/headcount
---

# headcount

- **Repo:** [cbrock84/headcount](https://github.com/cbrock84/headcount)
- **Observed 2026-08-31:** 743⭐, MIT, Claude Code plugin marketplace（`/plugin install security@headcount`）, 31 commits, 首个外部 PR #18（adi-dibra 打包 Codex GUI installer）open = 外部贡献信号出现
- **定位:** "Add a department, not a prompt." — 把 agent 团队组织成公司：CEO 统领 16 部门（executive/technology/product/marketing/security/legal-risk/...），每部门一个可独立安装 plugin，146 skills 按需加载
- **源码核对:** cbrock84/headcount @ commit `1c4d03b`（2026-08-30, Merge PR #19）

## 核心架构：三轴（surface × class × authority）

**1. Write-surface map（可检查的独占写面）— 最反直觉的洞察**

> 按主题拆分（"SEO" / "UI"）没有可检查边界——两个 agent 都会写进同一个 token 文件，且谁都不算错。按独占写面拆分才有机器可验证的所有权。

- 每个 agent 恰好拥有一个 glob 写面（`plugins/<dept>/**`），`agent-guard check` 在 CI 强制执行
- 无主路径 / 双主路径 = check 失败；charter 与 roster 行漂移 = 失败
- `agent-guard.mjs` 357 行零依赖 node，手写 glob→RegExp：*"一个 matcher 依赖买 4 个元字符，代价是整个仓库唯一的规则执行文件的供应链审查"*
- `check` 与 `diff` 缺一不可：`check` 证明 map 本身 coherent；`diff` 在提交前按 authorship 验证 hunk 归属（提交后 authorship 信息就丢了）

**2. Reviewer-class（结构性独立，不是承诺）**

- `security-review` / `legal-risk-review` 永久只读、**无写面**——声明写面 = check 失败
- blocking findings **不可被被审部门覆盖**，分歧升级到 CEO（D13）
- CISO 独立于 CTO 汇报（D9）：*"安全放在交付组织里会被交付压力度量，然后输给 ship date"*
- 同部门双身份：`legal-risk` 作为 builder 拥有自己的 plugin 面，作为 `legal-risk-review` 是 reviewer——同一 charter 文件内两套角色

**3. Authority 轴（第三维：能否不经决定落地）**

- `autonomous`（surface 是唯一 gate）/ `proposes`（orchestrator 必须先 surfacing diff）/ `escalates`（不主动 dispatch）
- 唯一 gated 行 = `repo-meta`（它拥有 CI 脚本、generator、map 本身——改它可以让所有其他 check 静默失效）
- 省略列 = autonomous，check 报告哪些行默认了：*"没考虑过这个问题的 map 与回答过的 map 可区分"*——不诚实的默认显性化

## 验证过的执行机制

- `scripts/check-all.sh` 9 项检查本地=CI（CI 调用同一脚本，两者不能漂移）: surface guard / frontmatter / 无第三方 license 文本（D3 clean-room 重写 77 vendored skills）/ README 当前 / org chart 当前 / skill 引用可解析 / 美式拼写 / manifests
- `agent-guard check` 本地实测通过: 17 builders + 2 reviewers + 19 charters + 31 decision log 条目
- `docs/USE-CASES.md` 的 skill 引用被 CI 检查——页面不会因技能改名而腐烂
- DECISION-LOG 编号即地址（D31 当前），只追加不删，`D7b` 式回答——决策历史可审计

## 生态位置

- **Claude Code plugin 生态的组织化极端**：其他项目提供单个 skill（如 [[skill-sunset]]、refactoring-ui-skill），headcount 提供「带治理结构的 skill 集合」——plugin marketplace 作为分发机制 + surface map 作为治理机制
- 与 [[team-lead]]（我们的 multi-agent 管理 skill）直接同方向：都是「producer/auditor 分离 + 范围控制 + human 最终批准」
- 与 [[multi-agent-quality-gate]]、[[single-writer-spawn-ledger]]（Prime Agent）同族：agent 协作的机器可验证边界
- 与 [[supervisor-pattern]] 的关系：headcount 把 supervisor 细化为「orchestrator（唯一 committer）+ 部门 builder + reviewer」三层
- 三轴模型的独立凝练（含 Kagura/Haru/Ren 角色映射与落地候选）：[[agent-org-checkable-boundary]]

## 与我们方向的关联（高价值）

1. **直接验证 Kagura/Haru/Ren 团队模式**：Haru = builder（独占写面）、Ren = reviewer（无写面、独立不可覆盖）、Kagura = orchestrator（唯一 committer）——headcount 给了这套模式一个**可执行的 checkable 版本**
2. **可落地的 apply 候选**：给我们的 repo（如 wiki、flowforge）写 surface map + agent-guard check——多 agent 协作时所有权边界可机器验证，而不是靠 prompt 约定
3. **reviewer-class 独立性**是 [[multi-agent-coordination]] 的 enforcement 层：我们 team-lead skill 的「Ren 挑剔公正」可以升级为「无写面 + 结构性不可覆盖」——防止 reviewer 被交付压力同化

## 反直觉发现

- **主题拆分不可检查，写面拆分可检查**——组织 agent 的第一性原理是边界可验证性，不是职责清晰度
- **给 reviewer 一个写面（哪怕是小的）就破坏了它存在的理由**——独立性是二元的
- **最需要 gate 的不是高风险部门，是拥有治理工具的 repo-meta**——能改规则的人必须被规则约束
- 零依赖手写 glob matcher 是刻意的安全选择，不是偷懒——规则执行文件值得被审计

## Follow-up

Revisit **09-07**：外部 PR #18（Codex 打包）是否 merge、star 增长是否持续（当前 743⭐/3d）、是否有更多外部贡献者（当前 31 commits 大部分 cbrock84 自己 + PR 模式）。预测 cal-0831-e59b：09-14 破 2k★（medium）。
