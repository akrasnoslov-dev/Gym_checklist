# Specialist Review Agents

These TOML files define specialist review instructions for repository tooling. They are not runtime application agents and must never be imported into the iOS app.

Routing is controlled by `agents/routing.toml`.

Agents:
- `architecture_guardian`
- `ios_ux_guardian`
- `design_prototype_guardian`
- `firebase_data_guardian`
- `security_privacy_agent`
- `code_quality_agent`
- `test_ci_agent`
- `release_appstore_agent`
- `product_spec_guardian`

ChatGPT decides when a specialist review is needed. Apply the relevant instructions directly when possible. If Codex is delegated a review, keep it bounded and read-only unless the task explicitly authorizes fixes.

Do not create extra worktrees or parallel editing checkouts for specialist reviews.

`design_prototype_guardian` applies to Phase 5 visual work only. It reviews the required HTML/CSS prototype, exported screens and the implementation mapping; it must not turn a design task into a SwiftUI implementation task.
