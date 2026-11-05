# Gym Checklist — product and delivery case study

## Problem and target user

People who already know what to train can still spend too much time navigating a workout tracker. Gym Checklist is a focused iPhone app intended to remove those steps. It does not try to prescribe training.

**Target journey:** Open → Today → complete each set with a tap → close.

## Hypothesis

If the workout is immediately visible and normal set completion takes one tap, people can track a workout with less navigation and distraction.

This is a product hypothesis, not a measured outcome. Formal usability/retention metrics have not been collected.

## Scope and trade-offs

**Kept in MVP:** Today checklist, Program calendar, one workout per day, plan copying/repetition, planned vs actual set values, offline cache, user accounts, Firestore owner isolation, appearance and kg/lb settings.

**Explicitly left out:** AI coaching, statistics dashboards, social sharing, nutrition, rest timers, HealthKit/Watch and Android. These would add complexity without improving the core Today interaction.

**Architecture trade-off:** One Firestore workout document per date simplifies the client and its offline model. Concurrent edits to the same date from two devices can overwrite one another. This remains a documented limitation rather than a proven multi-device merge solution.

## Delivery approach

The project uses product/UX specifications, a browser prototype, SwiftUI implementation, automated domain and UI contracts, Linux static/security checks and authoritative macOS/Xcode CI. GitHub PRs and exact-source checks separate implementation from validation. AI-assisted development is documented in the repository's process files; the product code and test results remain the authority.

## Metrics to measure

- **Primary experience:** time from app open to first set completion and taps/navigation steps per completed set.
- **Usage:** `set_completed` and `workout_completed` analytics events (instrumented; no usage numbers asserted).
- **Quality:** crash-free sessions, offline completion/reconnect success, owner-isolation correctness and failed-write recovery.
- **Acceptance:** real-iPhone interaction, accessibility and visual validation against approved mockups.

## Evidence and limitations

The repository contains unit/UI tests and recorded CI checkpoints; see [progress](progress.md) for specific SHA/run evidence and pending work. Physical-iPhone acceptance, live account-deletion backend and rejected-write rollback verification are not yet complete. This document does **not** claim the app is shipped, generally available or proven to improve retention.

## Next decisions

1. Resolve remaining Firebase dependency/CI lockfile reproducibility issues and verify the exact source build.
2. Run a full authoritative CI gate after independent audit.
3. Validate real-device gestures, login, persistence and offline/reconnect scenarios.
4. Decide on paid Apple and Firebase distribution only after functional MVP acceptance.
