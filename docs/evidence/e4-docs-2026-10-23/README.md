# Documentation and 5 ms scoring — 2026-10-23

Current visual defaults: 250 ms fading, one point per 5 ms (200 points/s), and rewards 100/150/200/250/400/500.

The IDE group build succeeded: main game Win64 Release, BaselineRunner Win32 Debug, console Win64 Debug. Console results are 46 engine + 104 physics/time + 41 presentation = **191 passing cases**, zero failures. VCL/bitmap results are **47 passing checks**, zero failures.

Temporal expectations now verify no increment at 4 ms, one point after the next millisecond, unit increments through the target, 200 points over one active second at 30/60/144 callback schedules, accumulated new targets, and 100 points after half a second through the VCL adapter. Fade coverage retains 250/350/500 ms.

This is targeted validation of the later parameter/documentation change. The original E4 four-configuration matrix and performance collections remain separate historical evidence. The Win32/Win64 Release executables supplied by the local IDE build both report file/product version 1.0.1.0; their exact packaged bytes are recorded in the release manifest and checksums.

PasDoc 1.0.4 generated the nine-unit API with English labels and no warnings. Local Markdown targets and HTML targets/anchors were checked. The English study guide explains formulas and limitations alongside the generated contracts.

Documentation paths now use `study/` and `evidence/`; reports and the implementation plan use English names. Historical JSON/CSV data and screenshot bytes are preserved. Paths embedded inside old provenance records describe their capture-time locations.
