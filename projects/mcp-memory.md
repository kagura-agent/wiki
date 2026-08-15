# MCP-Memory — OKF-Backed Agent Memory Server (fellowgeek/mcp-memory)

> 2026-08-15 deep read | 146⭐ / 6 forks | created 08-13, last push 08-13 | Python/FastMCP/SQLite | API 证据边界：本地 clone + 源码 + 测试 + gh api（3 open issues，1 外部 PR）

**One-liner**: MCP server 给 agent 持久记忆，记录用 OKF v0.2 标准格式（YAML frontmatter），双架构——人可读 .md 树（权威）+ SQLite FTS5（可重建索引）。

## 架构模式（核心价值）

```
memory_store / retrieve / search / delete
        │  (+ get_last / update_last 会话检查点)
        ▼
   OKF v0.2 序列化（provenance/trust/lifecycle 一等公民）
        │
   ┌────┴────┐
   ▼         ▼
memory/*.md    .mcp_memory/memories.db
（人可读树）    （SQLite FTS5 索引，可重建）
```

**关键设计决策：**
1. **选 OKF 而不是自造 schema**（issue #1 外部 review 点赞的核心决策）：Google Cloud knowledge-catalog 的 OKF v0.2 把 `sources`（出处）、`generated`/`verified`（谁写的 vs 谁确认的，可多个独立检查）、`status`/`stale_after`（生命周期）、`Attested Computation`（可验证计算）做成 frontmatter 一等公民。**长命记忆库在第 3 个月开始失效的问题，大多数实现没有任何字段对应**。
2. **文件权威、索引派生**（"files authoritative, index derived"）：人可读 `.md` 树可 `git diff`，SQLite 只是可重建索引——**这个排序让记忆库能活过工具本身**。与 [[lobster0]] 的 markdown-truth + SQLite-rebuildable-index 完全同构。
3. **index.md 渐进披露 + log.md 更新史**：每层目录自动生成 index.md（root 带 `okf_version: "0.2"`），log.md 按日期分组记录 update/deletion——OKF §8/§9。
4. **会话检查点契约**：`system/last_memory` 作为约定键，`memory_get_last`（session start 恢复现场）/`memory_update_last`（milestone 时更新）——把"记忆恢复"做成 MCP 工具契约。
5. **namespace 隔离**：`user/preferences` vs `project/architecture` vs `default` 按需分隔。

## 测试证据（test_memory.py 实测阅读，本地 15/15 green 声明）

- OKF 序列化/反序列化 round-trip（string + dict content）✅
- OKF v0.2 扩展字段（sources/verified/status/stale_after/generated_by）通过 conformance 验证 ✅
- §11 conformance：缺 type → invalid；actor 不符约定（无 human:/process://producer/version）→ invalid ✅
- 文件落盘 + index.md/log.md 生成（root 有 okf_version、子目录无 frontmatter）✅
- FTS5 搜索 + tag 过滤 ✅；delete 后 log 记 Deletion ✅
- project_root 必填校验、自定义 project_root 生效 ✅

## 批评视角（这次有真 issue 可借力，不是 0 社区）

- **#2 路径穿越（真实漏洞，已修）**：`get_memory_file_path()` 只 strip 首尾斜杠，key 含 `../` 可写出 bundle。外部贡献者 yunaremaia 发现并提交 PR #3（3 个回归测试：parent traversal、absolute key、normal keys）。⚠️ PR 仍 OPEN 未合并（08-15 时点）。
- **#1 设计提问**：`project_root` scoping 的语义边界——memory 归属项目还是全局？README 提供 env var 切换但无明确推荐。
- **红旗**：2 天新项目（08-13），pushed_at 已停更（08-13 后无 commit），3 open issues 无 maintainer 回复（除 #2 是 PR 作者自己回）；146⭐ 但 6 forks、单文件结构（okf_engine.py 全引擎）。

## 跟我们方向的关联

- **直接映射我们的 wiki/memex 实践**：我们的 wiki 就是 OKF 式 bundle（frontmatter + 双链 + 渐进披露），memory/ 日志 + MEMORY.md 就是检查点模式。OKF 的 `stale_after` ≈ 我们的 TODO revisit 日期；`verified` ≈ 我们的 `[已验证]` 标注纪律
- 可借鉴：**`sources` 字段带 usage_window/credibility signals**（author/usage_count/last_modified）——比我们的"标注来源"更结构化；记忆库 3 个月失效问题是真实风险，我们的 wiki 也该考虑 freshness 字段
- 路径穿越教训：**任何"用户/agent 提供 key/path 拼接存储路径"的代码都要做 containment**——我们的工具里类似模式要自查

## 跟踪决策

Watch 级别（146⭐ 中量级，但与我们记忆实践高度同构 + 有真实安全案例）。Revisit 08-22：PR #3 是否合并、maintainer 是否活跃、OKF 生态是否在涨。
