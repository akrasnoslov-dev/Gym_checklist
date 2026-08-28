# No-cost external MVP acceptance handoff

This is the one external handoff for the current functional MVP. It validates
the app source at `ee579d06cedaffad8c6e5b563aacdcf6ecd7a00b`; authoritative
macOS candidate run `33211219461` is green for that source.

Use one non-production Firebase **Spark** project with billing off, one Mac
with Xcode, and one iPhone on iOS 17 or later. Do not use the old `MVP_DEMO`
preview, TestFlight, App Store Connect, paid signing, Blaze, or Functions
deployment.

## 1. Configure one Spark project

In one Firebase Console session:

1. Create or select a dedicated non-production Spark project. Confirm billing
   is off, register the iOS bundle ID `dev.akrasnoslov.GymChecklist`, enable
   Analytics, and create Cloud Firestore in **production mode**.
2. Enable Authentication providers **Email/Password** and **Google**. Complete
   the Google iOS OAuth registration when requested.
3. Download the refreshed iOS configuration only to
   `GymChecklist/GoogleService-Info.plist` in the Mac checkout. Do not commit,
   share, paste, or return this file. The Xcode project derives the callback
   URL scheme from it.
4. Deploy only the tracked Firestore rules. From an authenticated terminal in
   the checkout, run:

   ```sh
   firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
   ```

   If the CLI is unavailable, publish the identical tracked
   `firestore.rules` content from the Firestore Rules editor. Do not deploy
   `functions:deleteAccount`, attach billing, or change to test-mode rules.

Why: this enables the live auth, persistence, owner-isolation, Analytics, and
Crashlytics checks while retaining the required owner-only policy.

## 2. Install the exact candidate for free

On a clean Mac checkout, use:

```sh
git checkout ee579d06cedaffad8c6e5b563aacdcf6ecd7a00b
open GymChecklist.xcodeproj
```

In Xcode, select the `GymChecklist` scheme and a connected iOS 17+ iPhone.
Sign in to Xcode with a Personal Team, keep automatic signing, and run the
Debug build. Trust the Mac and enable Developer Mode if iOS asks. Keep the
bundle ID and existing entitlements unchanged.

If free provisioning rejects the current Sign in with Apple entitlement,
return the exact Xcode error. Do not buy a membership, enable Apple services,
or remove the entitlement speculatively.

Why: this is the approved zero-cost path to validate the real Firebase-backed
architecture on the acceptance device.

## 3. Run the live acceptance sweep

Use three disposable identities: email user A, email user B, and one Google
account. Do not return their addresses, passwords, UIDs, tokens, reset links,
or plist content.

1. **Auth and persistence:** register A, verify Today, log out/in, request a
   password reset, then verify the reset path. Complete Google consent to
   Today and cancel a later Google attempt cleanly. As A, create a dated
   multi-exercise workout, custom exercise, and settings change; terminate
   and relaunch online to confirm persistence.
2. **Isolation:** sign in as B and confirm A's workouts, custom exercises,
   and settings never appear. In Rules Playground or equivalent, record only
   outcomes: same-user access allowed; cross-user, unauthenticated, and
   non-`settings/default` access denied. Return to A and confirm A's data is
   intact.
3. **Offline/reconnect:** prime A's cache online. In airplane mode relaunch,
   complete/undo/recomplete a set, edit actual values, skip/restore an
   exercise, and edit a Program set. Relaunch while offline, reconnect, then
   relaunch online. Confirm values occur once, no duplicate date/set IDs
   exist, and passive offline feedback clears. Sign out/in as B afterward to
   confirm A's cached data is not exposed.
4. **Product and accessibility:** verify Program previous/next-week and date
   selection, create/edit/delete, copy/repeat, historical actual editing,
   Today one-tap completion/undo, long-press edits, rest/no-program, the
   completion overlay, System/Light/Dark, kg/lb, VoiceOver labels/actions,
   largest Dynamic Type, contrast, and touch targets. Do not exercise account
   deletion; its live Function is deferred if it needs Blaze.
5. **Analytics and Crashlytics:** add `-FIRDebugEnabled` in Xcode's Run scheme
   launch arguments and check Firebase Analytics DebugView for parameter-free
   successful event names such as `sign_up`, `login`, `workout_created`,
   `set_completed`, `set_uncompleted`, `exercise_skipped`, and
   `workout_completed`. Remove the argument afterward. For Crashlytics,
   confirm dashboard intake only through Firebase's documented non-production
   test-crash procedure; it requires a temporary uncommitted Debug-only test
   control and a clean rebuild of this exact SHA afterward. Do not commit a
   crash control, log private workout/auth data, or add a production crash
   path. See Firebase's [Apple-platform test procedure](https://firebase.google.com/docs/crashlytics/ios/test-implementation).

## 4. Return one sanitized result

One reply is enough. Include:

- Spark/billing-off and rules-deployment outcomes; no project ID or secrets.
- iPhone model/iOS, Xcode version, and installed source SHA.
- Pass/fail for auth, Google success/cancel, persistence, A/B isolation,
  offline/reconnect, Analytics, Crashlytics, accessibility, and core workout
  flow; include transition timestamps for offline/reconnect.
- The exact signing/configuration/runtime error and reproduction step for any
  failure, with redacted screenshots only.

This is the minimum external work remaining. Paid Apple distribution, live
Sign in with Apple, live account-deletion Functions if Blaze is required, and
`dev -> main` remain deferred.
