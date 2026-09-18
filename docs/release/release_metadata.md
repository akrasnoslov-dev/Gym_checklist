# Release metadata baseline (M8.2)

| Field | Current value | Release action |
| --- | --- | --- |
| App name | Gym Checklist | Keep unless the App Store record uses an approved final name. |
| Bundle identifier | `dev.akrasnoslov.GymChecklist` | Confirm ownership/availability in the Apple Developer account before signing. |
| Marketing version | `1.0` | Increment for every submitted release. |
| Build number | `1` | Increase monotonically for every uploaded archive, including beta rebuilds. |
| Minimum iOS | 17.0 | Confirm final TestFlight device support before release. |
| Device family | iPhone | Keep aligned with the approved MVP scope. |
| Category | Health & Fitness | Confirm in App Store Connect metadata. |
| App icon | `GymChecklist/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` from the approved brand master | Validate the rendered icon in an archive and replace only after explicit brand approval. |

Release builds must preserve the bundle identifier, use a new build number, and
be tied to the exact `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` used for
Crashlytics dSYM verification. Do not put signing identifiers, certificates, or
App Store Connect credentials in this file or in source control.
