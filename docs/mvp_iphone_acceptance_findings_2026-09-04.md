# Physical-iPhone acceptance findings — 2026-09-04

The first functional acceptance pass confirmed the MVP workflow, then identified
the following approved pre-next-build work. The supplied iPhone screenshots are
the source evidence; the attached Claude prototype is used only for spacing and
form hierarchy, never its CIP branding or unrelated features.

| Finding | Current implementation checkpoint | Remaining proof |
| --- | --- | --- |
| ACC-01 Settings/profile | Profile fields, neutral BMI calculation, and an editable dated body-weight history are owner-scoped and offline-first. | Firebase Spark two-user/offline and device review. |
| ACC-02 Set editor | Sets have explicit weighted, reps-only, or timed types; irrelevant fields are hidden and completed actual type is preserved. | Focused simulator and device interaction review. |
| ACC-03 Repeat | Cadence supports every 1–4 weeks, keeps collision skips/independent copies, and uses `Create`. | Cadence/collision automated and device review. |
| ACC-04 Program hierarchy | Native destructive confirmation retained; status becomes a compact semantic treatment. | Device hierarchy review. |
| ACC-05 Today | Lime/mint semantic tokens and a compact branded completion modal preserve one-tap completion. | Device visual/accessibility review. |
| ACC-06 Copy | Existing source/destination validation remains; visual card pass is included in the Program polish checkpoint. | Device flow review. |
| ACC-07 Program editor | Workout actions are consolidated into one overflow menu; exercise cards provide separation. | Device layout/reorder review. |
| ACC-08 Month view | Week/Month share one local-date selection with a six-row month grid and accessible status labels. | Simulator and device navigation review. |
| ACC-09 Past workouts | Redundant History text is removed; selected date, compact status, actual values, and actual editing remain. | Device historical-edit review. |

No physical-device acceptance is claimed for this expanded scope. The prior
green IPA (`ee579d0`) predates these changes and cannot be reused.
