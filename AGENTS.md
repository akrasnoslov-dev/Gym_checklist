# AGENTS.md

## Project
Gym Checklist (`akrasnoslov-dev/Gym_checklist`) is a native iOS app for executing a pre-planned gym workout with minimal interaction.

Protected product invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

Do not add unapproved dashboards, statistics, timers, coaching, social features, calories, PRs, recommendations, exercise media, or other friction to Today.

## Read at the start of a Codex task
Read only the core context first:
- `AGENTS.md`
- `docs/progress.md`
- `docs/implementation_plan.md` for the active/relevant task sections
- `docs/product_spec.md`
- `docs/ux_spec.md`
- `docs/architecture.md`
- `agents/routing.toml`

Then inspect Git/worktree state, recent commits/diffs, relevant source/tests, and current CI.

Do **not** preload the whole `docs/` directory. Setup, Firebase, security, offline, acceptance, and release documents are reference material; read them only when the current task needs them.

`docs/codex_instructions.md` is a small compatibility/command reference, not a second scheduler.

## Source of truth
Priority:
1. explicit current user instruction;
2. `docs/product_spec.md` for product behavior;
3. `docs/ux_spec.md` for UX;
4. `docs/architecture.md` for technical boundaries;
5. `docs/implementation_plan.md` for task definitions and acceptance criteria;
6. actual Git/code/tests plus `docs/progress.md` for current runtime state.

The repository is durable memory. Chat history is not.

Never discard coherent local work merely because `origin/dev` is older. Never reset or overwrite uncommitted user work.

## Current pre-payment acceptance decision
Until the user explicitly accepts the functional MVP and reactivates paid release work, use **only zero-cost development and validation paths**.

Current runnable scope:
- fix every confirmed MVP product defect;
- keep all required CI green, including a final authoritative macOS `full` run on the exact candidate SHA;
- use a non-production Firebase **Spark** project for every supported no-cost live check;
- validate email/password auth, Google Sign-In, Firestore persistence and owner isolation, cached offline execution/reconnect, Analytics, Crashlytics, and manual accessibility where those checks remain free;
- produce a physical-iPhone candidate through a free personal-device path when available and use it for the user's product acceptance.

Explicitly deferred until the user approves payment/release work:
- paid Apple Developer membership;
- App Store Connect and TestFlight;
- release signing/secrets and paid distribution automation;
- final App Store icon/release metadata decisions that are needed only for distribution;
- live Sign in with Apple configuration where it requires paid Apple capabilities;
- any Firebase/Google Cloud action that requires enabling billing or moving from Spark to Blaze, including live deployment of `functions:deleteAccount` if billing is required;
- `dev -> main` release work.

Do not attach a billing account, upgrade Firebase to Blaze, buy Apple membership, or activate any paid service without explicit user approval.

The current goal is **pre-payment functional MVP acceptance**: all functionality that can be implemented and verified for free must be complete and proven first. Paid-only functionality remains documented as a known unverified limitation and is not a current acceptance blocker.

## Active MVP finish lock
This lock remains active until the completed original-MVP candidate—not an intermediate demo or preview—is ready for the user's product acceptance.

Rules:
- Freeze scope. Do not add features, opportunistic refactors, architecture cleanup, test-suite cleanup, or documentation expansion unless required to fix a confirmed MVP blocker.
- The Program week/date selector is a **confirmed product defect**: the user observed it failing on a previously installed physical-iPhone build, and the final macOS run reproduced failure on the same surface. The old `KNOWN_UI_TEST_HARNESS_FLAKE` classification is revoked. Reproduce, diagnose, fix production behavior as needed, add regression coverage, and verify it before acceptance.
- A green smoke run is a checkpoint, not a handoff. Continue resolving all technically achievable original-MVP implementation and verification work, including free Firebase Spark auth/persistence/offline/security paths.
- The final candidate must have a **green authoritative macOS `full` run on its exact SHA**. If `full` fails, diagnose the failure, fix any product/test defect that can affect acceptance, and rerun the required gates until the final run is green. A red final run is never an acceptable handoff.
- The final handoff is one completed physical-iPhone candidate using the real MVP architecture and all no-cost live services that can be validated on Spark. The prior in-memory `MVP_DEMO` preview does not satisfy this lock.
- Do not activate TestFlight, App Store, paid signing, release automation, final icon work, Firebase Blaze/billing, or `dev -> main` work.
- M9.2 is active now for the confirmed Program date-selector defect. After that defect is resolved, M9.2 remains runnable only for real acceptance blockers/regressions.
- Stop voluntarily only when all no-cost implementation/verification work is complete, the final exact candidate SHA has green required CI, and the completed physical-iPhone candidate is ready for product acceptance; or when one exact external zero-cost user action is genuinely required and no independent work remains.

