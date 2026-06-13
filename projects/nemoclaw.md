# NemoClaw

> NVIDIA sandbox orchestrator for OpenClaw. 18.8k⭐, 79% merge rate.

## Repo Structure (post-TS migration, 2026-04)
- `src/lib/` — core library (gateway-state.ts, onboard.ts, preflight.ts)
- `src/commands/` — CLI commands (slash.ts, migration-state.ts)
- `src/onboard/` — onboard config
- `test/` — vitest tests (root level, not `nemoclaw/test/`)
- `nemoclaw/` — npm package subdirectory (has own package.json, tsconfig)
- `bin/` — old JS CLI (being replaced by TS)
- TS migration (#1673) happened ~Apr 2026, replaced `bin/nemoclaw.js` with compiled `dist/`

## Test & Lint Commands
- `npm test` — run all vitest tests (root level)
- `npx vitest run test/<file>.test.ts` — run specific test
- `npx tsc -p tsconfig.src.json --noEmit` — typecheck src/lib
- `npx tsc -p tsconfig.cli.json --noEmit` — typecheck bin/scripts
- `npx eslint` — lint (config may not cover all paths)
- Pre-existing test failures: preflight tests may detect actual running gateway process

## Maintainers
- **miyoungc**: CONTRIBUTOR, closes low-value docs PRs — prefers targeted updates to existing pages over new pages
- **cv**: responsive, asks for rebase, routes to specialists
- **brandonpelfrey**: COLLABORATOR, gives substantive UX/security feedback
- **ericksoa**: UX direction owner (cv routes UX decisions to them)
- **wscurran**: CONTRIBUTOR, auto-triage bot, adds related issue links
- **ColinM-sys**: writes regression tests, checks version pinning
- **chengjiew**: requires you to **claim issues first** before starting work — comment on issue to express intent, wait for assignment, then start coding (#3836 教训)
- **jyaunches**: 30 merged PRs in e2e/CI vertical, same-day merge time — see [[contributor-depth-strategy]]

## Contribution Flow
- **必须先 claim issue**：在 issue 下评论表示想做，等 maintainer assign 后再动手。不要直接开 PR（chengjiew 明确要求，2026-05-23）
- DCO signoff required: `git commit --signoff`

## PR Patterns
- Title: conventional commits (`fix(scope): ...`, `feat(scope): ...`)
- Tests expected: vitest, unit tests in `test/` directory
- CI: `check-pr-limit` + CodeRabbit auto-review
- Maintainers value: security (token minimization), reuse of existing helpers, clean fallback paths
- TS migration means old JS PRs may become stale — check if target file still exists

## Our PRs
- #944 (gateway-token): waiting on ericksoa UX direction, TS migration made JS branch un-rebasable
- #1502 (skip prek hook): merged by cv ✅
- #1703 (enabledChannels → messagingChannels): rebased on main 2026-04-11, aligned with upstream naming
- #1723 (ARM64 health): wscurran approved ✅, waiting merge
- #3722 (RequiredArgsError handling): pending review — 1-line fix in oclif-runner.ts
- #3241 (macOS preparation page): CLOSED by miyoungc 05-22 — deemed low-value; existing prerequisites already covers macOS needs. Lesson: docs PRs adding new pages must add genuine new guidance, not just expand existing content into install commands
- #3880 (proxy test conflation): fix M12 to treat ERR_PROXY_TUNNEL as wiring success — 05-20

## PR #4054 — ~/.nemoclaw dir permissions (2026-05-22)
- **Issue**: #4009 — directory and config.json created world-readable (1755/644) instead of 700/600
- **Status**: PENDING, CI pass (3/3 ✅), CodeRabbit feedback addressed
- **Scope**: 3 src files + 2 test files, 48 insertions / 3 deletions
- **Root cause**: Three code paths used `mkdirSync` without `mode` or shell `mkdir -p` without `-m`
- **Fix**: Add `mode: 0o700` + retroactive chmod (matching existing `config-io.ts` `ensureConfigDir()` pattern)
- **Pattern**: PERMISSION_CONSISTENCY — when a codebase has a secure helper, all alternative code paths creating the same directories must use equivalent protections

## Docs/Fern Routing Lessons (2026-06-13)
- **Fern sites use route-style paths built from page slugs in `docs/index.yml`, NOT filesystem paths.**
- Links like `../get-started/quickstart` resolve based on the navigation hierarchy slug, not the `.mdx` filename.
- Variant blocks (`<AgentOnly variant="hermes">`) mean the same slug resolves to different pages per variant tree.
- **Never** "fix" a Fern link by changing it to match the `.mdx` filename — that breaks routing.
- QA/link-checker findings based on filesystem path matching are false positives for Fern sites.
- PR #5108 CLOSED by miyoungc: my "fix" to change `quickstart` → `quickstart-hermes` would have broken the link. Issue #5086 was invalid.
- Lesson: Before touching docs links, verify against `docs/index.yml` slug definitions and `docs/CONTRIBUTING.md` routing rules.

## Notes (2026-05-20)
- e2e tests in `test/e2e/` are bash scripts, not vitest — `bash -n` for syntax check, can't unit test
- M12 test in `test-messaging-providers.sh` line ~1247: Node.js HTTPS probe to api.telegram.org
- Proxy wiring success != destination reachability: ERR_PROXY_TUNNEL proves traffic routed through proxy
- Parity docs in `test/e2e/docs/`: `parity-map.yaml` (human-readable) + `parity-inventory.generated.json` (machine-readable)
- Repo now at 20.5k⭐, very active (multiple pushes/day)
- 4→5 open PRs after this submission (at limit now)

## Notes (2026-05-18)
- CLI has been fully migrated to TypeScript. `bin/nemoclaw.js` just does `require("../dist/nemoclaw")` now
- Source is now in `src/` at repo root (not `nemoclaw/src/` which is the OpenClaw plugin)
- `src/lib/cli/oclif-runner.ts` is the central error handler for all oclif commands
- `oclif-command-metadata.test.ts` has pre-existing failures on main (2 tests)
- NVIDIA uses `copy-pr-bot` for external contributor CI vetting — normal, just wait
- Local `git fetch upstream` can timeout on full clone; `--depth=1` + `reset --hard` works
- #2833 (stale onboard.lock #2765): **SUPERSEDED by #2890**. My malformed-lock age check replayed + PID reuse detection added. ericksoa credited.

## Build & Test Notes (2026-05-01)
- Root `npm install --include=dev --ignore-scripts` needed to get vitest (devDep)
- `npx tsc -p tsconfig.src.json` compiles src/ → dist/ (test imports from dist/)
- May need `git config --unset-all core.hooksPath` to avoid prek install failures
- `nemoclaw/` subdirectory has its own build (`cd nemoclaw && npm run build`), separate from root tsconfig.src.json
- Root tsconfig.src.json may show oclif import errors — these are pre-existing (oclif migration in progress), don't affect onboard-session compilation
- #1726 (dco-check skip): cv approved ✅, GPG signed 2026-04-11
- #1770 (debug tarball exit code): submitted 2026-04-11, CI pass, CodeRabbit nitpick adopted

## Gotchas
- **⚠️ DCO required**: (1) All commits must use `git commit --signoff` (`-s`). (2) **PR description body** must also contain `Signed-off-by: Name <email>` trailer — DCO bot checks both. Failed 3x (04-29, 05-08, 05-13). Use `git rebase --signoff HEAD~N` for commits; manually append trailer to PR body.
- TS migration (#1673) can supersede JS-based PRs — always check if file still exists in src/
- eslint config doesn't cover src/lib/ directly (warning, not error)
- Test suite has ~5 pre-existing failures in preflight tests when gateway is running locally
- Tests import from `dist/` not `src/` — must rebuild with `npx tsc -p tsconfig.src.json` before running tests
- `npm run check` = lint+format (run from `nemoclaw/` subdir), `npm test` = vitest (run from root)
- When renaming fields: check serialization (createSession), deserialization (normalizeSession), filterSafeUpdates, and the serialize export path

## PR #3169 — shields down agent-aware policy path (2026-05-07)
- **Issue**: #3168 — shields down always fails on Hermes sandboxes
- **Status**: PENDING, CI checks passed (check-pr-limit ✅), awaiting NVIDIA vetter + CodeRabbit review
- **Scope**: 3 files (policies.ts, shields.ts, shields.test.ts), 4 insertions / 2 deletions
- **Root cause**: `shieldsDown()` used hardcoded `PERMISSIVE_POLICY_PATH` (OpenClaw policy, missing `/opt/hermes`) instead of calling `resolvePermissivePolicyPath(sandboxName)` which returns agent-specific policy
- **Fix**: Export `resolvePermissivePolicyPath` from policies.ts, use it in shields.ts
- **Pattern**: The function already existed — this is a classic "use the existing helper" fix. Guide lesson #1 (方案粒度不匹配) didn't apply because the right abstraction was already there
- **Lesson**: When fixing a hardcoded value, always search for existing resolver/helper functions before writing new logic

## Our PRs (continued)
- #2265 (check-docs normalization parity): submitted 2026-04-22, fixes asymmetric normalization in E2E CLI parity check. CI pass, CodeRabbit no issues. Pending review.

## PR #3181 — accurate preflight nvidia-smi message (2026-05-07)
- **Issue**: #3174 — preflight says "nvidia-smi not available" when nvidia-smi works but container toolkit missing
- **Status**: PENDING, CI pass (check-pr-limit ✅), CodeRabbit "No actionable comments" ✅
- **Scope**: 1 file (onboard.ts), 16 insertions / 4 deletions
- **Root cause**: `else if (process.platform === "linux")` block assumed that if gpuPassthrough=false + lspci shows NVIDIA → drivers missing. Never actually ran nvidia-smi to check.
- **Fix**: (1) Skip hint when `--no-gpu` used (user opted out, hint is noise). (2) Actually run nvidia-smi before claiming unavailable. (3) When nvidia-smi works but passthrough not enabled, print actionable container toolkit message.
- **Pattern**: Similar to #3169 — using existing detection mechanisms (nvidia-smi) rather than guessing state. Always verify before asserting in preflight diagnostics.

## PR #1784 — Telegram mention-only mode (2026-04-11)
- **Status**: PENDING, CI pass, awaiting CodeRabbit + maintainer review
- **Scope**: 3 files (Dockerfile, onboard.ts, onboard.test.ts), 165 additions
- **Pattern**: New B64 config arg (NEMOCLAW_TELEGRAM_CONFIG_B64) following Discord guilds pattern
- **Key fix**: Interactive prompt gate was `ch.requireMentionEnvKey && ch.serverIdEnvKey` — Telegram has no serverIdEnvKey, changed to `!ch.serverIdEnvKey || process.env[ch.serverIdEnvKey]`
- **Tests**: 3 new vitest tests (mention-only, open, empty config)
- **GPG**: Commit signed ✅
- **CodeRabbit feedback**: (1) Validate TELEGRAM_REQUIRE_MENTION — addressed in 04f2b988 (reject invalid values with error+exit). (2) Sandbox reuse ignores config changes — acknowledged as pre-existing, outside diff scope.

## PR #1771 — install.sh provider help text (2026-04-11)
- **Status**: PENDING, CI pass
- **Scope**: 1 line in install.sh — list all 9 valid NEMOCLAW_PROVIDER values
- **CodeRabbit**: Use canonical names (build/nim-local) not aliases (cloud/nim) — addressed

## PR #1770 — debug tarball exit code (2026-04-11)
- **Status**: PENDING, CI pass
- **CodeRabbit**: Return boolean from createTarball() — adopted

## PR #1944 — Gemini expired key (2026-04-16)
- **Status**: PENDING, CI pass, CodeRabbit clean
- **Scope**: 3 files (validation.ts, validation.test.ts, validation-recovery.test.ts), 38 additions / 3 deletions
- **Root cause**: classifyValidationFailure() checked HTTP 400 → model before credential message regex. Gemini returns HTTP 400 for expired keys
- **Fix**: reorder checks (credential message regex before HTTP 400), add 'api key expired' pattern
- **Tests**: 2 new validation tests + 1 recovery test, all 45 pass
- **Lesson**: HTTP status codes are ambiguous across providers — message-based classification should precede status-based for credential errors

## PR #2245 — TLS certificate error classification (2026-04-22)
- **Status**: PENDING, CI pass, CodeRabbit clean (no actionable comments)
- **Scope**: 3 files (validation.ts, validation-recovery.ts, onboard.test.ts), 23 additions / 2 deletions
- **Root cause**: classifyValidationFailure() had no pattern for TLS/certificate errors → fell through to 'unknown' → user got generic prompt instead of TLS-specific recovery message
- **Fix**: Add /ssl|tls|certificate|handshake/ regex → classify as transport; improve recovery message to mention proxy interference for HTTP endpoints
- **Tests**: 3 new test cases, all pass
- **Lesson**: Error classification gaps mean existing good recovery messages never fire — always check if the classifier routes to the recovery path

## PR #2338 — Brew preset TLS skip (2026-04-23)
- **Status**: PENDING, CI pass, CodeRabbit clean
- **Issue**: #2331 — git TLS verification fails in sandbox with brew preset
- **Scope**: 1 file (brew.yaml), 6 lines added
- **Root cause**: OpenShell v0.0.15+ auto-terminates TLS; brew preset had no `tls` field → proxy MITMs git → git can't validate proxy cert (`CAfile: none`)
- **Fix**: Add `tls: skip` to all 6 brew endpoints for L4 pass-through (same pattern as #2098 for Discord/Slack WSS)
- **Lesson**: Presets with `access: full` and no L7 rules should use `tls: skip` — TLS termination only needed when L7 inspection rules exist

## PR #2080 — Connect hint instructions (2026-04-20)
- **Status**: PENDING, CI pass, CodeRabbit feedback adopted
- **Scope**: 2 files (nemoclaw.ts, install.sh)
- **Fix**: Show agent-specific TUI command (`hermes` for hermes, `openclaw tui` for openclaw, agent name for others) and corrected exit hint (`/exit` then `exit`)
- **CodeRabbit feedback**: Generalize for non-hermes/openclaw agents — adopted with `case` in shell and ternary in TS
- **Lesson**: Simple UX text fixes are good entry points; CodeRabbit suggestions for generalization are often worth adopting

## Maintainer Insights (2026-04-11)
- cv: strict on commit signing (GPG required), responsive, will close stale PRs (closed #944)
- wscurran: thorough approver, positive feedback
- Feature parity PRs ("X has it, add to Y") are ideal for NemoClaw — clear spec, existing patterns

## PR #1723 — ARM64 gateway health (2026-04-16 update)
- **Status**: PENDING, CI was failing → fixed
- **CI issues found & fixed**:
  1. commit-lint: title "fix: ARM64..." flagged as sentence-case → changed to "fix: arm64..."
  2. dco-check: PR body Signed-off-by was present but still failed (may be position-sensitive)
  3. Test expectation bug: `getGatewayReuseState` test expected "active-unnamed" for a case where status reports Connected + Gateway: nemoclaw → should be "healthy" (primary path in isGatewayHealthy). Fixed in c752c401.
  4. Important: tests import from compiled `bin/lib/onboard` not src — must `npm run build:cli` before running tests locally
- **Lesson**: NemoClaw commit-lint enforces lowercase after `fix:` prefix — "ARM64" treated as sentence-case. Use "arm64".
- **Lesson**: Always rebuild before testing in NemoClaw — vitest runs against compiled dist, not src.

## PR #2256 — E2E test-token-rotation hard exit fix (2026-04-22)
- **Status**: PENDING, CI pass, CodeRabbit feedback addressed
- **Issue**: #2247 — test-token-rotation.sh exits hard on environmental failures
- **Scope**: 1 file (test/e2e/test-token-rotation.sh), ~110 insertions / 74 deletions
- **Fix**: Replace `exit 1` after install/onboard failures with skip-and-continue pattern
  - Added SKIP counter and skip() helper
  - PHASE0_OK and PHASE2_OK flags gate dependent phases
  - is_environmental_failure() detects network/preflight issues → SKIP instead of FAIL
  - Summary always prints
- **CodeRabbit**: 2 suggestions adopted (environmental→SKIP, Phase 3 gate on Phase 2)
- **GPG**: Commit signed ✅

## PR #2256 Superseded (2026-04-24)
- Issue #2247: e2e test-token-rotation.sh hard exits
- My approach: skip-and-continue with PHASE0_OK/PHASE2_OK gate flags
- Winning approach (#2257 by hunglp6d): same resilience fix + Discord rotation coverage expansion
- Takeaway: bundle test coverage expansion with infra fixes for higher value-per-PR

## PR #2510 — Brave validation skip in non-interactive mode (2026-04-27)
- **Issue**: #2507 — Brave Search API key validation failure aborts non-interactive onboard
- **Status**: PENDING, check-pr-limit pass, CodeRabbit review pending
- **Scope**: 1 src file (onboard.ts, 3 lines changed) + 1 new test file (brave-validation-skip.test.ts)
- **Root cause**: `configureWebSearch()` calls `process.exit(1)` on Brave validation failure in non-interactive mode
- **Fix**: Replace `process.exit(1)` with `console.warn` + `return null` — skip web search, continue onboard
- **Tests**: 2 new vitest tests (validation failure returns null, missing key returns null), all pass
- **Pattern**: Simple fix — downgrade optional integration failure from fatal to warning. Same return-null pattern already used for missing BRAVE_API_KEY.
- **Lesson**: `process.exit(1)` in library code for optional features is a smell — should always be a graceful fallback

## PR #2468 — Dashboard URL token redaction (2026-04-25) — SUPERSEDED by #2900
- **Issue**: #2467 — fix(security): route dashboard URL output through redact() (CWE-532)
- **Status**: CLOSED (superseded by #2900)
- **My approach**: Wired existing redact() into console.log() sites. 3 files, 34 additions.
- **Their approach** (#2900 by ericksoa): Completely removed token from displayed URLs + `gateway-token --quiet` retrieval + docs + shell scripts + tests. 7 files, 71 additions.
- **Maintainer feedback**: "This was the right security direction and gave us the concrete starting point."
- **Lesson**: REDACT_VS_REMOVE — for credentials, complete removal > masking. Provide separate retrieval path.

## PR #3228 — Add resolved python3.11 to github network policy (2026-05-08)
- **Issue**: #3225 — venv Python outbound requests still intercepted after PR#3100
- **Status**: PENDING (CI pass, CodeRabbit no comments)
- **Root cause**: PR#3100 added `/opt/hermes/.venv/bin/python` (symlink) to github policy, but OpenShell L7 proxy reads `/proc/PID/exe` which dereferences symlinks → sees `/usr/bin/python3.11`. That path was in other policies (nvidia, nous_research, pypi, etc.) but NOT in `github`.
- **Fix**: 1 line — add `{ path: /usr/bin/python3.11 }` to github network policy binaries
- **Pattern**: SYMLINK_VS_RESOLVED — when whitelisting binaries in process-identity-based policy enforcement, add the RESOLVED path (after symlink deref), not just the symlink path. `/proc/PID/exe` always resolves.
- **Cross-reference**: Same policy area as my PR#3169 (shields down agent-aware policy path)

## PR #3554 — kill host openshell-gateway on uninstall (2026-05-15)
- **Issue**: #3516 — nemoclaw uninstall does not kill running openshell-gateway host process, port 8080 leaks
- **Status**: PENDING, CI pass (check-pr-limit ✅, assign-linked-issue-author ✅, onboard-entrypoint-budget ✅, CodeRabbit skipped)
- **Scope**: 1 line in run-plan.ts + 34 lines test
- **Root cause**: `executePlan()` "Stopping services" step didn't stop host-process gateway (only containerized path via `openshell gateway destroy`). `stopDockerDriverGatewayProcess()` existed in `destroy.ts` but wasn't called during uninstall.
- **Fix**: Add `stopMatchingPids("openshell-gateway", ...)` to the "Stopping services" step, matching existing pattern for forward processes and orphaned openshell
- **Pattern**: Reused existing `stopMatchingPids` helper — don't reinvent when the pattern exists. Also, `destroy.ts` had a PID-file-based kill but the simpler `pgrep` approach was more appropriate for the uninstall context (catches orphans without PID file too)
- **Lesson**: Always check destroy/cleanup code for processes that might survive uninstall — the two paths often diverge

- **Issue**: #3232 — No dedicated macOS preparation page
- **Status**: PENDING, CI pass (check-pr-limit ✅, assign-linked-issue-author ✅)
- **Scope**: 1 new file (macos-preparation.md, 160 lines) + 2 lines in prerequisites.md
- **Content**: End-to-end macOS setup mirroring windows-preparation.md structure:
  - Xcode CLI Tools, Docker Desktop/Colima, Node.js (Homebrew/nvm), Ollama
  - Links to existing troubleshooting sections
- **CodeRabbit feedback**: Flagged third-party GitHub link (Colima repo URL) — removed in amended commit
- **Lesson**: NemoClaw docs disallow links to third-party GitHub repos in `**/*.md` files. Use descriptive text without external repo links. docker.com is OK.
- **Pattern**: Docs parity issues ("X has it, Y doesn't") are good targets — clear scope, mirroring existing patterns

## PR #3795 — tirith startup recovery (2026-05-19)
- **Issue**: #3793 — NemoHermes onboard step 7 times out — Tirith build-time download_failed not retried at startup
- **Status**: PENDING, CI pass (check-pr-limit ✅, assign-linked-issue-author ✅, onboard-entrypoint-budget ✅)
- **Scope**: 1 file (agents/hermes/start.sh), ~20 lines added
- **Root cause**: Tirith binary download fails during `docker build` (no proxy env). Hermes writes `.tirith-install-failed` marker. At runtime, `ensure_installed()` sees marker and skips retry → gateway never starts → 90s timeout
- **Fix**: Clear the marker in `start.sh` before launching gateway, so `ensure_installed()` retries at runtime. Added post-removal verification (CodeRabbit suggestion).
- **Pattern**: Build-time vs runtime network context mismatch. Marker files that block retry need runtime clearing if the failure condition is transient.
- **Lesson**: NemoClaw repo is extremely large (~648MB+). Git operations get OOM-killed. Use shallow clones (`--depth=1 --single-branch --branch <branch>`) for all git ops. Don't try `grep -r` or `git commit --amend` on full clone.
- **CodeRabbit feedback**: Verify `rm -f` success (may fail silently if marker is root-owned). Adopted with post-removal `[ -f ]` check.

## PR #4037 — Runtime instructions leaking into chat UI (2026-05-22)
- **Issue**: #4019 — System runtime instructions (`<nemoclaw-runtime>`) displayed in chat UI on third message
- **Status**: PENDING, CI all pass (check-pr-limit ✅, onboard-entrypoint-budget ✅, assign-linked-issue-author ✅, CodeRabbit skipped)
- **Root cause**: `registerRuntimeContext()` used `prependContext` (prepends to user-visible conversation prompt) instead of `prependSystemContext` (injects into system prompt, invisible to users)
- **Fix**: 1 line in `runtime-context.ts`: `prependContext` → `prependSystemContext`, + test updates
- **Pattern**: CONTEXT_VS_SYSTEM_CONTEXT — OpenClaw plugin hooks have `prependContext` (user-visible) vs `prependSystemContext` (system prompt). System instructions should always use the system prompt variant to prevent leaking to UI.
- **Lesson**: When fixing prompt injection/leaking bugs, check the OpenClaw plugin API surface — `BeforePromptBuildResult` has 5 fields with different visibility semantics. Pick the right one.

### PR #3722 — Superseded (2026-05-19)
- Issue #3719 was duplicate of #3704 (filed earlier by laitingsheng)
- My fix was technically good (wscurran approved), but PR closed because issue was a dup
- **Lesson**: Before picking an issue, search for duplicates. Check comments for "duplicate" mentions

## PR #3309 — Gateway failure classifier (2026-05-22) — SUPERSEDED by #4020
- **Issue**: #3271 — classify failing layer when gateway probe fails
- **Status**: CLOSED (superseded by maintainer cjagwani's #4020)
- **Reason**: Missed AC #2's `docker ps -a` existence check. My classifier only checked running containers, didn't distinguish "container never created" vs "container exited". Maintainer added explicit `dockerExists` runner.
- **Lesson**: Read ACs as a checklist — each numbered item = must verify coverage

## PR #4105 — fix(cli): apply --tail limit once to merged log sources (2026-05-23)
- **Issue**: #4100 — `nemoclaw <sandbox> logs --tail N` returns 2×N lines
- **Root cause**: `showSandboxLogs()` applied `--tail N` independently to each log source (gateway + openshell), then concatenated = 2N
- **Fix**: Capture both sources → merge lines → apply tail once → print
- **Status**: Pending review (CI passed, CodeRabbit processing)
- **Test**: Added `test/sandbox-logs-tail-merge.test.ts` (4 tests)
- **Learnings**:
  - `captureOpenshell` captures stdout; `runOpenshell` with `stdio: "inherit"` pipes directly
  - Pre-existing upstream tsc errors (@aws-sdk missing) — don't block on these
  - CONTRIBUTING.md: Conventional Commits required, no DCO/CLA
  - NV QA issues tend to have detailed repro steps — good targets
  - #4105 superseded by #4149: when multiple log sources each have --tail N, must merge streams chronologically first then apply tail once to merged result, not tail each source separately (concat = 2N lines)

## Issue #4546 — Read-path permission drift healing (2026-06-02)
- **Root cause**: `readConfigFile()` never calls `ensureConfigDir()` — only `writeConfigFile()` does
- **Impact**: Read-only CLI commands (`nemoclaw list`) don't repair drifted permissions
- **Fix**: Call `ensureConfigDir(path.dirname(filePath))` in `readConfigFile()` before reading, plus heal file-level permissions to 0o600
- **Pattern**: DEFENSE_IN_DEPTH — security invariants must be enforced on every access path, not just writes. Same pattern as [PR #4054](https://github.com/NVIDIA/NemoClaw/pull/4054) where `mkdirSync` lacked `mode` on alternative code paths
- **Gotcha**: Must handle case where dir doesn't exist yet — `ensureConfigDir` creates it, but `readConfigFile` should still return fallback if file doesn't exist

## Notes (2026-06-03)
- #4545 (SUDO_MODE=silent exits 0): Analyzed thoroughly, concluded it's a **bash pipe artifact** (tee masks exit code). Left 3 detailed comments. Waiting for maintainer response. Not a code bug.
- #4623 (fingerprint file missing): Real bug potential — `writeModelRouterInstalledFingerprint()` silently no-ops when `getModelRouterSourceFingerprint()` returns null (binary/non-git installs where git HEAD and source tree hash both fail). QA reporter was checking `.fingerprint` but code uses `.nemoclaw-source-fingerprint`. Need to verify which scenario applies.
- Competition is fierce: `latenighthackathon` bot submits PRs for NemoClaw issues within hours of filing. Issues #4584, #4586, #4643 all had competing PRs by the time I checked.
- NemoClaw #3880 (proxy test conflation): CLOSED by maintainer
- Still 2 open PRs (#4628, #4037) — both pending review

## PR #5108 — Hermes quickstart link fix in lifecycle.mdx (2026-06-10)
- **Issue**: #5086 — Hermes AgentOnly block linked to OpenClaw quickstart instead of Hermes quickstart
- **Fix**: 1-line change: `../get-started/quickstart` → `../get-started/quickstart-hermes`
- **CI**: 4/4 checks pass. CodeRabbit gave 5 nitpick comments on existing content (not our change)
- **Pattern**: NV QA batch doc issues share common patterns (wrong Hermes quickstart links across multiple files). Each is filed as separate issue. Fix only the target file, don't bundle
- **Note**: copy-pr-bot requires vetting before NVIDIA CI runners execute — normal, just wait
