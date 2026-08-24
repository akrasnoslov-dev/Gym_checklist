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

1. Add a Sign in with Apple authentication path beside email/password and
   Google, with an Apple-approved button and cancellation/failure handling.
2. Enable Sign in with Apple for the app identifier and Firebase Apple provider;
   configure the required Apple/Firebase identifiers and redirect details
   without committing credentials or signing material.
3. Validate account/session routing, cancellation, and provider failure on a
   signed device against a non-production Firebase project.
4. Before external TestFlight, provide App Review test information and a valid
   non-personal demo account path when login is required.
5. Implement and verify in-app account-deletion initiation and backend data
   handling before beta/release; this is separate from logout and needs its
   own deletion/data-retention design.

Apple review also applies to external TestFlight builds. Internal testing can
help validate integration but is not release-compliance evidence.
