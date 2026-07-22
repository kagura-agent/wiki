---
title: skills.sh Marketplace
created: 2026-07-20
updated: 2026-07-20
tags: [agent-skills, marketplace, distribution]
last_verified: 2026-07-22
---

# skills.sh Marketplace

Agent skill 分发平台/协议。开发者通过 `npx skills add <skill-name>` 安装 SKILL.md 格式的技能包到本地 agent 环境。

## 机制

- **格式**：SKILL.md — 纯 Markdown 文件，包含 frontmatter 元数据 + 指令体
- **分发**：npm 生态复用，`npx skills add` 作为 CLI 入口
- **安装目标**：写入本地 `.claude/skills/` 或等效目录，agent 启动时自动加载
- **发布**：开发者 push skill 到 registry，类似 npm publish 流程

## 与 ClawdHub 的区别

| | skills.sh | [[agent-marketplace-landscape|ClawHub]] |
|---|---|---|
| 格式 | SKILL.md (标准化) | 自有格式 |
| 安装 | `npx skills add` (CLI) | Web UI + API |
| 生态定位 | 开发者工具链 | 注册表/目录 |
| 安全模型 | 本地审查 | 平台扫描（仍有 6.9% 恶意率） |

## 生态位置

skills.sh 代表 skill 分发从"平台托管"向"包管理器"模式的转变。降低了发布和安装门槛，但也继承了 npm 生态的供应链风险。

## Related

- [[agent-marketplace-landscape]] — 更广泛的 agent 市场格局
- [[agent-skill-standard-convergence]] — skill 格式标准化趋势
- [[mentor-smixs]] — 使用 skills.sh 作为分发渠道的项目
