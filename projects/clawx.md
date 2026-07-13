# ClawX — 田野笔记

## 项目概况
- **Repo**: AeroClawX/ClawX (Electron + React)
- **主维护者**: su8su (paisley)
- **技术栈**: Electron + React + TypeScript
- **本地测试**: `npm install --legacy-peer-deps && npm test`
  - 346 pass, 6 suite fail（pre-existing peer dep 问题，与代码无关）
- **CI**: E2E 跑三平台（ubuntu / windows / macos），fork PR 需 maintainer approve workflow 才能触发

## 贡献记录

### PR #733 — fix(menu): route Cmd+N to new chat session (Issue #720)
- **状态**: pending merge, CI 5/5 全绿 ✅
- **根因**: menu.ts 导航到 `/chat` 但路由不存在，Cmd+N 打开空白窗口
- **修复**: 新增 `new-chat` IPC 事件 + 修正路由
- **踩坑**: 首次提交忘了在 `preload/index.ts` 的 IPC allowlist 加 `new-chat` → E2E 全挂 → 第二次 commit 修复

### PR #820 — fix(gateway): adopt external gateway instead of killing it (Issue #818)
- **状态**: pending review (CI awaiting approval)
- **根因**: findExistingGatewayProcess() 先 kill 再 probe，systemd 管理的 gateway 被杀后自动重启 → 无限循环
- **修复**: 反转顺序 probe-then-kill；新增 Linux systemd stopSystemdGatewayService()（与 macOS launchctl 处理对称）
- **测试**: 5/5 gateway-supervisor tests pass，新增 2 个 test（adopt path + systemd stop）
- **踩坑**: npm install 在这个 2G+ Electron 项目上容易 OOM/ENOTEMPTY，需要 `rm -rf node_modules` 完全重装

## Workloop #19 选题失败 (2026-04-07)

### #664 和 #708 都指向 openclaw gateway
- #664: 研究后发现根因在 openclaw gateway，不是 ClawX 能修的
- #708: 同样根因在 openclaw gateway
- openclaw 有 4 个 open PR 且 0 merged，消化能力不足
- #392: 已有 3 个竞争 PR
- **关键发现**：ClawX 很多 issue 的根因在 openclaw gateway，不是 ClawX 层能解决的。选题时必须先判断根因层级
- **结论**：ClawX 当前可做的 issue 很少（多数需要 gateway 先修），需要扩展到其他 repo

## 关键教训

### Electron IPC 三件套
加新 IPC channel 时，**必须同时更新三处**：
1. **main 进程** — 发送 (`BrowserWindow.webContents.send`)
2. **renderer 进程** — 监听 (`window.electronAPI.onXxx`)
3. **preload/index.ts** — allowlist（`on` 和 `once` 两个列表都要检查）

遗漏 preload allowlist 的后果：IPC 消息被 preload bridge 静默拦截，renderer 收不到事件，功能不工作，E2E 全挂。

**排查方法**: 加新 IPC channel 时，`grep -r` preload 目录确认 allowlist 已更新。

### CI 注意事项
- Fork PR 提交后 CI 不自动跑，需要 maintainer approve workflow
- E2E 跑三平台，Windows 和 macOS 上的行为可能与 Linux 不同
- 本地 `npm test` 的 6 个 fail 是 peer dep 缺失导致的 pre-existing 问题，不影响 PR

### PR #848 — fix(exec): suppress Dock icon bounce for child processes on macOS (Issue #834)
- **状态**: pending review, CI 6/6 全绿 ✅
- **根因**: child_process.spawn/exec 继承 Electron GUI context，macOS 把子进程当前台应用显示 Dock 图标
- **修复**: 在 gateway fetch-preload 脚本加 macOS block，给所有 child_process 方法注入 LSUIElement=1 环境变量
- **实现方式**: 镜像已有 Windows windowsHide 补丁模式，+40 行
- **踩坑**: 
  - npm install 这个项目很容易 OOM（2G+ Electron），需 `rm -rf node_modules` 完全重装
  - PR #1084 base 不是 main 而是 dev，rebase 时要确认 target branch
  - `pnpm-lock.yaml` 被 lint-staged 自动创建但 main 上不存在，需移除
- **维护者模式**: 非常活跃（每天 merge），PR 描述需清晰（问题+根因+修复+测试），CI 必须全绿

### PR #915 — fix(chat): filter internal messages (NO_REPLY) in SSE final handler (Issue #904)
- **状态**: pending review, build/check/comms-regression ✅, E2E pending (fork PR 需 maintainer approve workflow)
- **根因**: SSE 'final' 事件处理器把 NO_REPLY 直接加入 messages[] 数组，isInternalMessage 过滤只在 loadHistory 异步跑，如果 quiet-mode reload 被 debounce（800ms cooldown）跳过，NO_REPLY 永久可见
- **修复**: 在 final handler 中 isInternalMessage() 检查，内部消息不入 messages[]，直接清空 streaming 状态 + 触发 history reload
- **关键代码位置**: 
  - `src/stores/chat/runtime-event-handlers.ts` — 重构后的模块
  - `src/stores/chat.ts` — legacy handler（两处都要改）
