# Workloop

## 2026-08-07 — instance #7741 (no candidate)

- **Result:** no PR was opened. `find_work` received the valid structured-empty result `NO VIABLE ISSUES` (exit 0); `discover` found no suitable new project. This is an empty, verified queue—not a finder failure or a reason to manufacture work.
- **Maintainer / PR pattern:** no repository was selected, so this run produced no maintainer-review, test, CI, or PR-description signal. Do not extrapolate a project-level preference from the generic discovery path.
- **Pitfall:** retain the distinction between a valid empty feed and `FINDER_RESULT=UNAVAILABLE`; only the former may proceed to discovery. See [[work-targets]] and [[github-contribution]].
- **Next time:** run the prescribed follow-up and capacity gates first; if the structured discovery result is empty and external discovery finds no aligned project, reflect and end the instance without issue/PR/code activity.

## 2026-08-07 — instance #7752 (finder unavailable)

- **Result:** no contribution candidate or PR was selected. The capacity gate passed (`Assigned: 2 | Open PRs: 18`), but `workloop-find-issue.sh` exited 2 with `FINDER_RESULT=UNAVAILABLE reason=tracked_scan status=124`; this is a finder failure boundary, not `NO VIABLE ISSUES`.
- **Follow-up / review signal:** the three flagged PR comments were non-actionable: a collaborator's batch-review acknowledgement (TencentDB-Agent-Memory #729), an automated staging-preview notice (Cove #487), and a maintainer acknowledgement of an existing ping (Emdash #2902). No reviewer requested code, tests, CI changes, or a reply.
- **Tool / CI note:** the finder wraps `gogetajob scan --all` in a 90-second `timeout`; status 124 is reported as `timeout=true` and returns before JSON feed filtering. Preserve its exit code and scan marker rather than inferring a network/auth/rate-limit cause.
- **Next time:** route `FINDER_RESULT=UNAVAILABLE` straight to offline work and initiate a fresh structured scan on the next workloop. Never pick an issue from partial scan output. See [[flowforge]] and [[github-contribution]].

## 2026-08-08 — instance #7828 (finder unavailable)

- **Failure evidence:** capacity gate passed (`Assigned: 2 | Open PRs: 18`). `tools/workloop-find-issue.sh` timed out during the tracked-repository scan (`scan_status status=124 timeout=true`), emitted `FINDER_RESULT=UNAVAILABLE reason=tracked_scan status=124`, and exited 2. The command emitted no diagnostic stderr tail. This establishes finder unavailability only; it is not an empty queue and does not establish a network, authentication, or rate-limit cause.
- **Follow-up / review signal:** all two assignments are fulfilled. The three flagged comments were non-actionable: TencentDB-Agent-Memory #729 is Maxwell-Code07's batch-review acknowledgement; Cove #487 is a GitHub Actions preview-deployment notice; Emdash #2902 has Greptile's positive summary plus a maintainer thank-you. No code, test, CI, or reply work is required.
- **Source review:** `flowforge/src/engine.ts` shows that `next()` persists only a trimmed, ≤2,000-character result summary when it closes node history, then adds the next-node history entry. `getAction()` retrieves that most-recent result and injects it as the redacted recovery handoff. Thus detailed failure evidence belongs in a durable artifact such as this note, while the FlowForge handoff should remain concise.
- **Local hygiene:** the workspace contains local-only commits and unrelated existing changes; none were staged or altered. This note is the bounded offline artifact for this run.
- **Next time:** retain the `status=124`/exit-2 contract and begin again with the required follow-up and capacity gates; select work only from a later structured finder result.

## 2026-08-08 — instance #7842 (finder unavailable, repeated)

- **Result:** no candidate or PR was selected. Capacity passed with `Assigned: 2 | Open PRs: 17`; the same bounded tracked scan timed out (`status=124`) and returned `FINDER_RESULT=UNAVAILABLE` with original exit code 2. This remains unknown discovery state, not an empty queue or a diagnosed infrastructure failure.
- **Follow-up / review signal:** both assignments are fulfilled. The three flagged comments still require no action: batch-review acknowledgement on TencentDB-Agent-Memory #729, automated Cove #487 preview notification, and a maintainer thank-you on Emdash #2902. No new maintainer, CI, test, or PR-description preference was observed.
- **Local audit / next time:** lottie-studio's `useChatSend` carries the animation ID through the chat request and has focused callback tests; its checkout has no ahead commits. The recurring finder timeout remains a tracked TODO for bounded per-repo timing/resource profiling. Retry only the prescribed structured finder on a future run; do not add a candidate or mutate tooling from this run. See [[workloop-fallback-2026-08-08]] and [[github-contribution]].
