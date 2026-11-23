# Current application audit — Phase 2

Audit date: 2026-09-08. Source: local `dev` and remote `dev` at `e6e80bc314867f7c87ae5fab0366707be5b61de1` (remote checked with `git ls-remote`). Production Swift and Xcode project match approved application source `e17cb8173a6373059729226453c568e976954d33`.

Phase 2 visual evidence now consists of user-captured physical-iPhone screenshots of the current MVP placed in the working Pencil file under `02 — Current App / Runtime References`. They are visual references, not an approved design, historical reconstruction, or Phase 3 proposal. The exhaustive implementation-state inventory below remains source-backed and is not reduced to the captured screenshot subset.

## Evidence and limits

- All application Swift files governing views, routing, state, models, formatting, palette, persistence, and fixtures were read. Required project/product/UX/architecture/redesign/progress instructions were read before authoring.
- Current physical-iPhone runtime screenshots have been captured by the user and placed in the working Pencil file. They cover representative current MVP surfaces; they are not an exhaustive capture of all 64 audited states and are not claimed here as committed repository assets.
- `docs/design/today-program-mockup.png` and `design/qa/original-reference*` remain historical evidence only and are not current-app screenshots.
- Windows cannot run this SwiftUI application or an iOS simulator. Source still provides the exhaustive state/behavior audit; the runtime screenshots provide native visual evidence for the states actually captured.
- **S/U** below means source-verified structure/state whose native rendering is not established by a matching runtime capture. **C/U** means conditional/system-owned rendering that still needs runtime evidence if it becomes important. Representative captured states have separate runtime visual evidence even when the inventory row keeps its source-audit rating.
- Authenticated appearance **A** means System/Light/Dark implemented through `SettingsViewModel.preferredColorScheme` and `AuthenticatedContentView`. **OS** means signed-out/system-controlled appearance; the authenticated appearance override and green tint do not wrap authentication.
- Runtime screenshots are accepted as the Phase 2 visual truth for captured states. Do not replace them with AI-generated editable approximations.
- Current CI was read once: [run 33991955146](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/33991955146) is completed/success. Its workflow head is `2286b312e8998c8d7c94e9aa3bda64389da4c78c`; `docs/progress.md` records the immutable checked-out application candidate as `e17cb8173a6373059729226453c568e976954d33`. This is functional gate evidence, not screenshot evidence. No CI was dispatched.

## Source keys

Paths are relative to repository root. Named symbols identify the inspected code independently of later formatting changes.

| Key | Code source |
| --- | --- |
| T | `GymChecklist/Features/Today/TodayView.swift`: `TodayView`, `TodayContentState`, `TodaySetEditorSheet`, `TodayCompletionOverlay` |
| P | `GymChecklist/Features/Program/ProgramView.swift`: `ProgramView`, `ProgramSetEditorSheet`, `HistoricalActualEditorSheet`, `CopyWorkoutSheet`, `RepeatWorkoutSheet` |
| PC | `GymChecklist/Features/Program/ProgramCalendarState.swift`: `ProgramDayState`, `ProgramCalendarState` |
| E | `GymChecklist/Features/Exercises/ExercisePickerView.swift`: `ExercisePickerView`, `CustomExerciseView` |
| S | `GymChecklist/Features/Settings/SettingsView.swift`: `SettingsView`, `SettingsViewModel`, `ProfileEditorSheet`, `BodyWeightHistorySheet` |
| R | `GymChecklist/Features/Auth/RegistrationView.swift`: `RegistrationView` |
| AU | `GymChecklist/Features/Auth/Authentication.swift`: `AuthenticationViewModel`, `RegistrationError`, `AccountDeletionError`, provider services |
| C | `GymChecklist/App/ContentView.swift`: auth router, authenticated tabs, test fixtures |
| APP | `GymChecklist/App/GymChecklistApp.swift`: bootstrap and `FirebaseConfigurationUnavailableView` |
| VM | `GymChecklist/App/WorkoutViewModel.swift`: local-date selection and all workout mutations |
| G | `GymChecklist/Core/UI/GymTheme.swift`: semantic palette, `GymCard`, `GymSectionHeader` |
| D | `GymChecklist/Core/Models/DomainModels.swift`, `WorkoutRules.swift`: settings/profile/set types, planned/actual/completion rules |
| F | `GymChecklist/Core/Utilities/SetDisplayFormatter.swift`, `LocalDate.swift`: visible values, units, dates |
| DB | `GymChecklist/Data/Repositories/WorkoutRepository.swift`; `Data/Firebase/Firestore*Repository.swift`, `FirestoreMapping.swift`, `FirebaseBootstrap.swift`; `Data/Local/*`: owner-scoped optimistic state, load availability, catalog, settings/history persistence |

