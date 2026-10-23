# Engine, physics, and presentation tests

Open DelphiBlocks.groupproj and activate Breakout.Tests.exe in Projects. The console uses RTL/engine units without VCL forms/controls. Build through Delphi 13 Community Edition's IDE; this installation's command-line compiler does not produce an executable.

After building the corresponding configuration, run from the repository root:

```powershell
.\build\tests\Win32\Debug\Breakout.Tests.exe
.\build\tests\Win32\Release\Breakout.Tests.exe build\e5\win32-release
.\build\tests\Win64\Debug\Breakout.Tests.exe build\e5\win64-debug
.\build\tests\Win64\Release\Breakout.Tests.exe build\e5\win64-release
```

Exit codes: 0 success, 1 assertion failures, 2 runner error. Default reports: build/e5/latest/engine.json, physics.json, presentation.json. The first argument selects another output directory.

There are **262 cases/configuration**: 117 engine state/command/life/score/ID/completion/seed/snapshot cases; 104 physics/time cases; 41 presentation cases. Presentation covers explicit classes, one-point 5 ms counting, accumulated targets, pause/restart/new level, detached snapshots, 250/350/500 ms fading, and viewport/input inversion at 100/125/150/200%.

The engine suite also clears all 136 real campaign bricks with controlled impacts, checks both fixed maps and legacy geometry equivalence, preserves counters across transitions, exercises the speed cap/zero growth/large finite increase, and rejects invalid campaign settings. Height-balance checks sample 1,024 seeds per level (139,264 generated bricks), assert premium side separation, exercise actual silver/gold diagonals, and compare broad band proportions/mean rewards. Observed class counts are saved in engine.json under class_balance.

Geometry covers four faces/circular corners, ascending/descending side hits, false corner contacts, tangency, initial overlap, seams, simultaneous contacts, high speed, remaining time, impact budgets, circular ball/capsule paddle, proportional angle/constant speed/center, lower loss, stalls, pause, and level transitions.

Equivalent 30/60/144 callback schedules execute 360 steps over three simulated seconds and compare position, velocity, state, lives, score, and active blocks. Ten seeds run 3,600 steps each with paddle tracking: thirty simulated seconds/match. This is neither a paint benchmark nor human playtesting.

Breakout.TestScenarios.pas prepares runner-only fixtures and is excluded from production. Synchronous tests call Step/Loop.Advance without Windows timer waits. The [E5 VCL runner](../tools/e5/README.md) covers integration and real clocks.

RTL/JSON keeps Win32 dependency-free: available DUnitX DCUs covered Win64, but usable Win32 sources were not found. [E4 results](../docs/e4-results.md) distinguish the original four-configuration validation from later parameter checks. For a guided explanation, read [presentation and tests](../docs/study/presentation-and-tests.md).
