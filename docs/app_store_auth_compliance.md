# App Store authentication compliance (M8.1)

## Decision

Gym Checklist's planned Google Sign-In creates/authenticates the primary app
account. Apple App Review Guideline 4.8 therefore requires an equivalent login
option that limits collection to name and email, supports private email, and
does not collect app interactions for advertising without consent. Sign in with
Apple is the required release path alongside Google Sign-In; email/password is
not treated as the equivalent option for this release decision.

The listed 4.8 exceptions do not fit this consumer workout app. Do not ship
Google Sign-In to external TestFlight or the App Store without Sign in with
Apple enabled and verified.

Sources, verified 2026-08-24:

- [App Review Guideline 4.8](https://developer.apple.com/app-store/review/guidelines/)
- [Sign in with Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple/)
- [TestFlight external testing](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers)

## Required implementation and external setup

1. A tracked native Sign in with Apple path now appears beside email/password
   in both account-creation and sign-in presentations. It uses Apple's system
   button, requests name/email, hashes a cryptographically secure nonce, and
   exchanges the resulting identity token with Firebase Auth. Cancellation
   leaves the auth screen unchanged; provider failures use a neutral message.
   The test-only path is deterministic and does not invoke the system sheet.
2. Enable Sign in with Apple for the app identifier and Firebase Apple provider;
   configure the required Apple/Firebase identifiers and redirect details
   without committing credentials or signing material.
3. The app target declares the Sign in with Apple entitlement. Account
   Holder/Admin action is still required to enable the matching explicit App ID
   capability and regenerate any affected provisioning profiles.
4. Validate account/session routing, cancellation, and provider failure on a
   signed device against a non-production Firebase project.
5. Before external TestFlight, provide App Review test information and a valid
   non-personal demo account path when login is required.
6. The tracked Settings confirmation and authenticated `deleteAccount` callable
   implement the local account-deletion boundary. Apple-backed accounts are
   reauthenticated as the same Firebase user, revoke the fresh Apple
   authorization code, refresh the Firebase ID token, and only then call the
   server-side erase. Deploy and verify the backend and every provider's
   reauthentication path before beta/release; this is separate from logout and
   has the data-retention design in `docs/account_deletion_design.md`.

Account-deletion/token-revocation sources, verified 2026-08-26:

- [Apple account deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [Firebase Sign in with Apple: token revocation](https://firebase.google.com/docs/auth/ios/apple#token-revocation)

Apple review also applies to external TestFlight builds. Internal testing can
help validate integration but is not release-compliance evidence.
