# Crashlytics setup (M7.2)

Gym Checklist links `FirebaseCrashlytics` from the existing pinned Firebase
Swift package. Crash reporting starts only after `FirebaseApp` has configured
from the local, untracked `GoogleService-Info.plist`; test processes without
that file remain configuration-free.

## Privacy boundary

- Do not set Crashlytics user IDs, custom keys, or log messages containing
  emails, Firebase/Auth tokens, workout dates, exercises, weights, reps, set
  values, or free-form user text.
- The MVP adds no manual non-fatal error recording. Automatic crash reporting
  remains limited to the Crashlytics SDK's standard reports.

## Submission privacy review

Before each TestFlight/App Store submission, verify the current Firebase
Analytics and Crashlytics collection disclosures against the exact SDK
configuration and complete the App Store privacy nutrition label and privacy
policy accordingly. Do not infer the submission answers from this repository's
parameter-free event policy: SDK diagnostics and device data require their own
current review.

## Symbols

The app target creates dSYMs in Debug and Release and has a final build phase
that runs the Firebase Crashlytics symbol uploader only when the built app
contains `GoogleService-Info.plist`. This preserves configuration-free CI and
test builds.

Before a signed/TestFlight archive, ensure the local plist is part of the app
target and verify that the Firebase Crashlytics dashboard accepts the uploaded
dSYM for that build. If automatic upload is unavailable, use the official
Firebase `upload-symbols` procedure; never commit the plist or any Firebase
credentials.
