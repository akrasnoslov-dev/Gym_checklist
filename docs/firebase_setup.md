# Firebase setup (M4.1)

The Firebase bootstrap hook intentionally contains no Firebase project
configuration or other credentials. The official Firebase Apple SDK package
linkage is the next M4.1 step.

## Required console setup before Firebase-backed features

1. Create a Firebase project and register the iOS app with bundle identifier
   `dev.akrasnoslov.GymChecklist`.
2. Enable Authentication and Cloud Firestore. Enable Analytics and Crashlytics
   when prompted by the Firebase console.
3. Download `GoogleService-Info.plist` and add it only to the app target in
   your local Xcode project. Do not commit it; `.gitignore` excludes it.
4. Resolve packages and build the `GymChecklist` scheme. The Firebase bootstrap
   returns a clear `missingConfiguration` development status until the plist is
   present; no Firebase services are used by the local/mock workout flow yet.
5. Before M4.3/M4.7 verification, create owner-scoped Firestore rules and use
   a non-production Firebase project for development and CI.

`GoogleService-Info.plist` contains project identifiers rather than a service
account key, but it remains local to avoid publishing project configuration.
Never add service-account JSON, Auth keys, or signing material to this
repository.