## Autonomous work loop
Repeat until a real stop condition exists:
1. reconstruct current Git/code/test/CI state;
2. select the highest-priority technically safe runnable action anywhere in the active backlog;
3. implement the smallest coherent solution;
4. add/update tests;
5. run useful local/static checks;
6. self-review against product, UX, architecture, security/privacy, offline behavior, and acceptance criteria;
7. fix established issues;
8. checkpoint coherent work and keep `docs/progress.md` current;
9. run authoritative CI when justified;
10. continue.

A task, milestone, commit, push, review, documentation update, CI dispatch, CI completion, or known `Next:` action is never by itself a reason to stop.

If one task is blocked, scan the full active backlog and continue independent safe work.

Dependencies remain strict for final acceptance/DONE. For implementation scheduling, a dependency pending only isolated CI/live/external evidence may be treated provisionally as satisfied when later work is clearly safe. Never use this to bypass security, ownership, data-integrity, destructive-action, or product-decision boundaries.

## CI policy
Paid CI is not approved. The public repository uses free GitHub-hosted runners.

Linux checks are routine feedback. macOS/Xcode CI is authoritative for iOS.

The macOS workflow is intentionally **not triggered by normal pushes**. Normal pushes should create only the lightweight Linux run; macOS verification is started explicitly with `workflow_dispatch` at a justified checkpoint, or by a pull request. Do not re-add a push trigger to the macOS workflow merely to make it automatic: that creates misleading skipped workflow records and obscures the real verification history.

### Normal macOS strategy
During the current MVP-hardening phase, optimize for reaching a user-visible MVP rather than repeatedly proving the entire regression suite after every small fix.

Use:
- exact filtered `unit`/`ui` runs while diagnosing one blocker;
- `smoke` only when a broad but non-final checkpoint is genuinely useful;
- `candidate` for the final verification of a blocker fix. It builds once, runs the exact blocker test, and if that passes automatically runs the full suite on the same runner/build/SHA;
- standalone `full` only when no focused blocker test exists or when explicitly justified.

Do not use `build -> unit -> ui -> smoke -> full` as a routine scheduler. In particular, do not run a separate smoke between a green blocker-focused test and final full verification; the `candidate` scope replaces that chain.

When one exact test fails:
- during diagnosis, dispatch `verification_scope=ui` with `test_filter=GymChecklistUITests/<TestClass>/<testMethod>`, or the equivalent unit filter;
- after implementing the candidate fix, dispatch exactly one `verification_scope=candidate` run with the same exact `test_filter`;
- if the focused stage fails, inspect that failure and change the code before dispatching another candidate run;
- if the focused stage passes, GitHub proceeds to the full suite automatically without Codex intervention;
- a green `candidate` run therefore satisfies the required final full gate for that exact SHA.

### Flaky UI-test budget
Do not spend an entire Codex task chasing XCTest-only instability.
- Maximum: two consecutive focused reruns of the same UI test **only when there is no independent product-failure evidence**.
- If the remaining failure is accessibility/selector/timing instability, domain/unit coverage is green, and the product behavior is not independently proven broken, record `KNOWN_UI_TEST_HARNESS_FLAKE` and continue MVP work.
- The Program week/date-selector failure is explicitly excluded from this flake allowance because the user independently reproduced the broken behavior on a physical iPhone.
- Keep flaky tests in the regression suite for later hardening; do not silently delete coverage.
- Never change production behavior solely to make XCTest discover an element. Production changes require independent product/UX/state evidence.

