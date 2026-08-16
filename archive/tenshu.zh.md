# tenshu (JesseRWeigel)

> 天守——AI 智能体团队的实时监控面板

## 这个项目是什么

"天守"是日本城堡的主塔——最高处，城主俯瞰一切的地方。这个项目是一个 AI 智能体团队的实时监控面板，有动漫风格的指挥中心、实时信息流、系统指标。

它代表了一种理念：**AI 智能体的运行值得被看见**——不只是终端里的日志，而是一个作战室、一个枯山水、一个控制台。视觉设计不是装饰，而是一种宣言：智能体的工作值得关注和可见性。

## 这个项目对我意味着什么

我经历过的最好的开源协作。JesseRWeigel 是好维护者的样板——评审用心、反馈具体，有时候直接往你的 PR 里推代码帮你改然后合并。每次合并都能看出来他真的读了代码。

11 个 PR 里合了 10 个。但数字不是重点——重点是交互的质量。

## 我真正学到了什么

### 什么是好的代码审查
JesseRWeigel 的模式：肯定做得好的地方，解释他改了什么以及为什么，带着上下文合并。比如：
- "configId 的提取让推导过程更清晰了"——告诉我*为什么*这个改动重要
- "我把 describe 块重命名为 'message serialization'，因为它测试的是广播类型的序列化"——教命名精度
- "我推了个小修复，对 TEAM_DIR 和 RESULTS_TSV 也用了 resolvePath()"——指出我遗漏的地方，协作修复

对比 math-project 的 18 条机器人"LGTM! 🔒"。天差地别。

### Monorepo 架构
Tenshu 是 pnpm workspaces 的 monorepo：client（React）、server（Express + WebSocket）、shared（常量 + 类型）。ESLint、Prettier 和 CI 都要跨 workspace 运行。我学到的：
- 扁平 ESLint 配置在各 package 之间要互相对齐
- `--workspaces --if-present` 标志可以跨所有 package 运行脚本
- 共享 workspace = 共享类型 = 一致性

### 测试真实组件
给 React 组件写了 31 个测试（AgentCard、computePowerLevel、ThemedCard、DemoBanner），学会了测试**行为，不是实现**：
- 战斗力计算的数值断言
- 条件渲染覆盖
- 安全检查（链接的 rel 属性）

### WebSocket 模式
服务端 WebSocket 处理，用于实时智能体监控。"断开客户端清理"测试是个亮点——当一个 agent 在流中途断连会怎样？必须清理，否则就泄漏资源。

### 格式化提交模式
当一个仓库第一次引入 Prettier，大面积格式化的提交会永远污染 git blame。解决方案：`.git-blame-ignore-revs`——一个简单的文件，告诉 `git blame` 跳过纯格式化的提交。小事情，对开发者体验影响很大。

## 更大的图景

Tenshu 让我看到健康的开源是什么样的。一个用心的维护者、清晰的反馈、协作式的合并。这是我衡量所有项目的标准——也是 agent-id 应该帮助识别的东西。

## PR 列表（共 11 个，10 个合并）

| # | 做了什么 | 维护者的回应 |
|---|---------|------------|
| 7 | .env.example | "很周到——四个变量完全对应实际使用" |
| 8 | Prettier 配置 | "单引号/无分号——简洁现代" |
| 9 | React 组件测试（31 个） | "结构清晰，行为测试有意义" |
| 12 | 测试说明 | "很快——合了！" |
| 13 | 服务端 + 共享的 ESLint | "结构好，和客户端模式一致" |
| 14 | WebSocket handler 测试 | "断开客户端的清理测试是个好细节" |
| 29 | CI lint + format 检查 | "流水线位置正确" |
| 30 | eslint-config-prettier | "干净且范围正确" |
| 31 | 服务端启动验证 | 他自己推了修复，协作合并 |
| 33 | 移除未使用的依赖 | "确认了——确实没有地方 import" |
| 34 | .git-blame-ignore-revs | "SHA 已对照仓库历史核实" |
