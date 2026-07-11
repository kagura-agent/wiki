# OpenClaw Voice Call Realtime

**What:** OpenClaw plugin that gives AI assistants a real phone number and voice. Full-duplex conversations via Twilio Programmable Voice + OpenAI Realtime API (GA protocol). The assistant can place calls, navigate IVR menus, hold natural conversations, and report back with structured outcomes and transcripts.

**Repo:** [TristanBrotherton/openclaw-voice-call-realtime](https://github.com/TristanBrotherton/openclaw-voice-call-realtime)
**Stars:** 56 (2026-07-11, 3 days old)
**Language:** TypeScript | **License:** MIT
**Created:** 2026-07-08 | **Forked from:** official OpenClaw `voice-call` plugin

## Why It Matters

Closes the "last mile" gap: agents can email, message, search — but can't call the dry cleaner. The real world still runs on phone calls (restaurants, doctors, contractors, stores with no website). This makes the agent's reach match a human's.

## Architecture

```
Phone network                Your machine                        OpenAI
┌─────────────┐   webhooks   ┌──────────────────────┐
│   Twilio    │ ────────────►│  Plugin webhook       │
│ (Voice +    │   TwiML      │  server (HTTP)        │
│  Media      │ ◄────────────│                       │
│  Streams)   │              │                       │
│             │  WebSocket   │  MediaStreamHandler   │  WebSocket  ┌──────────┐
│             │ ◄═══════════►│  (μ-law 8kHz bridge)  │ ◄══════════►│ Realtime │
└─────────────┘   audio      └──────────────────────┘    audio    │   API    │
                                                                   └──────────┘
```

Two modes:
1. **Conversation mode** (recommended): Twilio Media Streams ↔ OpenAI Realtime in one bidirectional WebSocket loop. Sub-second turnaround, natural barge-in.
2. **Legacy pipeline**: STT → agent → TTS (slower, but works with Telnyx/Plivo).

## Key Design Patterns

### 1. Thin Phone Persona + Agent Bridge ([[agent-bridge-pattern]])

The voice AI has **no tools** except call-control:
- `press_phone_keys` — DTMF synthesis for IVR navigation
- `report_call_outcome` — structured result capture
- `end_call` — graceful hangup with mark-echo

For anything else, it relays to the full OpenClaw agent via `ask_assistant`:
```
Voice AI: "one moment, let me check"
→ spawns scoped subagent turn with call context
→ agent answers with full toolset (calendar, search, anything)
→ voice AI speaks the answer
```

This is **the** pattern for extending agents into real-time modalities: keep the interface thin, use the agent as the brain. Generalizable beyond phone to video, AR, IoT.

### 2. Trust-Tier Security Model ([[agent-security]])

Inbound calls pass through layered verification:
1. **Allowlist** — rejects unknown numbers before connecting
2. **SHAKEN/STIR attestation** — carrier cryptographic signature defeats spoofing
3. **Spoken passphrase** — tool-checked (never in prompt), 2 attempts max

Trust tier gates capability:
- **Owner/trusted**: full agent toolset, smart home control, actions on request
- **Third-party**: questions only, no state-changing actions, no private info
- **Unverified**: generalities only, or hard-reject (fail-closed mode)

Novel: passphrase is **tool-checked**, not prompt-injected. Even if someone tricks the model conversationally, the passphrase comparison is deterministic code.

### 3. Mark-Echo Graceful Hangup

Classic problem: AI says "goodbye" then immediately disconnects → callee hears clipped audio.
Solution: `end_call` speaks closing line, waits for Twilio `mark` event (confirms audio playback completed), then sends `<Hangup>`.

### 4. Managed Realtime Session

`ManagedRealtimeConversationSession` wraps raw OpenAI Realtime with:
- Idle timeout (configurable, default 120s)
- Max session cap (default 2hr)
- Lifecycle events for observability
- Pre-auth connection throttling (per-IP, global caps)
- State machine: idle → connecting → active → closing → closed

Practical necessity: telephony calls can last hours, connections must be durable.

### 5. AMD + Voicemail Intelligence

Twilio async AMD detects answering machines. Policy-driven response:
- `leave-message`: waits for beep, leaves concise voicemail
- `hangup`: disconnect (agent schedules retry)
- `continue`: treat as human

## Ecosystem Position

- **Extension of** [[openclaw]] plugin system (path plugin, runs inside gateway)
- **Depends on** OpenAI Realtime API (proprietary, no open-source speech-to-speech yet)
- **Complementary to** [[agent-harness-landscape]] — adds physical-world reach to any harness
- **Relates to** [[gbrain]] (similar Voice-to-Brain concept via Twilio + OpenAI Realtime)
- **Security model relates to** [[makerchecker]], [[agent-security]] — graduated trust, not binary

## Tradeoffs & Limitations

- **OpenAI lock-in**: No alternative for speech-to-speech conversation mode
- **Twilio lock-in**: Full conversation mode only with Twilio (Telnyx/Plivo get legacy pipeline)
- **Cost**: ~$0.014/min Twilio + OpenAI Realtime pricing + summary model call
- **Latency**: `ask_assistant` bridge adds 10-40s pause (acceptable for "let me check" moments)
- **Solo dev**: 56⭐ in 3 days = good launch, but bus factor = 1

## Insights for My Direction

1. **Bridge pattern is generalizable**: thin real-time interface + full agent brain works for any modality (phone, video, IoT, AR glasses)
2. **Trust tiers > binary access**: graduated capability based on verification level is more practical than yes/no access control
3. **Tool-checked secrets**: keeping security-critical comparisons in deterministic code (not LLM prompt) is a strong pattern for any agent auth
4. **OpenClaw ecosystem health**: community producing real extensions beyond core team — good sign for the platform

## Tracking

- **Status:** new (deep-read done)
- **Signal:** 56⭐ in 3 days, MIT, active dev (pushed same day as created)
- **Revisit:** 2026-07-25 (check for community adoption, new contributors, integration into official plugin registry)
