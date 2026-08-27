# TabTin — 人与 Agent 协作平台

- **Repo:** tabtin-ai/TabTin | **官网:** tabtin.com | **License:** AGPL-3.0
- **Status:** 🟡 watch (08-26 deep_read) | **Created:** 2026-08-19 | **152⭐ / 36 forks**

## 一句话

中文团队（larchiveai.com）的人+Agent 协作平台开源版：消息+文档+表格+演示文稿+Agent Runtime 一体，主打「一个人完成的工作能直接成为下一位同事的起点」（工作交接）。

## 架构（deep_read 08-26，clone 源码）

Monorepo，apps/ 下 8 个组件：
- **tabtin_django** — Django 4.2 + django-ninja + celery + channels 服务端（~30 个 app：agent / agent_memory / credential_vault / skills / channel_gateway / tabchat / tabcode / tabdoc / tabmemo / tabslide / tabsite / integrations_feishu / integrations_github…）
- **tabtin-electron** — 桌面端（agent-autofill、cookie-sync、production CSP）
- **tabtin-daemon** — **headless Agent Runtime**（远程服务器无头执行）：CLI server（agent/session/create、fork、threads、SSE stream 桥接 WS Gateway）+ **MCP server** + gateway 桥接 + heartbeat 注册
- **collab-live** — Hocuspocus/Yjs 实时协作（冲突检测测试明确 **agent 连接不计入冲突**，excludeEditorId 排除）
- tabtin-web / tabtin-android / tabtin-ios / admindash
- contracts/ — OpenAPI + AsyncAPI + models 契约

## 高价值模式（跟我们方向的关联）

### 1. Agent = 纯 AI 身份（models.py 明确注释）
> 「AI 身份 — 描述『谁在参与』。只含人格/规则/配置；设备与工作目录属于 Workspace。」

Agent 与 Workspace/设备解耦，组织归属 + owner_user 记录创建者。→ 直接对应我们 Loom 的「agent-as-router / 身份先于工具」设计。

### 2. credential_vault — 密钥注入三不变量（skill_reveal.py 注释明确）
- **密钥绝不进 LLM 上下文** — endpoint 只返回 env 变量名，runtime 直接塞子进程，不回到 tool_result
- **绝不写日志** — logger 只出现 credential_id/service_name/env 变量名
- **绝不持久化** — 内存 5min TTL 缓存 + 子进程 env，执行完 OS 回收
- Fernet 加密存储（EncryptedJSONField）、前端脱敏、多匹配按 last_used_at DESC 自动选第一条（回写 timezone.now() 反映真实使用）
- → 对比我们的 pass/sops 凭据体系：我们缺「agent 执行时按需注入 env 且不进上下文」这一层

### 3. AgentMemory — 记忆跟 agent 生命周期走
- memo_type: about_you / insight / task_summary / diary
- 隔离维度：(agent, owner) 主锚 × organization 租户；active↔archived 两态，**无回收站**（记忆不是用户可回收资产）
- 物理独立表（agent_memory_entry），db_router 避免 select_for_update 跨连接死锁
- → 对应我们的 memory 体系：agent 删则记忆删，按 owner 隔离

### 4. 工作交接 = 冻结上下文 + 带引用文档
> 「交接的不只是最后一份文档。任务续接会冻结必要的对话上下文，并带上任务中引用且有权共享的文档/表格/云端/本地文件。」

- daemon agent fork session = 带完整历史创建分支
- → 直接映射 FlowForge 任务状态 + Loom 会话交接设计

### 5. TabCode context builder
项目路径/git 分支/变更文件注入；remote daemon git status 存在时跳过本地冗余字段。

## 红旗与风险（scout-precheck 触发）

- **5 commits squash 上传**（74MB / 20k+ 文件），全部作者 tabtinagent，**迭代史不可见** → 无法验证开发轨迹（非「Add files via upload」单 commit，但接近）
- **36 forks / 152⭐（fork 率 24% 异常高）** — 上传后大量 fork，社区信号存疑
- 商业产品开源（contact@larchiveai.com、tabtin.com 官网）→ 开源的可能是 Community/展示版
- 2 open issues（08-24）：①1MB 请求体限制 bug（真实用户报）②远程 HTTPS 部署 feature — 质量尚可，非灌水
- CI/测试存在（Django tests + vitest 冲突检测测试），工程是真实的

## 结论

**参考架构价值高，不投资**：这是「完整的人+agent 协作平台」的稀有开源实现——credential_vault 三不变量、Agent 纯身份模型、记忆生命周期隔离、agent 连接不计入实时协作冲突，都是我们 Loom/chat-infra 直接可借鉴的模式。但 solo squash 上传 + 商业闭源风险 → 归入 backlog 观察，不深追。与 [[lemma-platform]]（另一 human+agent workspace）对照看。

## Links

[[lemma-platform]], cumora（backlog 观察中）, [[loom]], [[chat-infra]], [[flowforge]], [[pass-sops-credential-management]]

---
*Tracked: 2026-08-26 quick_scout → deep_read*
