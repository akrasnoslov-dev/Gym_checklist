# Firebase setup (M4.1)

The Firebase bootstrap hook intentionally contains no Firebase project
configuration or other credentials. M4.1 links FirebaseCore,
FirebaseAuth, FirebaseFirestore, FirebaseAnalytics, and FirebaseCrashlytics
from the official Firebase Apple SDK. M7.1 uses FirebaseAnalytics only through
a parameter-free event tracker. M7.2 configuration and symbol-upload guidance
is in `docs/crashlytics_setup.md`.

## Current no-cost development boundary

For pre-payment MVP acceptance, use a dedicated non-production Firebase **Spark** project and keep billing disabled. Authentication, Firestore within Spark quotas, Analytics, and Crashlytics are part of current free validation. Do not attach a Cloud Billing account or upgrade to Blaze without explicit user approval.

## Required console setup before Firebase-backed features

1. Create a Firebase Spark project and register the iOS app with bundle identifier
   `dev.akrasnoslov.GymChecklist`.
2. Enable Authentication. Create Cloud Firestore in **production mode** so it
   denies access by default; do not use test mode. Before connecting real user
   data, deploy the owner-scoped rules in this repository and verify them with
   non-production accounts.
3. Download `GoogleService-Info.plist` to `GymChecklist/GoogleService-Info.plist`.
   Do not commit it; `.gitignore` excludes it. The tracked build phase copies
   this local file into configured app builds and derives the Google callback
   URL scheme from its `REVERSED_CLIENT_ID`; CI has no such file and remains
   configuration-free.
4. Resolve packages and build the `GymChecklist` scheme. The Firebase bootstrap
   returns a clear development failure until a valid plist is present; XCTest
   and UI-test processes intentionally bypass configuration so CI never needs a
   real plist. Normal app launches use Firebase Auth, Firestore, Analytics, and
   Crashlytics rather than the test-only in-memory repositories.
5. Before live Firestore verification, deploy `firestore.rules` as documented
   in `docs/firestore_security.md`, then validate owner isolation with two
   non-production test users. Do not use Firestore test mode.
6. Keep the authenticated `deleteAccount` callable source and its automated
   contracts verified. Do **not** enable billing merely to deploy it during the
   current pre-payment phase. If Firebase requires Blaze/billing for live
   deployment, defer that deployment and live deletion proof until the user
   explicitly approves paid release work. See `docs/account_deletion_design.md`.

`GoogleService-Info.plist` contains project identifiers rather than a service
account key, but it remains local to avoid publishing project configuration.
Never add service-account JSON, Auth keys, or signing material to this
repository.
