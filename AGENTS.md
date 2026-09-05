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
- App Store listing metadata and other distribution-only visual assets beyond the currently approved app icon;
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
- Do not activate TestFlight, App Store, paid signing, release automation, Firebase Blaze/billing, or `dev -> main` work. The current approved app icon/logo may be maintained as normal product UI/branding.
- M9.2 is active now for the confirmed Program date-selector defect. After that defect is resolved, M9.2 remains runnable only for real acceptance blockers/regressions.
- Stop voluntarily only when all no-cost implementation/verification work is complete, the final exact candidate SHA has green required CI, and the completed physical-iPhone candidate is ready for product acceptance; or after the consolidated external handoff below when execution genuinely requires an unavailable user/external environment.

## External handoff batching rule

A user/external prerequisite is not by itself a reason to stop immediately.

When one or more external actions are required:

1. Scan the entire remaining active MVP backlog.
2. Complete every implementation, static validation, automated test, configuration preparation, script, documentation, and diagnostic step that can be done without the user.
3. Prepare all files, configuration, templates, and commands needed for the external phase.
4. Identify all foreseeable user-required actions across Firebase, Xcode, signing, physical-iPhone validation, accessibility/manual validation, and other active no-cost MVP acceptance work.
5. Combine them into one external handoff; do not stop for the first dependency when another foreseeable dependency would cause another interruption.
6. Infer safe defaults where possible and never ask configuration questions one at a time.
7. Before stopping, verify that no technically safe work remains anywhere in the active no-cost MVP scope.

The one external handoff must state the exact user actions, why each is required, exact commands/paths/settings where applicable, the evidence to return, and the minimum number of user interactions needed. After it, stop only because access to the user's Firebase account, Mac/Xcode, physical iPhone, credentials, or another unavailable external environment is genuinely required.

Do not manufacture work merely to avoid stopping, and do not run redundant CI, reviews, or refactors. The asynchronous CI rule still applies: never keep a Codex task alive merely to wait for or poll GitHub Actions.

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

### macOS dispatch conservation rule
macOS/Xcode CI is an expensive authoritative remote verification gate, **not** the normal development loop and not a substitute for code review.

#### Two-pass remote-gate lock

To prevent using macOS CI as a repeated compiler/test oracle, authoritative macOS dispatch requires one locally exhaustive hardening pass and a separate clean final audit:

**Pass A — implementation/hardening task**
- Any Codex task that changes production Swift, XCTest/UI-test code, persistence/migration behavior, Xcode project configuration, or CI-relevant app code is **not allowed to dispatch macOS CI in that same task**.
- Repeat local inspection, audit, fixes, regression coverage, re-audit, and local/static validation in the same task until the active MVP scope is genuinely locally exhausted. A finding during local review must not force a new task.
- Finish and batch all runnable implementation, regression review, test maintenance, documentation, and local/static checks, then commit/push one coherent candidate checkpoint.
- Record `REMOTE_GATE_READY_FOR_FINAL_AUDIT <SHA>` in `docs/progress.md`.
- Stop without dispatching macOS.

**Pass B — fresh final remote-gate audit task**
- Start from the exact recorded SHA and perform an independent repository-wide preflight review before any macOS dispatch.
- The preflight must inspect changed production/test code, compile/type/concurrency risks, stale assertions, migration/backward-compatibility paths, and active acceptance requirements.
- Run all available local/static/security/offline checks again.
- If the audit requires **any** production/test/project code change, it becomes Pass A: make and re-audit every related fix in the same task until locally exhausted, then commit/push and record a new `REMOTE_GATE_READY_FOR_FINAL_AUDIT <new SHA>` without macOS CI.
- Only when the fresh preflight task requires no production/test/project code changes and finds no remaining runnable work may it record `REMOTE_GATE_APPROVED <SHA>` and dispatch exactly one justified macOS candidate/full gate.

Docs-only edits that merely record the audit/CI state do not invalidate approval.

