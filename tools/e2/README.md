# E2 VCL adapter checks (historical)

Check out the E2/E3 revision for this control-based mode; E4 no longer links it. Activate BaselineRunner.exe in DelphiBlocks.groupproj, select Win32/Debug, and Build. Set Run > Parameters to `--e2` and Run Without Debugging, or run:

```powershell
.\tools\e0\BaselineRunner.exe --e2
```

Results go to `build/e2/latest/checks.json`; a second argument selects another directory. The title reports passed/failed, and the game remains ready for manual evaluation. Close it before rebuilding. For F2039, right-click **only the failed project** in Projects, choose Clean, then Build, as authorized by the user.

There are 52 checks: 43 E1 flow cases adapted to engine ownership plus nine adapter cases. They verify that control position/visibility/Tag do not change rules, repainting does not move/score, timer callbacks do not advance Ready, collisions hide controls while retaining IDs, and messages/victory/diagnostics follow the engine snapshot.

E3 uses 23 diagnostic keys with velocity/second and accumulated/discarded time; fixtures supply 1/120 s steps. Its historical `--e3` mode includes this suite. The [console](../../tests/README.md) checks rules without forms. Neither replaces visual, DPI, or duration evaluation. See [E4](../e4/README.md) for the current runner.
