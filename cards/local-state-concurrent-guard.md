# Local-State Concurrent Guard

> 2026-08-15, extracted from JobHuntBot deep read.

## Pattern

当 agent 与 UI/用户共享同一状态文件（CSV、JSON、markdown）时，写入前必须重新校验目标行/目标键与调用方最后一次看到的快照一致；不一致 → 拒绝写入（409 语义），而不是静默覆盖。

## 为什么

Agent 可能在用户打开看板的同一时间窗口内更新了同一文件（改状态、加行、删行）。按行号/索引写会把 agent 的更新冲掉，或把用户动作写到错误的行上。JobHuntBot server.js 的实现：写 job_pool.csv 前按 `company + job_title` 重新定位行，不匹配返回 409 "data changed, please refresh"。

## 适用条件

- 同一状态文件有多个写入方（agent + 人类 UI + cron）
- 写入方之间没有锁/事务协调
- 数据有自然业务键（company+job_title 之类）可做校验锚点

## 反例（不适用）

- 单写入方场景 → 纯开销
- 写入方有事务/锁 → 冗余

## 应用候选

- flowforge 工作流状态文件（agent 推进 + 人工编辑）
- gogetajob work_log（CLI + 未来 UI）
- wiki/memory 文件（多 session 并发写）

Links: [[jobhuntbot]], [[gogetajob]], [[data-discipline]]
