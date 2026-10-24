# Architecture, states, and time

[Study guide](README.md) · [Next: physics](physics-and-collisions.md)

## Responsibilities that make experiments possible

`TGame` owns the match: ball, paddle, blocks, lives, score, and state. `TGameLoop` receives elapsed time and decides how often to call `TGame.Step`. It references the game but does not destroy it. `TGamePresentation` owns a state copy and effects needing visual time. `TGameRenderer` owns the bitmaps and draws the presentation. The form creates/frees these objects and translates VCL events into API calls.

This division lets the same engine run in a console. Replacing Canvas with another backend does not require moving rules into painting code. The renderer reads presentation; `FormPaint` does not advance physics, fading, or scoring.

The normal callback flow is:

```text
TStopwatch → elapsed seconds
           → Presentation.Advance (existing effects)
           → GameLoop.Advance → zero or more Game.Step calls
           → Presentation.Sync (snapshot; new effects start at age zero)
           → Invalidate
WM_PAINT   → Renderer.Paint → Compose → BitBlt
```

Mouse events and commands can also request updates. `Invalidate` requests painting from Windows; multiple requests can be coalesced. A callback therefore does not imply exactly one `Paint`.

## Explicit states

| State | Relevant behavior |
| --- | --- |
| `gsReady` | The paddle moves and carries the ball; launching starts play. |
| `gsPlaying` | `Step` advances the match; pause or focus loss suspends play. |
| `gsPaused` | Physics and animations freeze between F1 steps. Diagnostics allows paddle positioning and advances physics, fading, and score counting by one 1/120 s quantum per F1. Closing diagnostics freezes input again. |
| `gsLevelComplete` | Wait for a launch command to load the next level. |
| `gsGameOver` | No lives remain; restart creates a new match. |
| `gsVictory` | The last configured level has been completed. |

`TGame.Execute` centralizes transitions. Click/Space become `gcLaunch`; F2 becomes `gcRestart`; F3 becomes `gcTogglePause`. The VCL layer chooses key bindings; the engine knows intent. Losing a life ends that step immediately, resets positions, and enters Ready or GameOver. One fall cannot consume several lives within the same step.

The default match now has three boards. Continuing after `gsLevelComplete` loads the next board in Ready; another click/Space launches it. The HUD reads `Level`/`LevelCount` from the snapshot. See [levels and progression](levels-and-progression.md) for maps, speed policy, and presentation cleanup.

## Real time and simulated time

The **15 ms** timer schedules opportunities to work. Elapsed time comes from `TStopwatch`:

```text
elapsed = (currentTimestamp - previousTimestamp) / TStopwatch.Frequency
dt      = 1 / 120 seconds ≈ 0.008333333 s
```

`TGameLoop.Advance` accumulates `elapsed`. While at least one `dt` is available, it removes that quantum and calls `Step`. Fractional time survives for the next callback. Starting with an empty accumulator, 15 ms allows one step and leaves about 6.667 ms; another 15 ms allows two more steps and leaves about 5 ms.

Callbacks may vary in cadence while integration keeps the same `dt`. The engine does not round positions to pixels; drawing performs that rounding. This reduces dependence between trajectory and UI cadence.

## Bounded recovery after a stall

A stalled process must not require unlimited steps when it resumes. The loop has two limits:

- `MaxElapsedSeconds = 0.1`: at most 100 ms enters the accumulator per callback; excess is recorded.
- `MaxStepsPerCallback = 12`: limits catch-up work. Remaining complete steps are discarded and measured; a fraction below `dt` survives.

The current values are consistent: twelve 1/120 s steps cover 100 ms. The limits address separate risks and can be tuned independently. After a 500 ms stall, at least 400 ms is discarded. The game prioritizes bounded work and UI responsiveness rather than recovering all wall-clock time.

A separate budget exists **inside physics**: `MaxImpactsPerStep = 8`. `TLoopDiagnostics.DiscardedSeconds` measures loop discard; `TGameSnapshot.CollisionDiscardedSeconds` measures time unresolved after exhausting collision iterations. These counters describe different events.

## Pause, resume, and visual time

Pause/resume, restart, and diagnostic stepping reset pending loop time as appropriate for the transition. The form also resets its stopwatch reference so paused time does not enter the next callback. Reactivating the window requires explicit resume.

The timer may keep running in Ready and terminal states while fading or score debt remains. Physics stays idle there while feedback finishes. Pause or inactivity freezes both. The form caps visual elapsed time at 100 ms; that policy belongs to the adapter. `TGamePresentation.Advance` itself accepts larger finite deltas and catches up without iterating once per point.

## Snapshots and memory ownership

`TGame.Snapshot` copies the brick array: mutating that returned array cannot mutate the live board. `TGamePresentation` also copies it on synchronization. Assigning a Delphi record containing a dynamic array still shares that array reference; use `Copy` for another independently mutable array. A snapshot is a reading contract, not a compiler-enforced immutable type.

To reproduce a match, preserve configuration, seed, commands, and inputs applied at the same steps. A seed reproduces generation, not a match played with different movements. The loop has no OS clock, and the engine does not use global `Random`, making these factors controllable in tests.

See [Breakout.Loop](../../src/Breakout.Loop.pas), [Breakout.Game](../../src/Breakout.Game.pas), and schedule tests in [Breakout.Physics.Tests](../../tests/Breakout.Physics.Tests.pas).

## Resizing the native window

E7 enables border resizing and native maximize/restore and opens maximized.
The restored client starts at 688 by 453 logical units scaled by VCL for the current DPI. Its initial outer
window dimensions become the minimum constraints; VCL rescales those constraints
with DPI changes. The minimum protects the existing HUD readability.

The renderer fits one uniform viewport inside the client rectangle and clears
unused space to black. Input inverts that same viewport, then the engine clamps
the paddle. OnResize updates cursor bounds and invalidates painting: it neither changes game geometry
nor resets the loop accumulator, score counting, or fade ages. Native timer
callbacks and focus-loss pause retain their existing policy. Programmatic size
changes and painting are covered by regressions; interactive dragging,
maximize/restore and real DPI/monitor changes require the [manual checks](../../tools/e7/README.md).

## Cursor confinement belongs to the window adapter

The foreground Playing window hides the pointer and confines it to the displayed
field. The form converts viewport bounds into screen pixels for
[ClipCursor](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-clipcursor),
rounding inward to exclude black margins. This shared desktop resource is
released when leaving play, pausing, losing focus, minimizing/hiding, destroying
the native handle, or closing. Ready and terminal screens leave the pointer free.
F3 releases it before interacting with the native borders and buttons.

State refreshes and window move/size/DPI messages maintain the bounds. Unchanged
bounds avoid redundant native calls. Ownership is recorded only after a successful
acquisition; failed releases retain ownership so the next update can retry.
DestroyWnd releases before a handle is destroyed or recreated. No model or
simulation timing rule depends on this desktop resource.

The automated runner disables confinement on its host window. A separate hidden
form exercises the real handlers with recorded cursor calls and simulated window
eligibility, leaving the desktop cursor untouched. These tests cover policy,
geometry, failure/retry, and cleanup; actual foreground confinement remains part
of manual acceptance. Fullscreen and borderless fullscreen follow the menu.
