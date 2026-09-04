# Physical-iPhone acceptance findings — 2026-09-04

The first functional acceptance pass confirmed the MVP workflow, then identified
the following approved pre-next-build work. The supplied iPhone screenshots are
the source evidence; the attached Claude prototype is used only for spacing and
form hierarchy, never its CIP branding or unrelated features.

| Finding | Current implementation checkpoint | Remaining proof |
| --- | --- | --- |
| ACC-01 Settings/profile | Profile fields, neutral BMI calculation, and an editable dated body-weight history are owner-scoped and offline-first. Current BMI uses the latest non-future local date, not creation time. | Firebase Spark two-user/offline and device review. |
| ACC-02 Set editor | New/edited sets expose only weighted, reps-only, or timed types; irrelevant fields are hidden. Legacy mixed records retain plan and actual values through decode/re-save and copies until a user deliberately selects an editable type. | Candidate/full CI, then focused simulator and device interaction review. |
| ACC-03 Repeat | Cadence supports every 1–4 weeks, retains collision skips and independent copies, and the primary action is exactly `Create`; the count remains in Result content. | Candidate/full CI, then cadence/collision and device review. |
| ACC-04 Program hierarchy | Native destructive confirmation and semantic status treatment are implemented; final device hierarchy review is not yet complete. | Candidate/full CI, then device hierarchy review. |
| ACC-05 Today | The one-tap flow remains unchanged; lime/mint stays semantic and the completion overlay remains modal. | Candidate/full CI, then device visual/accessibility review. |
| ACC-06 Copy | Copy uses source/destination cards with visible disabled-date feedback and a full-width primary action exactly labeled `Copy`. | Candidate/full CI, then device flow review. |
| ACC-07 Program editor | Workout actions are consolidated in one overflow menu; exercise cards and scoped outlined add actions are implemented. | Candidate/full CI, then device layout/reorder review. |
| ACC-08 Month view | Week/Month share one local-date selection, use a fixed six-row Monday-first grid, weekday headers, semantic status, outside-month styling, and a non-color today ring. | Candidate/full CI, then simulator/device navigation review. |
| ACC-09 Past workouts | Redundant History text is removed; selected date, compact status, actual values, and actual editing remain. | Device historical-edit review. |

No physical-device acceptance is claimed for this expanded scope. The prior
green IPA (`ee579d0`) predates these changes and cannot be reused.
