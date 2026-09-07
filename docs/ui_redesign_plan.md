# Gym Checklist — UI Redesign Plan

## Purpose

Create one approved Pencil visual source of truth for Gym Checklist before changing production SwiftUI.

The project currently has three different visual representations:
1. the historical reference image `today-program-mockup.png`;
2. the current Pencil design file;
3. the current implementation in the iOS repository.

This plan reconciles them into one approved Pencil design and only then implements that design in the app.

Pencil working file:
`design/GymChecklist_Redesign.pen` (tracked in the repository)

## Governing rules

- Do not change production UI while the design is still being explored.
- The historical mockup is a visual baseline, not an authoritative product specification.
- Current explicit user decisions have highest priority.
- Product behavior must remain consistent with `docs/product_spec.md` and `docs/ux_spec.md` unless the user explicitly approves a behavior change.
- Existing application behavior and repository state must be inspected before adapting the historical mockup.
- Pencil becomes the visual source of truth only after explicit user approval.
- After design approval, update relevant UX documentation before or together with implementation so Figma, specs, and code do not diverge again.
- Any production/test/project-code change after the current approved candidate invalidates the existing authoritative macOS candidate evidence and must follow the repository's two-pass remote-gate policy.
- Protect the core invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

## Source-of-truth priority during redesign

1. explicit current user decision;
2. approved product behavior in `docs/product_spec.md`;
3. approved UX rules in `docs/ux_spec.md`;
4. current implemented behavior where it does not conflict with the above;
5. historical reference mockup.

The historical reference must first be reproduced faithfully for comparison, even where parts of it are later rejected as obsolete.

---

## Phase 1 — Reconstruct the historical reference

**Tooling:** ChatGPT + Pencil.

Create a Pencil canvas section using this frame-name prefix:

`01 — Original Reference / …`

Tasks:
- reproduce every screen/state visible in `today-program-mockup.png` as faithfully as possible;
- current expected inventory is 17 screens/states;
- match layout, hierarchy, spacing, typography, light/dark appearance, sheets, navigation, empty states, authentication, and other visible states;
- make UI elements editable rather than placing the whole source image as one bitmap;
- preserve the original visual decisions at this stage;
- do not redesign, modernize, recolor, simplify, or reconcile with the current app yet.

Acceptance:
- no source screen/state is omitted;
- screen count and ordering are documented;
- visual comparison against the source image is possible, including exported frame screenshots;
- the page is clearly labeled as historical/non-authoritative.

---

## Phase 2 — Audit the current application

**Tooling:** ChatGPT + GitHub/repository + Pencil.

Create a Pencil canvas section using this frame-name prefix:

`02 — Current App / …`

Inspect the live `dev` branch, including:
- `AGENTS.md`;
- `docs/progress.md`;
- `docs/product_spec.md`;
- `docs/ux_spec.md`;
- `docs/architecture.md`;
- relevant SwiftUI views;
- shared UI components;
- design tokens;
- colors;
- typography;
- spacing and radii;
- navigation;
- Today;
- Program Week and Month;
- Program editing flows;
- sheets and menus;
- Settings/Profile;
- authentication;
- empty/completion states;
- System/Light/Dark behavior.

Where source code is insufficient to prove actual rendering, use current screenshots from the physical iPhone or simulator when available.

Output:
- a visual reconstruction/inventory of the current app;
- a short gap matrix between historical mockup, current product requirements, and current implementation.

Do not modify production SwiftUI in this phase.

---

## Phase 3 — Reconcile the product and visual models

**Tooling:** ChatGPT + Pencil.

Create a Pencil canvas section using this frame-name prefix:

`03 — Adapted / …`

Tasks:
- combine useful structure from the historical reference with current approved features and behavior;
- preserve the current green/lime/mint brand direction unless the user changes it;
- remove historical interactions that conflict with current specs;
- keep native iOS behavior where it improves clarity and reduces maintenance;
- explicitly record important conflicts and the chosen resolution.

Examples of historical content that must not be copied blindly:
- Today must not gain a Start Workout flow;
- Today long-press editing must not expose obsolete set deletion if current UX rules prohibit it;
- top-level navigation and Program behavior must match current product rules.

Acceptance:
- every major screen has a defined role;
- no known product requirement is accidentally lost;
- no obsolete historical behavior is reintroduced silently.

---

## Phase 4 — Design research

**Tooling:** ChatGPT web research; Work may be used for a deeper dedicated research pass.

Research:
- Apple Human Interface Guidelines;
- current Apple first-party iOS patterns;
- Apple Health / Fitness;
- Reminders;
- relevant modern checklist/productivity apps;
- Strong;
- Hevy;
- Fitbod;
- Liftin';
- other high-quality workout/planning apps when useful.

