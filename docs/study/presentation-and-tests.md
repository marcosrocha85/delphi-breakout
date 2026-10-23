# Visual feedback, tests, and experiments

[Study guide](README.md)

## Real score and displayed score

At impact, the engine deactivates the block and adds its points immediately. Presentation receives that target and keeps a separate displayed value that rises over time. Scoring rules therefore do not depend on paint count.

| Class | Current points | Sprite index |
| --- | --- | --- |
| Green | 100 | 0 |
| Yellow | 150 | 1 |
| Cyan | 200 | 2 |
| Red | 250 | 3 |
| Silver | 400 | 4 |
| Gold | 500 | 5 |

The table lives in `Breakout.Bricks`. Generation copies each definition into a brick instance; appearance is not an implicit scoring rule.

With `ScoreCountIntervalMs = 5` and `ScoreCountStep = 1`:

```text
rate = 1000 / intervalMs × step = 200 points/s
time for 100 points = 100 / 200 = 0.5 s
time for 500 points = 500 / 200 = 2.5 s
```

These durations assume active execution without adapter time discard. Pause, inactivity, or heavily delayed callbacks can extend wall-clock duration. A new hit raises the target without clearing earlier debt.

`TGamePresentation.Advance` retains fractional time, computes complete available intervals, and adds increments arithmetically, bounded by the target. It does not loop once per owed point. Score progresses in logical one-point increments; at roughly 57 frames/s, several increments can occur between paintings. A 5 ms interval does not require 200 paintings/s or display every integer in a separate frame.

## The rule disappears before the image

`Sync` compares previous/current snapshots. An `Active=True → False` transition creates a `TBrickFade` holding a visual block copy at age zero. It examines every changed brick; `LastHitBrickId` is not used as an effect queue.

```text
duration = BrickFadeDurationMs / 1000 = 0.25 s
opacity = max(0, 1 - age / duration)
```

At 125 ms opacity is 0.5; at 250 ms the effect becomes inactive. The brick no longer collides or scores during that interval. Configuration allows comparing 250, 350, and 500 ms without confusing visual duration with physical state.

Fade slots are bounded by board size. A new level clears old residues while retaining score debt. Restart calls `Reset`, clearing both. Pause freezes visual time. The timer remains active in terminal states until pending effects finish, then stops.

## Seeds and reproduction

`GenerateLegacyLevel` creates a 12 × 8 grid with a local generator initialized from `Seed xor Level`. Its congruential sequence uses explicit 32-bit arithmetic:

```text
state = (state × 1664525 + 1013904223) mod 2^32
result = state mod count
```

This is a simple, reproducible choice preserving legacy generation. It is not cryptographic; modulo reduction does not promise perfect uniformity for every count. Repeated entries in the color table control relative class frequency.

To reproduce a bug, record configuration, seed, initial state, commands, and inputs per step. Test probes arrange positions/velocities to hit a particular face or corner. These probes belong only to runners and do not enter the main project.

## Test time without waiting for it

Engine tests call `Step` or `GameLoop.Advance` with known deltas. A score test can advance 4 ms, verify no change, then advance another 1 ms and observe one point. A fade test can advance half its duration and read opacity. This is fast/repeatable without sleeping through animations.

Schedules at 30, 60, and 144 callbacks/s check whether equivalent elapsed time produces the same step count/state with equivalent inputs. Presentation advances 200 points in one active second while the target remains ahead, regardless of schedule. Checking the same outcome across schedules detects animation incorrectly tied to callback count.

The VCL runner complements these tests with a real clock, form handlers, and renderer pixels. It checks HUD priority, transparency, residue cleanup, enlarged paddle caps, buffer reuse, and GDI/USER stability. The few real waits check `TStopwatch` integration rather than driving the whole suite.

## Runners and evidence

After building the corresponding configuration through the IDE:

```powershell
.\build\Win64\Debug\Breakout.Tests.exe build\study\console
.\build\Win32\Debug\BaselineRunner.exe --e5 build\study\view
```

The console has **262 cases**: 117 engine, 104 physics/time, and 41 presentation cases. BaselineRunner has **70 VCL/bitmap checks**. Read the [console instructions](../../tests/README.md), [VCL instructions](../../tools/e5/README.md), and [E5 evidence](../e5-results.md). Console exit code 0 means success; the runner also leaves its window open for evaluation.

A passing test demonstrates the scenario it exercises. Four bitmap scales do not validate every monitor; fifty restarts without continuously growing handles do not prove the absence of every leak; collision fixtures do not make this a universal solver. Keep those boundaries visible when comparing changes.

## Suggested experiments

1. Change `MaxPaddleAngle` from 60° to 45°, keeping the 5° minimum. Calculate edge components and compare against `PaddleVelocity` tests.
2. Compare 250 and 500 ms fading. Advance half the duration without painting, then compose a bitmap: both configurations should have opacity 0.5.
3. Compare 5 and 10 ms score intervals without changing the timer. Score rate should change; nominal physics rate should remain 120 Hz.
4. Arrange a high-speed side impact. Check `vx` sign, an inactive block, one score addition, and movement through remaining time.
5. Compose the same snapshot at 688 × 453 and 1000 × 453. Verify letterboxing and input inversion before changing the real window.
6. Measure with/without diagnostics. Compare CPU, interval p95, and drawing p95; distinguish additional cost from changes in match load.

Keep each experiment isolated and record parameters. When intentionally changing a rule, update the expected result and explain the new contract; do not remove assertions just to obtain a green run.
