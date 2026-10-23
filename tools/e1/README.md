# E1 flow regressions (historical)

Use the E1 revision to reproduce this mode; the E4 runner no longer links legacy control-based suites. `UE1Checks.pas` originally referenced the same forms through BaselineRunner.dproj in DelphiBlocks.groupproj. E2 adapted fixtures to the engine; E3 added explicit time and expanded diagnostics.

At the historical revision:

1. Activate BaselineRunner.exe, select Win32/Debug, and Build through the IDE.
2. Reload externally edited sources when appropriate before building.
3. Set Run > Parameters to `--e1`, then Run Without Debugging; or run `tools/e0/BaselineRunner.exe --e1` after the build.
4. Read `build/e1/latest/checks.json`. A second argument selects another output folder; the default file is replaced per run.
5. Expect `passed=true`, `checks=43`, `failures=0`. The window remains open for manual checks; close it before rebuilding.

Cases cover click/Space launch, immediate pause/focus loss, invalid-state commands, three falls without extra movement, game over, F2 during play/pause, diagnostic-only paused F1, F10, diagnostic values, score formatting, window-position-independent directions, ownership, and fifty stable restarts.

Calls are synchronous public handlers with timer disabled by the observer during fixtures. They do not depend on Windows cadence or inject physical keyboard events. E2 adds console rules without forms; E3 supplies elapsed time explicitly.

This suite does not certify continuous paddle angles, brick faces/corners, high speed, fixed-step timing, DPI, paint performance, or long-session leak absence. Visual checking complemented it and detected/fixed diagnostic contrast in E1. Current integration checks are documented under [E4](../e4/README.md).
