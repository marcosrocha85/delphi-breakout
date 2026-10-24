# E6 diagnostic visual stepping evidence

Date: 2026-10-23. Base: `22ded81` on `codex/e6-consolidation`.

The nine new form regression checks first reproduced the issue against the
previous UMain implementation: 85 checks, five failures. The preserved
`red-Win64-Debug.json` is that expected failing run, not a final validation.
After the correction, all four Win32/Win64 Debug/Release runners passed 85
checks and 13 baseline pixel comparisons each. Each directory contains its
fresh view/pixel report. The manifest records source and executable hashes,
PE architecture, and which targets were rebuilt.

All eight affected GUI targets (game and runner) used full IDE Build in the
existing Delphi group. No project or group was closed. The user's running
Win64 Release test was stopped through Delphi's Reset command before building.
Final runners were launched hidden with quoted absolute output paths, their
reports inspected, and the exact verified runner processes stopped afterward.

The pure engine/presentation sources and console test dependencies did not
change. All four existing console executables were rerun: 124 engine,
104 physics/time, and 41 presentation checks each, with zero failures.
Those binaries were not rebuilt for this form-only correction. Their complete
reports remain under ignored build/e6-debug-visual; counts/hashes are recorded
in the manifest. The prior full reports remain in the paddle-fix evidence.
Breakout.res remains byte-identical to its pre-fix backup. Local IDE preferences
were preserved and remain outside this commit.

The regression exercises a fresh impact through F1, freezes a 100 ms old fade,
advances it and the score by one quantum, reaches half opacity after three
quanta, completes the fade after 18 total quanta from the 100 ms pause point,
and confirms pause, F10 gating, and restart behavior. Mouse, paint, refresh,
and ordinary frames do not consume animation time while paused. New impacts
start at full opacity, preserving normal presentation-before-physics ordering.

The focused human retest is pending; see [E6 results](../../e6-results.md).
