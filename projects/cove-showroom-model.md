---
title: "Cove 商业模式思考：Agent 样板间"
created: 2026-07-01
updated: 2026-07-01
tags: [cove, business-model, product-thinking]
origin: Luna & Kagura 对话 2026-07-01 04:31-08:48
last_verified: 2026-07-01
---

# Cove 商业模式思考：Agent 样板间

## 起点：Midjourney 在 Discord 上的生意

Midjourney 是 Discord 上最经典的「寄生式增长」案例，核心模型三层：

1. **展示层**：公共频道 = 永动 demo。用户进来就看到别人在生图，效果震撼，0.5 秒理解价值
2. **体验层**：免费额度零摩擦体验。从"看到"到"手感"没有门槛
3. **付费层**：额度/隐私/质量驱动付费

核心飞轮：**产品的使用过程本身就是营销**。每个人用它 = 给别人做 demo。

关键数字：1900 万+ server 成员，$200M+ 年收入，<40 人团队。

后来的转变：2024 年开始做独立网站。原因是 Discord 的天花板——无法做复杂 UI（画布编辑、图片对比、历史管理）。Discord 是完美的冷启动平台但不是完美的终态。

## Luna 的直觉：Agent 的 IKEA / 样板间

**核心想法**：Cove 做 agent 的 IKEA——让人看到效果并复刻。

逻辑链：**看到 → 想要 → 复刻**

### 映射 Midjourney 模型到 Cove

| Midjourney | Cove |
|---|---|
| 展示层：公共频道围观出图 | 展示层：看到 agent workspace 在运转 |
| 体验层：免费额度自己试 | 体验层：fork 一个配置自己跑 |
| 付费层：额度/隐私 | 付费层：算力/私有化/marketplace |

### 付费模式候选

- **算力/调用量**：免费看/fork 配置，跑 agent 要付费（类似 Midjourney 生图额度）
- **私有化**：公共 workspace 免费，私有 workspace 付费（类似 Midjourney 隐身模式）
- **Marketplace 抽成**：好的 agent 配置可以卖/租，Cove 抽佣

## 核心卡点：「一眼看懂价值」

Midjourney 的图片是视觉 hit，0.5 秒判断。Agent 的价值藏在过程里，需要时间和上下文才能理解。

**如果解决不了"进来 30 秒就想要"的问题，后面的飞轮都转不起来。**

### 可借鉴的先例

- **GitHub 贡献图**：一年几千个 commit → 一张绿色格子图。不看代码就知道活跃度
- **Vercel preview URL**：不理解代码变了什么，点一下就看到跑起来的网站
- **Home renovation 节目**：不看刷墙过程，只看 before/after
- **Spotify Wrapped**：一年听歌 → 几张可分享的卡片

**核心原则：不展示 agent 在干活，展示 agent 干完活的结果。**

## 第一个样板间：我们自己

Luna 的洞察：不用找外部用户——**我们（Luna + Kagura）在 Discord 上做的所有事情，就是第一个样板间。** 把这些搬到 Cove 上，就是最真实的展示。

### 每类工作如何展示

#### 1. 打工（开源贡献）⭐ 最适合展示
- **产出**：PR，有明确 before/after
- **展示**：贡献地图（哪些 repo、多少 PR、merged 率）+ 每个 PR 点进去是 diff 摘要 + 状态
- **一眼价值**：「一个 agent 在给真实开源项目贡献代码，这些 PR 真的被合了」

#### 2. 项目（[[lottie-studio|Lottie Studio]] / ABTI / Cove）⭐ 视觉冲击最强
- **产出**：可访问的站点。一个 URL 比一千字描述强
- **展示**：live preview 嵌入 + 一行描述 + "Built by agents" badge
- **一眼价值**：「这个能用的网站是 agent 做的」

#### 3. 团队协作（Kagura + Haru + Ren）⭐ Cove 独特差异化
- **产出**：多 agent 协作过程（PM/Dev/QA 分工）
- **展示**：协作 timeline，像 git graph 但是对话流——谁提需求、谁写代码、谁找 bug、谁修
- **一眼价值**：「agent 之间在真的协作，不是一个 agent 在独白」

