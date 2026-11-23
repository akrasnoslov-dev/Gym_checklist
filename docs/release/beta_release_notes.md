# Gym Checklist beta release notes (draft)

Status: draft for the first internal TestFlight build. It must not be presented
as a released build until the acceptance and distribution gates in
`docs/mvp_acceptance_checklist.md` are complete.

## What testers can do

- Plan workouts on concrete calendar dates, add exercises and independent sets,
  and copy or repeat a workout.
- Open Today and complete or undo any set with one tap.
- Edit planned or completed values, skip and restore exercises, and view or
  correct past actual results in Program.
- Use System, Light, or Dark appearance and kg or lb display/input.
- Sign in with email/password, Apple, or Google after the corresponding
  non-production provider configuration is installed.

## Known beta limitations

- There is no signed TestFlight build yet; Apple signing, protected CI
  credentials, and installation proof remain required.
- Google and Apple sign-in need Firebase/Apple Console configuration and
  signed-device verification. A provider cancellation should leave the auth
  screen unchanged.
- Offline execution and automatic reconnect have deterministic coverage but
  still need airplane-mode and non-production Firebase validation.
- Accessibility needs final VoiceOver, Dynamic Type, and contrast checks on an
  Apple device or macOS environment.

## Deliberately not included

Gym Checklist remains a quiet workout checklist. It does not include charts,
coaching, timers, social features, HealthKit, exercise media, subscriptions,
or multiple workouts on one date.
