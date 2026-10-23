# E0 — Original behavior baseline

Date: 2026-10-22. Status: initial Win32 baseline completed.

E0 reproduced both reported defects and recorded build, behavior, and cadence without changing original rules/forms. Implementation fixes begin in E1.

## Environment and revision

| Item | Baseline |
| --- | --- |
| IDE | Delphi 13 Community Edition, executable 37.0.60542.8024 |
| OS | Windows 11 Pro 10.0.26300, build 26300 |
| CPU | AMD Ryzen 7 5700X, eight cores / sixteen logical processors |
| Starting local commit | `9d0a3709f1a4e901be8c01f1c84c5442b4bf1c1a` |
| Initial IDE target | Win32 / Release |
| Behavior source | Local files, including preexisting user README edits |

Local origin/main pointed to `984ab185705aa964f21c4e1c63d1802c17075ca2`, one README-only commit ahead. E0 did not fetch/pull/merge. That difference and two local README additions required reconciliation before implementation.

## Build and observation method

The original project built through the IDE as Win32/Debug: Success, displayed 0.5 s, no errors/warnings, six unused-declaration hints. Five H2164 hints identified fProgress, Label1, ProgressBar1, SList, and I at UDM lines 83–87; H2219 identified IsLabelsCreated at line 11. See [build/hints](evidence/e0-2026-10-22/03-build-hints.png) and [running original](evidence/e0-2026-10-22/04-original-em-execucao.png). The historical image under images/ was not used as evidence of that run.

Community Edition rejected command-line compilation with “This version of the product does not support command line compiling.” Its process returned zero without producing the helper executable. Successful-build evidence therefore came from the IDE.

The original window opened but was not exposed as an automation target. `tools/e0/` added a helper referencing the same UMain/UDM/UDebug and DFMs, without copying/changing their rules. It enabled MainFormOnTaskbar, called existing handlers for fixtures, and wrapped the original timer callback. An isolated brick prevented neighbors from hiding individual-face responses; F2 restored the grid afterward.

The final collection ran about twenty seconds without F10, then twenty with F10. A helper controller followed the ball and relaunched as needed, then disabled itself and left the game ready. Seeds differed; CPU/memory included instrumentation; helper appearance/focus/DPI could differ. These are not isolated, identical-load benchmarks of the standalone original executable.

The helper built as Win32/Debug. After group integration, Build All succeeded with the game Win32/Release and helper Win32/Debug in displayed 0.8 s, retaining the same legacy hints: [group build](evidence/e0-2026-10-22/15-build-grupo.png).

## Reproduced defects

With paddle X=300 and width 50, a descending ball produced:

| Region | Initial ball X | X displacement | Y displacement | Direction |
| --- | --- | --- | --- | --- |
| Left | 296 | −15 | −15 | 45° upward/left |
| Center | 320 | +5 | −5 | 45° upward/right |
| Right | 340 | +15 | −15 | 45° upward/right |

The code changed speed/horizontal direction while keeping equal X/Y magnitudes. Proportional angle response was absent, confirmed both by handlers and source inspection.

An isolated brick at (300,100), size 50×20, and a 17×17 ball at (310,84) descending with one pixel of top overlap reproduced the missing rebound. One update removed the brick, added ten points, and moved the ball to (315,89): Y remained downward. This happened at low speed with one isolated block; high-speed sweeps remained separate planned work. A bottom-face ascending hit exited downward, consistent with the first branch assigning Down. Incorrect face selection explained the asymmetry.

## States, commands, and lives

| Check | Recorded legacy behavior |
| --- | --- |
| Initialization | 96 bricks, three lives (`initial` CSV row). |
| Ready click/Space | Enabled timer/launched (`launch_click`, `launch_space`); click also exercised in the window. |
| Mouse | Paddle movement and ready-ball following observed in helper UI. |
| F3 after first tick | Paused; F3 resumed without relocation (`pause_after_first_tick`, `resume_f3`). |
| F3 immediately after launch | Ignored until first update because bPlaying was still false. |
| Space while paused | Repositioned/relaunched while retaining the pause message. |
| Focus loss | Paused; returning retained pause, checked by handler and real app switching. |
| F1 before launch | Moved the ball with timer off. |
| F1 while paused | Advanced one step. |
| Three falls | Life image width changed 45→30→15→0 pixels. |
| Life-loss callback | Still moved (+5,−5) after repositioning. |
| Game-over click | Did not launch. |
| Game-over F1 | Still moved the ball. |
| F2 | Restored 96 bricks, three lives, zero score; also checked through UI. |
| F10 | Opened/closed diagnostics in collection and UI checks. |

