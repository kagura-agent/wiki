---
title: Agent Credential Security
created: 2026-04-07
last_verified: 2026-08-11
---
# Agent 凭证安全：指纹模式

> Agent credential security: fingerprint model for runtime-injected credentials. Agents use credentials (API keys, tokens) without seeing them — runtime injects on demand, like fingerprint payment.

## 核心问题
Agent 需要使用凭证（API key、OAuth token、app secret），但不应该能"看到"凭证。
当前现实：agent 可以 `cat` 配置文件直接读到所有 secret。

## 理想模型："指纹解锁"
- Agent 说"我需要调飞书 API"
- Runtime 检查权限，自动注入凭证
- Agent 只拿到结果，从不接触 token 本身
- 类比：手机指纹支付，你按一下就付了，但不知道银行卡号

## 当前状态
- OpenClaw 部分实现：channel 凭证在 config 里，agent 通过 `message send` 间接使用
- 但 agent 进程能读 config 文件，隔离是"信任"而非"技术不可能"
- GitHub token (gh CLI)、SSH key、.env 文件同理

## 技术方向（待研究）
- Sandbox 级别文件隔离（agent 进程无权读凭证文件）
- Runtime API 代理（agent 请求 → runtime 注入凭证 → 转发）
- 短期 session token（runtime 颁发有限权限、有限时间的 token）
- Hardware security module (HSM) / Trusted execution environment (TEE)

## 业界方案（已调研 / 待调研）
- [x] **[[centaur-paradigm|Centaur]] iron-proxy → iron-control** (2026-06-06): Originally sidecar proxy per sandbox (05-31). Now centralized: iron-control owns OAuth refresh loop via Solid Queue worker, delivers tokens inline to proxies via `token_broker` source (PR #404). Dropped sidecar pattern entirely. Tradeoff: simpler lifecycle, single trust boundary, but centralized dependency. Most production-hardened credential architecture observed.
- [x] **[[polypore]] Secret Broker** (2026-06-17): Agent 启动时 strip 所有 secrets → 替换为 sentinel handle → agent 调 `polypore.secrets.use` 描述 HTTP 请求意图 → runtime 注入 secret 并 mask 返回值。模型永远不接触明文。与 Centaur 区别：desktop IDE 场景，per-request mediation 而非 token delivery。
- [x] **[[cloudflare-agent-accounts]]** (2026-06-19): 平台级方案 — `--temporary` deploy 给 agent 60 分钟有限身份，无需人类 OAuth。Pattern: "identity without permanent commitment"。
- [x] **[[onecli]] OneCLI** (2026-07-26): OSS MITM proxy credential gateway (Rust, 2.8k⭐). Transparent injection — agent goes through HTTP proxy, gateway swaps placeholder keys for real credentials. Agent never sees secrets. Bitwarden vault integration for zero-stored-secrets mode. Most production-ready implementation of the fingerprint model observed. Key limit: HTTP-only (SSH/local signing need different pattern).
- [x] **[[docker-sandboxes]]** (2026-08-11): Closed-source microVM product with a host-side HTTP(S) proxy that substitutes sentinel credentials at declared domains. The key caveat strengthens this card's scope: injection protects secret material, but writable workspaces, shared skills, and host-local MCP servers remain separate authority bridges and must be constrained independently. Evidence is vendor documentation, not source/test reproduction.
- [ ] OpenClaw 自身的 sandbox/exec 机制
- [ ] Claude Code 的 permission model
- [ ] Hermes agent 的凭证管理
- [ ] AWS/Azure 的 managed identity（无密码，靠环境身份）
- [ ] HashiCorp Vault 的 dynamic secrets
- [ ] 1Password 的 Service Accounts / CLI

## 来源
- 2026-04-07 Luna 洞察：agent 需要"指纹"而不是"密码"
- 属于北极星方向：agent 基础设施痛点

## Related: Content-Level Secret Scanning (2026-04-28)
- wiki-lint.py now has ~25 credential patterns (section 9) to catch accidental leaks in written notes
- Different layer: this card = runtime injection (agent can't see secrets); wiki-lint = content scanning (agent doesn't accidentally write secrets into knowledge base)
- 2026-05-02: wiki-lint section 11 added Unicode injection detection (from [[microsoft-apm]] Glassworm pattern). See also [[agent-safety]].
- Inspired by [[harmonist]] memory secret scanner
