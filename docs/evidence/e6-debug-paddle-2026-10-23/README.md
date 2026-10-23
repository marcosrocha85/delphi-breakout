# E6 paused diagnostic paddle regression evidence

Date: 2026-10-23. Base: `35a5bbe` on `codex/e6-consolidation`.

All three targets were rebuilt in the existing Delphi group for Win32/Win64
Debug/Release. The final four runs each passed 269 console checks (124 engine,
104 physics/time, 41 presentation), 76 VCL/bitmap checks, and 13 pixel comparisons.
Per-configuration directories contain the fresh JSON reports; the manifest
records the tested source and executable hashes, sizes, and PE architecture.
`Breakout.res` is byte-identical to its pre-fix backup. Full images remain under
ignored `build/e6-debug-paddle`; comparisons use the initial E6 before images.

The new checks cover paused diagnostic mouse positioning before/after F1,
edge clamps, frozen ball/clock/timer, presentation synchronization, default
pause locking after F10, and rejection of opted-in movement in terminal states.
The physics and presentation suites retain all prior checks.

The initial runner invocation used a relative output directory and failed before
tests; the successful runs use a quoted absolute output path and explicit
repository working directory. Final GUI runners were launched with a hidden
window and their exact verified process IDs were terminated after report export.
No runner process remained after verification. Initial F2039 output-file failures
for Win32 runner Debug/Release and game Release were resolved by cleaning only
the affected project/configuration and rebuilding. No running instance of those
targets was present when checked; the cause of the write failure is unconfirmed.

Marcos reported all other requested manual checks passed. His focused retest of
this correction is pending. No new native play, monitor, resource, or FPS
measurements are inferred from the automated runs or the qualitative report.
See [E6 results](../../e6-results.md) for the remaining manual sequence.
