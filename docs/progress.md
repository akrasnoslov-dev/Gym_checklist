# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`.
- Approved MVP product implementation is frozen pending user evaluation.
- Authoritative macOS MVP smoke run `33082510251` completed `success`.
- The Program XCTest selector issue remains `KNOWN_UI_TEST_HARNESS_FLAKE` and is non-blocking; do not rerun it without new independent product evidence.
- A dedicated sideload demo path now exists for first-device evaluation without paid Apple/TestFlight distribution.

## MVP demo IPA
- Workflow: `.github/workflows/mvp-demo-ipa.yml`.
- Successful build run: `33087360512`.
- Source checkpoint: `4e6a241c2aad68c39a5df0e6c4d19e9f7459139d`.
- Artifact: `GymChecklist-Demo` (artifact id `9652911549`).
- IPA: `GymChecklist-Demo.ipa`, arm64 iPhone build, bundle id `dev.akrasnoslov.GymChecklist.demo`.
- Verified in packaged app: `MVP_DEMO=true`, no `GoogleService-Info.plist`, no embedded provisioning profile.
- Demo mode uses local in-memory auth/workout/custom-exercise/settings repositories and no Firebase/Analytics live services.
- Important demo limitation: data is not durable across a full app process restart. This is acceptable for the first UI/interaction evaluation but does not replace later Firebase/offline persistence validation.

## External/deferred
- Physical iPhone installation now proceeds through Sideloadly using the demo IPA and the user's Apple Account.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.
- Live Google/Firebase/Crashlytics/account-isolation/offline reconnect and final physical-device validation remain later acceptance work.

## Next action
1. User installs `GymChecklist-Demo.ipa` on the iPhone with Sideloadly.
2. User evaluates the MVP UI and core workout flow.
3. Do not resume autonomous feature development until explicit user feedback identifies a blocker or approved change.
