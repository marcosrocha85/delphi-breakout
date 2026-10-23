# E6 consolidation verification evidence

Collected on 2026-10-23 against integrated E5 `82b7b24` using Delphi 13 Community
Edition with the existing `DelphiBlocks.groupproj` open.

For each of `Win32-Debug`, `Win32-Release`, `Win64-Debug`, and `Win64-Release`:

- `engine.json`, `physics.json`, `presentation.json`: 117 + 104 + 41 = 262
  console checks; zero failures.
- `view.json`: 70 shared VCL/bitmap checks; zero failures.
- `pixel-comparison.json`: 13 comparisons against the pre-extraction runner;
  zero differences. Five full fixed-fixture frames plus HUD/message bands at
  100/125/150/200% were compared. Random Ready-board bricks are excluded.

`before/` and `after/` retain the image pairs used for the Win32 Debug
comparison. `before/view.json` records the 70 passing checks before extraction.
Other configurations' exports were compared to the same baseline, with results
in their JSON files. These are renderer exports and controlled fixtures, not
screenshots of human play.

`resource-comparison.json` compares embedded icon/group-icon and named `BO_*`
sprite bytes against the before game executable in each architecture. Every
resource hash matches in all four game configurations. Product metadata is
intentionally aligned with the authorized Delphi Blocks title.

`manifest.json` records the full four-configuration build matrix, all twelve
executable hashes/sizes/PE architectures, the source/configuration/resource hashes,
and artifact hashes. Builds used fresh separated output/DCU directories and full
IDE Build. All three projects produced independent caches in every configuration.

`console-build-attempt.json` is deliberately a **failed** build experiment:
MSBuild returned zero, but the installed compiler rejected command-line compiling
and produced no fresh executable or isolated DCUs. Raw environment/diagnostic
logs and the evolving local knowledge base are excluded from Git. They are not
accepted build evidence or part of this public snapshot.

Reproduce the [console](../../../tests/README.md),
[VCL suite](../../../tools/e5/README.md), and
[pixel experiment](../../../tools/e6/README.md) after corresponding IDE builds.
See [E6 results](../../e6-results.md) for changes and interpretation.

The complete automated matrix passed. Full human campaign evaluation, prolonged
play with/without diagnostics, and native DPI/monitor/minimize/restore checks
remain open. No new FPS/CPU measurement is claimed.
