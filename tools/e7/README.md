# E7 resizable-window verification

Keep DelphiBlocks.groupproj open. Build game, console tests, and BaselineRunner
with full Build for Win32/Win64 Debug/Release. Output paths remain those defined
in [E6](../e6/README.md). On the current Community Edition, actual compilation
requires the IDE; terminal execution of the tests is supported.

```powershell
.\build\Win64\Release\Breakout.Tests.exe build\e7\Win64-Release\console
$workspacePath = (Get-Location).Path
$viewOutput = Join-Path $workspacePath 'build/e7/Win64-Release/view'
$exePath = Join-Path $workspacePath 'build/Win64/Release/BaselineRunner.exe'
$testProcess = Start-Process -FilePath $exePath -ArgumentList ('--e5 "' + $viewOutput + '"') -WorkingDirectory $workspacePath -WindowStyle Hidden -PassThru
# Wait for a fresh view.json, inspect its results, then stop this exact process.
# Verify $testProcess.Path before Stop-Process -Id $testProcess.Id.
python tools/e6/compare_frames.py docs/evidence/e6-2026-10-23/before build/e7/Win64-Release/view build/e7/Win64-Release/pixel-comparison.json
```

The shared runner retains its --e5/--e4 aliases and adds the E7 checks to the same
suite. Expect 279 console checks (124 engine, 104 physics/time, 51 presentation),
118 VCL/bitmap checks, and 13 unchanged baseline pixel comparisons. Read the JSON
reports; launch alone does not confirm success. Close the runner before rebuilding.

New exports: window-wide.png (1000x453), window-tall.png (688x900),
window-double.png (1376x906), and window-fractional.png (1101x733). The native
form checks use 100% DPI; bitmap scales and pure viewport checks provide separate
coverage. They do not replace moving the real window between DPI configurations.

## Native manual acceptance checklist

Use the rebuilt game, preferably starting with Win64 Release:

1. Before launch, drag each border/corner. Make a wide window and a tall window;
   maximize and restore. Shapes retain their proportions, the field stays
   centered, and lives/level/score remain visible. The window cannot shrink
   below its initial DPI-scaled client size.
2. Move the mouse across the entire field and into the black side margins.
   The paddle follows the cursor's horizontal position within the field and
   clamps at both edges; the Ready ball follows its center.
3. Launch and resize/maximize/restore during play. Check the rebound feel and
   cadence. Resizing must not restart a match, alter the field dimensions, or
   change lives/score. Report any native drag-related pause or jump observed.
4. Pause while a brick is fading and points are counting, resize, then use F1
   with F10 diagnostics open. Mouse positioning and single-step feedback still
   work; waiting between commands keeps the paused simulation frozen. Close
   diagnostics, resume with F3, and verify normal play.
5. Minimize/restore and switch applications. Focus loss pauses the match;
   return and explicitly resume with F3. Check repaint and HUD clipping.
6. Where equipment permits, move between monitors or native DPI configurations.
   Check minimum bounds, proportions, text, paddle/cursor alignment, and restore
   behavior. Record actual configurations exercised rather than assuming coverage.

Keep the PR in draft until this focused native evaluation is accepted. Results
and evidence are in [E7 results](../../docs/e7-results.md).
