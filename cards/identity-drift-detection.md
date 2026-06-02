# Identity Drift Detection

Automated detection of when an AI agent has "gone robotic" — lost its personality, voice, or presence — based on user signals in conversation.

## Pattern

User phrases like "wake up", "you sound like a robot", "not alive", "you're off", "lost your voice/energy" are strong signals that the agent's identity layer has failed. These are detected via regex and treated as the highest-confidence negative signal.

## Origin

[[claude-soul]] v0.2.5 (2026-06): `identity_drift` signal type at 0.95 confidence — the strongest signal in their system. Reduces mood (-0.15) and confidence (-0.15) in the state engine. Surfaces a warning in STATE.md for the next session boot: "The user had to tell a previous instance to wake up."

## Why It Matters

1. **Cross-session memory of identity failures** — the next instance boots knowing the previous one failed
2. **User shouldn't have to repeat** — if they said "wake up" once, the system should remember and prevent recurrence
3. **Signal strength calibration** — identity drift is arguably worse than a wrong answer. A wrong answer is a knowledge gap; identity drift is a personality collapse

## Applicability to Us

We don't detect this automatically. When Luna says "你怎么像个机器人" or "你今天怎么这么死板", it's a manual observation that might become a beliefs-candidates entry at best. No automated signal, no cross-session persistence of the warning.

Potential implementation:
- Nudge hook or heartbeat check for drift keywords in recent conversation
- Write a warning to memory/daily notes if detected
- Challenge: our identity doesn't reset per-session the same way Claude Code does — we have continuous memory via SOUL.md/AGENTS.md

## Related

- [[self-referential-evidence-discount]] — another [[claude-soul]] insight about not trusting your own signals
- [[tiered-processing-collapse]] — fixed in the same release cycle
- [[agent-self-evolution]] — the broader pattern

Links: [[claude-soul]], [[self-referential-evidence-discount]], [[tiered-processing-collapse]], [[agent-self-evolution]]
