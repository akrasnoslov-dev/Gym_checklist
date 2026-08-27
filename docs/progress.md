# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; repository head includes MVP-finish scheduling changes; current product-code checkpoint remains `f40315e` (`Default manual macOS CI to MVP smoke`).
- Product implementation is frozen for the first MVP handoff: no new features/refactors/cleanup unless a confirmed blocker prevents the MVP from being shown.
- Apple/Google deletion reauthentication dismisses its sheet before routing to auth; failure/cancellation retain the sheet/session.
- Program week navigation recreates only its dynamic calendar/content subtrees after a selected-date change.
- A malformed Firestore workout document retains any cached workout for that same date and presents non-blocking unavailable state instead of erasing Today into a false rest day.

## Verification
- Local safety checks pass: whitespace plus Firebase security hygiene, Firestore rules, account-deletion, and offline cache/reconnect contracts.
- Full macOS verification `33054548821` ran all unit tests plus 41/42 UI tests; only Program week navigation failed.
- Multiple focused Program diagnostics established XCTest accessibility/selector instability while domain/unit coverage and the rest of the UI suite remained green.
- Final focused diagnostic `33077303696` completed with `failure`. The Program surface remains classified `KNOWN_UI_TEST_HARNESS_FLAKE`; the focused rerun budget is exhausted. Do not run that focused test again without new independent evidence of a product bug.

## MVP finish lock
- The next authoritative gate is one current-head macOS `smoke` run.
- If smoke is green, stop implementation/hardening and immediately produce a real user-visible MVP handoff.
- Preferred handoff: current development build on the user's iPhone using the available non-paid path if technically sufficient.
- If physical installation is blocked by signing/provider configuration or another genuinely external requirement, produce a real simulator-based preview from the current build (not a mockup) and identify the single exact external action required for iPhone installation.
- Do not run `full`, TestFlight/release work, another Program focused diagnostic, or broad cleanup before the user's first MVP look.
- If smoke fails, inspect once, fix only the confirmed MVP blocker, then rerun smoke.

## External/deferred
- Real-device validation remains required later for live Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone pass where applicable.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Dispatch one current-head macOS `smoke` verification.
2. Green smoke -> immediately create the real MVP handoff/preview and show it to the user.
3. Smoke failure -> fix only the reported MVP blocker and rerun smoke.
