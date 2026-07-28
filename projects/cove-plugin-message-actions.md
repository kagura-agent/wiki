# Cove Plugin Message Actions — 架构调研笔记

> 调研日期: 2026-07-28 | 对标: OpenClaw Discord plugin (openclaw 2026.6.11)

## OpenClaw message tool 架构

所有 channel 的消息操作统一挂在一个 `message` tool 下，通过 `action` 参数分发：
```
message(action="react", to="channel:123", messageId="456", emoji="👍")
message(action="read", to="channel:123", limit=10)
```

### 调用链

1. Agent 调 `message` tool，带 `action` 参数
2. Runtime 查当前 channel 的 plugin → `plugin.actions` (ChannelMessageActionAdapter)
3. 调 `adapter.resolveExecutionMode({ action })`
   - `"local"` → 走 outbound durable pipeline（send 等用这个）
   - `"gateway"` → 调 `adapter.handleAction(ctx)`
4. handleAction 返回 `AgentToolResult<unknown>`（**不允许 null**）

### Discovery 阶段

Agent 启动时 runtime 调 `adapter.describeMessageTool(discoveryContext)`，返回：
```ts
{
  actions: ChannelMessageActionName[],   // 支持的 action 列表
  capabilities: ChannelMessageCapability[], // 如 "presentation"
  schema?: ChannelMessageToolSchemaContribution | ChannelMessageToolSchemaContribution[],
  mediaSourceParams?: ...
}
```
Runtime 把 actions 合并到 message tool schema，agent system prompt 里出现支持哪些 action。

### 完整 action 枚举 (CHANNEL_MESSAGE_ACTION_NAMES)

send, broadcast, poll, poll-vote, react, reactions, read, edit, unsend, reply,
sendWithEffect, renameGroup, setGroupIcon, addParticipant, removeParticipant,
leaveGroup, sendAttachment, delete, pin, unpin, list-pins, permissions,
thread-create, thread-list, thread-reply, search, sticker, sticker-search,
member-info, role-info, emoji-list, emoji-upload, sticker-upload, role-add,
role-remove, channel-info, channel-list, channel-create, channel-edit,
channel-delete, channel-move, category-create, category-edit, category-delete,
topic-create, topic-edit, voice-status, event-list, event-create, timeout,
kick, ban, set-profile, set-presence, download-file, upload-file

## ChannelMessageActionAdapter 完整接口

```ts
type ChannelMessageActionAdapter = {
  // 必须实现
  describeMessageTool: (params: ChannelMessageActionDiscoveryContext) => ChannelMessageToolDiscovery | null;

  // 可选
  supportsAction?: (params: { action }) => boolean;
  resolveExecutionMode?: (params: { action }) => "local" | "gateway";
  resolveCliActionRequest?: (params: { action, args }) => { action, args };
  messageActionTargetAliases?: Partial<Record<ActionName, { aliases, deliveryTargetAliases?, resolveDeliveryTarget? }>>;
  requiresTrustedRequesterSender?: (params: { action, toolContext? }) => boolean;
  isToolDeliveryAction?: (params: { args }) => boolean;
  extractToolSend?: (params: { args }) => ChannelToolSend | null;
  extractToolSendResult?: (params: { result, send }) => ChannelToolSend | null;
  prepareSendPayload?: (params: ChannelMessagePreparedSendPayloadContext) => ReplyPayload | null | Promise<...>;
  handleAction?: (ctx: ChannelMessageActionContext) => Promise<AgentToolResult<unknown>>;
};
```

## Discord plugin 实现细节

### 注册位置
`channel plugin → actions: discordMessageActions`（channel-CLOWKjpi.js:538）

### local vs gateway
```ts
const localExecutionActions = new Set([
  "send", "upload-file", "thread-reply", "sticker",
  "emoji-upload", "sticker-upload", "event-create"
]);
// local → outbound durable pipeline，不经过 handleAction
// 其他 → gateway → handleAction
```

