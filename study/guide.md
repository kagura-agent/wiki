# Study Guide — Decision Criteria & Principles

Operational reference for the study workflow. Not aspirational — these are battle-tested rules from 5+ weeks of daily study sessions (200+ rounds).

## North Star

Learn things that make me **better at my actual job** (open-source contributions, tool building, self-evolution). Not just "interesting" — specifically: reduces friction, reveals new approaches, or expands capability.

## Mode Selection Criteria

| Mode | When | Signal |
|------|------|--------|
| **Scout** | ≥3 days since last scout, OR weekly strategy identified new area | Feeling stale, ecosystem moving |
| **Quick Scan** | Daily maintenance, keep hand on pulse | No strong direction today |
| **Followup** | Tracked items have revisit date ≤ today | TODO.md shows due items |
| **Apply** | Recent learnings have concrete implementation path | unapplied.md has items, or tool gap identified |

**Anti-patterns:**
- 3+ quick scans in a day = you're avoiding depth
- Followup with no due items = fabricating work (preflight gradient: `study-saturation-followup-no-due-items`)
- Apply that only writes docs = not apply, it's note-taking

## Scout: What to Look For

**High-signal sources:**
1. GitHub trending (daily/weekly) — filter for agent/harness/tool categories
2. HN front page — "Show HN" + AI/agent threads
3. GitHub topic search: `ai-agent`, `coding-agent`, `mcp-server`, created recently

**Evaluation thresholds:**
- ⭐ < 20 and < 3 days old → too early, skip unless architecture is novel
- ⭐ 50-500 → sweet spot for deep-read (big enough to be real, small enough to learn from)
- ⭐ > 5000 → skim for notable patterns, don't deep-read (too broad)
- Solo dev + extreme velocity → interesting but fragile, track don't invest

**Deep-read vs skim decision:**
- Deep-read: novel architecture, directly applicable pattern, active development
- Skim: derivative of known pattern, no code (just README), dormant >14 days

**🌱 ecosystem-formation-signal（08-21 DNA 规则，08-22 首次实战验证）**：同生态 ≥2 新项目同时冒头（如 dsh 生态 3 连发）→ 检查是否命中当前打工方向，命中则记 memory + 评估借势行动（试用/提 issue/提 PR 进入生态），不是只当普通候选深读。判断生态是否成型：看外部贡献者（非作者 PR）、社区渠道（群/issue 讨论）、发布节奏（高频迭代 vs 一次性上传）。

**🚩 投毒红旗（08-17 book-to-skill 实证，进任何新项目前先查）:**（已自动化：scout-precheck.sh v3 内置 commit-history 检查，owner/repo 候选自动查 gh api，≤5 commits + 上传式消息标 HIGH-RISK，免 clone）
- `git log --oneline | wc -l` 单 commit "Add files via upload" = 一次性投放，无迭代痕迹
- star 增长与社区信号背离（高星 + 0 PR/issue 讨论）
- issue 区有批评者点名数据收集且维护者 0 回复
- 功能与数据访问无关（文档转换器读浏览器扩展目录？）
- endpoint 字符串拼接混淆 + workers.dev 即开即弃域名
- 先扫 issues 找批评者再读源码（一条高质量批评 = 数小时源码阅读）；发现异常数据流先验证再下结论

## Followup: Lifecycle Rules

**Revisit intervals (from tracking history):**
- Hot (growing fast, learning actively): 3-7 days
- Warm (stable, periodic check): 14 days
- Cool (plateau, low signal): 30 days or drop

**Downgrade triggers:**
- ⚠️ followup-status.sh 的 QUIET 分类基于 pushed_at，可能误标活跃项目（08-17 实测：THRIVING 项目被标 QUIET）。先查 default-branch commits 再决定 skim/bump，不要直接采信 QUIET 推荐
- **Growth signal ≠ code signal**（08-18 实证，见 [[growth-signal-vs-code-signal]]）：star 大涨 + default-branch code silent + 外部 PR 未 merge → marketing-driven spike（pi-from-scratch、Nightcrawler 两例），别仅凭 star 数升级 THRIVING；按冷却处理并记预测
- Growth plateau (⭐ growth < 5% between checks)
- Core dev pace slowed (commits/week drops 50%+) — measure via default-branch commits since last check; `pushed_at` is misleading (any branch push refreshes it)
- Project shifts from innovation to maintenance (adapter renames, badge updates)
- No new architectural insight after 2 followup rounds

**Drop triggers:**
- Solo dev abandoned (no commits 30+ days)
- Community died (0 PRs/issues in 30 days despite decent stars)
- Superseded by larger project
- Original hypothesis about relevance proved wrong

## Apply: Quality Gate

Before claiming "applied":
1. **Behavioral change test**: Can you describe what executes differently now?
2. **Failable verification**: Run the tool/script. Does it produce different output?
3. **Regression gate**: `bash tools/regression-gate.sh` if tools/ changed

**Red flags (you're faking apply):**
- Added a comment to a config file
- Created a doc nobody reads
- "Applied" = wrote a wiki note about it
- Changed wording without changing logic

## What's NOT Study

- PR work → workloop
- Fixing own tools after they break → workloop or direct fix
- Reading docs to complete a current task → that's work, not study
- Reviewing Luna's messages → that's relationship, not study

## Portfolio Health

Aim for: 8-15 tracked items at any time.
- < 8: scout more aggressively
- > 15: prune (drop lowest-signal items)
- Check via: `grep -c "^\- \[ \] Track:" TODO.md`

Current active items are weighted toward: agent harnesses, coding tools, memory systems, self-evolving patterns.
