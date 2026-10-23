# E5 verification evidence

Collected on 2026-10-23 from IDE builds in Delphi 13 Community Edition.

- `win32-debug-*.json` and `win64-debug-*.json`: 87 engine + 104 physics/time +
  41 presentation checks per configuration; zero failures.
- `view.json`: 67 Win32 Debug VCL/bitmap checks; zero failures. The suite retains
  the E4 checks and adds 20 progression checks. It uses direct form handlers and
  one-brick transition fixtures; console campaign checks hit all 136 real bricks.
- `level-N-ready.png`: actual generated campaign layouts, Ready message, and HUD.
- `level-N-complete.png`: terminal-message compositions after controlled fixture
  collisions, with immediate actual score. These are composed snapshots rather
  than screenshots of a human playthrough.
- `manifest.json`: source/executable SHA-256 values, IDE build matrix, and hashes
  confirming that the three pre-existing local files retain their initial bytes.

Game builds succeeded in Win32 Debug and Win64 Release. No new frame-rate
benchmark was collected. The 5% compounded speed setting still needs human
difficulty evaluation. Four bitmap scales in the shared runner exercise uniform
scaling/input inversion, not real Windows DPI or monitor transitions.

Run the [console](../../../tests/README.md) and [VCL runner](../../../tools/e5/README.md)
after building through the IDE. See [E5 results](../../e5-results.md) for scope,
interpretation, and the remaining E6 evaluation.