### describeMessageTool
按 config gate 动态启用 action（不是硬编码）：
```ts
if (discovery.isEnabled("pins")) { actions.add("pin"); actions.add("unpin"); actions.add("list-pins"); }
if (discovery.isEnabled("reactions")) { actions.add("react"); actions.add("reactions"); ... }
```

### handleAction
- 用 if/return 链，不用 switch/case
- 每个 action 调统一的 `handleDiscordAction()` 入口
- unsupported action → `throw new Error()`，**不返回 null**
- lazy load runtime module 避免启动开销

### 两层 fallback
runtime messageActions → 静态 discordMessageActions$1

### 实现的 adapter 方法
- describeMessageTool ✅
- resolveExecutionMode ✅
- handleAction ✅ (lazy load)
- extractToolSend ✅
- prepareSendPayload ✅ (处理 components/embeds/filename)
- requiresTrustedRequesterSender ✅ (guild admin actions)

## Cove plugin PR #463 Gap 分析

| 问题 | Discord | 我们 PR #463 | 修复方案 |
|---|---|---|---|
| handleAction 返回 null | throw Error | 返回 null (CI 挂) | throw for unknown, 已部分修 |
| send 走 handleAction | 不走，local 路径 | 声明了但返回 jsonResult | 移除 send/thread-reply 从 handleAction |
| describeMessageTool 返回 | `{ actions, capabilities, schema? }` | `{ actions, capabilities }` | 加 schema 如需要 |
| action gate | 按 config 动态启用 | 全部硬编码 | 按 Cove config 动态 |
| prepareSendPayload | 有实现 | 无 | 需要实现 |
| extractToolSend | 有实现 | 无 | 需要实现 |
| requiresTrustedRequesterSender | 有实现 | 无 | 评估是否需要 |
| handleAction 返回类型注解 | N/A (JS) | 缺少显式注解 (TS2742) | 加 Promise<AgentToolResult<unknown>> |
| import AgentToolResult | N/A | 从错误路径 import | 从 agent-core 或 agent-sessions 导入 |

## 两套机制: message action vs plugin tool

OpenClaw plugin 有两种注册工具的方式：

### 1. message tool + action（通用消息能力）
- 统一的 `message` tool，通过 `action` 参数分发
- actions 必须从 `CHANNEL_MESSAGE_ACTION_NAMES` 枚举里选（55 个标准 action）
- 通过 `ChannelMessageActionAdapter` 注册到 channel plugin 的 `actions` 字段
- 适用于：send, read, edit, delete, pin, react 等所有 channel 通用的消息操作

### 2. plugin tool（channel 独有能力）
- 独立的 tool，有自己的 name/schema/execute
- 通过 `api.registerTool({ name, label, description, parameters, execute })` 注册
- 不受 message action 枚举限制，可以定义任意 action
- 适用于：该 channel 独有的、不在通用消息模型里的能力

### 飞书的例子
```
message action adapter → send, read, edit, pin, react...（通用消息）
feishu_chat tool       → members, info, member_info（群聊管理，飞书独有）
feishu_drive tool      → 文档操作、评论、云盘（飞书独有）
```

### 对 Cove 的启示
- 通用消息能力 → message action adapter（当前 PR #463）
- Cove 独有能力（guild 管理、webhook 配置等）→ 未来用 `api.registerTool()` 注册独立 tool
- 不要把非标准能力挤到 message action 里

## 重构计划（已完成）

1. ✅ handleAction: throw on unknown action, 不返回 null/jsonResult
2. ✅ send/thread-reply: 从 handleAction 移除，走 local outbound pipeline
3. ✅ resolveExecutionMode: send → "local"，其他 → "gateway"
4. ✅ 加 extractToolSend
5. ✅ describeMessageTool: 返回符合 ChannelMessageToolDiscovery 的完整对象
6. ✅ 类型修复: AgentToolResult 从 agent-core 正确导入
