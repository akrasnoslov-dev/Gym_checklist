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

## Current release-scope decision
Until the user explicitly reactivates release work:
- paid Apple Developer membership is deferred;
- App Store Connect is deferred;
- TestFlight is deferred;
- release signing/secrets are deferred;
- final App Store icon decision is deferred;
- live Sign in with Apple release configuration is deferred where it requires the paid Apple path.

These items may remain documented in the long-term implementation plan, but they are **not current blockers and not runnable backlog**.

Current goal: finish the full originally approved MVP defined by the product, UX, architecture, and active-plan acceptance criteria; then complete final verification and provide one physical-iPhone candidate for the user's next product review. A preliminary device preview is only an intermediate checkpoint, not a product-acceptance stop or freeze. Do not request another product review or hand off an intentionally incomplete in-memory demo before the full MVP persistence, authentication, offline, security, and product paths are complete to the maximum extent possible without the deferred paid Apple distribution path.

Google/Firebase development configuration and non-production validation are still relevant because they are part of the app itself, not only App Store release.


## Active MVP finish lock
This lock remains active until the completed original-MVP candidate—not an intermediate demo or preview—is ready for the user's product acceptance.

Rules:
- Freeze scope. Do not add features, opportunistic refactors, architecture cleanup, test-suite cleanup, or documentation expansion unless required to fix a confirmed MVP blocker.
- The Program navigation selector issue already classified as `KNOWN_UI_TEST_HARNESS_FLAKE` is non-blocking. Run `33077303696` was the final focused diagnostic for that surface. Do not rerun it without new independent product evidence.
- A green smoke run is a checkpoint, not a handoff. Continue resolving all technically achievable original-MVP implementation and verification work, including real Firebase/auth/offline/security paths.
- Run exactly one final macOS `full` verification after the final product/UX reconciliation. Fix only confirmed MVP defects it exposes.
- The final handoff is one completed physical-iPhone candidate using the real MVP architecture. The prior in-memory `MVP_DEMO` preview does not satisfy this lock.
- Do not activate TestFlight, App Store, paid signing, release automation, final icon work, or `dev -> main` work.
- M9.2 is runnable only for an actual acceptance blocker. A stale `TODO` label alone is not work.
- Stop voluntarily only when the completed MVP candidate is ready for product acceptance, or all independent work is complete and one exact external user action is required.

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
- `smoke` as the normal iterative macOS gate. It runs all unit tests plus a small set of critical stable UI flows.
- exact filtered `unit`/`ui` runs for one known failing test.
- `full` only once after final original-MVP reconciliation, after high-risk cross-cutting changes, or when explicitly requested. The final original-MVP candidate requires that checkpoint before handoff.

Do not use `build -> unit -> ui -> full` as a routine scheduler.

When one exact test fails:
- dispatch `verification_scope=ui` with `test_filter=GymChecklistUITests/<TestClass>/<testMethod>`, or the equivalent unit filter;
- do not rerun the whole UI/unit target;
- after the exact test passes, use `smoke`, not automatically `full`;
- return to `full` only at the next broad checkpoint.

### Flaky UI-test budget
Do not spend an entire Codex task chasing XCTest-only instability.
- Maximum: two consecutive focused reruns of the same UI test without new independent evidence of a product bug.
- If the remaining failure is accessibility/selector/timing instability, domain/unit coverage is green, and the product behavior is not independently proven broken, record `KNOWN_UI_TEST_HARNESS_FLAKE` and continue MVP work.
- Keep the test in the full regression suite for later hardening; do not silently delete coverage.
- Never change production behavior solely to make XCTest discover an element. Production changes require independent product/UX/state evidence.

A CI result proves the checkpoint SHA it actually ran against.

### CI while implementation exists
CI is background verification. After dispatching a run, continue other safe implementation immediately.

### CI wait budget
Pending CI is not a voluntary stop condition. Continue independent useful MVP work while it runs. If none remains, wait or poll reasonably for its terminal result, process it immediately, and continue. Record an in-flight run only for continuity when an actual platform, tool, or context limit forces a checkpoint; never end a task merely to conserve quota while CI is pending.

When CI completes:
- green focused run -> run `smoke` if a coherent checkpoint is ready;
- green smoke -> continue implementation or prepare the MVP/device handoff;
- failure -> inspect once and fix only the narrow reported surface;
- full -> use only for broad reconciliation, not every small fix;
- cancelled/infrastructure failure -> record no pass/fail evidence and rerun only when justified.

## Final-response gate
Before a final response:
1. inspect Git/worktree, `docs/progress.md`, active backlog, and relevant CI;
2. identify the exact next safe action;
3. if it is executable now, execute it instead of stopping;
4. if CI is running, continue independent MVP work or wait reasonably for its terminal result; CI pending alone is never a voluntary stop condition;
5. if a task is externally blocked, scan the rest of the active backlog;
6. stop only when no technically safe active work remains and the remaining blocker is genuinely external/user-required, destructive approval/product decision is required, a real failure blocks all continuation, a required tool is unavailable, or the platform/model/tool limit actually ends execution.

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
