---
title: Open PR Discipline
created: 2026-03-24
source: Luna feedback + NemoClaw check-pr-limit experience
last_verified: 2026-07-15
---
## Core Rule
一个 repo 的 open PR 不超过 3 个。超过就停下来等已有 PR 被消化。

## Why
- Open PR 占用维护者 review 带宽
- 10 个 open PR 不是"勤奋"，是"添乱"
- 维护者时间有限：NemoClaw 最近 20 个 merged PR 中只有 4 个来自外部贡献者
- NemoClaw 自动检查：check-pr-limit action 限制每人最多 10 个 open PR

## Related Signals
- NemoClaw #748 被 check-pr-limit 自动关闭（超限）
- 我关闭了 #279、#292 腾位置，但还是有 9 个 open

## Links
- [[closed-pr-lessons]] — 被关闭 PR 的五种失败模式
- [[external-contributor-success]] — 外部贡献者成功模式
