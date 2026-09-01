---
title: Scallop — 半环 Datalog 引擎
created: 2026-09-01
tags: [datalog, semiring, provenance, deductive-db, knowledge-graph]
last_verified: 2026-09-01
source: https://scallop-lang.org
---
# Scallop — 半环 Datalog 引擎

开源 Datalog 引擎，核心贡献是把**半环（semiring）标注**引入 Datalog 求值：事实可带置信度（product t-norm）、provenance（set union）等标注，推导时标注自动传播——统一了概率推理与溯源追踪，不离开引擎。

## 为什么相关
- [[lemmalog]] 的置信度×provenance 半环机制直接引用 Scallop（Green et al. PODS 2007 半环标注理论）
- 递归查询 + 保证终止 + 无副作用 → 适合安全暴露给 LLM 作为查询语言
- 与 RelationalAI/Rel、DDlog 同属增量求值/声明式推理生态
