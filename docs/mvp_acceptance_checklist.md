# MVP acceptance checklist (M9.1)

This is a release-readiness matrix, not a claim that the MVP is accepted.
`Static coverage` means deterministic local/unit/UI coverage exists; the listed
macOS and live checks must still pass before release acceptance.

| Scenario | Static coverage | Remaining release evidence |
| --- | --- | --- |
| Register via email/password | Unit + UI registration tests | macOS CI; live Firebase validation |
| Login via email/password and logout | Unit + UI auth-routing/isolation tests | macOS CI; live Firebase validation |
| Google sign-in | Native SDK/client credential path plus deterministic unit/UI coverage | Configure provider/URL scheme and validate signed-device success, cancel, failure |
| First-use Today and create workout | Today/Program UI tests | macOS UI CI |
| Concrete-date workout creation | Domain + Program UI tests | macOS CI |
| Search/add custom exercise | Domain + Program UI tests | macOS CI; live custom-exercise persistence |
| Arbitrary reps, weight, and time | Domain + Program editor UI tests | macOS CI |
| Copy workout independently | Domain + Program UI tests | macOS CI |
| Repeat workout independently | Domain + Program UI tests | macOS CI |
| Today complete/undo in arbitrary order | Domain + Today UI tests | macOS CI |
| Today planned/actual long-press edit | Domain + Today UI tests | macOS CI |
| Skip and restore exercise | Domain + Today UI tests | macOS CI |
| Rest day and no-program states | Today UI tests | macOS CI |
| Completion popup | Domain + Today UI tests | macOS CI; manual VoiceOver review |
| Historical viewing and actual edit | Domain + Program UI tests | macOS CI; live persistence validation |
| System/Light/Dark appearance | Unit + UI test | macOS UI CI; manual contrast review |
| kg/lb display and input | Unit + UI test | macOS CI |
| Offline execution and reconnect | Deterministic availability/repository tests | Airplane-mode/cache/reconnect validation against non-production Firebase |

## Required release gates

- The active macOS unit run and its gated focused UI run must pass for their
  checkpoints; a full suite remains required for release reconciliation.
- Configure and validate Google and Apple sign-in, Firestore owner rules,
  cached offline/reconnect behavior, Crashlytics, and account deletion as
  listed in `docs/progress.md`.
- Complete manual VoiceOver, Dynamic Type, and appearance-contrast checks.
- Produce and install a signed internal TestFlight build before any release
  acceptance claim.

No future-scope feature is a release gate. In particular, analytics dashboards,
timers, coaching, social features, HealthKit, and multiple workouts per day
remain out of scope.
