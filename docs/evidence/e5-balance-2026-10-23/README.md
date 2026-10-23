# E5 height-balance verification evidence

Collected on 2026-10-23 from Delphi 13 Community Edition IDE builds with
`DelphiBlocks.groupproj` open. This snapshot follows E5 commit `9d85f43` and
the authorized class-balance adjustment across all three approved formations.
The [original E5 evidence](../e5-2026-10-23/README.md) remains historical.

- `win32-debug-*.json` and `win64-debug-*.json`: 117 engine, 104 physics/time,
  and 41 presentation checks per configuration; zero failures.
- `engine.json`'s `class_balance` field samples seeds 0..1023 in every level:
  139,264 generated bricks per console run. Checks reject every horizontal or
  vertical premium pair, require observed mixed silver/gold diagonals in every
  level, lock geometry, and compare broad class-frequency and reward trends.
- `view.json`: 70 Win32 Debug VCL/bitmap checks; zero failures. Three new checks
  verify premium separation in actual loaded campaign boards. The suite retains
  the 47 E4 checks and 20 progression checks.
- `level-N-ready.png`: actual generated boards, exported from the renderer and
  visually inspected. The grid, twin gates, and diamond retain their geometry.
  These use the runner's match seed; they are examples, not population quotas.
- `level-N-complete.png`: visually inspected terminal messages after one-brick
  fixture collisions. These composed snapshots do not represent human play.
- `manifest.json`: source/executable and report/image SHA-256 hashes, build
  matrix, sampling details, and confirmation that the three pre-existing local
  files retain their initial bytes and remain excluded from the commit.

Observed premium percentages from the deterministic seed sample:

| Level | Top | Middle | Bottom |
| --- | --- | --- | --- |
| 1 | 18.35% | 4.34% | 1.87% |
| 2 | 22.31% | 4.39% | 1.89% |
| 3 | 20.38% | 4.54% | 1.92% |

Initial weights are documented in the [study chapter](../../study/levels-and-progression.md).
Spacing reduces final premium frequencies; these observations are not exact
test expectations. No premium side neighbors occurred, and mixed silver/gold
diagonals occurred in every level's sample. All six classes occurred in each band.

Game builds succeeded in Win32 Debug and Win64 Release. The Win64 Release build
initially reported F2039; Clean on only Breakout, followed by Build, succeeded.
The group stayed open. No new FPS/CPU benchmark or full human campaign evaluation
is claimed. Human difficulty feedback remains open.

Reproduce through the [console](../../../tests/README.md) and
[VCL runner](../../../tools/e5/README.md) after IDE builds. See
[E5 results](../../e5-results.md) for scope and remaining evaluation.