Manual F10 followed by Space also exposed the window system menu; handlers did not consume F10. E1 needed to recheck this considering helper differences. Direct handler fixtures complement rather than replace real keyboard/mouse checks. Screenshots of [pause](evidence/e0-2026-10-22/07-pausa-f3.png), [Space during pause](evidence/e0-2026-10-22/08-espaco-durante-pausa.png), [focus loss](evidence/e0-2026-10-22/10-perda-foco.png), [F1](evidence/e0-2026-10-22/11-f1-passo-pausado.png), and [diagnostics](evidence/e0-2026-10-22/09b-painel-debug.png) preserve the observations.

## Cadence and resources

Calculated with tools/e0/summarize.py:

| Metric | Without F10 | With F10 |
| --- | --- | --- |
| Recorded callbacks | 320 | 319 |
| Duration | 20.008 s | 19.950 s |
| Mean update interval | 62.509 ms | 62.523 ms |
| Interval p95 | 76.110 ms | 75.602 ms |
| Maximum interval | 80.466 ms | 79.006 ms |
| Mean update frequency | 15.998/s | 15.994/s |
| Mean original-handler cost | 0.207 ms | 0.413 ms |
| Handler p95 | 0.994 ms | 1.832 ms |
| CPU, one logical core | 11.71% | 20.91% |
| Observed resident memory | 20.69–20.93 MiB | 21.13–21.27 MiB |
| Handles, start→end | 270→270 | 274→276 |
| GDI, start→end | 155→149 | 157→155 |
| USER, start→end | 54→55 | 65→61 |

Across sixteen logical processors, the CPU figures correspond to about 0.73%/1.31% aggregate machine capacity. Instrumentation/controller costs are included; differences do not isolate F10 causally. The nominal 50 ms timer did not deliver twenty updates/s. Handler cost was much smaller than the interval, supporting explicit time/scheduling work before attributing poor smoothness to physics cost.

These are **simulation update rates**, not presentation FPS. Final painting was not instrumented separately. The short sample cannot establish leak absence. Full temporal data includes ball position and per-call duration.

## Evidence, IDE integration, and next stage

- [Scenarios](evidence/e0-2026-10-22/scenarios.csv), [timer sample](evidence/e0-2026-10-22/timer.csv), and [resources](evidence/e0-2026-10-22/resources.csv).
- [Calculated summary/integrity checks](evidence/e0-2026-10-22/summary.json) and [source hashes](evidence/e0-2026-10-22/sources-sha256.json).
- [Runner instructions](../tools/e0/README.md) and [final IDE state](evidence/e0-2026-10-22/16-ide-final-grupo.png).

The summary passed after IDE reload; it characterizes legacy behavior rather than approving those rules. DelphiBlocks.groupproj included both executables with Build/Make/Clean targets and shared source references, without runtime dependency. Double-click a project to activate it while keeping the group open. Final state: Breakout active, Win32/Release, main form visible.

Saving the group updated ProjectVersion 19.5→20.3 and default ProjectName only. Pascal/DFM/DPR/preexisting README hashes stayed unchanged; regenerated Breakout.res was restored to initial versioned bytes.

E1 should centralize launch/pause, exit immediately on loss, remove ProcessMessages from scoring, and remove direction ambiguity. Retain paddle-angle and missing-brick-rebound regressions throughout evolution. Score-format duplication, side-face selection, reentry risk, and missing level completion were source findings not separately reproduced in E0. Win64, DPI matrix, and ten-minute sessions remain planned validation. No Gideon session was opened.
