# GitHub release credentials (M8.4)

The manually triggered release workflow must remain disabled until the Apple
Developer and App Store Connect prerequisites in
`docs/apple_signing_checklist.md` are complete. It is separate from simulator
CI and never runs on a normal push or pull request.

Configure these as **environment secrets** on the protected
`testflight-internal` environment. Never add their values to a workflow file, `.xcconfig`, issue,
pull request, or terminal transcript.

| Secret | Value | Scope |
| --- | --- | --- |
| `IOS_DISTRIBUTION_CERTIFICATE_P12_B64` | Base64-encoded `.p12` Apple Distribution certificate and private key | Archive signing |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for that `.p12` | Archive signing |
| `IOS_PROVISIONING_PROFILE_B64` | Base64-encoded App Store provisioning profile for `dev.akrasnoslov.GymChecklist` | Archive signing |
| `CI_KEYCHAIN_PASSWORD` | Unique random, per-runner keychain password | Temporary CI keychain |
| `APPSTORE_CONNECT_API_PRIVATE_KEY_B64` | Base64-encoded App Store Connect API private key (`.p8`) | TestFlight upload |

Use repository **variables**, not secrets, for the non-sensitive identifiers:

| Variable | Value |
| --- | --- |
| `APPLE_TEAM_ID` | Apple Developer Team ID used by the provisioning profile |
| `IOS_PROVISIONING_PROFILE_NAME` | Exact installed profile name |
| `APPSTORE_CONNECT_KEY_ID` | App Store Connect API key identifier |
| `APPSTORE_CONNECT_ISSUER_ID` | App Store Connect API issuer identifier |

Use a dedicated, least-privilege **individual** App Store Connect key where
feasible; team keys cannot be scoped to one app. Apple API keys are private,
downloadable once, and must be revoked immediately if exposed. The release
operator must confirm the app record and bundle ID before the first upload. Apple documents the available upload paths
and roles in [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
and API-key handling in [Creating API keys](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api).

Before enabling the workflow, a security reviewer must confirm:

1. The `testflight-internal` environment requires approval and each secret is
   only available from that environment.
2. Workflow logs do not print decoded files, keychain contents, tokens, or
   command tracing.
3. The profile, certificate, entitlement, explicit App ID, and bundle ID match.
4. A rotation/revocation owner is known for the certificate and API key.

The workflow's first target is **Internal Testing**. Apple processes an upload
before it appears in App Store Connect; external testing needs separate review
and App Review information.
