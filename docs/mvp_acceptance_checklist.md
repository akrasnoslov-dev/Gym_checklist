# MVP acceptance checklist (M9.1)

This checklist defines the **current pre-payment functional acceptance**. It is not App Store/TestFlight release acceptance.

Current rule: verify everything that can be implemented and proven at zero cost before the user decides whether to pay for Apple distribution. Use Firebase Spark only; do not attach billing or upgrade to Blaze without explicit approval.

## Current blocker status

- Program week/date navigation was a confirmed product defect. It is regression-covered, and authoritative candidate run `33211219461` passed both the focused Program test and full suite on source SHA `ee579d06cedaffad8c6e5b563aacdcf6ecd7a00b`.
- Physical-iPhone confirmation remains required; do not treat simulator CI as that evidence.

## Free acceptance matrix

| Scenario | Automated/static coverage | Free evidence required now |
| --- | --- | --- |
| Register via email/password | Unit + UI registration tests | Live Firebase Spark |
| Login/reset/logout via email/password | Unit + UI auth tests | Live Firebase Spark |
| Google Sign-In | Native SDK path + deterministic tests | Live Spark/provider configuration on device |
| First-use Today and create workout | Today/Program UI tests | Physical-iPhone review |
| Program date/week navigation | UI coverage exists | CI green; physical-iPhone proof |
| Create/edit/delete dated workout | Domain + Program UI tests | Physical-iPhone review |
| Search/add custom exercise | Domain + Program UI tests | Live Firestore persistence + device review |
| Arbitrary reps/weight/time and set ordering | Domain + UI tests | Physical-iPhone review |
| Copy workout independently | Domain + Program UI tests | Physical-iPhone review |
| Repeat workout independently | Domain + Program UI tests | Physical-iPhone review |
| Today complete/undo in arbitrary order | Domain + Today UI tests | Physical-iPhone review |
| Today planned/actual long-press edit | Domain + Today UI tests | Physical-iPhone review |
| Skip and restore exercise | Domain + Today UI tests | Physical-iPhone review |
| Rest day / no-program states | Today UI tests | Physical-iPhone review |
| Completion popup | Domain + Today UI tests | Device + VoiceOver review |
| Historical view / actual edit | Domain + Program UI tests | Relaunch/persistence proof |
| System/Light/Dark | Unit + UI tests | Device + contrast review |
| kg/lb display and input | Unit + UI tests | Device review |
| Firestore persistence | Mapping/repository tests | Create -> terminate -> relaunch on Spark |
| Two-user owner isolation | Rules/contracts | Two non-production Spark users |
| Offline execution/reconnect | Deterministic repository tests | Cache -> airplane mode -> mutate -> reconnect |
| Analytics | Event tests/contracts | Verify free Spark Analytics path |
| Crashlytics | Bootstrap/privacy contracts | Verify free Spark crash-reporting path |
| Accessibility | UI identifiers/Dynamic Type coverage | Manual VoiceOver + Dynamic Type + contrast |

## Current CI gates

- Iteration may use focused diagnostics and `smoke`.
- Before physical-iPhone acceptance, the exact candidate SHA must have all required CI green.
- In particular, the final authoritative macOS `full` run must conclude **success**. A known red test is not an acceptable final state.
- A failure independently reproduced in the product cannot be waived as a test flake.

## Paid/billing-dependent checks deliberately deferred

These are not current acceptance failures:

- Apple Developer Program membership.
- App Store Connect and TestFlight.
- Paid/release signing, distribution secrets, and App Store submission.
- Live Sign in with Apple configuration where paid Apple capabilities are required.
- Live deployment/validation of `functions:deleteAccount` if Firebase requires Blaze/billing. The client flow, backend source, and automated contracts remain required now.
- Final App Store icon/release metadata and `dev -> main`.

## Product-acceptance gate

After the free matrix passes and the final CI is green, install the exact free candidate on the user's iPhone. The user then decides subjectively whether functionality and UX are acceptable. Only after that decision may paid Apple/Firebase work be proposed or activated.
