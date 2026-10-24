# E7 maximized startup and cursor confinement evidence

Date: 2026-10-23. Base: E7 `4ac848f` on codex/e7-resizable-window.

Each configuration directory contains a fresh VCL and pixel-comparison report.
All four Win32/Win64 Debug/Release variants passed 150 VCL/bitmap checks and 13
unchanged E6 pixel comparisons. The [manifest](manifest.json) records source
hashes, executable hashes/sizes/PE architecture, build timestamps and counts.

All eight affected GUI targets used full IDE Build in the existing Delphi group.
Every target reported Success and refreshed its executable. Console dependencies
are unchanged: the four existing console binaries were rerun and passed 279
checks each (124 engine, 104 physics/time, 51 presentation). They were not rebuilt
for this form/runner change; their hashes match the initial E7 manifest. Their
fresh full reports remain under ignored build/e7-cursor, with hashes recorded
here. The initial E7 evidence already retains the full console reports.

The [red report](red-Win64-Debug.json) preserves the pre-confinement regression:
16 failures out of 150 checks. This intentionally failing run is separate from
the final passing reports.

The 32 added checks cover maximized startup and cursor policy: Ready versus
Playing, pause/debug/resume, simulated foreground eligibility, app/native focus,
four viewport rectangles in screen pixels, move/resize, minimize/restore, handle
recreation, restart/life loss/terminal states, native failure/retry, and shutdown.
The hidden probe records ClipCursor requests instead of changing the desktop
cursor. The normal automated host disables confinement and restores its normal
bounds for fixed-size rendering checks. GetClipCursor confirms the shared desktop
clip remains unchanged across the probe checks. All runner processes launched
for validation were verified by path/ID and stopped after report inspection.

This validates policy and coordinate conversion through real form handlers with
simulated native calls; it does not claim a human foreground mouse test, actual
native startup/maximize interaction, or monitor/DPI transitions. Those remain in
the [manual checklist](../../../tools/e7/README.md). Fullscreen and borderless
fullscreen follow the initial menu.

The three local .dproj files and Breakout.res remain byte-identical to their
pre-change backups and are excluded from this commit. The IDE group/projects
remained open. A reload warning was declined to preserve the in-memory project;
no unsaved state was deliberately discarded. The local .codex knowledge base
remains outside Git. See [E7 results](../../e7-results.md).
