#!/usr/bin/env python3
"""Machine-checkable stop gate for the Gym Checklist autonomous supervisor."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / "docs" / "implementation_plan.md"
STOP_STATE = ROOT / ".codex" / "stop_state.json"

TASK_RE = re.compile(r"^###\s+(M\d+\.\d+)\s+`([^`]+)`\s+", re.MULTILINE)
ALLOWED_REASONS = {
    "USER_ACTION_REQUIRED",
    "PRODUCT_DECISION_REQUIRED",
    "DESTRUCTIVE_APPROVAL_REQUIRED",
    "REAL_FAILURE_BLOCKS_CONTINUATION",
    "REQUIRED_TOOL_UNAVAILABLE",
    "MODEL_OR_TOOL_LIMIT",
}


def fail(message: str, code: int = 20) -> int:
    print(f"GATE_ERROR: {message}")
    return code


def main() -> int:
    if not PLAN.exists():
        return fail(f"missing {PLAN.relative_to(ROOT)}")

    text = PLAN.read_text(encoding="utf-8")
    tasks = [(task_id, status.strip()) for task_id, status in TASK_RE.findall(text)]
    if not tasks:
        return fail("no milestone tasks found in implementation_plan.md")

    incomplete = [(task_id, status) for task_id, status in tasks if not status.upper().startswith("DONE")]

    if not incomplete:
        print(f"STOP_ALLOWED: implementation plan complete ({len(tasks)} tasks DONE)")
        return 0

    if STOP_STATE.exists():
        try:
            state = json.loads(STOP_STATE.read_text(encoding="utf-8"))
        except Exception as exc:
            return fail(f"invalid .codex/stop_state.json: {exc}")

        reason = str(state.get("reason", "")).strip()
        evidence = str(state.get("evidence", "")).strip()
        resume_action = str(state.get("resume_action", "")).strip()
        no_safe_work = state.get("no_safe_work_remains") is True

        if reason not in ALLOWED_REASONS:
            return fail(f"unsupported terminal reason: {reason!r}")
        if not evidence:
            return fail("terminal stop state has no evidence")
        if not resume_action:
            return fail("terminal stop state has no resume_action")
        if not no_safe_work:
            return fail("terminal stop state does not confirm no_safe_work_remains=true")

        print(f"STOP_ALLOWED: {reason}")
        print(f"Evidence: {evidence}")
        print(f"Resume action: {resume_action}")
        print(f"Incomplete plan tasks remaining: {len(incomplete)}")
        return 0

    preview = ", ".join(f"{task_id} [{status}]" for task_id, status in incomplete[:8])
    if len(incomplete) > 8:
        preview += f", ... +{len(incomplete) - 8} more"
    print(f"CONTINUE: {len(incomplete)} implementation-plan tasks are not DONE and no valid terminal stop state exists.")
    print(f"Next incomplete tasks: {preview}")
    return 10


if __name__ == "__main__":
    raise SystemExit(main())
