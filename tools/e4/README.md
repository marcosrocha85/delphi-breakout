# E4 presentation verification

This describes the E4 measurement protocol; its original results remain historical.
The current shared runner retains those 47 checks and adds progression checks
([current suite](../e5/README.md)). In DelphiBlocks.groupproj, activate
BaselineRunner.exe, choose Win32/Debug, and Build through the IDE. The project
remains in tools/e0; its executable now uses the configuration output directory.
Optional commands:

```powershell
.\build\Win32\Debug\BaselineRunner.exe --e4 build\e4\view
.\build\Win32\Debug\BaselineRunner.exe --benchmark build\e4\after
```

--e4 writes view.json and bitmaps at original size, enlarged paddle, half fade, and 100/125/150/200% scales. It checks input, commands, focus loss, real clock, impacts, lives, victory with pending effects, F2/F1/diagnostics, layers, paddle pixels, transparency, and buffer reuse. Direct handler calls complement real keyboard/mouse checks.

--benchmark collects twenty seconds without diagnostics and twenty with them; keep the window active for forty seconds. A runner-only controller follows the ball. timer.csv records interval/handler/simulation cost; paint.csv records paint-start intervals, composition, presentation, total cost; resources.csv records accumulated CPU, memory, handles, GDI, USER. The program remains open afterward. A third optional integer argument overrides timer interval only for this benchmark process, e.g. `--benchmark <directory> 15`.

There is no monitor-refresh synchronization; callbacks and paintings are separate metrics. Different seeds are not identical workloads. See [FPS calculations and limits](../../docs/study/rendering-and-fps.md).

Tests do not implement powerups. A runner-only probe changes paddle width to check renderer/input contracts. Production draws Snapshot.Paddle.Width using the three original sprites. Scale tests compose equivalent bitmaps, not actual Windows DPI/monitor transitions. See [results and limits](../../docs/e4-results.md).

For an in-use F2039, close the relevant test window, right-click **only the failed project** in Projects, Clean it, then Build. Do not Clean All as a recovery shortcut.
