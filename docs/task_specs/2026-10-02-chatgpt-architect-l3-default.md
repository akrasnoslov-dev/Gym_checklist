Date: 2026-10-02

## Goal

Make Gym Checklist use `CHATGPT_ARCHITECT` as the default codex-chatgpt-bridge operating mode and
`L3_WORKSPACE_WRITE` as the default permission level for bridge-assisted Gym Checklist work.

## Clarified requirements

- The user explicitly requested the same bridge defaults as CCWBot.
- Make the setting durable in the repository source of truth rather than only in chat or a task prompt.
- Keep bridge access scoped to the existing narrow Gym Checklist workspace: `D:\Projects\gym_checklist`.
- Keep Codex responsible for independent verification, git operations, and final claims.
- Keep existing L4/L5 approval gates and all L3 exclusions for secrets, installs, destructive actions,
  commit/push/history mutation, and access outside the approved workspace.

## Out of scope

- Changing product/runtime behavior.
- Changing the bridge controller, tunnel, OAuth, or Cloudflare configuration.
- Broadening filesystem roots.
- Changing model routing in `.codex/config.toml` or `agents/routing.toml`.
- Git commit, push, PR creation, or merge.

## Expected files

- `docs/codex_instructions.md` — canonical workflow owner.
- This task spec only.

## Risks

- `L3_WORKSPACE_WRITE` is a policy grant, not a technical sandbox; bridge shell execution can carry
  local-user authority. The workspace must remain narrow and secret-free.
- Making L3 the default increases the trust surface compared with read-only operation.

## Data / migration impact

None.

## Validation strategy

This is documentation/policy configuration, so a conventional regression test is not meaningful.
Validate by:
1. confirming the canonical owner contains the new default exactly once;
2. confirming the approved workspace remains `D:\Projects\gym_checklist`;
3. confirming `AGENTS.md`, `.codex/config.toml`, and `agents/routing.toml` are not changed for this policy;
4. reviewing the final diff for scope and safety guardrails.

## Implementation plan

1. Add one concise bridge-default section to `docs/codex_instructions.md`.
2. Preserve existing safety boundaries and final-verification ownership.
3. Verify exact occurrences and inspect the final diff.
