# E7 — resizable proportional game window

Date: 2026-10-23. Base: integrated E6 `648cc82`.
Environment: Delphi 13 Community Edition, Windows, VCL.
Status: implemented and automated validation passed; native manual acceptance pending.

Marcos selected the resizable-window delivery after accepting E6 and authorizing
PR #10 merge. That PR is integrated. The E6 acceptance record is retained in this
branch because its documentation update arrived after the merge.

## Delivered behavior

The main form now has a native sizing border and maximize button. It starts at
the existing client dimensions; its initial DPI-scaled outer dimensions set
the minimum window constraints. VCL rescales those constraints on DPI changes.
AutoScroll is disabled so the client remains the single drawing surface.

The existing viewport fits the 688 by 453 logical field uniformly inside any
larger client rectangle. The field stays centered and unused space is black.
Sprites, ball, paddle, text, and HUD retain their proportions. The window itself
can be wide or tall; it is not constrained to the field's aspect ratio.

Rendering and horizontal mouse inversion use the same viewport. Mouse movement
outside the field still clamps the paddle to its logical edges, and the Ready
ball follows the paddle's center. Resize only invalidates painting. The model,
fixed-step loop, animation ages, score debt, and controls retain their existing
behavior; no new resize-specific timing policy was introduced.

Production changes are limited to form properties and initial minimum bounds.
The existing viewport, renderer, engine, and loop required no implementation
changes. Menus and fullscreen remain later deliveries.

## Automated validation

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

## Native acceptance still required

Follow the [manual checklist](../tools/e7/README.md): drag borders/corners,
maximize/restore, exercise mouse alignment during Ready and play, resize a
paused fade and use F1/F10, minimize/restore, and switch focus. Check actual
monitor/DPI transitions where equipment permits, recording the configurations
used. Programmatic size changes do not establish how Windows modal sizing and
native focus/DPI messages behave during human interaction.

Keep the PR in draft until Marcos accepts these focused checks. No human E7
playtest or native DPI transition is claimed by this report.
