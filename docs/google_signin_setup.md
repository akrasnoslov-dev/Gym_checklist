# Google Sign-In setup (M5.4)

Complete these non-production Firebase/Google Console steps before the app can
bind and verify Google Sign-In:

1. Enable Google as a Firebase Authentication provider.
2. Register the iOS OAuth client for `dev.akrasnoslov.GymChecklist` and add
   its reversed client ID as an iOS URL scheme.
3. Download the refreshed `GoogleService-Info.plist` and add it locally to the
   GymChecklist app target. Do not commit it.
4. Confirm a non-production Google account can complete the consent flow.

After this is present, add the Google Sign-In SDK, bind its Firebase credential
to the existing UID-scoped session, and verify a Google user reaches Today.
