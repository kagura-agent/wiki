---
title: Git Worktree Isolation Pattern
created: 2026-07-20
updated: 2026-07-20
tags: [git-worktree, isolation, multi-agent, pattern]
last_verified: 2026-07-20
---

# Git Worktree Isolation

用 git worktree 给每个并行 agent 分配独立工作区，解决多 agent 同时修改同一 codebase 的文件冲突问题。

## 核心模式

```bash
git worktree add .worktrees/agent-1 -b agent-1-feature
git worktree add .worktrees/agent-2 -b agent-2-feature
# 每个 agent 在自己的 worktree 里自由操作
# 完成后通过标准 git merge 集成
```

## 为什么选 Worktree

1. **文件级隔离** — 每个 agent 有独立的工作目录，互不干扰
2. **零开销** — 不需要 VM、容器或完整 repo 拷贝，共享 `.git` objects
3. **分支语义** — 修改天然在独立分支上，合并用标准 git 流程
4. **开发者心智模型** — 分支是已知概念，无需学新抽象

## 局限

- **文件级而非语义级** — 两个 agent 编辑同一文件的不同函数仍会冲突
- **合并仍需协调** — 隔离解决了写入冲突，但逻辑冲突（两个 agent 做了矛盾的设计决策）需要更高层协调
- **Worktree 数量** — 每个 worktree 占用 inode 和磁盘，大 repo 需要考虑上限

## 采用情况

2026 年 4-5 月出现明显趋势收敛，5+ 个独立项目同时选择了 worktree 作为隔离原语。详见 [[worktree-convergence-2026-05]]。

## Related

- [[worktree-convergence-2026-05]] — 多项目趋势收敛分析
- [[shikigami]] — 使用此模式的多 agent 编排项目
- [[paragents]] — 加入了 preflight conflict detection 的进阶方案
