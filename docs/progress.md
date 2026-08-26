# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; latest checkpoint `40c1c24` (`Assert Program navigation with date controls`); an account-deletion sheet-dismissal fix is uncommitted.
- The current fix explicitly dismisses Apple/Google reauthentication sheets only after successful deletion, so the auth screen is reachable; failure and cancellation retain the sheet/session.

## Verification
- Local checks pass: whitespace, Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- Latest macOS UI diagnostic `33014732903` at `40c1c24` had two simulator/Xcode launch failures and one independent Apple deletion failure: successful Apple verification left its sheet presented, hiding the auth screen. The current fix addresses that product defect; it does not treat launch failures as app evidence.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Commit the UI-test follow-up and run one macOS `ui` diagnostic.
2. If it passes, run one current-head macOS `full` verification; otherwise fix only the reported UI surface.
