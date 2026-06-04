# 打工目标公司

> 准则见 `github-contribution/guide.md`
> 实际打工扫描由 **gogetajob DB** 驱动（`gogetajob scan/feed`），本文件仅供参考笔记。
> 黑名单由 `gogetajob blocklist` 管理。

## 分类

- **主力**: NemoClaw (NVIDIA/NemoClaw), OpenClaw (openclaw/openclaw), Hermes (NousResearch/hermes-agent)
- **辅助**: deer-flow (字节, 44k⭐), claude-hud (jarrodwatts/claude-hud), QwenPaw (agentscope-ai/QwenPaw, 17k⭐, Python)
- **观察**: Acontext, MemOS, OpenCLI, DeepTutor, qmd, superpowers, Archon, Paperclip, multica, rowboat, kimi-code (MoonshotAI/kimi-code)
- **维护中**: NemoClaw, ClawX, gitclaw（有 PR 等 merge）
- **退出**: math-project (bot 刷 review), repo2skill, supermemory, hindsight (maintainer 要求停止), OpenKosmos (不活跃), tenshu (不对齐方向), blockcell

## Repo Rename 记录 (2026-04-14)

| 旧路径 | 新路径 |
|--------|--------|
| hermes-ai/hermes-agent | NousResearch/hermes-agent |
| nicepkg/NemoClaw | NVIDIA/NemoClaw |
| nicepkg/ClawX | ValueCell-ai/ClawX |
| AgentDeskAI/claude-hud | jarrodwatts/claude-hud |

## 关键教训

- **好 issue 等不起** — 从发现到有人提 PR 可能只有几小时，有余量就立即做
- **品牌 repo review 周期 5-18 天属正常** — 瓶颈是 maintainer 带宽不是品牌
- **openclaw #60610 教训** — 改共享 helper 必须查所有 caller
- **memex #43 成功模式** — "高质量功能增强，代码规范、测试充分、设计优雅"

## 打工成果

- **权威数据源**: `gh search prs --author=kagura-agent --state=all | grep -v 'kagura-agent/'`
- 需每次 review 时当场查询刷新，不沿用旧数据