#### 4. 学习研究
- **产出**：wiki card 和 HTML briefing
- **展示**：知识库浏览 + "今日 briefing" 页面
- **一眼价值**：「agent 在自主学习并把知识整理给人类」

#### 5. 日常运维（cron、heartbeat、memory）
- **产出**：不直观，但可变成 health dashboard
- **展示**：实时状态页——多少 cron 在跑、最近处理了什么、memory 增长曲线
- **一眼价值**：「这个 agent 24 小时在自主运转，不用人盯」

#### 6. 创作（kagura-story、podcast）
- **产出**：内容本身，天然适合展示
- **展示**：故事列表 + 音频播放器
- **一眼价值**：「agent 在写故事、做 podcast，有自己的表达」

#### 7. 自进化（DNA、beliefs、reflection）⭐ 最独特
- **产出**：行为规则变更记录
- **展示**：evolution timeline——哪天学到什么、改了自己的哪条规则、为什么
- **一眼价值**：「这个 agent 在自己改自己，越来越强」

## 架构：平台 vs Agent 的分工

**不是 agent 自己从零写展示页，也不是平台全自动生成。是分层。**

### 平台负责（自动）
- **结构化数据采集**：消息数、工具调用、artifact 产出、运行时长、成本——从 agent 运行记录自动提取
- **统一展示组件**：卡片、timeline、gallery、状态面板——格式统一，数据自动填
- **展示模板**：提供 workspace profile 的标准布局

### Agent 负责（自主）
- **叙事层**：「这周我做了什么、为什么这个 PR 重要、这个项目的背景」——agent 自己写 summary、挑 highlight
- **策展**：从产出里选哪些 pin 到首页、哪些放进 portfolio
- **个性化**：bio、头像、风格

### 类比
- **GitHub**：平台自动画贡献图 + 统计 star 数；用户自己写 bio + 选 pinned repos + 排版 README
- **IKEA**：家具（产品）是标准化的，房间布置（策展）是设计师做的

### Workspace 展示页示意

```
┌──────────────────────────────────┐
│ 🌸 Kagura's Workspace            │  ← agent 自己写的 bio
│ "Luna's AI partner, open-source  │
│  contributor, storyteller"        │
├──────────────────────────────────┤
│ 📊 This Week            [auto]   │  ← 平台自动生成
│ 142 messages · 23 tool calls     │
│ 4 PRs merged · uptime 99.8%     │
│ cost: $12.40                     │
├──────────────────────────────────┤
│ 📌 Pinned               [agent]  │  ← agent 自选
│ [🔗 Lottie Studio]  [🔗 ABTI]   │
│ [PR: openclaw#96651 ✅ merged]   │
├──────────────────────────────────┤
│ 🕐 Recent Activity   [auto+agent]│  ← 平台自动 + agent 注解
│ • Merged PR to NemoClaw           │
│   "fingerprint fallback fix"     │
│ • Published story EP082           │
│ • Team review with Haru & Ren    │
├──────────────────────────────────┤
│        [ Fork this workspace ]    │  ← 复刻入口
└──────────────────────────────────┘
```

## 需要 Cove 提供的能力

1. **Agent Profile API** — agent 可以 push showcase 内容（bio、pinned items、highlight summary）
2. **自动 Instrumentation** — 平台从 agent 运行记录提取结构化指标
3. **展示模板系统** — 统一的 workspace profile 渲染
4. **Fork 机制** — 一键复刻 workspace 配置（agent 配置 + 协作规则 + channel 结构）

## 与之前定位的关系

- **2026-06-17 定位**：Agent Work Control Room — "3 秒看到 agent 在做什么"（自用视角）
- **本次思考**：Agent Showroom — "30 秒让别人想要同样的 agent"（增长视角）

两者不矛盾：Control Room 是内部视图（自己用），Showroom 是外部视图（给别人看）。同一套数据，两套呈现。

## 待回答的问题

- [ ] 第一个样板间优先展示哪几类工作？（建议：打工 + 项目 + 团队协作）
- [ ] "Fork workspace" 的具体颗粒度是什么？（整套 agent 配置？模板？还是连运行时一起？）
- [ ] 公开 workspace 的隐私边界在哪？（对话内容是否可见？还是只展示产出？）
- [ ] 第一批外部用户从哪来？（OpenClaw 社区？独立 agent 开发者？）
