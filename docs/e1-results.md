# E1 — Organization and flow fixes

Date: 2026-10-22. Base: E0 merge `fc29204`. Environment: Delphi 13 Community Edition, Windows, Win32.

**E1 completed.** The timer delegates to methods with explicit responsibilities. Launch, pause, restart, life loss, and diagnostics follow centralized paths. This stage retains legacy controls and physics.

| Situation | E0 behavior | E1 result |
| --- | --- | --- |
| Launch after moving | Could recenter prepared position. | Click/Space preserve prepared position. |
| Immediate F3 | Could be ignored before first timer tick. | Pauses immediately with message. |
| Click/Space in pause | Space relaunched while keeping pause text. | Preserve pause/position/message; F3 resumes. |
| Life loss | Repositioned then moved again. | Lose one life, reposition, end step. |
| F1 outside inspection/game over | Allowed inappropriate motion. | Requires paused match, lives, visible diagnostics. |
| F2 in play/pause/game over | Different paths handled state/messages. | Three lives, zero score, 96 bricks, ready state. |
| Diagnostics | Inconsistent keys, stale positions, poor contrast. | Nine shared keys, post-step values, readable contrast; F10 does not move main window. |
| Long score | Padding could duplicate digits. | At least nine digits without truncating larger values. |

UMain.StepGame coordinates bounds, loss, paddle, bricks, disposal, and movement. StartNewGame/LaunchBall/SetPaused/update methods remove duplication. Typed directions avoid the form Left-property conflict. Randomness initializes once at creation.

Scoring no longer calls Application.ProcessMessages, and a reentry guard protects stepping. The form owns Language, which owns its labels; shutdown disables timer and frees diagnostics/text. Unused declarations were removed. Bricks remain TImage controls with reverse-order disposal and no inactive-brick reuse.

## Validation

- Historical Clean All succeeded for game/runner Win32 Debug, followed by successful Build All. The game also built separately Win32 Debug/Release. Final builds showed no warnings/hints; E0's six unused hints disappeared.
- `BaselineRunner --e1`: **43 checks, zero failures**, including three losses, no extra motion, state permissions, score through MaxInt, diagnostic close/reopen, and fifty restarts with stable counts.
- Manual helper UI: Space launched, F3 paused, Space/click preserved pause, F10 showed diagnostics, F1 stepped while paused; all nine rows had corrected contrast.
- Preexisting local README edits and E0 evidence were preserved outside this change.

An intermediate F2039 occurred because the helper was still running. Closing its main window followed by the historical Clean All/Build All resolved it; source compilation was not defective. The later standing policy is Clean **only the failed project** in Projects.

Automated checks call form handlers rather than testing an independent engine or injecting keys. Manual UI work complements them. Fifty stable restarts do not prove leak absence. No FPS/cadence improvement was established here; Win64, DPI, and long sessions remained consolidation work.

## Evidence and reproduction

- [43-check report](evidence/e1-2026-10-22/checks.json), [Clean All](evidence/e1-2026-10-22/05-clean-all-win32-debug.png), [runner build](evidence/e1-2026-10-22/01-build-runner-win32-debug.png).
- [Game Debug](evidence/e1-2026-10-22/04-build-main-win32-debug.png), [Release](evidence/e1-2026-10-22/02-build-main-win32-release.png).
- [Space preserving pause](evidence/e1-2026-10-22/03-space-preserves-pause.png), [readable diagnostics](evidence/e1-2026-10-22/06-debug-readable.png), [historical instructions](../tools/e1/README.md).

The runner stayed in the same IDE group. At this stage, no arguments selected a fresh build/baseline-runs directory; --e1 defaulted to build/e1/latest. E4 subsequently changed default mode.

E2 extracts engine/states and permits rules without VCL. Proportional paddle response and brick tunneling/rebound remain E3 work with fixed-step geometry; rendering remains E4.