## Data provenance

No real user/account/workout data is included.

- **F1:** C `seedCompletionWorkoutForUITests`: Bench Press, one `8 reps × 60 kg` set; Barbell Row, one `12 reps` set. Use `2026-08-14`, the existing UI-test reference date. Incomplete/partial/completed variants derive only from supported completion/undo actions on this fixture. These are not production defaults or observed runtime captures.
- **F2:** C `seedTodayWorkoutForUITests`: Bench Press `8 reps × 60 kg`, `10 reps × 65 kg`; Barbell Row `12 reps`; Overhead Press sixteen `10 reps × 20 kg` sets. Used only when multiple sets are needed to prove reorder-menu conditions.
- **F3:** C `seedHistoryWorkoutForUITests`, dated `2026-08-07`: Bench Press completed actual `7 reps × 65 kg`, incomplete `12 reps`; skipped Barbell Row `10 reps × 20 kg`. Current date `2026-08-14`.
- **F4:** `GymChecklistTests/ExpandedFeatureTests.swift`, `testLegacyMixedSetRoundTripsWithoutDiscardingPlanOrActualValues`: plan 8 reps/60 kg/45 sec; completed actual 7 reps/65 kg/50 sec. The type selector has only Weighted/Reps only/Timed; no selectable Legacy option is invented.
- **F5:** `GymChecklistTests/ExpandedFeatureTests.swift`: timed 45 seconds; dated body measurements 81 kg on September 1, 2026 and 80 kg on September 2, 2026; height 180 cm. `GymChecklistUITests/GymChecklistUITests.swift`, `testSettingsProfileAndBodyWeightUpdateBMI`, independently asserts `180 cm · BMI 25.0` after entering 81 kg. Measurement dates in that UI test use `Date()`, not its workout reference-date override.
- Unknown dynamic values are shown as explicitly labeled audit placeholders, never as observed data. Provider branding, account email, custom names, keyboard contents, status-bar time, and native menu positions are not fabricated.

## A. Complete implementation state inventory

These 64 source-audited entries are the complete implementation-state inventory. They retain every inspected state, condition, source reference, prerequisite, appearance note, verification rating, and uncertainty from the Phase 2 audit. They are not a requirement for 64 standalone Pencil phone frames.

## Exact ordered inventory row names

Every name below is literal, including the prefix. The number matches the evidence row immediately below it. These are audit row names, not a requirement to create matching Pencil phone frames.

