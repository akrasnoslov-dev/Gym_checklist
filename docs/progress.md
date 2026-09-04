# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; the user approved the 2026-09-04 post-acceptance scope expansion (profile/body weight/BMI, set types, repeat cadence, Month view, and the listed visual hierarchy work). It supersedes the former scope freeze for those items.
- Working checkpoint fixes the red candidate’s real defects: legacy mixed rep/weight/time documents retain raw plan and actual values through Firestore decode/re-save, current body weight is selected by applicable local date, and Program Week/Month is deterministically Monday-first. It also replaces generic Copy/Repeat forms and the top-level Settings list with the approved card hierarchy.
- Current phase remains **pre-payment functional MVP acceptance**: no billing, paid Apple, TestFlight, App Store, or Blaze work.

## Latest verification
- Previous-scope evidence only: IPA run `33262381993` is green; it built source `ee579d0`. That workflow currently hard-codes this old source and must be updated only after the new final candidate SHA exists.
- Current static checks: Firestore owner-rule and offline cache/reconnect contracts pass. Windows has no local Swift/Xcode toolchain.
- `33879273252` is terminal red on `c9c4c241effa2839a6e84b4fe5238a368b3c05aa`: build and focused body-weight test passed; full suite exposed the destructive legacy decoder, local-date ordering gap, Monday-first gap, and stale set/history UI expectations. Those fixes are in the uncommitted working checkpoint and require a new candidate run.

## CI operating rule
- During diagnosis: one focused `unit`/`ui` run per code change when needed.
- For the proposed fix: dispatch one `candidate` run with the exact blocker test filter.
- Do not separately run smoke before full.
- After dispatch, record run ID/scope/SHA and do not keep Codex alive polling. If no useful non-invalidating work remains, end the task immediately and resume after CI is terminal.
- A green `candidate` run is both focused blocker evidence and required full-suite evidence for that exact SHA.

## Free live-validation scope
Live Spark/device proof remains: email/password auth/reset/logout, Google Sign-In, Firestore persistence and two-user isolation, relaunch, offline cache/reconnect, Analytics, Crashlytics, accessibility, and free personal-device installation. This Windows workspace has neither an authenticated Firebase CLI nor Xcode; do not infer live proof from static contracts. The single prepared handoff is `docs/mvp_external_acceptance_handoff.md`.

## Paid/deferred
Apple Developer Program, TestFlight/App Store, paid release signing/secrets, Firebase Blaze/billing, live Cloud Function deployment if Blaze is required, paid-only Apple configuration, final release work, and `dev -> main`.

## Next action
1. Review/commit this checkpoint, then dispatch one candidate run against `GymChecklistTests/ExpandedFeatureTests/testLegacyMixedSetRoundTripsWithoutDiscardingPlanOrActualValues`; its full-suite stage is the required gate for the exact candidate SHA.
