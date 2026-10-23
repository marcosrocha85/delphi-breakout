# Trajectory, paddle response, and continuous collision

[Study guide](README.md) · [Next: rendering](rendering-and-fps.md)

## Coordinates and motion

X increases rightward and Y downward. `TBall.X/Y` is the top-left of the ball's bounding square; collision geometry receives the **circle center**:

```text
r  = Size / 2
Cx = X + r
Cy = Y + r
p(t) = p(0) + v × t
```

Velocity is constant between contacts. Launch components are `±speed/√2` and `−speed/√2`, preserving `√(vx² + vy²) = speed`. At 240 units/s and 1/120 s per step, the ball travels 2 units per step regardless of direction. Each axis displacement depends on its velocity component.

## Impact location controls the paddle rebound

At contact, the engine normalizes the ball center's distance from the paddle center:

```text
offset = clamp((ballCenterX - paddleCenterX) / (paddleWidth / 2), -1, 1)
theta  = offset × MaxPaddleAngle
```

The angle is measured from upward vertical. Current defaults limit edge deflection to **60°** and absolute minimum deflection to **5°**. If `abs(theta) < 5°`, the method chooses ±5°; at the exact center, incoming horizontal velocity selects the sign. This floor avoids a perfectly vertical trajectory repeatedly following the same corridor.

After converting degrees to radians:

```text
vx = speed × sin(theta)
vy = -speed × cos(theta)
```

| Offset | Final angle | vx at speed=240 | vy at speed=240 |
| --- | --- | --- | --- |
| −1 | −60° | −207.846 | −120.000 |
| −0.5 | −30° | −120.000 | −207.846 |
| 0, with `IncomingVX > 0` | +5° | +20.917 | −239.087 |
| +0.5 | +30° | +120.000 | −207.846 |
| +1 | +60° | +207.846 | −120.000 |

Response is proportional to offset outside the minimum-angle region. Since `sin²(theta) + cos²(theta) = 1`, speed magnitude is preserved. The code uses speed at impact, allowing future mechanics to change it without breaking this contract.

See `PaddleVelocity` in [Breakout.Physics](../../src/Breakout.Physics.pas) and its caller in `TGame.Advance`. Snapshot width participates in offset and movement limits; enlarging the paddle does not leave a fixed divisor of 25 behind.

## Why testing only the final position fails

A ball can cross a block between samples without overlapping it at the end of the step. Even when overlap exists, choosing an axis using only that final position can produce the wrong response on side faces, corners, or seams.

A continuous query finds the first contact in `[0, remainingTime]`. The engine moves to that instant, resolves contact, and simulates the remaining interval with the new velocity. This is the **time of impact** (TOI). The geometry distinguishes the visible circle from its bounding square.

## Circle versus rectangle: faces and arcs

`SweepCircleRect` tests four face segments and four circular corner arcs. Expanding a rectangle by `r` in each axis produces a useful approximation, but its square corners contain regions where the circle has not touched the block. The exact boundary for the ball center has rounded corners.

For the left face, one candidate is:

```text
t = (left - r - Cx) / vx
contactY = Cy + vy × t
```

It is valid only when `t` is in range, the ball approaches the face, and `contactY` belongs to the original segment `[top, bottom]`. Other faces use the appropriate axis/sign. The left face normal is `(−1, 0)`.

For corner `Q`, the center-to-corner distance at contact must equal `r`. With `O = center - Q`:

```text
|O + v × t|² = r²
A = dot(v,v)
B = dot(O,v)
C = dot(O,O) - r²
D = B² - A × C
tEntry = (-B - sqrt(D)) / A
```

The polynomial is written as `A×t² + 2×B×t + C = 0`, explaining the denominator in the last line. Here `C` is a scalar coefficient, not the circle center.

The candidate needs a valid discriminant, an in-range time, and the correct corner quadrant. The normal is normalized `(centerAtContact - Q)`. `dot(v,n) < 0` indicates approach; tangency without inward normal motion must not invent a rebound. The query chooses the earliest candidate using explicit spatial/temporal tolerances.

## A rounded paddle represented as a capsule

The paddle is a horizontal segment with a disk at each end. End-cap radius is `height/2`. The segment spans `left + capRadius` to `right - capRadius` at the paddle's vertical center.

Sweeping a radius-`r` ball against this capsule is equivalent to sweeping its center against the segment dilated by `r + capRadius`. `SweepCirclePaddle` reuses the rectangle query with a zero-height rectangle representing that segment. The game accepts paddle contact while the ball is descending, above the paddle center, and the normal points upward. The response uses the proportional angle rather than freely reflecting around the cap.

That is a Breakout gameplay choice: the paddle directs the outgoing ball upward. Geometric detection and gameplay response remain separate.

## Surface response and remaining time

For blocks and walls, an outward unit normal `n` defines reflection:

```text
outgoingVelocity = incomingVelocity - 2 × dot(incomingVelocity,n) × n
```

A horizontal side normal reverses `vx`; a vertical top normal reverses `vy`. A corner normal can affect both components. `ReflectVelocity` leaves a separating velocity unchanged (`dot(v,n) >= 0`), avoiding reversal of an already-resolved response when a seam repeats the same normal.

Each iteration of `TGame.Advance`:

1. Finds the earliest time among walls, paddle, active blocks, and the loss plane.
2. Moves to that instant and subtracts it from remaining time.
3. Processes tied contacts within `TimeEpsilon`, in stable order.
4. Deactivates/scores hit blocks, applies response, and separates the ball spatially.
5. Continues through remaining time or exits on a state change.

The loss plane is reached when the **top of the ball** reaches `Height`; paddle X does not participate in that decision. A step starting with the ball already below the limit also consumes only one life.

## Overlap, precision, and limits

Rounding or test fixtures can produce initial penetration. The query finds the closest rectangle point. If the center is outside, the difference gives normal and depth; if inside, it chooses a shortest exit with deterministic tie-breaking. The engine separates by `normal × (penetration + PositionEpsilon)`.

`PositionEpsilon = 10⁻⁶` is spatial, in logical units; `TimeEpsilon = 10⁻¹⁰` is temporal, in seconds. They are not interchangeable. Distinct simultaneous contacts are processed sequentially in stable order. This is a Breakout solver rather than a general rigid-body constraint solver.

After eight impact iterations in one step, unresolved time is recorded/discarded. The engine does not blindly advance through solids to complete the interval. Tests cover this budget, false corner contacts, simultaneous contacts, all four faces, and high speeds.

See [Breakout.Physics.Tests](../../tests/Breakout.Physics.Tests.pas) and [Breakout.Game.Tests](../../tests/Breakout.Game.Tests.pas). The search currently scans all active blocks; measure that cost before introducing a spatial grid or another acceleration structure.
