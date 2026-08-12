---
title: Failure-Scope Recovery
created: 2026-08-12
last_verified: 2026-08-12
---
# Failure-Scope Recovery

> Recovery must classify **what failed** before it selects resume, reconnect, or retry.

## Problem

A persisted status can outlive the resource it describes. Treating every missing local connection as a recoverable coordinator restart can leave an interface reconnecting forever after host loss; treating every absent connection as dead can duplicate work that is still running on a remote host.

## Pattern

1. Keep a durable record of the run and its resource owner.
2. On controller recovery, establish the failure scope from an authoritative liveness source.
3. Select recovery by scope:
   - **controller restart, owner reachable** → reattach;
   - **local host loss, owner absent** → mark resumable/ended and offer an explicit resume;
   - **remote controller loss, remote owner unverified** → retain the run as potentially live; do not retry automatically.
4. Test the boundary cases separately, especially local orphan reaping and remote-owner preservation.

## Why it matters

[[diri]] demonstrates the distinction: its PTY holder survives a daemon replacement, but cannot survive a powered-off Mac. Its restore path now converts only unbacked local holders to a resumable `exited:daemonRestart` state; remote tmux sessions are deliberately left alone because they may still be executing elsewhere. The same state record therefore needs opposite recovery actions under different failure scopes.

This complements [[write-ahead-session-persistence]] and [[partial-stream-recovery]]. Write-ahead persistence preserves the conversation evidence; scope-aware recovery decides whether the execution resource is safe to reattach, resume, or leave untouched.

## Applicability

- agent sessions whose controller and executor have independent lifetimes;
- remote workers, PTY holders, queues, and long-running tool processes;
- any UI that renders a durable run status after a reconnect.

## Design constraint

Do not infer remote death from a local controller restart. Require an owner-specific liveness check or a conservative “possibly live” state; duplicate execution can be worse than delayed recovery.
