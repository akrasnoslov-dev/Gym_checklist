# Internal TestFlight beta workflow (M8.7)

This workflow is for internal iPhone testing only. It does not publish to the
App Store and it does not make an external TestFlight build release-compliant.
Before the first run, complete `docs/apple_signing_checklist.md` and configure
the protected `testflight-internal` GitHub environment exactly as described in
`docs/github_release_secrets.md`.

1. Choose the next unused integer build number. It must be greater than every
   prior upload for version `1.0`.
2. In GitHub, open **Actions → TestFlight release (manual) → Run workflow** on
   `dev`.
3. Enter the build number. Use `artifact` for the first signing/export check;
   download the short-lived IPA only through the restricted workflow artifact.
4. Record the immutable source revision printed by the workflow's **Validate
   and record source revision** step. After the artifact check succeeds, run
   again with `destination: testflight` and enter that SHA as `source_revision`.
   This archives the same source revision and uploads directly to App Store
   Connect without retaining the IPA as an Actions artifact. Leave
   `source_revision` blank only when a same-revision retry is not needed.
5. Wait for Apple processing. When it completes, open App Store Connect →
   TestFlight, add the build to the Internal Testing group, then install or
   update it through the TestFlight app on the iPhone.
6. Report bugs with the TestFlight build number, iPhone/iOS version, screen,
   expected result, actual result, and reproducible steps. Codex should locate
   the matching commit/workflow run, reproduce with an equivalent test where
   possible, add a regression test, and create a newer build number after a
   fix.

Apple processes uploaded builds before they appear in TestFlight. Internal
testing is the first distribution target; external testing remains blocked on
the App Review/auth/deletion work in `docs/app_store_auth_compliance.md`.

Never upload a build from an untrusted branch, paste certificate/API-key
material into a task, or reuse a build number.
