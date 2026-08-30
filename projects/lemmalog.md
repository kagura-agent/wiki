# Lemmalog — Datalog 引擎作为 LLM agent 记忆

> 源码核对基于 `JordyZomer/lemmalog` commit `7d6f154` (2026-08-30, 16 commits, 8,037 LOC Rust)

## 一句话

把 agent 记忆从「向量检索的缓存」变成「增量维护的演绎数据库」：事实带双时态（valid/asserted）+ 置信度×provenance 半环标注，规则在运行时安装，推导闭包/时序投影/矛盾检测全部机械化——LLM 只在摄取边界做抽取，不参与推导。

## 核心论点（为什么现在）

- **上下文被当 buffer 而不是 database**：context rot（Liu et al.）、LongMemEval 显示知识更新/时序推理是模型最差能力（跌 21-30%），因为现有记忆系统（Zep/Graphiti, Mem0, GraphRAG, Letta）只存事实不推导。
- **Datalog 是天然形态**：递归查询（传递支持、依赖追踪）2-3 条规则搞定，Cypher/SQL 笨拙；保证终止+无副作用 → 安全暴露给 LLM 作为查询语言；增量求值是已解决问题（DBSP/DDlog）。
- **半环标注**（Green et al. PODS 2007, Scallop）：置信度（product t-norm）× provenance（set union）统一机制，不离开引擎。

## 架构模式（反直觉点）

1. **LLM 不进 fixpoint**：无系统把 LLM 调用放进 Datalog 不动点内（非单调+昂贵），通过严格分层 + memoization 把 LLM 谓词隔离在摄取层。这是设计硬约束。
2. **规则即记忆**：derived views（current/contradiction/salience）就是记忆本身，不是额外索引。版本化规则注册表：agent 可安装/卸载规则批，变更时 backfill。
3. **更新=标注而非删除**：`valid_to` 关闭边，全历史保留，支持 as-of 查询。确定性更新策略 ADD/UPDATE/NOOP/escalate——矛盾处理是数据问题+策略，不是每次查询的 LLM 判断。
4. **实体消解**：LLM 提 star-shaped alias 边 → Datalog 推导闭包 → canonical 视图投影（读侧只读 canonical）；拓扑违规（两个 canonical）推导出 `alias_conflict` 事实而不是静默合并；置信度穿透闭包。
5. **demand evaluation**（magic sets `ask_deep`）：点查询不跑全 fixpoint——上下文选择只碰极小切片。
6. **hypothetical `what_if`**：delta-epoch 求值让「如果 X 成立会怎样」毫秒级完成（字节级 store 恢复）——纯 LLM 推理做不到的 lookahead 原语。

## 验证方法（亮点）

- **Differential testing**：450 个随机分层程序 vs 朴素 fixpoint oracle 对比——抓住并修了跨 run negation soundness bug。这是 Datalog 引擎的标准验证法，值得借鉴到我们的工具测试。
- 诚实状态日志：设计文档明确写「LongMemEval counting 问题受 extraction recall 限制，不是聚合缺陷」「leapfrog triejoins 在 agent 规模实测不必要」——不吹的 benchmark 记录。
- 数字：42 tests pass, deterministic suite 100% @1.5ms/turn, 12.8× token savings（1000-turn scenario）; LongMemEval oracle 30 实例：F1 0.48 vs transcript 0.50 统计平手，但 context 小 1.4-30×。

## 生态位置

- 邻接：Synalog（Datalog 语义层）、FluctlightDB（agent 记忆数据模型）、RelationalAI/Rel（Datalog 知识图谱）、Scallop（半环）、Zep/Graphiti（双时态）。
- 与 RAG/向量记忆的关系：**互补不是替代**——BM25 + 实体/图 boosting 的混合检索照用，Datalog 提供的是推导层。语义侧索引（Embedder trait + `near` 扩散）是附属不是核心。
- MCP server 暴露为 Claude Code/Kimi CLI 工具 + skill（SKILL.md 写得很好的「纪律」：assert as you verify / rules are experiments / why before trust / hypotheses have lifecycles）。

## 与我们的方向关联（北极星：自进化记忆层）

1. **「claim 不在引擎里就不存在」** 的纪律 ↔ 我们的 [已验证]/数据纪律——把验证状态变成可查询的推导事实，比 memory 日志更强。
2. **矛盾检测机械化** ↔ 我们的 beliefs-candidates 管线：如果事实带 valid/asserted 双时态，belief 纠正就是标注关闭，不用「覆盖写」。
3. **rule registry + backfill** ↔ FlowForge 规则版本化思路的延伸：规则作为一等公民安装/回滚。
4. **provenance proof tree（why()）** ↔ 审计纪律：任何结论可回溯到源 episode。
5. 我们的 memory_search 是纯语义检索；如果叠一层推导（如「哪些 beliefs 依赖这个事实」），能回答「改了这个会连锁影响什么」——dreaming/自进化时有用。

## 🚩 观察不投资

- 0 issues / 0 PRs / 0 外部贡献者，solo dev，16 commits，pushed 08-30（活跃但无社区）。
- 星数 156 且刚起步（<2 周）→ 架构新颖但未验证。**观察不投资**：卡片已建，模式已提取，不深读第二遍。
- 预测 cal-0830-XXXX：09-13 前仍无外部贡献者（low-medium 信心）。

## Links

[[agent-memory-architecture]], [[agent-memory-landscape-202603]], [[mechanism-vs-evolution]], [[scallop]], [[datalog-context-engine]]

---
*Deep-read: 2026-08-30 | Source: GitHub API + clone (commit 7d6f154) | Issues: 0*
