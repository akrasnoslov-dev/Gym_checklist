# Codex Instructions

## Purpose
This repository is designed for long-running, low-touch Codex implementation. The repository is durable project memory; chat history is not.

## Startup sequence
For every new Codex session:
1. Read `AGENTS.md`.
2. Read `docs/product_spec.md`.
3. Read `docs/ux_spec.md`.
4. Read `docs/architecture.md`.
5. Read `docs/implementation_plan.md`.
6. Read `docs/progress.md`.
7. Read `docs/ci_free_quota_policy.md` when it exists.
8. Read `agents/routing.toml` and required agent files.
9. Inspect git status/branch, recent commits/diff, relevant source/tests, and available CI state.
10. Resume the active task from repository state.

If the user says only `continue`, perform this startup sequence and resume without asking them to restate context.

## Autonomy policy
Continue task-by-task without waiting for user confirmation between routine implementation steps.

Stop only for:
- product ambiguity that materially changes intended behavior/UX;
- required credentials, Firebase/Apple/external account configuration, or signing/provisioning that cannot be completed from the repository;
- destructive/irreversible decisions needing approval;
- an actual implementation/test failure that makes later work unsafe;
- a genuinely required tool being unavailable with no technically safe work remaining;
- model/tool usage limits.

Do not stop for routine naming, folder placement, reversible implementation decisions, or a missing Git remote in Codex Cloud.

## No-cost GitHub Actions policy
Paid GitHub Actions usage is not approved unless the user explicitly reverses that decision.

When authoritative macOS CI cannot start solely because the included GitHub Actions quota is exhausted, apply `docs/ci_free_quota_policy.md`:
- classify the state as `CI UNAVAILABLE — FREE QUOTA EXHAUSTED`, not as a code failure;
- keep affected tasks/checkpoints `IN PROGRESS (PENDING CI)` rather than falsely marking them `DONE`;
- run every available non-macOS/static/deterministic check;
- treat implementation-complete dependencies pending only on quota-blocked CI as provisionally satisfied for scheduling;
- continue across milestone checkpoints and into later milestones when technically safe;
- never use this exception to bypass a real build/test failure, product ambiguity, security issue, external credential/configuration blocker, or destructive choice;
- reconcile pending verification with one consolidated macOS CI run when free capacity becomes available again.

This no-cost exception overrides generic `dependency must be DONE` and `milestone checkpoint must stop execution` rules **only for deciding whether safe implementation may continue**. It does not change acceptance criteria or the meaning of `DONE`.

Do not ask the user to add a payment method, buy GitHub Pro, increase an Actions budget, rent a Mac runner, or pay for another CI provider merely to continue normal development.

## Codex Cloud execution
Codex Cloud may receive a repository snapshot without writable `origin`, authenticated `gh`, or PR creation. That is expected and is not a user blocker.

In Cloud:
- make focused checkpoint commits when possible;
- do not request PAT/`GH_TOKEN` merely to work around the sandbox;
- if CI is unavailable, record the exact reason and continue safe implementation;
- do not end after one task while another safe task is eligible;
- consolidate external verification instead of asking the user to apply/publish every small task.

## Task lifecycle
For each implementation item:
1. Read the full task body and referenced Product/UX/Architecture sections.
2. Check dependencies. A dependency pending **only** quota-blocked CI may be provisionally satisfied under `docs/ci_free_quota_policy.md`.
3. Apply required agents from `agents/routing.toml`.
4. Mark the task `IN PROGRESS` and update `docs/progress.md` before substantial edits.
5. Implement the smallest coherent solution.
6. Add/update required unit/UI/regression tests.
7. Run the strongest verification available in the current environment.
8. Self-review against every acceptance criterion, product scope, Today UX, architecture, security/privacy, and offline implications.
9. Fix all failures that can be established in the current environment.
10. Mark `DONE` only when required acceptance and verification actually pass. If required macOS CI is unavailable because of the free quota, keep `IN PROGRESS (PENDING CI)`.
11. Update `docs/progress.md` with exact verification state, blockers, commit/checkpoint, and next task.
12. Create a focused checkpoint commit.
13. Immediately continue to the next technically safe task.

## CI failure classification
Distinguish these states:

### Real CI failure
A runner starts and produces build/test steps or logs showing an actual failure. Treat this as a real engineering signal. Fix it before proceeding when the affected behavior is required for safe continuation.

### CI unavailable
A job cannot start because of exhausted included Actions quota or equivalent external runner availability. Under the no-cost policy, record it as verification pending and continue safely.

Never describe quota-blocked CI as a passing test.

## Session continuity
Keep `docs/progress.md` current enough that a fresh session can resume without chat history. Record at least:
- current branch;
- active task;
- last verified checkpoint;
- implementation-complete tasks pending CI;
- latest available verification/CI state;
- genuine blockers;
- exact next action.

Prefer focused commits. If context becomes unreliable, finish the smallest safe atomic unit, checkpoint it, and recommend a fresh Codex task. A fresh task must recover from repository state alone.

## Branching
- `main`: stable/release only.
- `dev`: integration/default development branch.
- Prefer `feature/*` from `dev` when useful.
- PR target is `dev` by default.
- `dev -> main` only when explicitly requested for release.
- Never overwrite uncommitted user work.

## Product-change rule
The approved specifications are authoritative. Do not add attractive but unrequested fitness features. Record ideas under `Future candidates` instead of implementing them automatically.

## Today rule
Today is the protected UX surface. Preserve:

```text
Open app -> Today -> one tap per completed set -> close app
```

Do not add charts, stats, timers, coaching, social content, PR dashboards, calories, recommendations, or other unapproved noise.

## Windows/macOS reality
The user's primary machine is Windows and has no Xcode.
- Never claim Xcode verification on Windows/Linux.
- Static checks there are non-authoritative.
- Authoritative iOS build/test verification requires a real macOS/Xcode environment.
- If GitHub-hosted macOS is quota-blocked, use verification-deferred mode rather than paid usage.

## Verification commands
Preferred authoritative macOS command:

```bash
DESTINATION_UDID="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; data=json.load(sys.stdin); devices=[device for runtime, entries in data["devices"].items() if "iOS" in runtime for device in entries if device.get("isAvailable") and device.get("name", "").startswith("iPhone")]; print(devices[0]["udid"] if devices else "")')"
test -n "$DESTINATION_UDID"
xcodebuild -project GymChecklist.xcodeproj -scheme GymChecklist -sdk iphonesimulator -destination "platform=iOS Simulator,id=$DESTINATION_UDID" CODE_SIGNING_ALLOWED=NO test
```

Useful non-authoritative checks when Xcode is unavailable:

```bash
python3 -c 'import xml.etree.ElementTree as ET; ET.parse("GymChecklist.xcodeproj/xcshareddata/xcschemes/GymChecklist.xcscheme")'
git diff --check
```

Add deterministic source/test checks appropriate to the active task. Static checks do not prove Swift compilation or UI-test success.

## External configuration checkpoints
When real external action is required, batch it in `docs/progress.md` under `USER ACTION REQUIRED` with exact steps, values/secrets, and follow-up verification. Avoid piecemeal interruptions.

## Progress continuity
`docs/progress.md` is mandatory. `docs/implementation_plan.md` remains the ordered backlog and its acceptance criteria must not be weakened merely because CI is temporarily unavailable.