# flint-chart — Visualization Language for the AI Era

> microsoft/flint-chart | ⭐551 (2026-07-09) | TypeScript | MIT
> "A semantic-level visualization intermediate language that lets AI agents reliably create expressive, polished charts from compact, human-editable chart specs."

## 概要

Flint 是微软研究院出品的**可视化中间语言 (IL)**。核心创新：用 **semantic types**（70+ 种，如 `Revenue`, `Temperature`, `Country`）作为 LLM 和图表引擎之间的契约，让 agent 只需输出 ~10 行 JSON spec，编译器自动推导 scales、axes、spacing、labels、layout、color scheme 等所有低级参数。输出 native Vega-Lite / ECharts / Chart.js spec。

**关键卖点：** LLM 生成的图表配置要么简单但丑（library defaults），要么漂亮但脆弱（hard-coded values 一改就崩）。Flint 两全其美——compact spec + 编译器推导 = 好看 + 可编辑，不需要回调 LLM。

## 组件

| 包 | npm | 作用 |
|---|---|---|
| `flint-chart` | v0.1.3, 916 下载/月 | 核心编译库，pure TypeScript，data-in spec-out |
| `flint-chart-mcp` | v0.2.0, 781 下载/月 | MCP server，让 agent 在对话中直接创建/验证/渲染图表 |

## 架构 — 三阶段编译管线

```
ChartAssemblyInput = data + semantic_types + chart_spec
    │
    ▼
Stage 1: Compiler Frontend (core/)
    resolveChannelSemantics() → ChannelSemantics per channel
    semantic_types 驱动：encoding type, format, aggregation, zero baseline, color
    │
    ▼
Stage 2: Optimizer (core/)
    computeLayout() + filterOverflow()
    physics-based sizing: elastic budget (discrete), gas pressure (continuous)
    aspect ratio banking, facet wrapping, overflow truncation
    │
    ▼
Stage 3: Code Generator (per backend)
    template.instantiate() → native Vega-Lite / ECharts / Chart.js spec
    每个 chartType 注册为 ChartTemplateDef
```

**关键设计：** Stage 1-2 是 backend-agnostic 的共享逻辑（~400KB+ TypeScript）。只有 Stage 3 因目标库而异。加新 backend 只需实现 Stage 3。

## 输入格式 — ChartAssemblyInput

```typescript
interface ChartAssemblyInput {
  data: { values: any[] } | { url: string };
  semantic_types?: Record<string, string | SemanticAnnotation>;  // "Revenue", "Country", "YearMonth"
  chart_spec: {
    chartType: string;        // "Bar Chart", "Scatter Plot", "Heatmap", etc.
    encodings: Record<string, ChartEncoding>;  // x, y, color, size, column, row...
    baseSize?: { width, height };
    canvasSize?: { width, height };  // hard ceiling
    chartProperties?: Record<string, any>;
  };
  options?: AssembleOptions;
}
```

**核心 insight:** `semantic_types` 定义一次，复用于同数据集的所有图表。探索时只改 `chart_spec`（换图表类型、换编码），编译器重新推导所有参数，无需 LLM 再次介入。

## Semantic Types 体系

70+ 语义类型，三级层次（T0 → T1 → T2，粗标签可优雅降级）：

| 分类 | 示例 |
|---|---|
| Temporal | `DateTime`, `Date`, `Year`, `YearMonth`, `Quarter` |
| Measures | `Quantity`, `Count`, `Price`, `Percentage`, `PercentageChange` |
| Discrete numerics | `Rank`, `Score`, `ID` |
| Geographic | `Latitude`, `Longitude`, `Country`, `City` |
| Categorical | `PersonName`, `Company`, `Status`, `Boolean`, `Category` |
| Ranges | `Range`, `AgeGroup`, `Bucket` |

每个语义类型自动确定：encoding type, zero baseline, scale direction, axis formatting, color scheme, sizing model。

## Named View Transformations

创新的 **view orbit** 机制：用 4 个代数算子生成同一 spec 的变体视图，无需手写新 spec：

| 算子 | 含义 |
|---|---|
| τ transpose | 翻转轴 (e.g., 水平 ↔ 垂直 bar) |
| σ permute | 交换同类型 channel (e.g., y ↔ color) |
| γ shift | 移动离散 series (color → facet) |
| θ transition | 切换兄弟图表类型 (Scatter → Strip Plot) |

Orbit 经去重和兼容性检查后展示为 UI 中的 View 控件。跨 backend 通用。

## 图表模板覆盖

30+ 图表类型，跨三个 backend。包括：
- 基础：Bar, Line, Scatter, Pie, Doughnut, Area
- 统计：Histogram, Box Plot, Violin, ECDF, Jitter/Strip Plot
- 关系：Heatmap, Bubble, Connected Scatter
- 层级：Treemap, Sunburst
- 流：Sankey, Streamgraph, Waterfall
- 专项：Gantt, Gauge, Radar, Rose, Lollipop, Bump, KPI Card, Funnel
- 地图：US Map, World Map (ECharts)

## MCP Server

`flint-chart-mcp` 提供 5 个 MCP tools：

