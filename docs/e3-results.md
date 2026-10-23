# E3 — Time and continuous collision

Date: 2026-10-22. Base: E2 merge `3af2531`. Branch: codex/e3-physics; no Gideon session opened.

E3 fixes brick rebounds and implements proportional paddle response. Ball geometry is circular; the paddle has a straight body and semicircular caps, matching the sprite/user observation. Existing VCL sprites/controls remain; single-surface drawing belongs to E4.

## Reported defects

| Directed scenario | Verified result |
| --- | --- |
| Descending ball hits block top | Destroy/score once, reverse Y upward, consume remaining time. |
| Ascending ball hits bottom | Reverse Y downward, preserve X on isolated face contact. |
| Either side face while ascending/descending | Reverse X, preserve Y; inactive block cannot collide/score again. |
| Near an empty corner | Circular arc geometry rejects bounding-box-only false contacts. |
| Paddle hit | Center offset selects angle; rounded ends use combined ball/cap radii. |

## Implementation and parameters

- Physics provides circle sweeps over four faces/four arcs, capsule sweeps, normals, penetration, reflection, and proportional angle without VCL.
- Game finds earliest contact, moves there, reflects/separates, and consumes remaining time. Stable tie order: left/right/top walls, paddle, brick array, loss. Separating seam normals do not reflect twice; all simultaneous hit bricks deactivate/score once.
- Loop uses 1/120 s steps, accepts at most 100 ms, and performs at most twelve steps/callback. Pause/resume/deactivate/restart/loss/level transitions clear pending fractional time; terminal remainder is not carried to another life/match.
- UMain measures GetTimeStamp/Frequency and used a 16 ms timer at this stage. Command transitions reset clocks; diagnostic paused F1 advances one step.
- Initial speed 240 units/s, 45° launch. Paddle preserves incident speed, at most 60° from vertical, minimum absolute 5° near center, prior horizontal sign at exact center. Upward magnitude is at least half total speed after rebound.
- Ball diameter 17; paddle 50×15, cap radius 7.5. Ready may use fractional placement; only control synchronization rounds.
- At most eight impact groups/step. Exhaustion stops at the last safe contact and records discarded remaining time. Spatial separation 1e-6 logical unit; time tolerance 1e-10 s.
- Loss occurs when the ball fully crosses the lower edge: its top reaches Y=453, independently of paddle X. Loss/completion ends both the step and accumulated processing.
- Diagnostics has 23 keys, including velocity, dt, last/total steps including F1, accumulator, limited callbacks, discarded time. Scheduling counters remain cumulative; physical counters reset with the match.

The 5° minimum creates a small center region; outside it angle is proportional. Paddle input remains instantaneous between steps; this stage does not sweep a moving paddle or calculate its impulse.

## Validation

IDE: Delphi 13 Community Edition 37.0.60542.8024. Main/console built Win32/Win64 Debug/Release; runner Win32 Debug. F2039 cases were resolved by cleaning **only the failed project**, then Build.

| Configuration | Engine | Physics/time | Result |
| --- | --- | --- | --- |
| Win32 Debug | 46 | 104 | 150 passed, zero failures |
| Win32 Release | 46 | 104 | 150 passed, zero failures |
| Win64 Debug | 46 | 104 | 150 passed, zero failures |
| Win64 Release | 46 | 104 | 150 passed, zero failures |
| VCL Win32 Debug | 52 earlier regressions | 11 E3 cases | 63 passed, zero failures |

Debug retains range/overflow checks. Geometry cases cover all faces/circular corners, tangency, overlap, seams/simultaneous walls, high speed, remaining time, collision budget, single scoring, loss below the paddle, paddle angles/speed/center/caps, empty corners, and ascending passage.

Equivalent 30/60/144 callbacks/s schedules executed 360 steps over three simulated seconds and matched position, velocity, state, lives, score, active blocks within explicit tolerance. A 1.5 s delay performed at most twelve steps and recorded 1.4 s discarded. Pause/deactivate/restart/loss/victory/level change carried no time debt.

Ten seeds ran 3,600 steps each (thirty simulated seconds/match) with paddle tracking. All preserved speed 240, field limits, and unexhausted collision budgets. This is rules simulation, not five measured minutes of UI rendering or human playtesting.

The VCL mode checks real clock with short waits, jump-free resume, sprites/score after top/side impacts, and diagnostics. Live evaluation observed preserved sprites, launch, motion, brick destruction/scoring, loss, restart. Pause is demonstrated by automated tests; this manual check is not claimed as additional pause evidence.

[Full reports/screenshots/hashes](evidence/e3-2026-10-22/validation.json) retain prior stage evidence and local README edits. Local IDE preferences stayed separate from required new project references.

## Limits and next stage

E3 validates mechanics/integration, not presentation FPS, DPI scales, hour-long leak absence, or bit-identical floating-point across platforms. Reproduction is per configuration with numerical tolerances. E4 can replace TImages with one buffered/cached surface and measure updates/painting separately. Interpolation and throttled diagnostics require evaluation there; physics stays 120 Hz.
