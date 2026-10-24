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
150 VCL/bitmap checks, and 13 unchanged baseline pixel comparisons. Read the JSON
reports; launch alone does not confirm success. Close the runner before rebuilding.

The automated host restores its normal bounds before running the fixed-size
fixtures and never confines the desktop cursor. A separate hidden form verifies
the maximized startup property and cursor policy with recorded native calls and
simulated foreground eligibility. This preserves the user's mouse during checks;
real Win32 confinement and native maximize/monitor behavior still need acceptance.

New exports: window-wide.png (1000x453), window-tall.png (688x900),
window-double.png (1376x906), and window-fractional.png (1101x733). The native
form checks use 100% DPI; bitmap scales and pure viewport checks provide separate
coverage. They do not replace moving the real window between DPI configurations.

## Native manual acceptance checklist

Use the rebuilt game, preferably starting with Win64 Release:

1. Confirm the game opens maximized with a normal title bar/border. Restore it,
   then before launch drag each border/corner. Make a wide and a tall window;
   maximize and restore. Shapes retain their proportions, the field stays
   centered, and lives/level/score remain visible. The window cannot shrink
   below its initial DPI-scaled client size.
2. In Ready, the mouse is free and visible; the ball follows the paddle's center.
   Launch: the pointer hides and cannot leave the displayed field, including into
   black margins or another monitor. Check paddle reach at both edges.
3. Press F3: the cursor becomes free and visible. Resize/maximize/restore using
   native controls, then resume. The cursor is confined to the new field bounds;
   movement, rebounds, and cadence still feel correct. The match, lives/score and
   logical field dimensions are preserved. Pause before using window borders.
4. Pause while a brick is fading and points are counting, resize, then use F1
   with F10 diagnostics open. Mouse positioning and single-step feedback still
   work; waiting between commands keeps the paused simulation frozen. Close
   diagnostics, resume with F3, and verify normal play.
5. Switch applications during play: focus loss pauses and releases the mouse.
   Return and explicitly resume with F3. Pause, minimize/restore, and check repaint,
   HUD clipping, and the free cursor while minimized/paused. Check that Ready after
   losing a life and all completion screens leave it free. Close during play and
   confirm the desktop mouse stays free.
6. Where equipment permits, move between monitors or native DPI configurations.
   Check minimum bounds, proportions, text, paddle/cursor alignment, and restore
   behavior. Record actual configurations exercised rather than assuming coverage.

Fullscreen and borderless fullscreen follow the initial menu. Keep the PR in
draft until this focused native evaluation is accepted. Results
and evidence are in [E7 results](../../docs/e7-results.md).
