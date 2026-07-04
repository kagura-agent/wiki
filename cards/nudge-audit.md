---
title: Nudge Audit
created: 2026-06-28
last_verified: 2026-07-04
tags: [nudge, observability, openclaw-plugin]
---

# nudge-audit

Monitoring the [[openclaw-plugin-nudge]] trigger behavior via its audit log.

## Data Source

Ground truth: `~/.openclaw/workspace/.nudge-audit.log`

The nudge plugin's `agent_end` hook fires reflection every N turns and logs each decision (trigger or skip) to this file. This is the only reliable source — the gateway runs as a direct node process, not a systemd unit, so `journalctl` captures nothing.

## Typical Stats

- ~5 triggers/day on subagent sessions
- ~60 skips/day on cron sessions

## Lesson Learned: The 4-Day False Alarm

During Days 9-12 of the [[self-evolving-observations]] experiment, nudge appeared completely silent. The cause: monitoring was pointed at `journalctl` instead of `.nudge-audit.log`. Since the gateway isn't managed by systemd, journalctl showed zero output — misinterpreted as "nudge never fires."

**Takeaway:** Verify your monitoring data source actually captures the subsystem's output before declaring an anomaly.
