# E3 visual checks (historical)

Use the E3 revision to run this control-based suite; the E4 runner no longer links it. Activate BaselineRunner.exe in DelphiBlocks.groupproj, choose Win32/Debug, Build, set parameters to `--e3`, and Run Without Debugging. Alternatively:

```powershell
.\tools\e0\BaselineRunner.exe --e3
```

Output defaults to `build/e3/latest/checks.json`; a second argument selects another folder. The title reports PASSED/FAILED and leaves Ready for play/F10 evaluation. Close before rebuilding. On F2039, Clean **only the failed project** through Projects, then Build.

The 63 cases combine 43 E1, nine E2, and eleven E3 checks. They inject elapsed time into the same AdvanceFrame used by the timer. E3 covers the then-current 16 ms timer, real TStopwatch time, multiple fixed steps/callback, resume without pause catch-up, top/both-side impacts with hidden/scored controls, reflected positions, velocity/delay diagnostics, and a 1/120 s F1 step.

Short 30/120 ms waits occur only in the runner; game code does not sleep or call ProcessMessages. Assertions bound step counts without requiring an exact Windows scheduling frequency. Detailed geometry is covered by E3's 150 non-VCL tests, expanded to 191 in E4.

E3 diagnostics had 23 keys: velocity/second, 8.333 ms step, last/total steps including F1, accumulator remainder, discarded delay, and collision budget. Scheduling counters are cumulative; F2 resets match/physical limits while retaining scheduling history.

This validated the TImage adapter. Single-surface painting, DPI, interpolation evaluation, and graphics measurements belong to E4. Historical evidence is retained; see [current runner instructions](../e4/README.md).
