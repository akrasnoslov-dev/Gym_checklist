# Firebase setup (M4.1)

The Firebase bootstrap hook intentionally contains no Firebase project
configuration or other credentials. M4.1 links only FirebaseCore,
FirebaseAuth, and FirebaseFirestore from the official Firebase Apple SDK.
Analytics and Crashlytics product linkage, data collection, and Crashlytics
dSYM upload are deliberately deferred to M7.1/M7.2.

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
5. Before M4.3/M4.7 verification, create owner-scoped Firestore rules and use
   a non-production Firebase project for development and CI.

`GoogleService-Info.plist` contains project identifiers rather than a service
account key, but it remains local to avoid publishing project configuration.
Never add service-account JSON, Auth keys, or signing material to this
repository.
