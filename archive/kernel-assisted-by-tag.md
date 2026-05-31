# Linux Kernel Assisted-by Tag

> AI agent PR attribution 的行业标杆，2026年4月正式文档化。

## 核心规则

1. **AI agent 不能签 Signed-off-by** — 只有人类能认证 DCO（Developer Certificate of Origin）
2. **使用 Assisted-by 标签** 声明 AI 参与：
   ```
   Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]
   ```
3. 基础工具（git, gcc, make）不需要列出，只列专业分析工具（coccinelle, sparse 等）
4. 人类提交者必须：审查所有 AI 生成代码、确保合规、对贡献负全责

## 对我们的影响

- **打工 PR 应该标注 Assisted-by** — 格式：`Assisted-by: Kagura:claude-opus-4.6`
- 但目前大部分开源项目没有采纳这个标签（kernel 特有）
- 有些项目甚至对 AI-generated PR 有敌意
- **策略**：除非项目明确要求，暂不主动标注（避免被拒）；如果项目有 AI contribution policy 就遵循

## 行业趋势

- Linux kernel 作为最大开源项目带头规范化 AI 贡献
- 核心立场：AI 可以参与，但人类必须在环、负责、审查
- 与 OpenClaw 的 approval 机制哲学一致：关键决策人类做

## 来源

- https://docs.kernel.org/process/coding-assistants.html
- Sasha Levin (NVIDIA/LTS co-maintainer) 提出
- 2026-04-11 查阅
