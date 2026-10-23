# Levels, progression, and difficulty

[Study guide](README.md) Â· [Architecture and loop](architecture-and-loop.md)

## Data describes a board; rules decide when it changes

`GenerateLevel(Seed, Level)` returns a new brick array. Level 1 delegates to the
unchanged `GenerateLegacyLevel(Seed, 1)`: the original 12 by 8 grid, weighted
classes, coordinates, and seeded sequence are preserved. Levels 2 and 3 are
small fixed maps in `Breakout.Levels`. They do not consume random numbers.

| Level | Layout | Blocks | Initial speed (logical units/s) |
| --- | --- | --- | --- |
| 1 | Legacy grid | 96 | 240 |
| 2 | Twin gates | 20 | 252 |
| 3 | Diamond | 20 | 264.6 |

Each added map has five strings of twelve cells. A dot is empty; digits 0..5
select Green, Yellow, Cyan, Red, Silver, Gold. For example, the first diamond
row is `.....55.....`: two centered gold bricks. The maps use the original
50 by 20 brick size and 56/24 column/row spacing, starting at (10, 40).
The generator assigns row-major IDs and obtains sprites/rewards from
`BrickDefinition`; the map never duplicates scoring rules.

These are three finite boards embedded in source, with no file parser, level
editor, cycling templates, or generation of further boards. `LevelCount` can
select a prefix of 1..3 levels. Other counts and unsupported level numbers are
rejected instead of silently repeating a board.

## Completion is an explicit transition

The last collision first deactivates and scores its brick and reflects the
ball. Then `TGame.Advance` sets `gsLevelComplete`, or `gsVictory` on the last
configured level, and immediately ends the step. `TGameLoop` drops its time
remainder so the next board cannot receive catch-up movement from the old one.

```text
Ready --click/Space--> Playing --last brick--> LevelComplete
                                             |
                                      click/Space
                                             v
                                       next Ready
                                             |
                                      click/Space
                                             v
                                          Playing --last board--> Victory
```

Continuing loads a board in Ready and preserves lives and actual score. A
second click/Space launches the prepared ball. Pause, focus loss, normal steps,
and diagnostic steps cannot advance a completed board. Victory accepts F2 to
restart. F2 from any state restores level 1, three lives, zero score, the original
seeded board/launch sequence, collision diagnostics, and presentation effects.

## Speed is derived from the level, not accumulated by events

The policy is `min(MaxBallSpeed, BallSpeed * (1 + LevelSpeedIncrease)^(level-1))`.
Defaults are 240, 0.05, and a cap of 300. The implementation compares with the
cap before each multiplication, so a very large finite increase also saturates
without overflowing. A zero increase disables growth; negative/nonfinite
increases and nonfinite caps or caps below the initial speed are invalid.

`ResetPositions` applies this policy both when loading a level and after losing
a life. Losing a life therefore neither stacks difficulty nor resets it to the
first-level speed. Launch still starts at 45 degrees, with a seeded horizontal
sign. Paddle contacts preserve speed while changing angle. Changing difficulty
does not change the fixed 1/120 s simulation step or the 15 ms UI timer.

Five percent is an initial playtesting parameter. Automated collision/flow
checks establish behavior; they cannot decide whether a campaign feels fair.

## Feedback has its own lifetime

The HUD shows `Level n / total`, and Ready now explains how to launch. Pause,
completion, game over, and victory give the next applicable action. All text
stays in `Breakout.Texts` resource strings; the engine supplies values only.

The old board remains visible during completion, allowing the final fade and
score counting to finish. Continuing immediately removes old-board fades,
including when IDs are reused, while preserving displayed-score debt and its
fractional counting interval. Ready may keep the timer running until that debt
finishes. Loading a new board never launches it as a side effect of animation.
F2 explicitly resets both engine and presentation. Painting remains read-only.

## Reproduce the contracts

`TEngineTests.Campaign` clears every real brick of all three generated boards
using controlled top impacts, preserving the generated arrays. It loses a life
between boards and checks scores, speeds, explicit Ready transitions, terminal
victory, and restart. This is a collision/flow experiment, not a human playthrough.

`LevelDefinitions` checks seed equivalence of level 1, fixed maps, bounds,
nonoverlap, IDs, rewards, and independent arrays. `SpeedPolicy` exercises the
cap, disabled growth, a very large increase, and invalid configurations.
The VCL runner additionally drives actual form handlers across transitions,
checks time/effect cleanup, and exports ready/completed frames for inspection.

Try changing a map while retaining valid cells, then compare its image and
collision tests. Try `MaxBallSpeed := 250` to cap both added levels, or set
`LevelCount := 1` for a short legacy-only match. Record human observations
before changing defaults.
