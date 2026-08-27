# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; rebased local `Harden Firestore cached snapshot recovery` checkpoint is ready to push.
- Current goal: complete the entire originally approved MVP before the next product review. The prior physical-iPhone preview was intermediate only; do not stop or solicit acceptance until the final MVP candidate is ready.
- The app contains the planned Program, Today, Settings, Firebase/auth, offline, Analytics, and Crashlytics paths. Remaining work is to reconcile their real implementation and verification against the approved MVP, fix confirmed gaps, and complete one final broad verification.
- Program week navigation rebuilds only dynamic calendar/content after date changes. Malformed Firestore workout snapshots preserve any cached workout and show a non-blocking unavailable state rather than a false rest day.
- Firestore workout listeners now receive metadata-only updates, so a recovered connection clears the stale sync-unavailable state. A successful cached snapshot, including an empty collection, is usable offline; malformed entries remain non-blocking unavailable state.
- The existing ignored Firebase plist is installed at the app's expected local path. It remains untracked and enables non-test Firebase/Auth/Google composition on a configured device build.
- The previous sideloadable in-memory `MVP_DEMO` artifact is an intermediate preview only and is not the final MVP candidate.

## Verification
- Local whitespace, Firebase-security-hygiene, Firestore-rules, account-deletion, and offline cache/reconnect contracts pass.
- Added focused unit coverage for successful cached snapshot availability and malformed-snapshot fallback.
- macOS smoke `33082510251` passed before this Firestore recovery checkpoint. Run smoke again on the rebased current head.
- Focused macOS diagnostic `33077303696` failed at the same Program date selector after Next week; it is the fourth matching result. Retain `KNOWN_UI_TEST_HARNESS_FLAKE` and do not rerun or alter production behavior for that selector without independent product-failure evidence.

## External/deferred
- Real Firebase console setup remains required: deploy `firestore.rules`, enable the email/password and Google providers, and validate with non-production accounts. Real-device validation remains required for cache/reconnect, Google sign-in, account deletion, Crashlytics, and accessibility.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, paid-release Apple configuration, and `dev -> main` remain deferred.

## Next action
1. Push the Firestore offline recovery checkpoint, then dispatch macOS `smoke` against that exact SHA while continuing safe reconciliation.
2. Reconcile the remaining product surfaces against MVP acceptance criteria; use non-production Firebase/device evidence once the necessary console configuration is available. Reserve one `full` run for final MVP reconciliation.
