# Workloop fallback — 2026-08-08 10:04 CST

## Finder evidence

- Command: `bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1`
- Result: `FINDER_RESULT=UNAVAILABLE reason=tracked_scan status=124`; wrapper exit code `2`.
- Retained scanner evidence: `scan_status status=124 timeout=true`, followed by `scan_unavailable status=124 timeout=true`. The captured stderr tail was empty.
- Boundary: this is a failed tracked scan, **not** evidence that the issue queue is empty, nor evidence for a network, authentication, or API-limit cause. FlowForge selected `fallback_offline`.

## Existing-work check

- `lottie-studio` has no commits ahead of its upstream tracking branch. Its only local change is the pre-existing untracked `playwright-report/` directory, left untouched.
- The current workspace root has unrelated pre-existing modifications; this fallback note is staged and committed by path only.

## Source reading: Lottie Studio chat response contract

Read `lottie-studio/src/hooks/chat/useChatSend.ts`.

- Every chat request serializes the current editor identity as `animationId: currentAnimationId` in the `/api/chat` POST body.
- A non-SSE response creates editor state when there is no current ID: it stores `data.animationId`, calls `onAnimationCreated`, then applies `lottieJson` through `onAnimationUpdated`.
- When an animation already exists, the fallback path uses `currentAnimationId` (or the returned ID as a fallback) and calls `onAnimationUpdated`. This preserves the two-turn edit path rather than creating a disconnected preview.
- This matches the existing #782 review-wait test contract. No implementation work is justified without a failed check or concrete reviewer request.

## Gradient review

Reviewed `beliefs-candidates.md` entries at the 3+ occurrence threshold. `flowforge-terminal-node-stuck` is already graduated to the FlowForge terminal-node auto-close mechanism (recorded there as the 2026-07-25 engine change). The finder-unavailable rule has just reached its third observation and is already enforced by the current `find_work` node's explicit `FINDER_RESULT=UNAVAILABLE` → `fallback_offline` branch. No separate candidate required promotion in this fallback.

## Maintenance note — resumed unavailable branches (13:02 CST)

When a resumed FlowForge instance reaches `fallback_offline` but the original finder stdout/stderr is unavailable, record only **发现不可用**. Do not reconstruct an exit code, guess a network/authentication/rate-limit cause, or convert it into an empty-queue result. The appropriate record is a dated artifact under `memory/workloop-fallback-*.md`.

For FlowForge itself, `engine.next()` intentionally preserves only a bounded redacted handoff summary (2,000 characters); raw diagnostic output must therefore be saved outside its SQLite history before a node is advanced. Its direct focused test command is `npm test` from the `flowforge/` repository.