1. `02 — Current App / 00 Evidence and current tokens`
2. `02 — Current App / 01 Today — Incomplete`
3. `02 — Current App / 02 Today — Partial`
4. `02 — Current App / 03 Today — Completed`
5. `02 — Current App / 04 Today — Dark`
6. `02 — Current App / 05 Today — Completion overlay`
7. `02 — Current App / 06 Today — Skip context menu`
8. `02 — Current App / 07 Today — Skipped and restore`
9. `02 — Current App / 08 Today — All skipped`
10. `02 — Current App / 09 Today — No program`
11. `02 — Current App / 10 Today — Rest day`
12. `02 — Current App / 11 Today — Empty workout`
13. `02 — Current App / 12 Today — Loading`
14. `02 — Current App / 13 Today — Unavailable`
15. `02 — Current App / 14 Today — Cached warning`
16. `02 — Current App / 15 Today — Mutation alert`
17. `02 — Current App / 16 Today — Edit planned weighted`
18. `02 — Current App / 17 Today — Edit actual weighted`
19. `02 — Current App / 18 Today — Typed editor variants`
20. `02 — Current App / 19 Set editors — Error alternatives`
21. `02 — Current App / 20 Program — Week`
22. `02 — Current App / 21 Program — Month`
23. `02 — Current App / 22 Program — Empty date`
24. `02 — Current App / 23 Program — Past empty date`
25. `02 — Current App / 24 Program — Empty workout and add set`
26. `02 — Current App / 25 Program — Exercise actions`
27. `02 — Current App / 26 Program — Set ordering`
28. `02 — Current App / 27 Program — Edit set`
29. `02 — Current App / 28 Program — Typed plan variants`
30. `02 — Current App / 29 Program — Edit completed plan`
31. `02 — Current App / 30 Program — Legacy plan`
32. `02 — Current App / 31 Program — Delete exercise`
33. `02 — Current App / 32 Program — Delete set`
34. `02 — Current App / 33 Program — Workout actions and deletion`
35. `02 — Current App / 34 Program — Historical workout`
36. `02 — Current App / 35 Program — Historical actual editor`
37. `02 — Current App / 36 Exercises — Picker`
38. `02 — Current App / 37 Exercises — No results`
39. `02 — Current App / 38 Exercises — Custom and errors`
40. `02 — Current App / 39 Copy — Same date`
41. `02 — Current App / 40 Copy — Valid destination`
42. `02 — Current App / 41 Copy — Occupied destination`
43. `02 — Current App / 42 Repeat — Default schedule`
44. `02 — Current App / 43 Repeat — Until date and conflicts`
45. `02 — Current App / 44 Repeat — Nothing to create`
46. `02 — Current App / 45 Program — Availability and errors`
47. `02 — Current App / 46 Settings — Unset profile`
48. `02 — Current App / 47 Settings — Populated profile`
49. `02 — Current App / 48 Settings — Dark and units`
50. `02 — Current App / 49 Profile — Unset`
51. `02 — Current App / 50 Profile — Date of birth enabled`
52. `02 — Current App / 51 Body weight — Empty history`
53. `02 — Current App / 52 Body weight — History`
54. `02 — Current App / 53 Body weight — Edit and delete`
55. `02 — Current App / 54 Settings — Feedback alternatives`
56. `02 — Current App / 55 Account — Delete confirmation`
57. `02 — Current App / 56 Account — Verify with Apple`
58. `02 — Current App / 57 Account — Verify with Google`
59. `02 — Current App / 58 Auth — Registration`
60. `02 — Current App / 59 Auth — Sign in`
61. `02 — Current App / 60 Auth — Password reset`
62. `02 — Current App / 61 Auth — Reset sent and feedback`
63. `02 — Current App / 62 Startup — Resolution and unavailable setup`
64. `02 — Current App / 63 Appearance — System behavior`

