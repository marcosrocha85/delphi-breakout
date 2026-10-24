# E6 — project outputs, consistent settings, and named layout

Date: 2026-10-23. Base: integrated E5 `82b7b24`.
Environment: Delphi 13 Community Edition, Windows, VCL.
Status: the manual route exposed paused diagnostic input and visual-stepping issues.
Both corrections are implemented; the focused visual-stepping retest is pending.

## Delivered changes

All three projects now place executables in `build/<Platform>/<Config>/`.
DCU/DCP directories add a final `game`, `tests`, or `view` component under
`build/dcu/<Platform>/<Config>/`. Debug/Release binaries no longer overwrite
each other, and projects cannot share compiled-unit caches across targets.
BaselineRunner now enables Win64 as well as Win32.

Each project imports `CodeGear.Delphi.Targets` once, using the IDE-compatible
`Exists(...)` condition. This also prevents the IDE from appending another
conditional import when saving a project that used an unconditional import.
Legacy forced compiler/dependency-output fields, the conflicting
`Configuration` default, and old `Version=7.0` compiler settings are removed.
Modern platform/configuration properties select the compiler. Debug explicitly
disables optimization and enables range/overflow checks; Release enables
optimization and omits local debug information. The game shares icon, manifest,
DPI policy, and version metadata across all configurations. Existing auxiliary
IDE compatibility settings were retained where they do not conflict with this.

Marcos explicitly authorized including the previously preserved local changes.
The form caption, application title, product name, and file description now say
`Delphi Blocks`; the README and documentation entry use the same title. Project,
unit, repository, and executable names remain compatible with existing references.
The existing 1.0.1.0 release was not replaced or republished. Generated
`Breakout.res` reflects the aligned metadata while retaining icon/sprite content.
The initial local files remain backed up under ignored `build/e6/preserved-local`.

Shared logical field dimensions live in `Breakout.Types` and are used by the
model defaults, viewport defaults, and renderer. HUD coordinates, margins, font,
life-icon crop/position/spacing, and message-band geometry use named constants
and derived anchors. Sprite/HUD coordinate conversion shares the same final
rounding helpers. This extracts the E5 appearance; it introduces no new game
mechanic, resizable-window behavior, or custom-size renderer contract.

## Initial consolidation validation

The pre-extraction Win32 Debug runner passed 70 checks. The new output/DCU
directories began empty. Every subsequent target used the IDE's full Build
through the already open `DelphiBlocks.groupproj`; no command-line success was
accepted as build evidence, and no Clean All or project-closing shortcut was used.

| Configuration | Game build | Console | VCL/bitmap | Pixel comparison |
| --- | --- | --- | --- | --- |
| Win32 Debug | Succeeded | 262, zero failures | 70, zero failures | 13 identical |
| Win32 Release | Succeeded | 262, zero failures | 70, zero failures | 13 identical |
| Win64 Debug | Succeeded | 262, zero failures | 70, zero failures | 13 identical |
| Win64 Release | Succeeded | 262, zero failures | 70, zero failures | 13 identical |

The console retains 117 engine, 104 physics/time, and 41 presentation checks.
The VCL suite retains lifecycle, form-handler, real-clock, collision, progression,
layers, paddle pixels, mouse inversion, scale, handle-count, and buffer reuse
checks. Tests were executed from the terminal after compilation. Recent GUI
runner instances were launched hidden, their JSON reports checked, and those
test processes terminated afterward.

Each pixel comparison checks five complete fixed fixture frames plus the HUD
and message bands at 100/125/150/200%. Ready boards use a time-derived seed;
their random brick classes are outside this experiment. The engine separately
locks geometry and seeded generation. Original embedded icon/group-icon and
`BO_*` sprite resource hashes match the before executable in all four game
configurations. PE headers identify the expected x86/x64 architecture.

PasDoc 1.0.4 regenerated the checked-in HTML. The [study chapter](study/rendering-and-fps.md)
explains logical anchors and rounding; the [build instructions](../tools/e6/README.md)
describe output paths and pixel reproduction. Reports, image pairs, resource
comparisons, and source/executable hashes are in
[evidence/e6-2026-10-23](evidence/e6-2026-10-23/README.md).

