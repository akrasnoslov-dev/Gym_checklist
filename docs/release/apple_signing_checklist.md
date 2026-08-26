# Apple signing and App Store Connect checklist (M8.3)

Complete this once, as the Account Holder/Admin, without sending credentials to
Codex or committing signing material.

1. Confirm Apple Developer Program membership and ownership of
   `dev.akrasnoslov.GymChecklist`; register an explicit App ID if needed.
2. Enable the Sign in with Apple capability for that App ID when M8.1 is
   implemented, then let Xcode automatic signing manage the matching profile or
   create the App Store Connect distribution profile.
3. Create the iOS App Store Connect record with the final name, primary
   language, SKU, category, and the exact bundle ID before the first upload.
4. Confirm an Apple Distribution certificate/profile path and a secure release
   operator; do not export certificates, profiles, or private keys into Git.
5. Supply the final App Store icon, privacy disclosures, TestFlight test
   information, and account-review demo path before external testing.

Apple references verified 2026-08-24: [create an app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/), [App Store provisioning profiles](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile), and [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview).