**After any red macOS candidate/full run, `REMOTE_GATE_APPROVED` is revoked automatically.**
The next task becomes Pass A, completes all related local hardening, and then requires a separate fresh Pass B audit before another macOS dispatch.

This two-pass lock is mandatory even when the reported CI failure looks small. Do not bypass it to "quickly check" one fix.

Default behavior:
- Do **not** dispatch macOS CI after each code change, bug fix, commit, test update, or individual acceptance finding.
- Continue autonomously across the whole active task while any useful implementation, migration, regression review, test maintenance, UX work, documentation, static validation, or repository inspection can still be done in the current environment.
- The Windows workspace lacking Xcode is **not** by itself a reason to dispatch macOS CI early.
- Prefer one larger, implementation-complete checkpoint over several small remote checkpoints.

A checkpoint is **locally exhausted** only when all of the following are true:
1. every currently approved requirement that can be implemented without macOS/Xcode is implemented;
2. all touched code paths have been self-reviewed for compile/type risks, data migration, backward compatibility, product behavior, and obvious regressions;
3. existing tests affected by intentional behavior/model changes have been reviewed and updated;
4. useful deterministic regression tests have been added;
5. all available Windows/Linux/static/security/offline checks pass;
6. relevant specs/progress/docs match the implementation;
7. no known issue remains that can reasonably be diagnosed or fixed by repository inspection;
8. no independent runnable work remains elsewhere in the active task.

Local exhaustion is necessary but no longer sufficient by itself. Codex may dispatch macOS CI only from a fresh Pass B final-audit task on an exact `REMOTE_GATE_READY_FOR_FINAL_AUDIT` SHA, and only if that audit makes no production/test/project code changes.

Scope selection:
- `build`: only when compilation itself is the remaining blocker and further useful repository work cannot resolve the uncertainty;
- focused `unit`/`ui`: only when one specific runtime/test behavior is the remaining blocker after related fixes have already been batched;
- `candidate`: only for an implementation-complete checkpoint intended to become the next physical-acceptance candidate; it may build once, run an exact blocker regression, then run the full suite on the same SHA;
- standalone `full`: only when a candidate filter does not fit and final authoritative verification is otherwise justified.

Do **not** use `candidate` merely to discover ordinary compiler errors, stale tests, incomplete migrations, or unfinished implementation that careful repository review could find first. Do not use `build -> unit -> ui -> smoke -> full` as a routine scheduler.

After a failed macOS run:
1. inspect the terminal result and concise diagnostics once;
2. classify all reported failures before editing;
3. fix related failures as one batch rather than one tiny fix at a time;
4. review the repository for the same class of defect beyond the exact reported lines/tests;
5. complete any other useful remaining work in the active task;
6. rerun all available local/static checks;
7. dispatch another macOS run only after the repository is locally exhausted again.

A failed run does **not** automatically justify an immediate replacement run. Multiple intermediate authoritative runs are not a goal; minimize them by batching implementation and review between dispatches.

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
- failed build/focused/candidate stage -> inspect the concise failure summary/artifact once, batch all related fixes and remaining runnable work, then return to the local-exhaustion checklist; do **not** immediately dispatch a replacement run after the first small fix;
- green `candidate` -> both the focused blocker test and full suite passed on the exact SHA; do not run smoke/full again;
- cancelled/infrastructure failure -> rerun only when justified and only if the repository checkpoint still warrants remote verification.

CI logs are intentionally compact. Prefer the failure summary emitted by the workflow; download the diagnostic artifact only when the summary is insufficient.

## Final-response gate
Before a final response:
1. inspect Git/worktree, `docs/progress.md`, active backlog, and relevant CI;
2. identify the exact next safe action;
3. if it is executable now, execute it instead of stopping;
4. if CI is running, follow the asynchronous CI rule: scan for non-invalidating useful work and continue it; only end when no such work remains, and never wait/poll merely to keep the task alive;
5. if a task is externally blocked, apply the External handoff batching rule before stopping;
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
