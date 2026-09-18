# Codex Review Agents

These TOML files are developer-tooling instructions for Codex/subagent review. They are not runtime application agents and must never be imported into the iOS app.

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

For non-trivial work, inspect routing before implementation. Use required agents through Codex delegation when available; otherwise manually apply their instructions and note that fact in the PR/progress entry.

`design_prototype_guardian` applies to Phase 5 visual work only. It reviews the required HTML/CSS prototype, exported screens and the implementation mapping; it must not turn a design task into a SwiftUI implementation task.
