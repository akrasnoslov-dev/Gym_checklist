# Firebase setup (M4.1)

The Firebase bootstrap hook intentionally contains no Firebase project
configuration or other credentials. M4.1 links FirebaseCore,
FirebaseAuth, FirebaseFirestore, FirebaseAnalytics, and FirebaseCrashlytics
from the official Firebase Apple SDK. M7.1 uses FirebaseAnalytics only through
a parameter-free event tracker. M7.2 configuration and symbol-upload guidance
is in `docs/crashlytics_setup.md`.

## Required console setup before Firebase-backed features

1. Create a Firebase project and register the iOS app with bundle identifier
   `dev.akrasnoslov.GymChecklist`.
2. Enable Authentication. Create Cloud Firestore in **production mode** so it
   denies access by default; do not use test mode. Do not add Firestore client
   calls until M4.7 has committed and verified owner-scoped rules.
3. Download `GoogleService-Info.plist` and add it only to the app target in
   your local Xcode project. Do not commit it; `.gitignore` excludes it.
4. Resolve packages and build the `GymChecklist` scheme. The Firebase bootstrap
   returns a clear development failure until a valid plist is present; XCTest
   and UI-test processes intentionally bypass configuration so CI never needs a
   real plist. No Firebase services are used by the local/mock workout flow yet.
5. Before live Firestore verification, deploy `firestore.rules` as documented
   in `docs/firestore_security.md`, then validate owner isolation with two
   non-production test users. Do not use Firestore test mode.
6. Before external release, deploy the authenticated `deleteAccount` callable
   from `functions/` to a non-production project and validate its recent-auth,
   owner-only erase, retry, and provider reauthentication paths as described in
   `docs/account_deletion_design.md`. This backend deployment may require
   Firebase/Google Cloud billing/runtime configuration; do not configure it
   with credentials in the repository.

`GoogleService-Info.plist` contains project identifiers rather than a service
account key, but it remains local to avoid publishing project configuration.
Never add service-account JSON, Auth keys, or signing material to this
repository.
