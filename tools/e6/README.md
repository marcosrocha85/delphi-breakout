# E6 build and visual verification

Open `DelphiBlocks.groupproj` in Delphi 13 Community Edition. For each of
Win32/Debug, Win32/Release, Win64/Debug, and Win64/Release, build all three
projects through the IDE. Build compiles every unit; using an initially empty
configuration directory also verifies that no old DCU is needed. Keep the
group open and use Clean on only a failed project if F2039 occurs.

| Output | Location relative to repository root |
| --- | --- |
| Game | `build/<Platform>/<Config>/Breakout.exe` |
| Console tests | `build/<Platform>/<Config>/Breakout.Tests.exe` |
| VCL runner | `build/<Platform>/<Config>/BaselineRunner.exe` |
| Game DCUs/DCPs | `build/dcu/<Platform>/<Config>/game/` |
| Console DCUs/DCPs | `build/dcu/<Platform>/<Config>/tests/` |
| VCL runner DCUs/DCPs | `build/dcu/<Platform>/<Config>/view/` |

Changing platform, configuration, or project cannot reuse another target's DCUs
or replace another configuration's executable. The three `.dproj` files import
the Delphi targets once. A compatible Delphi installation supplies the RTL/VCL,
compiler, and default manifest; there are no machine-specific absolute paths.
Debug enables range/overflow checks and disables optimization; Release enables
optimization and omits local debug information. Both GUI platforms use the same
PerMonitorV2 manifest policy. That setting does not prove real monitor transitions.

After each build, run that configuration's executables, for example:

```powershell
.\build\Win64\Release\Breakout.Tests.exe build\e6\Win64-Release\console
.\build\Win64\Release\BaselineRunner.exe --e5 build\e6\Win64-Release\view
```

Expect 269 console checks and 85 VCL/bitmap checks with zero failures. Read the
JSON reports. The VCL runner leaves a window open; close it before rebuilding
that executable. Existing E4/E5 command flags and report schemas remain usable.

For the HUD extraction experiment, run the E5 runner before changing the source,
then run the new runner on the same machine/font environment. Compare exports:

```powershell
python tools/e6/compare_frames.py build/e6/before-view build/e6/Win32-Debug/view build/e6/pixel-comparison.json
```

The comparison uses Pillow, reads images only, and exits nonzero on a difference.
It compares five complete deterministic fixture frames plus the HUD and message
bands at four scales. Ready boards use a time-derived seed, so their random brick
colors are excluded from this pixel experiment. Independent engine tests lock
their geometry and seeded classes. These 13 comparisons verify visual equivalence
on the sampled scales; the VCL suite also retains layers and mouse inversion.

The production window and application/version metadata consistently say
`Delphi Blocks`. Marcos explicitly authorized incorporating the previously
preserved IDE/form adjustments during E6. The repository, project, unit, and
executable names remain compatible with existing references. Icon/sprite inputs
remain unchanged; the existing 1.0.1.0 release is not replaced by these builds.

Marcos reported completing the [manual route](../../docs/implementation-plan.md),
with paused diagnostic-input issues: the paddle could not move, and follow-up
testing found that F1 did not advance a partially faded brick.
The corrections allow mouse positioning with diagnostics visible and advance
physics, brick fading, and score counting by one 1/120 s quantum per F1. The ball,
clock, and animations remain frozen between steps. The focused human retest
is still pending; see [E6 results](../../docs/e6-results.md). No detailed monitor
setup, duration, or resource measurements were supplied with the user report.
