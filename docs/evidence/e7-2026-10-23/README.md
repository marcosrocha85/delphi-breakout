# E7 validation evidence

Date: 2026-10-23. Base: integrated E6 `648cc82`.

Each configuration directory contains the engine, physics, presentation, VCL,
and pixel-comparison JSON reports. All four configurations passed 279 console
checks (124 + 104 + 51), 118 VCL/bitmap checks, and 13 E6 pixel comparisons.
The [manifest](manifest.json) records counts, source/binary hashes, PE headers,
executable modification times, and the preserved local build inputs.

All twelve targets used full IDE Build in Delphi 13 Community Edition through
the open DelphiBlocks group. The IDE reported Success for each target and the
executables were refreshed. The installed compiler's known console restriction
was not retried. Console tests and hidden VCL runner invocations used the shell;
reports were checked and the exact verified test processes stopped afterward.

The pre-existing local changes in the three .dproj files and Breakout.res remain
outside the commit. Their bytes match the backup made before E7 work; hashes in
the manifest identify the effective local inputs used to build. No project/group
was closed and no Clean All was used. The ignored .codex knowledge base is not
part of this evidence or the PR.

## Actual form renderer exports

These images come from the Win64 Debug VCL run at 100% native DPI. The form's
client bounds were changed programmatically and its actual renderer painted
each client. Randomized Ready brick classes are not a pixel baseline.

- [Wide: 1000x453](images/window-wide.png)
- [Tall: 688x900](images/window-tall.png)
- [Double: 1376x906](images/window-double.png)
- [Fractional: 1101x733](images/window-fractional.png)

The pixel-comparison reports compare deterministic fixture frames and HUD/message
regions against the unchanged [E6 reference](../e6-2026-10-23/before/paddle-100.png).
They do not assert equality for arbitrary randomized boards or native DPI changes.

Native border dragging, maximize/restore, minimize/focus behavior and real monitor
transitions are pending human checks. See [E7 results](../../e7-results.md) and
the [manual checklist](../../../tools/e7/README.md).
