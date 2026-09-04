# Account deletion design — release blocker

Gym Checklist supports account creation, so external TestFlight/App Store
release requires an in-app account-deletion initiation path. This is separate
from logout and must erase the user-generated Firestore records and Firebase
Auth account without exposing another user's data.

The client must **not** delete Firebase Auth first: that would remove the
authorization needed to delete the owner-scoped Firestore subcollections.
Likewise, a client-side sequence cannot provide a reliable, idempotent
all-or-nothing deletion across an expiring/re-authenticated Auth session.

## Implemented local boundary

- Settings offers a native destructive confirmation and routes only after the
  deletion callable reports success. Cancellation makes no request; failures
  retain the session and expose neutral, retryable feedback.
- `functions/deleteAccount` accepts no caller-supplied UID. It requires a
  Firebase-authenticated request with an `auth_time` no older than five
  minutes (and rejects implausible future timestamps), recursively deletes that
  UID's `users/{uid}` document tree, then deletes the Auth user. It neither
  logs user data nor allows cross-user input.
- The iOS client maps the callable's recent-authentication failure to a
  retryable prompt. Apple and Google accounts use fresh provider credentials
  to reauthenticate the same Firebase UID, refresh its Firebase token, and
  only then invoke the callable; neither route uses ordinary sign-in, which
  could switch the deletion target.
- For a Sign in with Apple user, the reauthentication flow must collect a fresh
  authorization code and call `Auth.auth().revokeToken(withAuthorizationCode:)`
  before the deletion callable. Firebase does not retain that token. This
  revocation flow and signed-device validation remain required before release.

## Current pre-payment status

The account-deletion client flow, backend source, and automated security/behavior contracts remain required now. Live Cloud Function deployment is **not** a current functional-acceptance blocker if Firebase requires attaching billing or upgrading from Spark to Blaze. Do not enable billing for this purpose without explicit user approval. Record the live backend deletion path as a paid-phase limitation until release work is reactivated.

## Required deployment and proof

After paid/billing-dependent release work is explicitly reactivated, the Function source uses Node 20. After installing dependencies in
`functions/` on a trusted machine and selecting a non-production Firebase
project, deploy only the callable:

```text
firebase deploy --only functions:deleteAccount --project YOUR_FIREBASE_PROJECT_ID
```

Do not deploy it before reviewing the Firebase project billing/runtime policy and receiving explicit approval for any billing change.

## Required implementation shape

1. Add a compact Settings → Account → Delete account entry with an explicit
   destructive confirmation and accessible error/success feedback.
2. Require recent authentication before initiating deletion. The provider used
   for reauthentication must match the active account and remain bound to the
   same Firebase UID; do not ask for or store a password for an Apple/Google
   account. Sign in with Apple must revoke its newly collected authorization
   code before the server-side erase.
3. Invoke an authenticated, server-side Firebase deletion job that derives the
   UID only from the verified request context. It must delete every document in
   `users/{uid}/workouts`, `customExercises`, `bodyWeightMeasurements`, and `settings`, then delete the
   Firebase Auth user. The job must be idempotent and safely resume partial
   Firestore batch work without accepting a caller-supplied UID.
4. Clear local repositories/session only after the job reports success. A
   retryable failure keeps the account signed in and gives a neutral recovery
   message.
5. Define and publish the retention/deletion disclosure before release. Do not
   retain workout data or provider tokens for an undisclosed purpose.

## Required proof before release

- Unit coverage for confirmation, cancellation, reauthentication-required,
  success, retryable failure, and cross-account isolation.
- Emulator/non-production Firebase integration proof that one user can erase
  only their data and no documents remain for that UID.
- Signed-device validation for email/password, Apple, and Google accounts,
  including Google cancellation/failure and a mismatched-account attempt.
- Manual VoiceOver/Dynamic Type validation for the destructive flow.

This design follows Apple's [Offering account deletion in your
app](https://developer.apple.com/support/offering-account-deletion-in-your-app/).
It intentionally remains a release blocker until the server-side job and live
validation exist.
