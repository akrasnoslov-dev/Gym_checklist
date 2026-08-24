#!/usr/bin/env python3
"""Write a validated runtime stop state for the autonomous Codex supervisor."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STOP_STATE = ROOT / ".codex" / "stop_state.json"

ALLOWED_REASONS = (
    "USER_ACTION_REQUIRED",
    "PRODUCT_DECISION_REQUIRED",
    "DESTRUCTIVE_APPROVAL_REQUIRED",
    "REAL_FAILURE_BLOCKS_CONTINUATION",
    "REQUIRED_TOOL_UNAVAILABLE",
    "MODEL_OR_TOOL_LIMIT",
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("reason", choices=ALLOWED_REASONS)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--resume-action", required=True, dest="resume_action")
    parser.add_argument(
        "--confirm-no-safe-work",
        action="store_true",
        help="Required confirmation that the entire remaining backlog was scanned and no safe work remains.",
    )
    args = parser.parse_args()

    if not args.confirm_no_safe_work:
        parser.error("--confirm-no-safe-work is required")

    STOP_STATE.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "reason": args.reason,
        "evidence": args.evidence.strip(),
        "resume_action": args.resume_action.strip(),
        "no_safe_work_remains": True,
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
    }
    STOP_STATE.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {STOP_STATE.relative_to(ROOT)} with reason {args.reason}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
