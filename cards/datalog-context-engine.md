---
title: Datalog Context Engine — 用演绎数据库做 LLM 上下文
created: 2026-09-01
tags: [datalog, context-management, agent-memory, deductive-db]
last_verified: 2026-09-01
---
# Datalog Context Engine — 用演绎数据库做 LLM 上下文

把「上下文工程」从检索缓存升级为**演绎数据库**的模式：事实存入 Datalog 引擎，规则推导出当前状态、矛盾、salience 等派生视图，LLM 只在摄取边界做抽取、不参与推导（LLM 不进 fixpoint）。

## 关键属性
- 增量求值（DBSP/DDlog 路线）+ demand evaluation（magic sets）→ 点查询只碰极小切片
- 双时态标注（valid/asserted）→ 知识更新是标注关闭而非覆盖写，支持 as-of 查询
- 半环标注（[[scallop]]）→ 置信度与 provenance 在推导中自动传播

## 相关
- [[lemmalog]] — 本模式的代表性开源实现（Rust, 2026-08）
- [[agent-memory-architecture]] — agent 记忆架构的父主题