A CI result proves the checkpoint SHA it actually ran against.

### Asynchronous CI rule
Do **not** keep a Codex task alive merely to wait for GitHub Actions.

After dispatching a macOS run:
- record the exact run ID, scope, and candidate SHA in `docs/progress.md`;
- continue only work that is genuinely useful and does not invalidate the candidate being tested;
- if no such work exists, end the Codex task immediately. This is an intentional efficient checkpoint, not a failure to continue;
- do not poll the same in-progress run repeatedly.

At the start of the next Codex task:
- read the recorded run once;
- if it is still running, do not reconstruct/review the whole project and do not enter a polling loop; report the still-running gate and end quickly;
- if terminal, process the result immediately.

When CI completes:
- failed focused/candidate stage -> inspect the concise failure summary/artifact, fix the narrow reported surface, then dispatch one new candidate run;
- green `candidate` -> both the focused blocker test and full suite passed on the exact SHA; do not run smoke/full again;
- cancelled/infrastructure failure -> rerun only when justified.

CI logs are intentionally compact. Prefer the failure summary emitted by the workflow; download the diagnostic artifact only when the summary is insufficient.

## Final-response gate
Before a final response:
1. inspect Git/worktree, `docs/progress.md`, active backlog, and relevant CI;
2. identify the exact next safe action;
3. if it is executable now, execute it instead of stopping;
4. if CI is running, follow the asynchronous CI rule: continue only non-invalidating useful work; otherwise record the run and end immediately instead of waiting/polling;
5. if a task is externally blocked, scan the rest of the active backlog;
6. in the current pre-payment acceptance phase, do not hand off a red final candidate as accepted; however, an in-progress CI run is now an explicit efficient stop condition once its run ID/SHA/scope are recorded.

Do not stop merely because Codex wants to summarize.

## Progress-file discipline
`docs/progress.md` is a **short live checkpoint**, not project history.

Keep only:
- current branch/code checkpoint;
- current implementation state;
- current/latest meaningful CI evidence;
- current external/deferred items;
- exact next action.

Do not accumulate old superseded CI runs, old fixed compiler failures, or historical checkpoint archaeology. Git history already stores that.

Do not create a separate progress-only commit after every diagnostic attempt. Update/commit `docs/progress.md` only when the runtime checkpoint materially changes, before a clean stop, or at a broad handoff.

## Product rules
- English only for MVP.
- Top-level navigation: Today / Program / Settings.
- Today opens first after authentication.
- One tap completes a set; tapping again undoes it.
- No Start Workout flow.
- Sets/exercises may be completed in any order.
- Long press opens compact set editing.
- Skip/restore must remain available without cluttering Today.
- One workout maximum per concrete local date.
- Copy/repeat create independent workouts.
- History lives in Program; completed historical actual values may be edited.
- Offline workout execution is mandatory.
- kg/lb supported.
- System/Light/Dark share one design system.
- Completion motivation appears only after the whole workout finishes as a dismissible overlay.

## Architecture/security
Target stack: Swift + SwiftUI, feature-oriented MVVM, repository/service boundaries, Firebase Auth/Firestore/Analytics/Crashlytics, bundled system exercise catalog.

User cloud data must be owner-scoped. Never log or commit passwords, auth tokens, signing secrets, service-account material, `GoogleService-Info.plist`, or unnecessary private workout content. Never weaken security to make tests pass.

## Branching
- `main`: stable/release only.
- `dev`: integration/default development branch.
- focused `feature/*` branches are optional.
- PRs target `dev` by default.
- `dev -> main` only after explicit user approval.
- do not auto-merge without explicit instruction.
