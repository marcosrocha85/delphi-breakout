# Building a 2D engine with Delphi

This guide follows the implementation through E4. Find a rule in the code, understand its mathematics, reproduce a scenario, and change a parameter knowing what to measure. Contracts are documented in the [PasDoc API reference](../api/README.md).

## Reading path

1. [Architecture and loop](architecture-and-loop.md): state ownership, commands, and converting elapsed time into fixed steps.
2. [Physics and collisions](physics-and-collisions.md): coordinates, motion, rebound, circle sweeps, and remaining-time resolution.
3. [Rendering and FPS](rendering-and-fps.md): persistent buffering, layers, the three-part paddle, viewport, and measurement interpretation.
4. [Presentation and tests](presentation-and-tests.md): fading, score counting, seeds, tests without waiting, and exercises.

Keep the [project group](../../DelphiBlocks.groupproj) open while reading. The main executable contains the game; the console contains deterministic scenarios; BaselineRunner checks VCL integration. Stage decisions and evidence are recorded in the [plan](../implementation-plan.md) and the E0–E4 reports in the parent directory.

## Code map

| Unit | Main responsibility | Start here |
| --- | --- | --- |
| [Breakout.Types](../../src/Breakout.Types.pas) | Values, configuration, states, budgets, and snapshots | `TGameConfig.Default`, `TGameSnapshot` |
| [Breakout.Game](../../src/Breakout.Game.pas) | Rules and contact resolution | `Execute`, `Step`, `Advance` |
| [Breakout.Physics](../../src/Breakout.Physics.pas) | Geometric queries and velocity response | `SweepCircleRect`, `PaddleVelocity` |
| [Breakout.Loop](../../src/Breakout.Loop.pas) | Accumulator and step budget | `Advance` |
| [Breakout.Levels](../../src/Breakout.Levels.pas) | Deterministic legacy grid | `GenerateLegacyLevel` |
| [Breakout.Bricks](../../src/Breakout.Bricks.pas) | Class identity, sprite, and points | `BrickDefinition` |
| [Breakout.Presentation](../../src/Breakout.Presentation.pas) | Visual state and coordinate conversion | `Sync`, `Advance`, `TViewport.Fit` |
| [Breakout.Renderer.Vcl](../../src/Breakout.Renderer.Vcl.pas) | Canvas/GDI composition and presentation | `Compose`, `Paint` |
| [Breakout.Texts](../../src/Breakout.Texts.pas) | Player-facing text | `resourcestring` |
| [UMain](../../UMain.pas) | VCL events, clock, and lifecycle adaptation | `Timer1Timer`, `AdvanceFrame`, `FormPaint` |

## Conventions

Positions are **logical units** in a 688 × 453 field. At that destination size, one logical unit corresponds to one pixel; scaling changes that correspondence. Velocity is logical units per second. Physics time is seconds; fade/count configuration uses milliseconds. Configurable angles are degrees, converted to radians for sine and cosine.

Examples use current defaults. Historical results may use earlier values: score counting started at 20 ms, changed to 10 ms, and now uses **5 ms**; fading started at 350 ms and now uses **250 ms**. Do not replace an old measurement with an expectation calculated from new parameters.

## Current scope

This is a dedicated Breakout engine with a linear scan over blocks and a VCL backend. Its techniques can transfer to an engine of your own. There is no spatial index, render interpolation, monitor synchronization, or separate physics thread. The generator currently creates one 96-block grid recipe; the default configuration has one level and ends in victory. Level progression, menus, fullscreen, powerups, and other backends remain planned work.
