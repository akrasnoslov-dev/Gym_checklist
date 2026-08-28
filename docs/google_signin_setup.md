# Google Sign-In setup (M5.4)

Complete these non-production Firebase/Google Console steps on the current no-cost Firebase **Spark** project before the app can bind and verify Google Sign-In. Do not attach billing for this validation:

1. Enable Google as a Firebase Authentication provider.
2. Register the iOS OAuth client for `dev.akrasnoslov.GymChecklist` and add
   its reversed client ID as an iOS URL scheme.
3. Download the refreshed `GoogleService-Info.plist` to
   `GymChecklist/GoogleService-Info.plist`. Do not commit it. The app target
   copies it only for local configured builds and registers its
   `REVERSED_CLIENT_ID` as the Google callback URL scheme.
4. Confirm a non-production Google account can complete the consent flow.

The tracked app now pins the official Google Sign-In SDK and uses its native
SwiftUI button, redirect handler, Firebase client ID, and Firebase credential
exchange. It treats cancellation quietly and never logs Google tokens or
profile data. After completing the console/configuration steps above, verify a
Google user reaches Today and that cancellation/failure return cleanly to the
auth screen.
