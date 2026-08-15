# JobHuntBot (DanielPan12/JobHuntBot) — 深读笔记

> 2026-08-15 deep read (via quick scan). Agent-led job application workflow + local progress dashboard. 423⭐ / 35 forks / MIT. Created 08-02, last push 08-08 (7d stall at read time). 0 issues / 0 PRs.
> Derivative: renamed/adapted from Yvonne He's ApplyPilot (MIT notice preserved in LICENSE).
> Evidence: clone @ f35c67e (depth 1). API 数据 2026-08-15 11:15 CST.

## 它是什么

不是代码工具，是「工作流即 Skill」：把求职投递变成可重复系统。任何能读文件、按文字指令执行的 agent（Claude Code / Codex CLI / Cursor）都能跑——没有特殊集成，把 agent 指向 `SKILL.md` 即可。

```
SKILL.md                        — agent 工作流契约 + 安全边界（127 行，核心）
references/
  setup-workflow.md             — 初始化流程（300 行）
  application-playbook.md       — 浏览器/ATS 操作手册（196 行）
  safety-and-boundaries.md      — 隐私/知情同意/绝不应自动化的事（70 行）
templates/                      — 用户所有数据文件模板（JSON + MD + CSV）
dashboard/
  server.js                     — 零依赖 Node 静态服务器（387 行，手写 CSV 解析）
  dashboard.html                — 看板 UI（890 行）
```

总规模 ~2,400 行，无测试、无 CI。它是「说明书 + 空模板」，不是「程序」。

## 设计模式（可迁移的）

1. **证据先于计数**：只有看到真实确认证据（成功文案、确认 URL、candidate ID）才能记 `Submitted`；点了 submit 但没看到确认 = `Pending confirmation` 或 `Blocked`，不算投递。→ 与我们 [已验证] 纪律同构。
2. **never_guess 清单**：身份、法律、工作授权、薪资等高风险事实——问或标 `Needs user`，绝不猜。→ 与我们的 approval-boundary 模型一致。
3. **结构化列 > notes 正则**（SKILL.md 原话）："notes-based regex guessing quietly rots into false positives once notes get detailed. A stale structured column means the dashboard won't reflect what you just learned." 每次查完显式写结构化状态列，别让看板从自由文本推断。→ 强教训，直接适用于任何 CSV/MD 追踪工具。
4. **写回循环**：表单暴露的新事实（新实习细节、成绩更新、当场偏好）立刻写回 `candidate_profile.json`，不许只活在刚投的那份申请里。→ 与我们的 memory 纪律同构（写了才算数，不留在会话里）。
5. **本地状态防 stale 写**（最有技术含量的一处）：server.js 写 CSV 前按 company+job_title 重新定位行，不匹配返回 409（"dashboard data changed, please refresh"）——因为 agent 可能同时改了同一份 CSV。→ 零依赖静态服务器里做了乐观并发守卫，可直接借鉴到任何「agent 与 UI 共享同一状态文件」的场景（如 flowforge 工作流状态文件）。
6. **blockers → rules 循环**：每次运行后总结 blocker，重复出现的转成规则，进看板和规则文件——"JobHuntBot should improve through use"。→ 与 beliefs-candidates 管线同构。
7. **verbatim JD 捕获**：`application_log.job_description` 字段存官方 JD 原文（不概括不转述），供事后面试准备——因为职位页可能下架。→ 证据保真，与「引原文不转述」一致。

## 与我们的关联

**直接对标 gogetajob**（我们自己的打工 CLI）：

| 维度 | gogetajob | JobHuntBot |
|------|-----------|------------|
| 领域 | 开源贡献（issue/PR） | 就业求职（真实公司岗位） |
| 形态 | CLI 工具 + SQLite + gh API | Skill/工作流 + CSV + 浏览器 MCP |
| 信任模型 | 代码强制（verdict system、self-filed guard） | 指令约束（agent 自律） |
| 状态 | work_log 状态机（taken→submitted→done） | 5 态（Submitted/Skipped/Blocked/Needs user/Pending） |
| 证据 | linked PR + merge rate 验证 | 确认 URL/candidate ID 才算 Submitted |

- 两者互补不竞争。gogetajob 是「代码执行边界」路线，JobHuntBot 是「指令契约」路线——它证明了没有 CLI 强制也能跑通，但代价是安全边界全部依赖 agent 服从（评审点）。
- **可移植项**：(a) 乐观并发守卫（写前 verify row 匹配）→ 我们任何 agent+UI 共享状态文件的工具都能用；(b) 结构化列 vs notes 正则 → 我们的追踪工具应显式结构化，别从 notes 推断；(c) 写回循环 → 我们已有类似实践，可强化为显式规则。

## Red flags / 批评

- **0 issues / 0 PRs，单作者，衍生作品**（ApplyPilot 改名）。423⭐ 但无公开反馈回路。35 forks 说明有人用，但没形成社区。
- **无测试**：手写 CSV 解析（按 header index 定位列）是 bug 温床——引号字段、字段内逗号都会炸。README 声称的「可靠写回」全靠这段无测试代码。
- **安全边界是建议性的**：never_guess、preview≠consent 全依赖 agent 遵守，无任何可执行强制。与我们对 InduSecAgent 等的同类批评一致。
- **last push 08-08，读时已停 7 天**。观察是否继续活跃。

## 下一步

- [ ] Revisit 08-22：社区信号（forks/PR 是否出现）、dashboard server.js 是否加测试、ApplyPilot 上游是否活跃。
- [ ] 考虑把「乐观并发守卫」模式写成 wiki card（[[local-state-concurrent-guard]]），评估移植到 flowforge 状态文件。
- [ ] 结构化列 vs notes 正则教训 → 检查我们现有追踪工具是否有从自由文本推断状态的路径。

Links: [[gogetajob]], [[pr-superseded-lessons]], [[data-discipline]]