| Frame suffix | Route / state | Code source | Data / state prerequisites | Appearance | Verification | Notes / uncertainties |
| --- | --- | --- | --- | --- | --- | --- |
| 00 Evidence and current tokens | Audit legend, not app route | G; C; S | None | A / OS | S/U | Explicit RGB/spacing shown; native semantic colors/fonts unresolved. |
| 01 Today — Incomplete | Today active workout | T `exerciseSection`, `setRow`; C F1 | F1, neither set complete | A; Light schematic | S/U | Circle icons, no set numbers or Start button. |
| 02 Today — Partial | Today active workout | T; D `completionStatus` | F1, first set complete | A; Light schematic | S/U | Filled check circle; row text not struck through. |
| 03 Today — Completed | Today after dismissing completion | T; D | F1, both complete | A; Light schematic | S/U | Same checklist; opening already-completed data does not trigger popup. |
| 04 Today — Dark | Today active workout | T; G | F1 partial, Dark selected or OS dark | A; Dark semantic schematic | S/U | Mint foreground; system surface colors require runtime capture. |
| 05 Today — Completion overlay | Overlay on Today | T `TodayCompletionOverlay` | Transition from noncompleted to completed | A | S/U | 28% black scrim, 78pt circle, 32pt dumbbell symbol, exact two lines and Done. Native button/symbol rendering unverified. |
| 06 Today — Skip context menu | Long press exercise header | T `exerciseSection` | Active F1 exercise | A | C/U | One action: Skip exercise. Native menu placement/material unverified. |
| 07 Today — Skipped and restore | Today restore menu | T `restoreSkippedExercisesMenu` | Barbell Row skipped in F1 | A | C/U | Skipped exercise absent from active cards; Skipped exercises → Restore Barbell Row. |
| 08 Today — All skipped | Today restore-only content | T; D `completionStatus` | All F1 exercises skipped; overlay dismissed | A | S/U | All-skipped counts completed; no invented rest-day text. |
| 09 Today — No program | Today noProgram | T `noProgramState` | Available empty workout collection | A | S/U | No workout planned yet. / Create workout. CTA selects today in Program. |
| 10 Today — Rest day | Today restDay | T `restDayState`; C rest fixture | Program exists, no workout today | A | S/U | Rest day. / See you tomorrow. / View program. No illustration in source. |
| 11 Today — Empty workout | Today active but no exercises | T `emptyWorkoutState` | Today's workout exists with zero exercises | A | S/U | No exercises added yet. / View program. |
| 12 Today — Loading | Today loading | T `loadingState`; DB | Load state loading | A | C/U | Loading workout; spinner geometry is native. |
| 13 Today — Unavailable | Today without usable snapshot | T `unavailableState`; DB | unavailable(false) | A | S/U | Automatic-retry message, no manual Sync control. |
| 14 Today — Cached warning | Today with usable data | T `syncUnavailableMessage`; DB | unavailable(true), F1 cached | A | S/U | Warning above active content. Offline success alone does not guarantee this warning appears. |
| 15 Today — Mutation alert | Today save/skip/restore failure | T `TodayMutationError` | Mutation throws | A | C/U | Couldn't confirm this change / Check your workout before trying again. / OK. |
| 16 Today — Edit planned weighted | Long-press sheet | T `TodaySetEditorSheet` | Incomplete F1 weighted set | A | C/U | Edit set; Planned set; Weighted; reps/weight only; Cancel/Save. No detent declared. |
| 17 Today — Edit actual weighted | Long-press sheet | T `TodaySetEditorSheet` | Completed F1 weighted set | A | C/U | Edit actual; Actual results. Completion preserved. |
| 18 Today — Typed editor variants | Reps-only / timed / legacy sheet alternatives | T; D; F | F1 reps-only; F5 timed; F4 legacy | A | C/U | Reps only → reps; Timed → seconds; Legacy set → all three fields. No deletion/type picker. |
| 19 Set editors — Error alternatives | Native alert alternatives | T; P historical/set editors | Invalid values or save throws | A | C/U | Nonnegative-values alert versus save-failure alert. Program catches all failures as invalid values. |
| 20 Program — Week | Program selected-date planning | P `weekHeader`, `dateButton`, `selectedDateSections`; PC | F1, Aug 14 selected/current | A | S/U | Monday-first Aug 10–16; selected date and planned label below; inline exercise cards. |
| 21 Program — Month | Program Month mode | P `monthGrid`, `monthDateButton`; PC | F1, August 2026 | A | S/U | 42 dates, July 27–September 6; selected/current/outside-month semantics. Native scroll viewport unverified. |
| 22 Program — Empty date | Program current/future empty date | P `selectedDateSections` | No workout on selected nonpast date | A | S/U | No workout planned for this date. / Create workout. |
| 23 Program — Past empty date | Program past empty date | P `isHistorical`, `selectedDateSections` | Empty past date | A | S/U | No recorded workout for this date. No create button. |
| 24 Program — Empty workout and add set | Program after create / after add-exercise | P; VM `addExercise`, `addSet` | Empty workout; then catalog exercise added | A | S/U | Zero-set exercise shows header and Add set. First added set is 0 reps; later sets copy last planned values. No separate Add set sheet. |
| 25 Program — Exercise actions | Exercise menu | P `exerciseRow` | Nonhistorical F1/F2 | A | C/U | First exercise: Move down/Delete; last: Move up/Delete. Boundary actions omitted. |
| 26 Program — Set ordering | Set menu | P `exerciseRow` | F2 two-set Bench Press | A | C/U | Menu present only with >1 set. First Move down; last Move up. No drag handles assumed. |
| 27 Program — Edit set | Program set sheet | P `ProgramSetEditorSheet` | Nonhistorical F1 weighted set | A | C/U | Weighted/Reps only/Timed segmented picker; relevant fields; Delete set; Cancel/Save. |
| 28 Program — Typed plan variants | Reps-only / timed plan alternatives | P `ProgramSetEditorSheet` | F1 reps-only or F5 timed | A | C/U | Hidden irrelevant fields; 0/1 technical values not added to row text. |
| 29 Program — Edit completed plan | Program completed set sheet | P `ProgramSetEditorSheet`; D | Completed F1 set | A | C/U | Edit plan; Bench Press plan; Actual results are unchanged. Initializes planned values. |
| 30 Program — Legacy plan | Program legacy set sheet | P `ProgramSetEditorSheet`; D | F4 | A | C/U | Recorded-values notice; three fields until type changed; selector has no legacy segment. Native no-selection appearance unverified. |
| 31 Program — Delete exercise | Confirmation dialog | P `pendingDeletion` | Exercise Delete selected | A | C/U | Delete Bench Press? / configured sets removed / Delete / Cancel. |
| 32 Program — Delete set | Confirmation dialog over editor | P `ProgramSetEditorSheet` | Delete set selected | A | C/U | Delete this set? / This set will be removed from the workout. / Delete set / Cancel. |
| 33 Program — Workout actions and deletion | Menu and confirmation alternatives | P toolbar, `pendingWorkoutDeletion` | Nonhistorical workout exists | A | C/U | Copy workout / Repeat workout / Delete workout; destructive dialog includes recorded results. |
| 34 Program — Historical workout | Program past-date shared surface | P history rows; C F3 | F3 selected | A | S/U | Actual/planned labels and Skipped; completed set opens editor. No separate history route, no planning toolbar. |
| 35 Program — Historical actual editor | Historical completed-set sheet | P `HistoricalActualEditorSheet` | F3 completed set selected | A | C/U | Edit actual; Actual results; values 7/65. Type-specific fields; no delete. |
| 36 Exercises — Picker | Program → Add exercise sheet | E; catalog; VM | Existing nonpast workout, empty search | A | C/U | Your exercises only if nonempty; Exercises system section; category captions; secondary Add custom exercise. Search reveal behavior unverified. |
| 37 Exercises — No results | Picker empty results | E | Query with no matches | A | S/U | Exact empty-results copy and Add custom exercise; query value not invented. |
| 38 Exercises — Custom and errors | Navigation destination in picker | E `CustomExerciseView` | Add custom; normalized query seeds name | A | C/U | Name only; Add disabled when blank; Cancel/Add. Error variants separately labeled; no category input. |
| 39 Copy — Same date | Initial Copy sheet | P `CopyWorkoutSheet` | F1 source; initial destination equals source | A | C/U | Source date/2 exercises · 2 sets; Choose a different date.; Copy disabled. |
| 40 Copy — Valid destination | Copy sheet | P; VM `copyWorkout` | F1 source; empty Aug 21 destination | A | C/U | Creates an independent planned workout.; Copy enabled. Success dismisses and selects destination. |
| 41 Copy — Occupied destination | Copy sheet | P `destinationMessage` | Destination different but already occupied | A | C/U | A workout already exists on this date. Choose another date.; Copy disabled. |
| 42 Repeat — Default schedule | Repeat sheet | P `RepeatWorkoutSheet` | F1 source, no occupied future dates | A | C/U | Every week; 4 weeks; 4 independent workouts will be created.; Create. |
| 43 Repeat — Until date and conflicts | Repeat alternative states | P `candidateDates`, `scheduleSummary` | Until date chosen; optional occupied generated dates | A | C/U | Cadence 1–4 weeks; date picker appears only for Until date; occupied dates individually listed. Counts remain symbolic without fixture. |
| 44 Repeat — Nothing to create | Repeat disabled alternatives | P `scheduleSummary` | No repetition in range OR every candidate occupied | A | S/U | Exact two alternative messages; Create disabled; no success page. |
| 45 Program — Availability and errors | Program loading/error alternatives | P; DB | loading / unavailable(false) / unavailable(true) / mutation failure | A | C/U | Calendar remains above selected-date state. Copy/repeat failure alerts separately recorded. |
| 46 Settings — Unset profile | Settings root | S; C; D defaults | Authenticated, empty profile/history, nil email fixture | A; Light schematic | S/U | Health profile, preferences, account, danger zone; fallback Your account is ready. No About/version row. |
| 47 Settings — Populated profile | Settings root | S `profileSummary`, `weightSummary`; F5 | 180 cm, current 81 kg, one saved record | A | S/U | 180 cm · BMI 25.0; 81 kg · 1 saved. No fabricated age/email. |
| 48 Settings — Dark and units | Settings preferences | S; C; G; F | Dark and lb selected | A; Dark semantic schematic | S/U | Preferences persist per user; weight converted only for display. Exact native segmented visuals unverified. |
| 49 Profile — Unset | Edit profile sheet | S `ProfileEditorSheet` | Empty profile | A | C/U | Sex Not specified; Add date of birth off; Height (cm) blank; exact BMI-use footer. |
| 50 Profile — Date of birth enabled | Edit profile sheet | S; D | DOB toggle on | A | C/U | DatePicker max Date(); Female/Male/Prefer not to say plus nil. Actual date is unresolved, no guessed age. |
| 51 Body weight — Empty history | Body weight sheet | S `BodyWeightHistorySheet` | No measurements | A | C/U | Log body weight; Weight (kg); Date; Save measurement; Recent measurements empty; Done. |
| 52 Body weight — History | Body weight sheet | S; F5 | 80 kg Sept 2, 81 kg Sept 1, 2026 | A | C/U | Descending local-date order; values canonical kg. Rows are editable buttons, not a chart. |
| 53 Body weight — Edit and delete | Same-sheet edit / swipe alternatives | S `BodyWeightHistorySheet`; DB | Select saved measurement / swipe row | A | C/U | Update measurement; native destructive Delete; failed deletion preserves/restores row. No separate edit route. |
| 54 Settings — Feedback alternatives | Preference/profile/history/account errors | S; AU; DB | Corresponding failure | A | C/U | Inline preference/account errors; profile/weight validation alerts; measurement deletion failure. Failure reachability varies by repository. |
| 55 Account — Delete confirmation | Settings native alert | S `.alert("Delete account?")` | Delete account selected | A | C/U | Exact permanent-deletion copy; Cancel/Delete account. Log out has no confirmation in source. |
| 56 Account — Verify with Apple | Account deletion sheet | S nativeAppleDeletionButton; AU | Linked Apple provider | A | C/U | Verify with Apple copy; SDK continue button black; provider UI unverified/paid capability deferred. |
| 57 Account — Verify with Google | Account deletion sheet | S nativeGoogleDeletionButton; AU | Linked Google provider, no Apple precedence | A | C/U | Verify with Google copy; SDK Google button; same-account verification; failures retain session. |
| 58 Auth — Registration | Default signed-out route | R; AU | Auth resolved nil | OS | C/U | Gym Checklist nav title; Create your account; Email/Password/Confirm password; Create account; production SDK buttons. |
| 59 Auth — Sign in | Registration mode toggle | R; AU | isSignIn=true | OS | C/U | Two fields; Sign in; Forgot password?; Create an account; provider SDK controls. |
| 60 Auth — Password reset | Sign in → Forgot password? | R; AU | isResettingPassword=true | OS | C/U | Email only; Send reset instructions; Back to sign in. No providers/password fields. |
| 61 Auth — Reset sent and feedback | Reset feedback / auth errors / submitting alternatives | R `buttonTitle`; AU | Reset response or matching validation/provider failure | OS | C/U | Enumeration-safe reset message; Creating account…/Signing in…/Sending…; disabled submit/providers. |
| 62 Startup — Resolution and unavailable setup | App routing alternatives | C; APP; FirebaseBootstrap | Auth resolving OR release invalid/missing config | OS | C/U | ProgressView; App setup unavailable. Debug invalid setup traps instead; not an onboarding screen. |
| 63 Appearance — System behavior | Audit contract, not app route | C; S; G | Appearance system/light/dark | A / OS | S/U | System follows OS; explicit Light/Dark override authenticated tabs/sheets. No third fixed System palette. |

