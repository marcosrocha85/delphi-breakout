# E5 progression verification

Open `DelphiBlocks.groupproj` and build `BaselineRunner.exe` in Win32 Debug
through the IDE. The project stays in `tools/e0`; the shared VCL suite stays in
`tools/e4/UE4ViewChecks.pas` to retain all existing rendering regressions.

```powershell
.\build\Win32\Debug\BaselineRunner.exe --e5 build\e5\view
```

With no arguments, output is `build/e5/latest`. `--e4` remains an alias.
The runner executes the shared checks and leaves its window open with a
PASSED/FAILED caption. Read `view.json`; a window appearing alone is not proof.

The current suite runs 150 checks, including E7 window/cursor regressions and a premium-spacing check for each actual loaded board. The E5 scenarios use actual form handlers, loop, and presentation to move
through all three levels, with one-brick fixtures for terminal impacts. They
check the generated board sizes, Ready feedback, a separate continuation and
launch, score/life preservation, accumulator reset, pending score across levels,
removal of previous fades, idle timers, terminal victory, and F2 cleanup. The
console separately clears every brick of the real campaign boards.

Ready and completed frames are exported as `level-N-ready.png` and
`level-N-complete.png`. The existing suite also exports paddle/fade/scaling
images and retains collision, layers, GDI/USER, real-clock, pause/focus, F1/F10,
and buffer-reuse regressions. Bitmap scale checks do not validate actual Windows
DPI changes or physical monitor transitions.

For human evaluation, play through the campaign and record whether 240 / 252 /
264.6 units/s feels appropriate. Five percent growth with a 300 cap is an initial
setting. Do not describe fixture-driven progression as a complete human match.
The existing `--benchmark` mode retains its E4 timing/resource protocol; E5
does not claim a new FPS measurement.

On an in-use/F2039 failure, close the relevant executable, right-click only the
failed project in Projects, Clean it, then Build. Do not use Clean All.