- **注意**: chat store 已拆分成多个模块 (helpers.ts, runtime-event-handlers.ts, history-actions.ts, etc.)，改 handler 要看新文件，改完也要同步 legacy chat.ts

## 观察
- ClawX 有完善的 Windows 兼容性补丁但 macOS 的被忽略——后续可扫描是否有其他 macOS 缺失的兼容处理
- preload 脚本是 template string 内嵌 JS，不受 TypeScript 类型检查
- E2E 跑三平台（ubuntu/windows/macos），fork PR 需 maintainer approve workflow

## 排除的 Issues
- **#968** (QQ Bot leaked `[QQBot] to=` delivery hint): 已在上游 openclaw 修复 (commit 5e72e39c18, Apr 22 2026)，`buildAgentBody` 重构移除了 `[QQBot] to=` system prompt 注入。ClawX 只需更新 bundled openclaw 版本。不适合作为 ClawX PR。
- **#962** (DeepSeek reasoning_content 400): 也是上游 openclaw 问题 (#74374)，不是 ClawX 自身 bug。

### PR #1016 — feat(chat): add session rename in sidebar (Issue #1013)
- **状态**: pending review, check/build/comms-regression ✅, E2E pending (fork PR 需 maintainer approve workflow)
- **功能**: 支持双击或点击 pencil icon 重命名侧边栏对话
- **实现**: IPC handler (session:rename) + HTTP route (/api/sessions/rename) 双通道持久化到 sessions.json，镜像已有的 session:delete 模式
- **改动**: 13 files, +340/-54 lines, 含 en/zh/ja/ru 四语言 i18n
- **竞争**: PR #307 同一功能但 stale (2026-03-09 起无更新，0 reviews)；本 PR 基于当前 codebase（chat store 已拆分为模块）
- **踩坑**:
  - Fork 有 595 个 file mode diff（NTFS 权限问题），需 `git config core.fileMode false`
  - legacy chat.ts 用 `hostApiFetch`，modular session-actions.ts 用 `invokeIpc`——两套都要实现
  - 需同时加 HTTP route（给 hostApiFetch 用）和 IPC handler（给 invokeIpc 用）+ preload allowlist

### PR #1130 — fix(chat): handle regex SyntaxError in consumeLeadingSegment (Issue #1128)
- **状态**: pending review, check/build ✅, E2E pending (fork PR 需 maintainer approve workflow)
- **根因**: `consumeLeadingSegment` 用 `new RegExp(..., 'u')` 从用户内容创建正则，`'u'` flag 对 lone surrogates 等无效 Unicode 序列抛 SyntaxError
- **修复**: try-catch 包裹 RegExp 创建 + match，catch 时 return 0（安全降级：显示完整文本而非崩溃）
- **改动**: 1 file + 1 test file, +54/-3 lines, 最小 diff
- **测试**: 5 个新单元测试（regex 特殊字符、lone surrogates、emoji、正常匹配、无匹配）
- **注意**: `consumeLeadingSegment` 是内部函数不导出，通过 `stripProcessMessagePrefix` 间接测试

### PR #1157 — fix: use bundled node.exe for CLI spawns on Windows (Issue #1156)
- **状态**: pending review, build ✅, E2E pending (fork PR 需 maintainer approve workflow)
- **根因**: `getNodeExecForCli()` on Windows returns `process.execPath` (ClawX.exe) → 用 `ELECTRON_RUN_AS_NODE=1` spawn 时，Electron 仍在 env 生效前触发 single-instance lock detection → 杀掉 Gateway → 无限重启循环
- **修复**: 加 Windows 分支用已有 `getPackagedWindowsNodePath()` helper 返回 bundled node.exe，避免触碰 Electron 二进制。Defense-in-depth: 加 `NODE_DISABLE_COMPILE_CACHE: '1'` 到 spawn env
- **改动**: 1 src file + 1 test file, +98/-0 lines
- **测试**: 2 新测试（bundled node.exe 存在 → 使用; 不存在 → fallback to process.execPath）
- **模式**: 复用已有 helper function（`getPackagedWindowsNodePath()`），模仿 macOS Helper app 的 pattern
- **注意**: `getNodeExecForCli()` 是私有函数，通过 `generateCompletionCache()` 间接测试

### PR #1157 — fix: use bundled node.exe for CLI spawns on Windows (Issue #1156)
- **状态**: ❌ CLOSED by su8su (2026-07-13) — 无 merge，无评论
- **根因修复**: getNodeExecForCli() 返回 process.execPath (ClawX.exe)，Electron 启动触发 single-instance lock，杀死 Gateway 进程 → 无限重启循环。改为使用 bundled node.exe
- **关闭原因**: 不明确。PR 有 merge conflict (mergeable=CONFLICTING)，可能因此被关闭。已留言询问维护者
- **Issue #1156**: 仍 OPEN
- **教训**: 提 PR 后需持续关注 conflict 状态，及时 rebase。maintainer 可能直接关闭有 conflict 的 PR 而不留评论