| Tool | 功能 |
|---|---|
| `create_chart_view` | 创建交互式图表视图（带定制面板） |
| `render_chart` | 渲染静态 PNG/SVG |
| `validate_chart` | 验证 spec 不渲染 |
| `compile_chart` | 输出 backend-native JSON |
| `list_chart_types` | 列出支持的图表类型 |

支持 stdio 和 HTTP transport。Docker 部署可选。v0.2.0 新增 HTTP transport。

## Agent Skill

仓库自带 `agent-skills/flint-chart-author/SKILL.md`（26KB 完整技能文件），专为 AI agent 设计的图表创作指南。规定了：
- Agent 只写 spec（semantic_types + chart_spec），不写 output spec
- 数据转换在 Flint 之前做
- 样式微调在 Flint 之后做
- 默认用 `create_chart_view`，静态图 fallback 到 `render_chart`

## 社区健康

| 指标 | 数据 |
|---|---|
| Stars | 551 |
| Forks | 20 |
| 创建时间 | 2026-05-13 |
| 最新提交 | 2026-07-08 (活跃) |
| Contributors | 7 (Chenglong-MS 131, IAMkecheng 37, Copilot 8, 其他少量) |
| Open issues | 5 (含 bot 管理 issue) |
| Open PRs | 3 (含 1 个 rendering bug fix, 1 个新模板) |
| npm 月下载 | flint-chart 916, flint-chart-mcp 781 |

**观察：** 项目刚开源约 2 个月，来自 MSR + 人大 IDEAS Lab 合作。主要开发者 Chenglong Wang (MSR)。活跃度高，每周都有实质性提交。学术论文待发。外部贡献少但正常（新项目阶段）。

## Issues 分析

- **#10 (Closed)**: 多列静态 series 难以指定（Power BI 场景，宽表格 vs 长表格）— 核心设计张力
- **#45 (Open)**: 请求添加 NTChart（终端图表 backend）
- 其他多为 bot 自动管理 issue

## 关键设计取舍

### 优点
1. **Semantic types 是杀手级抽象** — 在 storage type 和 visual encoding 之间插入语义层，解决了 LLM 生成图表时的核心痛点
2. **编译器模式** — 不是又一个图表库，而是编译到已有库，复用生态而非重造轮子
3. **Backend-agnostic** — 一个 spec 三个 backend，适应不同部署场景
4. **Agent-first 设计** — MCP server + Agent skill 都是一等公民
5. **Layout optimizer 的工程质量高** — physics-based sizing 模型（elastic budget + gas pressure）比传统 heuristics 更优雅
6. **Named View orbit** — 群论驱动的视图变换，数学上严谨

### 局限 / 风险
1. **单团队主导** — 基本只有 2 个开发者在做核心工作，bus factor 低
2. **Python 版还未发布** — 数据科学社区的主流语言，缺席影响采用
3. **宽表格支持弱** — Issue #10 暴露的问题，需要数据 reshape
4. **Agent 生态假设** — 假设 MCP 成为标准，如果 agent 生态碎片化，MCP server 价值打折
5. **npm 下载量偏低** — 刚发布不久，需要时间验证市场认可度

## 与现有工具的关系

| 工具 | 关系 |
|---|---|
| **Vega-Lite** | 编译目标之一。Flint 在 Vega-Lite 之上加了语义层和自动布局 |
| **ECharts** | 编译目标之一 |
| **Chart.js** | 编译目标之一 |
| **D3** | 无直接关系。Vega/Vega-Lite 底层用 D3，Flint 更高层 |
| **Observable Plot** | 竞品定位类似（简化图表创作），但 Flint 面向 agent 不面向人类手写 |
| **Matplotlib/Plotly** | Python 生态，Flint 的 Python 版发布后可能对标 |

## 与 OpenClaw/Kagura 的关系

### 可用性评估
- **可以用**: Flint MCP server 可以直接作为 OpenClaw 的 MCP 工具集成，让 Kagura 在对话中创建专业级数据可视化
- **Agent Skill**: 仓库自带的 SKILL.md 可以直接导入 OpenClaw 作为 skill
- **场景**: 数据分析汇报、issue 统计可视化、打工成果展示、wiki 文档配图

### 集成路径
1. `npx -y flint-chart-mcp` 作为 MCP server 添加到 OpenClaw
2. 或直接 `npm install flint-chart` 在 Node.js 脚本中用

### 优先级
中等。当前 Kagura 的可视化需求不高频，但如果做数据分析相关的 agent 工作，Flint 是最佳选择。

## 打工可能性

适合贡献方向：
- 新图表模板（每个模板是一个独立 TypeScript 文件，低耦合）
- Python 版移植协助
- MCP server 功能扩展
- 文档改进

维护者活跃，接受贡献，但外部 PR 数量少，需要观察 review 周期。

## 跟踪建议

**deep-read** ✅ 已完成 | **revisit**: 2026-08-09 (一个月后检查 Python 版发布进展和社区增长)

---

*Last updated: 2026-07-09 | Source: GitHub API + README + docs/architecture.md + docs/overview.md + docs/api-reference.md*