Research topics:
- checklist completion;
- tappable set rows;
- hierarchy and density;
- week/month navigation;
- list editing;
- sheets;
- menus;
- destructive actions;
- empty states;
- completion feedback;
- settings;
- dark mode;
- accessibility;
- Dynamic Type;
- native iOS 17+ patterns.

Research output should be decision-oriented:

`Problem -> references -> chosen pattern -> why it fits Gym Checklist`

Do not turn the product into a generic fitness dashboard. Research must support the core invariant and minimalist checklist mental model.

---

## Phase 5 — Create Final Design Candidate

**Tooling:** ChatGPT + Pencil.

Create a Pencil canvas section using this frame-name prefix:

`04 — Final Candidate / …`

Also create a reusable `Components / Tokens` area in the same Pencil file.

The candidate should cover all relevant MVP surfaces and important states, including:
- Today with incomplete/partial/completed sets;
- skipped/restored exercise handling;
- Today rest day;
- Today no-program state;
- long-press set editor;
- workout completion overlay;
- Program Week;
- Program Month;
- selected-date workout details;
- add/edit/remove/reorder exercise and set flows;
- exercise picker;
- custom exercise;
- copy workout;
- repeat workout;
- historical workout editing;
- Settings/Profile;
- body-weight history;
- appearance and unit settings;
- authentication;
- account/destructive actions;
- relevant loading/offline/error states where they materially affect UX;
- Light and Dark appearance.

Reusable foundations should cover:
- color tokens;
- typography;
- spacing;
- radii;
- buttons;
- rows;
- cards/sections;
- navigation;
- sheets;
- form controls;
- completion states;
- destructive states.

Acceptance:
- screens form one coherent design system;
- Today remains the simplest and fastest surface;
- important states are represented;
- accessibility is considered;
- design is feasible in native SwiftUI without unnecessary custom frameworks.

---

## Phase 6 — User review

Stop before implementation.

The user reviews the Pencil candidate and records changes.

No production SwiftUI changes during this phase.

---

## Phase 7 — Iterate to approval

Apply user feedback only in Pencil until the design is explicitly approved.

Repeat as needed:

`Final v1 -> v2 -> ... -> APPROVED`

Do not treat silence or partial acceptance as design approval.

---

## Phase 8 — Design freeze

After explicit approval:

1. mark the approved Pencil canvas section/version clearly;
2. treat approved Pencil as the visual source of truth;
3. update `docs/ux_spec.md` and any other affected product documentation so approved behavior and visual rules are durable;
4. prepare an implementation mapping from approved Figma screens/components to SwiftUI files/components;
5. record any deliberate implementation tolerances or native-system substitutions.

Only after this freeze may production UI implementation begin.

---

## Phase 9 — Implement in SwiftUI

**Tooling:** Codex/repository task workflow.

Implement in coherent batches rather than one giant task:

1. design tokens and shared UI components;
2. Today;
3. Program navigation and date surfaces;
4. Program editors, sheets, copy/repeat flows;
5. Settings/Profile;
6. Auth and empty/completion states;
7. final visual consistency and accessibility pass;
8. regression tests and relevant UI tests;
9. Pass A implementation/hardening;
10. separate Pass B final remote-gate audit and authoritative macOS verification when justified.

Implementation rules:
- approved Pencil is the visual reference;
- `product_spec.md` remains authoritative for product behavior;
- do not invent missing UI in Codex without returning to the approved design/spec decision;
- preserve offline behavior, ownership/security, migrations, and existing data semantics;
- prefer native SwiftUI and system components where they match the approved design;
- keep Today interaction count minimal;
- compare implementation screenshots against approved Pencil before final acceptance.

---

## Tool responsibility

| Work | Primary tool |
| --- | --- |
| Historical mockup reconstruction | ChatGPT + Pencil |
| Current app/repository audit | ChatGPT + GitHub + Pencil |
| Reconciliation | ChatGPT + Pencil |
| Design research | ChatGPT; Work optional for deep research |
| Final design | ChatGPT + Pencil |
| User review/iterations | ChatGPT + Pencil |
| Design freeze/spec update | ChatGPT + repository |
| SwiftUI implementation | Codex |
| Tests/hardening/CI | Codex |
| Final visual QA | ChatGPT + Pencil + real screenshots |

## Current checkpoint at plan creation

At the time this plan was created:
- branch: `dev`;
- current approved candidate source recorded in `docs/progress.md`: `e17cb8173a6373059729226453c568e976954d33`;
- authoritative macOS candidate run `33991955146` is green for that exact candidate;
- production UI implementation must not be changed until the design has been approved and frozen;
- any later production/test/project-code change invalidates that current remote-gate evidence and must follow the repository rules again.
