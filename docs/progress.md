# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; the user approved the 2026-09-04 post-acceptance scope expansion (profile/body weight/BMI, set types, repeat cadence, Month view, and the listed visual hierarchy work). It supersedes the former scope freeze for those items.
- Working checkpoint adds a lime/mint semantic theme; owner-scoped profile/body-weight persistence; explicit set types with legacy inference and completed actual-type preservation; 1–4-week repeat cadence; Month navigation sharing the repaired Program selection; and focused Program/Today/Settings polish.
- Current phase remains **pre-payment functional MVP acceptance**: no billing, paid Apple, TestFlight, App Store, or Blaze work.

## Latest verification
- Previous-scope evidence only: IPA run `33262381993` is green; it built source `ee579d0`. That workflow currently hard-codes this old source and must be updated only after the new final candidate SHA exists.
- Current static checks: Firestore owner-rule contract and account-deletion contract pass. Windows has no local Swift/Xcode toolchain.
- `CI_PENDING 33879273252`: `candidate` scope for `GymChecklistTests/ExpandedFeatureTests/testBodyWeightHistoryIsOwnerBoundAndSortedByMostRecentMeasurement` on exact source SHA `c9c4c241effa2839a6e84b4fe5238a368b3c05aa`; focused pass automatically proceeds to the full suite. Do not poll from this task.

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
1. Resume only after `33879273252` is terminal: process its concise failure summary or, if green, update the physical-IPA workflow to the final accepted source SHA and prepare the next device candidate.
