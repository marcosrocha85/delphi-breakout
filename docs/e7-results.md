# E7 — resizable proportional game window

Date: 2026-10-23. Base: integrated E6 `648cc82`.
Environment: Delphi 13 Community Edition, Windows, VCL.
Status: completed and accepted by Marcos on 2026-10-23; squash merge explicitly authorized.
Current validation after the cursor/startup follow-up: 279 console checks,
150 VCL/bitmap checks, and 13 pixel comparisons per configuration, with zero failures.

Marcos selected the resizable-window delivery after accepting E6 and authorizing
PR #10 merge. That PR is integrated. The E6 acceptance record is retained in this
branch because its documentation update arrived after the merge.

## Delivered behavior

The main form now has a native sizing border and maximize button and opens
maximized. Restored bounds retain the existing client dimensions; its initial DPI-scaled outer dimensions set
the minimum window constraints. VCL rescales those constraints on DPI changes.
AutoScroll is disabled so the client remains the single drawing surface.

The existing viewport fits the 688 by 453 logical field uniformly inside any
larger client rectangle. The field stays centered and unused space is black.
Sprites, ball, paddle, text, and HUD retain their proportions. The window itself
can be wide or tall; it is not constrained to the field's aspect ratio.

Rendering and horizontal mouse inversion use the same viewport. Mouse movement
outside the field still clamps the paddle to its logical edges, and the Ready
ball follows the paddle's center. Resize updates cursor bounds and invalidates painting. The model,
fixed-step loop, animation ages, score debt, and controls retain their existing
behavior; no new resize-specific timing policy was introduced.

The form also manages foreground cursor confinement and its native window
lifecycle. The existing viewport, renderer, engine, and loop required no
implementation changes. Fullscreen and borderless fullscreen follow the menu.

## Initial resize validation

All three projects used full IDE Build in the already open Delphi group for
each configuration. The twelve executables were refreshed and their PE
architectures and SHA-256 hashes recorded. Tests ran from the terminal; the VCL
runners used hidden startup with absolute output paths. Their reports were
inspected and the exact verified test processes stopped afterward.

| Configuration | Game build | Console | VCL/bitmap | E6 pixel comparisons |
| --- | --- | --- | --- | --- |
| Win32 Debug | Succeeded | 279, zero failures | 118, zero failures | 13 identical |
| Win32 Release | Succeeded | 279, zero failures | 118, zero failures | 13 identical |
| Win64 Debug | Succeeded | 279, zero failures | 118, zero failures | 13 identical |
| Win64 Release | Succeeded | 279, zero failures | 118, zero failures | 13 identical |

Console coverage comprises 124 engine, 104 physics/time, and 51 presentation
checks. Ten new pure presentation checks cover centered uniform fitting,
pixel-rounded inverse input at four sizes, and empty/invalid client safety.

Thirty-three new VCL checks exercise the actual form and renderer: native
resize/maximize flags, minimum bounds, four client sizes, centered viewports,
unchanged match snapshots on resize/paint, buffer dimensions/reuse, black
letterboxes, mouse alignment, Ready ball attachment, both paddle clamps,
deterministic trajectories and fractional accumulator time, paused feedback,
F1 after resize, and bounded GUI resources after thirty size changes.

The four client sizes are 1000x453, 688x900, 1376x906, and 1101x733. Exported
images show the actual main renderer at those dimensions. Native form checks
ran at 100% DPI. Existing bitmap checks at 125/150/200% are rendering tests,
not evidence of native monitor/DPI transitions. The E6 pixel comparison retains
five full deterministic fixture frames plus HUD/message regions at four scales;
it excludes randomized Ready brick colors.

Reports, images, hashes, and build-input notes are retained in
[E7 evidence](evidence/e7-2026-10-23/README.md). Historical E6 evidence is unchanged.
The pre-existing local project preferences and generated resource were preserved
byte-for-byte and are outside the E7 commit. The local Delphi knowledge base
remains ignored by Git.

## Native evaluation and acceptance

Follow the [manual checklist](../tools/e7/README.md): drag borders/corners,
maximize/restore, exercise mouse alignment during Ready and play, resize a
paused fade and use F1/F10, minimize/restore, and switch focus. Check actual
monitor/DPI transitions where equipment permits, recording the configurations
used. Programmatic size changes do not establish how Windows modal sizing and
native focus/DPI messages behave during human interaction.

Marcos accepted the result on 2026-10-23 and explicitly requested a squash merge
of PR #11 and a continuation prompt for a new chat. This closes E7. His report
did not enumerate monitor/DPI configurations or individual checklist results;
no additional native DPI coverage or measurements are inferred from the acceptance.

## Maximized startup and cursor confinement follow-up

Marcos requested opening maximized and keeping the mouse inside the game while
playing, with fullscreen after the initial menu. The foreground Playing window
now hides/confines the cursor to the displayed field in screen coordinates,
excluding black margins. F3 releases/shows it; resuming captures again. Ready,
level completion, GameOver, Victory, app/form deactivation, minimize/hide,
handle destruction/recreation, and shutdown release confinement. Window
movement, size and DPI notifications update the rectangle. A failed acquisition
does not grant ownership; failed release is retried on the next update.

Thirty-two added checks cover the maximized startup property and cursor policy,
including four known viewport bounds, screen movement without simulation,
pause/debug stepping, foreground eligibility, app/native activation, minimize,
handle recreation, restart/life loss/terminal states, native failure/retry,
destruction, and unchanged desktop cursor bounds. Calls that would confine the
shared desktop cursor are recorded by a hidden test form. The automated host
disables confinement and restores normal bounds for the existing pixel fixtures.
These are policy/geometry tests, not an actual foreground mouse playtest.

The regression run before implementing confinement failed 16 of 150 checks.
After implementation all four runners passed 150, and all four existing console
binaries were rerun with 279 passing checks. Console dependencies did not change,
so those binaries were not rebuilt for this follow-up. All eight affected GUI
targets used fresh full IDE Build; all 13 E6 pixel comparisons remained identical
per configuration. Reports and hashes are in
[cursor/startup evidence](evidence/e7-cursor-2026-10-23/README.md).