## Console build investigation and computer use

Marcos requested terminal/file operations wherever possible and desktop control
only when Delphi is necessary. Initializing the installed `rsvars.bat` and
calling MSBuild reproduced the full compiler command without desktop control.
However, the compiler explicitly rejected command-line compilation in this
installed edition. MSBuild still returned success and exit code zero, creating
neither a fresh executable nor isolated DCUs. This is a failed compilation.

An evolving knowledge base and exact local attempt logs are kept outside Git.
They record the environment, command, working directory, actual restriction,
and the requirement to verify fresh artifacts and test results. Necessary IDE
builds remain the fallback; source edits, Git, reports, and image comparisons
use the terminal/files. No licensing configuration was changed.

## Paused diagnostic paddle correction

Marcos reported completing the requested manual route on 2026-10-23, with one
issue: after pausing and using F1 with diagnostics open, the paddle could not
be moved. The engine rejected all paused paddle input. `MovePaddle` now accepts
an explicit per-call opt-in from the form only while diagnostics is visible.
Mouse movement repositions the paddle before and after each F1 step, with the
same field clamps; it does not advance the ball, simulation clock, or effects.
Closing diagnostics restores the ordinary frozen pause. Terminal states still
reject paddle input even with the opt-in.

The updated suites contain 269 console checks (124 engine, 104 physics/time,
41 presentation) and 76 VCL/bitmap checks per configuration. The new engine
checks cover the opt-in, both clamps, frozen normal ticks, one debug quantum,
movement between steps, and nonpersistent permission. Existing terminal-state
checks now also reject opted-in movement. The form tests exercise the actual
mouse/F1/F10 handlers, presentation synchronization, paused timer, and step count.
Fresh reports are retained separately from the initial consolidation evidence in
[evidence/e6-debug-paddle-2026-10-23](evidence/e6-debug-paddle-2026-10-23/README.md).

## Diagnostic visual stepping correction

In follow-up manual testing, Marcos paused during a brick fade and observed
that F1 advanced physics while the fade stayed frozen. `SendCommand` now advances
presentation by `FixedDeltaSeconds` for an accepted paused debug step. Existing
fades and score debt advance before physics, matching `AdvanceFrame`; newly hit
bricks are synchronized afterward and begin at full opacity with zero fade age.
A full 250 ms fade takes 30 debug steps from its impact.
No wall-clock time is consumed while waiting between F1 steps. F1 in Playing or
without diagnostics does not advance visual feedback.

Nine form-level regression checks cover a fresh F1 impact, a fade paused at
100 ms, one 1/120 s quantum, three steps reaching half opacity, completion after
18 steps, the displayed score, frozen timer/step count between commands, closing
diagnostics, and restart cleanup. The suite now has 85 VCL/bitmap checks.
The new checks first failed against the previous implementation (five failed
assertions), then passed with this correction. Fresh evidence is recorded in
[evidence/e6-debug-visual-2026-10-23](evidence/e6-debug-visual-2026-10-23/README.md).

## Human report and remaining retest

Marcos's report is the acceptance evidence for the other requested manual checks.
No detailed duration, physical monitor/DPI setup, CPU/memory values, or new
FPS benchmark was supplied; no such measurements are inferred from it. The
automated handler and bitmap evidence remains narrower than native human play.

Only this focused human retest is pending:

1. Launch a ball and show diagnostics with F10.
2. Hit a brick and pause with F3 while it is fading and the score is counting.
   Move the mouse: the paddle follows and clamps at both edges; other feedback stays still.
3. Press F1 repeatedly: each step advances physics, brick fading, and score counting
   by 1/120 s. The paddle follows the mouse, and feedback stays still between steps.
4. Hide diagnostics with F10: mouse and F1 leave the paused match frozen.
5. Resume with F3 and verify normal play.

PR #10 was already marked ready for review when this correction began. Its
review status is preserved; this record does not authorize merging it.
