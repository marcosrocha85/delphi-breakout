# Levels, progression, and difficulty

[Study guide](README.md) · [Architecture and loop](architecture-and-loop.md)

## Data describes a board; rules decide when it changes

`GenerateLevel(Seed, Level)` returns a new brick array. The legacy 12 by 8 grid,
twin gates, and diamond keep their coordinates, occupancy, sizes, and row-major
IDs. All three now draw classes from a seeded height-weighted distribution.
`GenerateLegacyLevel` remains unchanged as a historical reference; the played
first level reuses its geometry and then balances its classes.

| Level | Layout | Blocks | Initial speed (logical units/s) |
| --- | --- | --- | --- |
| 1 | Legacy grid | 96 | 240 |
| 2 | Twin gates | 20 | 252 |
| 3 | Diamond | 20 | 264.6 |

Each added map has five strings of twelve cells: `#` means a brick and `.` means
empty. For example, the first diamond row is `.....##.....`: two centered
positions whose classes can change with the seed. The maps retain 50 by 20
brick size and 56/24 column/row spacing, starting at (10, 40). The generator
obtains sprites/rewards from `BrickDefinition`; shape data does not duplicate
scoring rules.

## Height weighting and premium spacing

Class assignment uses a local `TSeededRandom` stream reset to `Seed xor Level`.
Gameplay launch randomness stays independent. The same seed and level repeat
the full board, while changing the seed can recolor any of the three formations.
F2 reproduces the current match's balanced boards.

Rows are assigned to top/middle/bottom thirds using each row's center over the
occupied formation span. Coordinates are relative to that formation, not the
whole field or window. Empty outer rows do not affect the bands. With the
current shapes, top/middle/bottom row counts are 3/2/3 for the grid, 1/2/1 for
the gates, and 2/1/2 for the diamond.

| Band | Green | Yellow | Cyan | Red | Silver | Gold |
| --- | --- | --- | --- | --- | --- | --- |
| Top | 10% | 15% | 20% | 30% | 18% | 7% |
| Middle | 15% | 30% | 30% | 20% | 4% | 1% |
| Bottom | 60% | 30% | 6% | 2% | 1% | 1% |

These are initial draw weights, not final quotas. All classes remain possible
in every band. Cheaper blocks dominate below; premium rewards are more likely
above. Small boards need not reproduce population percentages in one seed.

Silver and gold are premium classes. They cannot occupy horizontally or
vertically neighboring cells, whether the pair is silver/silver, gold/gold, or
silver/gold. Diagonals are allowed. Neighbor checks use the 56/24 cell pitch,
including the visual gaps between sprites; missing cells do not create new
neighbors across a hole.

Assignment proceeds in stable row order. If a premium draw conflicts with an
already assigned neighbor, one new draw uses that band's nonpremium weights.
The replacement cannot be silver/gold, so no retry loop is needed and geometry
never changes. This reduces final premium frequencies below the initial weights.
It does not impose hard color layers, hit points, or new collision mechanics.

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

`LevelDefinitions` locks the approved geometry, checks repeatable classes in
all three levels, different seeds, bounds/nonoverlap, IDs/rewards, and independent
arrays. `ClassBalance` samples 1,024 seeds per level, checks every premium pair,
requires actual silver/gold diagonals, and compares band proportions and mean
rewards using broad behavioral thresholds. Counts and observed rates are saved
in `engine.json`; exact sample percentages are not test expectations. `SpeedPolicy` exercises the
cap, disabled growth, a very large increase, and invalid configurations.
The VCL runner additionally drives actual form handlers across transitions,
checks time/effect cleanup, and exports ready/completed frames for inspection.

Try changing a map while retaining valid cells, then compare its image and
collision tests. Try `MaxBallSpeed := 250` to cap both added levels, or set
`LevelCount := 1` for a short grid-only match. Record human observations
before changing defaults.
