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

Current goal: finish and verify the MVP as far as possible, then get a development build onto the user's own iPhone for real-device evaluation. Only after that does the user decide whether to pay for Apple distribution.

Google/Firebase development configuration and non-production validation are still relevant because they are part of the app itself, not only App Store release.

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
Use **one `full` macOS run at a coherent checkpoint** as the normal authoritative path.

Do not use `build -> unit -> ui` as the normal foreground scheduler. Narrow scopes exist for diagnosis:
- use `build` when diagnosing compilation/project/dependency failures;
- use `unit` when a full run points to unit-test failures;
- use `ui` when a full run points to UI-test failures;
- after a narrow fix is clean, return to a `full` run for current-head reconciliation.

Do not dispatch duplicate identical runs without a code/config change or clear infrastructure reason.

A CI result proves the checkpoint SHA it actually ran against.

### CI while implementation exists
CI is background verification. After dispatching a run, continue other safe implementation immediately.

### CI when nothing else is runnable
If no independent safe work exists and the only next action depends on an already-running CI job, Codex must stay in the same task without burning reasoning turns or user-visible narration on unchanged CI status.

Do **not** run model-driven polling loops such as repeated `gh run view`, API/status checks, or `Ran commands` every 60–90 seconds. Do not repeatedly narrate that the job is queued, healthy, running, or still within timeout.

Use this order instead:
1. check the run once to confirm the exact run ID and checkpoint SHA;
2. start **one foreground blocking wait** for that exact run, with routine progress output suppressed;
3. give that command the longest available timeout, preferably longer than the workflow timeout;
4. when the blocking wait returns, inspect the completed result once and immediately continue with diagnosis/fix or the next runnable action.

Preferred GitHub CLI wait:

PowerShell:
```powershell
gh run watch <RUN_ID> --repo akrasnoslov-dev/Gym_checklist --exit-status --interval 60 *> $null
```

Bash:
```bash
gh run watch <RUN_ID> --repo akrasnoslov-dev/Gym_checklist --exit-status --interval 60 >/dev/null 2>&1
```

The command may internally refresh GitHub state; that is acceptable because it does not require repeated model turns. It is a foreground wait, not an external watchdog, daemon, scheduled task, or heartbeat process.

If `gh run watch` is unavailable, use one equivalent foreground shell loop that sleeps internally and emits only the final state. If the execution tool imposes a shorter hard timeout than the CI run, wait in the largest practical silent chunks, **never more frequently than once every 5 minutes**, and perform at most one status check between chunks. Do not emit commentary for unchanged state.

If the platform/model/tool itself prevents any further foreground waiting or execution, record `MODEL_OR_TOOL_LIMIT` and stop only because of that actual limit.

When CI completes:
- green -> reconcile what it proves and continue;
- failure -> inspect once, fix the narrow reported surface, use narrow CI if useful, then run `full` again;
- cancelled/infrastructure failure -> record no pass/fail evidence and rerun only when justified.

## Final-response gate
Before a final response:
1. inspect Git/worktree, `docs/progress.md`, active backlog, and relevant CI;
2. identify the exact next safe action;
3. if it is executable now, execute it instead of stopping;
4. if CI is running and no other work exists, remain in the task using the silent foreground-wait rule above instead of polling or summarizing;
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
