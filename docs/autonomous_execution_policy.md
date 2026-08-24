# Gym Checklist — Autonomous Execution and Supervisor Policy

## 1. Objective

The intended operating mode is:

```text
start once -> Codex works -> Codex may end a turn -> supervisor checks state -> Codex resumes automatically -> repeat
```

The user should only be required when a real external action, product decision, destructive approval, unavailable required tool, unresolved blocking failure, or platform/model limit leaves **no other technically safe backlog work anywhere in the plan**.

A Codex final message is not itself a stop signal. The repository state and the machine-checkable final gate decide whether execution stops.

## 2. Two-layer autonomy

Autonomy has two layers:

1. **Codex execution layer**
   - implements tasks;
   - runs tests/reviews;
   - updates `docs/progress.md`;
   - commits/pushes coherent checkpoints when available;
   - scans for the next technically safe backlog action.

2. **Supervisor layer**
   - launches Codex through `codex exec`;
   - captures the exact Codex thread ID;
   - runs `scripts/codex_final_gate.py` whenever a Codex turn exits;
   - resumes the same Codex thread automatically when the gate says `CONTINUE`;
   - stops only when the gate says `STOP_ALLOWED` or the supervisor itself cannot continue safely.

This protects the project from routine premature final responses.

## 3. Implementation state is separate from verification state

`DONE` keeps its existing strict meaning: all required acceptance criteria and required verification are satisfied.

The following states are allowed for implementation-complete work that is not yet fully verified:

- `IN PROGRESS (PENDING CI)`
- `IN PROGRESS (PENDING LIVE)`
- `IN PROGRESS (PENDING EXTERNAL)`
- combinations such as `IN PROGRESS (PENDING CI/LIVE/EXTERNAL)`

These are **not DONE**.

However, for scheduling only, an implementation-complete dependency may be treated as provisionally satisfied when its only missing requirement is unavailable verification or external configuration and the later task can be implemented safely without that missing evidence.

Never use provisional scheduling to claim acceptance, security, offline, auth, release, or live integration verification passed.

## 4. A blocked task is not a blocked run

When the current task cannot advance because of external configuration, credentials, live validation, unavailable verification, or another non-code prerequisite:

1. Finish every safe local/repository part of the task.
2. Record the task as the appropriate `PENDING ...` state.
3. Record the missing user/external action in `docs/progress.md` under a batched `USER ACTION REQUIRED QUEUE`.
4. Do **not** emit a final response yet.
5. Scan the entire remaining implementation plan for another technically safe task.
6. Continue with that task.
7. Return to deferred tasks when their prerequisites become available.

Do not limit the scan to the immediately following task. Later tasks with independent dependencies may be implemented first when this does not violate product or architecture rules.

Example:

```text
M5.4 needs Google Console configuration
-> implement all local Google Sign-In code/tests that are safe
-> mark M5.4 PENDING EXTERNAL
-> scan M5.5, M6.x, M7.x, etc.
-> continue any task that is genuinely safe
-> stop only if all remaining useful work is blocked
```

## 5. External action batching

External action includes, for example:

- Firebase Console changes;
- Google OAuth/provider configuration;
- refreshed local `GoogleService-Info.plist`;
- Apple Developer account/signing;
- App Store Connect setup;
- GitHub release secrets;
- physical-device/TestFlight actions that cannot be completed by current tools.

Rules:

- Batch related user actions.
- Do not stop for piecemeal setup if other safe backlog work exists.
- `USER_ACTION_REQUIRED` is a **run-level terminal reason**, not a task-level label.
- Use `USER_ACTION_REQUIRED` only after scanning the full backlog and establishing that no technically safe work remains without the user action.

## 6. Runtime stop-state protocol

The supervisor uses this runtime file:

```text
.codex/stop_state.json
```

It is ignored by Git and must never be committed.

Codex must not create this file for normal checkpoints, summaries, commits, pending CI, or a blocked individual task.

Before a genuine terminal response, Codex must write the stop state with:

```bash
python scripts/write_codex_stop_state.py <REASON> --evidence "<evidence>" --resume-action "<exact resume action>" --confirm-no-safe-work
```

Allowed reasons:

- `USER_ACTION_REQUIRED`
- `PRODUCT_DECISION_REQUIRED`
- `DESTRUCTIVE_APPROVAL_REQUIRED`
- `REAL_FAILURE_BLOCKS_CONTINUATION`
- `REQUIRED_TOOL_UNAVAILABLE`
- `MODEL_OR_TOOL_LIMIT`

`--confirm-no-safe-work` means Codex has scanned the remaining plan and found no technically safe work it can perform now.

If all implementation-plan tasks are `DONE`, no stop-state file is required; the final gate detects completion directly.

## 7. Machine-checkable final gate

Before every final response, Codex should run:

```bash
python scripts/codex_final_gate.py
```

Results:

- exit `0`: `STOP_ALLOWED`
- exit `10`: `CONTINUE`
- any other exit: gate/configuration error; do not claim normal completion

If the gate says `CONTINUE`, Codex must continue instead of returning control.

The external supervisor runs the same gate after every Codex process exit, so a premature model final response becomes only a checkpoint.

## 8. Supervisor behavior

Use:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_codex_autonomous.ps1
```

The supervisor:

1. reads the fenced prompt from `docs/codex_master_prompt.md`;
2. starts `codex exec --json`;
3. captures `thread.started.thread_id`;
4. waits for that Codex turn to finish;
5. runs `scripts/codex_final_gate.py`;
6. if the result is `CONTINUE`, resumes the exact thread with `codex exec resume <SESSION_ID>`;
7. repeats until stop is allowed.

The default sandbox is `workspace-write`.

Use broader sandbox access only when the user deliberately chooses it and the environment is controlled.

## 9. Stall protection

The supervisor is not allowed to retry forever without repository progress.

If several consecutive Codex turns:

- leave Git HEAD unchanged;
- leave `docs/progress.md` unchanged;
- and the final gate still says `CONTINUE`;

the supervisor stops with a stall error so the user can inspect the environment instead of burning usage indefinitely.

A model/tool process error is retried with a delay, but repeated no-progress errors eventually stop the supervisor.

## 10. Source-of-truth interaction

This policy changes **execution mechanics only**.

It does not weaken:

- product scope;
- UX rules;
- architecture boundaries;
- security/privacy requirements;
- acceptance criteria;
- definition of `DONE`;
- release approval requirements.

Priority for execution mechanics:

1. explicit current user instruction;
2. this policy;
3. `AGENTS.md`;
4. `docs/codex_instructions.md`;
5. `docs/ci_free_quota_policy.md`;
6. generic execution wording in `docs/implementation_plan.md`.

Product/UX/architecture priority remains defined in `AGENTS.md`.

## 11. Progress-file requirements

`docs/progress.md` must keep:

- current branch;
- active task;
- implementation-complete tasks pending verification/external action;
- current CI/live state;
- `USER ACTION REQUIRED QUEUE`;
- blockers;
- exact next safe action;
- exact deferred tasks to revisit.

Do not use `docs/progress.md` itself as the machine stop signal. Runtime stop state belongs in `.codex/stop_state.json`.
