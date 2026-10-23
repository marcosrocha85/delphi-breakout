# E2 — Independent engine and explicit states

Date: 2026-10-22. Base: E1 merge `c91c248`. Environment: Delphi 13 Community Edition, Windows.

**E2 completed.** Rules run without forms, controls, labels, timers, or global VCL state. The form forwards commands and synchronizes a data snapshot. Per-tick physics remains the baseline for E3.

## Structure and behavior

Types defines states/commands/configuration/entity/snapshot records and local randomness. Game owns rules/state/lives/score/commands/steps. Levels generates the seeded 96-block grid. Texts contains localization-ready resource strings. UMain adapts input/scheduling/labels/legacy controls; UDebug displays state/level/seed; tests contains a console and fixtures without VCL.

States are Ready, Playing, Paused, LevelComplete, GameOver, and Victory. Execute handles launch/continue, restart, pause, deactivate, and paused stepping. MovePaddle clamps movement; Step only advances Playing. The UI requires visible diagnostics for F1; engine state still controls permission if someone enables the timer directly.

Loss ends the step in Ready/GameOver; last brick ends it in LevelComplete/Victory. Continuing an intermediate level loads the next in Ready and preserves lives/score. Default configuration has one level; larger counts reuse the legacy generator. Additional layouts/difficulty remain E5.

Inactive bricks retain IDs/array positions. The adapter hides/reuses controls without detecting collisions or scoring. Snapshot copies the board; modifying its returned array or a control does not change live rules. Double positions round only at presentation; initial integer coordinates preserve E1 appearance.

The engine receives an explicit seed; the form chooses/displays it at startup. F2 reuses it, reproducing board/initial direction; a new process selects another. Board and launch sequences have separate local states, unaffected by RandSeed/external draws.

TLanguage and the empty data module were removed after migrating references. The form owns labels. English resource strings preserve Marcos's localization intent; language selection/additional translations were not implemented. The engine exposes data/states rather than UI phrases.

## Validation and limitations

| Run | Result |
| --- | --- |
| Engine Win32 Debug | 46 passed; console exit 0. |
| Engine Win64 Debug | Same 46 passed; exit 0. |
| Adapter/E1 regressions Win32 Debug | 52 passed: 43 flow plus nine adapter checks. |
| Final group Build All | Game, observer, tests Win32 Debug succeeded. |
| Main game Win32 Release | Succeeded. |

Final IDE builds showed no warnings/hints. Debug tests enable range/overflow checking; outputs are separated by platform/configuration. Closing/reopening the group let the IDE reread output configuration. An intermediate observer F2039 was resolved with Clean **only BaselineRunner** through Projects, then Build, following user policy.

Tests cover invalid-state commands, immediate pause/focus loss, three falls, no extra motion, unique scoring, inactive blocks/IDs, restart/progression/victory, detached snapshots, deterministic generation, and a 200-step replay under global-random interference. Adapter tests verify that control mutation cannot change rules, synchronization cannot move/score, and messages/diagnostics follow state.

Manual observer checks covered grid, Space launch, lives/score, brick hiding, and readable diagnostics. Direct handler calls complement rather than replace UI checks; neither proves long-session behavior, DPI, or smoothness.

DUnitX DCUs were found for Win64 but no usable Win32 set/sources in checked locations. RTL/JSON avoided installing dependencies. Scenario probes are test-only and excluded from production.

## Evidence

- [Engine Win32](evidence/e2-2026-10-22/engine-win32-debug.json), [Win64](evidence/e2-2026-10-22/engine-win64-debug.json), [adapter](evidence/e2-2026-10-22/adapter-win32-debug.json).
- [Runner build](evidence/e2-2026-10-22/01-build-runner-win32-debug.png), [engine Win32](evidence/e2-2026-10-22/02-build-engine-win32-debug.png), [Win64](evidence/e2-2026-10-22/04-build-engine-win64-debug.png).
- [Game Release](evidence/e2-2026-10-22/05-build-main-win32-release.png), [Debug](evidence/e2-2026-10-22/06-build-main-win32-debug.png), [group build](evidence/e2-2026-10-22/07-build-group-win32-debug.png).
- [State/level/seed diagnostics](evidence/e2-2026-10-22/03-debug-ready.png), [configuration/hashes](evidence/e2-2026-10-22/validation.json), [console instructions](../tests/README.md), [historical adapter instructions](../tools/e2/README.md).

E0/E1 evidence and local README edits were preserved. Fixtures now arrange the engine directly; summary uses the isolated brick's reward because a second distant brick remains in the fixture. Reprocessing copies of historical CSVs reproduced E0 summary without modifying originals.

E3 must correct clocks, velocity units, lower loss plane, proportional paddle response, and reported top/side rebounds. E2 tests do not certify those geometries. Controls still move, snapshots synchronize them, and diagnostics updates each step; E4 handles frame composition/performance. This stage establishes no FPS result, Win64 visual matrix, DPI certification, or duration result.
