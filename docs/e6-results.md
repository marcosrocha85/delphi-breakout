# E6 — project outputs, consistent settings, and named layout

Date: 2026-10-23. Base: integrated E5 `82b7b24`.
Environment: Delphi 13 Community Edition, Windows, VCL.
Status: technical consolidation delivered; full human manual matrix remains open.

## Delivered changes

All three projects now place executables in `build/<Platform>/<Config>/`.
DCU/DCP directories add a final `game`, `tests`, or `view` component under
`build/dcu/<Platform>/<Config>/`. Debug/Release binaries no longer overwrite
each other, and projects cannot share compiled-unit caches across targets.
BaselineRunner now enables Win64 as well as Win32.

Each project imports `CodeGear.Delphi.Targets` once; the game's duplicate import
is removed. Legacy forced compiler/dependency-output fields, the conflicting
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

## Validation

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

## Human evaluation still open

The automated matrix is complete. The full manual matrix is not:

- Human campaign difficulty evaluation, including the 5% growth setting.
- At least ten minutes of human play with and without diagnostics, with
  smoothness and CPU/memory/resource observations.
- Physical DPI/monitor transitions and cursor/paddle correspondence where the
  equipment is available, plus native minimize/restore and cover/uncover checks.

Handler fixtures, hidden runner execution, and four bitmap scales do not satisfy
these human/native checks. No new FPS/CPU benchmark is claimed; E4 measurements
remain historical. The E6 PR should remain a draft while this evaluation is pending.
