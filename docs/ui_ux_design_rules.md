# Gym Checklist — UI/UX Design Rules

**Status:** active design constraints for Phase 5 and later SwiftUI implementation.  
**Derived from:** product/UX specs, Phase 2 current-app audit, and Phase 4 UI/UX research.  
**Approval boundary:** these rules constrain design; they do not make a Phase 5 candidate approved. User approval is still required before implementation.

## 1. Product invariant

```text
Open app -> Today -> one tap per completed set -> close app
```

Every UI decision must preserve or improve this path.

## 2. Platform

- Native iOS app, iOS 17+.
- Prefer SwiftUI system navigation, tab bars, lists, forms, menus, sheets, pickers, alerts and confirmation dialogs.
- Do not manually reproduce a specific OS generation of system chrome.
- Custom visual identity belongs mainly in content, state and reusable app components.
- Newer OS-specific styling may be adopted through native APIs/availability checks, never by breaking older supported versions.

## 3. Brand

- Approved direction: green/lime/mint.
- Purple is not part of the active visual direction.
- Brand color is restrained.
- Use accent mainly for completion, selection, primary actions and compact feedback.
- Do not paint every control, surface or page with the accent.
- Do not repeat the logo throughout authenticated product screens.

## 4. Semantic color tokens

Required conceptual tokens:
- `accentFill`
- `accentForeground`
- `accentSoft`
- `surfaceBase`
- `surfaceGrouped`
- `surfaceElevated`
- `textPrimary`
- `textSecondary`
- `separator`
- `destructive`
- `scrim`

Rules:
- Light/Dark values are semantic pairs, not inversions.
- Prefer system semantic colors for backgrounds, labels and separators.
- Completion/error/status must never rely on color alone.

## 5. Typography

- Use San Francisco/system font for MVP.
- Use semantic Dynamic Type styles.
- Large title for top-level orientation where appropriate.
- Headline/title for exercise identity.
- Body for set values and primary row content.
- Secondary/caption styles for metadata.
- No arbitrary fixed typography scale.
- No truncation caused by fixed-height text containers.
- Allow wrapping when Dynamic Type requires it.

## 6. Layout and density

Baseline:
- screen inset: 16–20 pt;
- spacing rhythm: multiples of 4 pt;
- interactive minimum: 44 pt;
- Today set row target: 48–52 pt minimum;
- subtle group radius: ~12–16 pt;
- avoid heavy shadows.

Today:
- lowest cognitive density;
- exercise group + internal set rows;
- no card per set;
- no dashboard metrics.

Program:
- denser editing/planning surface is acceptable.

## 7. Today

Hierarchy:
1. Today/navigation title;
2. local date/context;
3. exercise;
4. set rows;
5. secondary restore/offline feedback only when needed.

Set row:
- entire row tappable;
- leading incomplete/completed symbol;
- one tap completes;
- second tap undoes;
- no confirmation;
- no navigation;
- preserve scroll position.

Never add to Today:
- Start Workout;
- Finish Workout;
- timer;
- coaching;
- charts;
- progress rings;
- recommendations;
- calories;
- PRs;
- social content.

## 8. Today secondary actions

- Skip exercise stays behind exercise-level menu/context action.
- Restore skipped exercises stays available but low prominence.
- Do not show Edit/Delete/Skip beside every set.
- Long press set -> compact edit sheet.
- Today set editor must not delete sets.

## 9. Program

- Week and Month share one selected date.
- Week: seven equal date targets.
- Month: compact fixed calendar grid.
- State indicator uses symbol/shape + accessibility label, not color only.
- Today, selected date, outside-month state and workout state are distinct concepts.
- Week/Month uses segmented control.
- Program may expose add/edit/reorder/copy/repeat/delete.
- Destructive mutations require native confirmation.

## 10. Lists, forms and sheets

Prefer native grouped structures for:
- Program editors;
- custom exercise;
- profile;
- body weight;
- preferences;
- account;
- auth.

Use focused sheets:
- clear title;
- standard Cancel/Save or Done placement;
- only relevant controls;
- inline validation where practical;
- keyboard-safe scrolling.

## 11. Settings/Profile

Order:
1. Profile;
2. Body weight;
3. Preferences;
4. Account;
5. Danger zone.

- Body-weight history is a compact dated list.
- No chart/dashboard for body weight in MVP.
- BMI is neutral information.
- Use native segmented controls/pickers/swipe actions.

## 12. Authentication

- Minimal native hierarchy.
- No onboarding carousel.
- One clear primary submit action.
- Provider controls follow provider/system rules.
- Errors are human-readable and near the relevant form context.
- Sign in with Apple styling follows Apple requirements.

## 13. Empty/loading/offline/error

- Short state message.
- At most one primary contextual action.
- Cached Today remains interactive offline.
- Sync/offline feedback is secondary.
- No manual Sync.
- Do not block usable cached content with a full-screen network state.

## 14. Workout completion

- In-place overlay/modal.
- Small symbol/illustration.
- Short encouragement.
- One dismiss action.
- No stats, share, rating request or navigation.
- Motion is optional and respects Reduce Motion.

## 15. Iconography

- Prefer SF Symbols for familiar platform actions.
- Keep one icon vocabulary.
- Pair ambiguous actions/states with text or accessibility labels.
- Destructive actions must not rely on a trash icon alone.

## 16. Light/Dark

- One design system.
- Semantic surfaces and label colors.
- Verify completed/selected/error/disabled states in both appearances.
- Avoid hard-coded white/black system surfaces.
- Preserve elevated/background separation in dark mode.

## 17. Accessibility

Required:
- Dynamic Type resilience;
- VoiceOver labels/values/actions;
- non-color-only state;
- practical touch targets;
- sufficient contrast;
- Reduce Motion;
- predictable focus and dismissal.

## 18. Design review gate

Before approving any Phase 5 screen:
1. Does it preserve product behavior?
2. Does it preserve one-tap set completion?
3. Is Today still quieter than Program?
4. Is any visual element unnecessary during execution?
5. Are rare actions secondary?
6. Does the screen work in Light and Dark?
7. Does it remain feasible with native SwiftUI?
8. Does it avoid manual imitation of system chrome?
9. Does it work with Dynamic Type and VoiceOver semantics?
10. Is state understandable without color alone?

If not, revise before approval.