## B. Representative runtime screenshot set

Phase 2 uses real current-MVP runtime screenshots as its representative visual set. In the working Pencil file they belong under:

`02 — Current App / Runtime References`

The screenshots may remain locked bitmap references. Editable reconstruction is explicitly not required: repeated controlled Pencil AI attempts materially changed geometry, typography, spacing, workout data, and native controls, so those reconstructions were rejected as inaccurate evidence.

The current screenshot collection covers the main visual surfaces across Today, Program Week/Month and editing, exercise selection/custom exercise, copy/repeat, Settings/Profile/body weight, and authentication. The collection is representative rather than exhaustive. Conditional, error, offline, provider-verification, and other uncommon states remain fully documented in section A and need additional runtime capture only when a later design decision depends on their exact native rendering.

## Explicit tokens, geometry, and native boundaries

| Source | Proven declaration | Rendering not proven here |
| --- | --- | --- |
| G | accent RGB(0.05, 0.40, 0.23), approximately `#0D663B`; foreground dark RGB(0.37, 0.77, 0.54), approximately `#5EC48A`; foreground light equals accent; soft foreground alpha 0.16 | Color-space/raster conversion, display contrast under accessibility settings |
| G | secondarySystemGroupedBackground / tertiarySystemGroupedBackground / separator / Color.red / Color.secondary / primary at 8% border | Exact resolved RGBA values in each iOS version/appearance |
| G | GymCard padding 16, continuous radius 18, border 1; uppercase caption semibold header tracking 0.5 | Continuous-corner curve and semantic-font metrics |
| T | Main stack gap 24; vertical padding 20; header gap 4; exercise gap 8; header min height 44; set group radius 12; set row gap 12, horizontal padding 14, min height 48 | Default horizontal padding, safe areas, actual Dynamic Type row heights |
| T overlay | 28% black scrim; content gap 16; 78×78 circle; symbol font 32 semibold; content padding 28; outside padding 32; radius 20; Done min height 44 | Final intrinsic panel height, native button width, SF Symbol path |
| P | Calendar stack gap 8; outer content gap 12; Week gap 2, cell min height 58 plus vertical padding 4, radius 10, selected border 2; Month gap 6, 7 columns min 36, cell min 44, radius 9, selected border 1.5 | Native large-title collapse, exact viewport fit, Section header treatment outside List |
| P copy/repeat | Content gap 20; card padding/radius from G; source icon box 38, radius 10; full-width action min height 48 | DatePicker and segmented-control metrics; no explicit sheet detents |
| S | Root gap 24; preferences gap 16; profile icon boxes 38, radius 10; native Form/List editors | Native row insets, sheet height, menu/toggle/date picker presentation |
| R | Native Form and NavigationStack; SDK provider controls min height 44; Apple style black | System tint; Google SDK styling/logo; keyboard, native screen and row dimensions |

