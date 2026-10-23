# E5 - finite progression and feedback

Date: 2026-10-23. Environment: Delphi 13 Community Edition, Windows, VCL.
Base: integrated E4 (`dd4c50b`); branch: `codex/e5-progression`.

## Delivered behavior

The default match has three boards: the unchanged seeded 96-brick legacy grid,
20-brick twin gates, and a 20-brick diamond. Added maps are source data with
explicit class cells and no random draws. Generation keeps stable row-major
IDs, centralized rewards, and independent arrays. Configured matches may use a
prefix of 1..3 boards; unsupported counts/numbers raise an argument exception.

The final brick reflects/deactivates/scores once and ends the step in
LevelComplete or final Victory. Click/Space after completion explicitly loads
the next board in Ready, keeping lives/score; a second input launches. F2
restores the seeded first board, counters, initial speed, diagnostics, and
presentation. No production skip-level input was added.

Difficulty starts at 240 units/s and compounds by 5% per level: 252 and 264.6.
`LevelSpeedIncrease` and `MaxBallSpeed` are configuration fields; the default
cap is 300. Life loss reapplies the current level speed. Zero increase disables
growth; invalid/nonfinite values are rejected. Large finite increases saturate
at the cap before multiplication. Physics remains 1/120 s; UI timer remains
15 ms. The percentage is an initial setting awaiting human difficulty feedback.

The HUD now shows `Level n / total`. Ready, pause, completion, game-over, and
victory messages explain their applicable next action using resource strings.
Existing presentation keeps counting/fading during terminal feedback. Immediate
continuation removes old-board fades while retaining score debt; Ready idles
after counting finishes. Painting still reads state without advancing it.

## Validation

All builds were made through the IDE with `DelphiBlocks.groupproj` open.
The command-line compiler was not used as evidence of a successful build.

| Target | Result |
| --- | --- |
| Console, Win32 Debug | 232 checks, zero failures |
| Console, Win64 Debug | 232 checks, zero failures |
| BaselineRunner, Win32 Debug | 67 VCL/bitmap checks, zero failures |
| Breakout, Win32 Debug | Build succeeded |
| Breakout, Win64 Release | Build succeeded |
| PasDoc 1.0.4 | Regenerated checked-in HTML, no warnings/errors |

The console includes 87 engine, 104 physics/time, and 41 presentation cases.
New engine coverage clears every real campaign brick by controlled isolated
impacts, loses a life between boards, checks score/life/speed preservation,
terminal victory, and restart. Map checks compare level 1 against the original
generator and check fixed-board bounds/nonoverlap/IDs/rewards. Speed cases cover
caps, zero growth, a very large finite increase, and invalid settings. Existing
final-board tests explicitly configure one level rather than weakening their
victory assertions after the default became three.

The shared VCL suite retains all 47 E4 checks and adds 20 progression checks.
These drive form handlers, loop, and presentation through three one-brick
fixtures, independently checking actual generated board sizes at each load.
They exercise separate continuation/launch, pending score, new-board fade
cleanup, time remainder reset, timer settling, victory rejection of launch,
and F2 cleanup. Ready/completed bitmap exports were visually inspected for
new layouts, messages, and the level HUD.

Evidence and source/executable hashes are in
[evidence/e5-2026-10-23](evidence/e5-2026-10-23/README.md).
See the [console](../tests/README.md), [VCL runner](../tools/e5/README.md), and
[study chapter](study/levels-and-progression.md) to reproduce these contracts.

An F2039 while rebuilding BaselineRunner was resolved with Clean on **only
BaselineRunner** in Projects, followed by Build. No Clean All was used.
IDE source caches were synchronized while keeping the group open.

## Scope and remaining evaluation

Controlled impacts and handler fixtures establish rules/feedback, not a full
human campaign playthrough or the fairness of 5% growth. Full human difficulty
evaluation remains open. E5 does not claim new FPS/CPU measurements; E4's
measurements and limits remain historical evidence.

E6 retains the full four-configuration consolidation, remaining HUD/layout
magic-number extraction, real DPI/monitor transitions, and prolonged human
evaluation. Menus, resizing/fullscreen, powerups, OpenGL comparison, and
continuous template-based levels remain later work.

The pre-existing local edits in `Breakout.dproj`, `UMain.dfm`, and
`tests/Breakout.Tests.dproj` remain outside this delivery. Their original bytes
were backed up under ignored `build/e5/preserved-local` and checked by SHA-256.
The existing release 1.0.1.0 was not replaced; its binaries precede this campaign.
