# 远程 SSH 管理方案：Tailscale + Termius

## 场景
从手机/外网 SSH 到内网机器（无公网 IP），用于远程重启服务、排障等。

## 方案
1. **Tailscale** — 内网穿透，所有设备加入同一 tailnet，自动分配内网 IP
2. **Termius (iOS/Android)** — 手机 SSH 客户端，免费版够用
3. SSH 到 Tailscale IP 即可

## 优点
- 免费（个人 3 用户 + 100 设备）
- 不暴露公网 IP
- 不需要端口转发/DDNS
- 跨平台（macOS/Linux/Windows/iOS/Android）

## 替代方案
- **Cloudflare Tunnel** — 不装客户端，浏览器访问，但需要域名
- **端口转发** — 暴露家庭 IP，不推荐
- **frp/ngrok** — 需要公网服务器做中继

## 认证方式
- 密码登录（简单但不够安全）
- SSH key（推荐，Termius 可生成 key）
- Tailscale SSH（用 Tailscale 身份认证，不需要密码/key）