Fonts are SwiftUI semantic styles (largeTitle bold, title2 semibold/bold, title3 semibold, headline, body, subheadline, footnote, caption/caption2), not a repository-defined numeric typography scale. A cross-platform audit font is a labeled substitute, not verified San Francisco rendering. SF Symbols are named in evidence rather than replaced by unrelated icon-library glyphs.

## Remaining runtime verification

1. Use the existing physical-iPhone screenshots as the visual baseline for captured current-MVP states.
2. Capture additional runtime states only when their exact native rendering matters to a Phase 3/5 design decision, especially skip/restore menus, destructive confirmations, provider verification, offline/error feedback, keyboard behavior, and other system-owned surfaces.
3. Keep accessibility-specific verification separate: Dynamic Type, VoiceOver, contrast, focus return, and large-text wrapping are not proven by the current representative screenshots.
4. Real Google/Apple SDK controls and paid/deferred Apple capability remain subject to the existing project policy.

## Scope and Pencil handoff

Phase 1 files and the historical image are read-only inputs. Production, tests, project, CI, Firebase, product behavior, progress checkpoint, QA assets, and Phase 3+ work are outside this commit.

This documentation change does not modify `design/GymChecklist_Redesign.pen`. The user's working Pencil file already contains the current runtime screenshot references; this document does not claim that those bitmap references have been committed to Git yet. Section A remains the exhaustive 64-state implementation inventory, while the screenshot collection is the accepted representative visual evidence for Phase 2.
