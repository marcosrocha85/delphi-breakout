# Canvas, layers, and FPS calculation

[Study guide](README.md) · [Next: presentation and tests](presentation-and-tests.md)

## Compose before presenting

The renderer owns a persistent `TBitmap`. `Compose` resizes it only when destination dimensions change, clears the frame, draws the field, and finishes with the HUD. `Paint` copies the result to the form Canvas using one `BitBlt`. Sprites also belong to the renderer and are loaded once.

The form treats `WM_ERASEBKGND` as handled and uses opaque painting. This prevents an intermediate window erase before copying the complete frame, a common source of flicker. Another VCL double buffer is not stacked over this explicit buffer. This technique reduces exposure of partial drawings; it does not synchronize with the monitor scanout or universally prevent tearing.

Engine coordinates remain floating-point logical values. The renderer transforms and rounds destination bounds at drawing time. Making physics depend on that rounding would make trajectory sensitive to scale and window size.

## Layers and transparency

Lower **layer 2** contains active blocks, fading residues, the paddle, and ball. Upper **layer 1** contains lives, score, and messages. It is drawn last with opaque backing. The numbering expresses visual priority; execution starts with the lower layer.

Original resources were extracted from the DFM and embedded in the executable. Loading prepares 32-bit bitmaps with alpha zero for the transparent color and 255 for opaque pixels, using premultiplied alpha. `AlphaBlend` combines sprite alpha with constant fade opacity. See [resources and provenance](../../resources/README.md).

Painting does not mutate the brick array, real score, or effect ages. Repainting after minimizing/restoring redraws the same state. This also permits generating test bitmaps without advancing the match.

## A three-part paddle

The original `TPanel` with three `TImage` controls expressed a useful design: rounded caps and a green center with horizontal lines that can grow. The renderer keeps three separate sprites.

Cap width follows the ratio between native cap width/height and requested height, limited to half the total paddle width. The remaining space belongs to the center. Only the center stretches horizontally, and the renderer reads `Snapshot.Paddle.Width`. Tests at width 100 compare cap pixels against the original width 50 and verify center stripes and seams. This prepares drawing; powerup collection/duration rules remain unimplemented.

## Viewport and input inversion

For logical field `Lw × Lh` and destination `Cw × Ch`:

```text
s  = min(Cw/Lw, Ch/Lh)
W  = Lw × s
H  = Lh × s
ox = (Cw - W) / 2
oy = (Ch - H) / 2
clientX = ox + logicalX × s
clientY = oy + logicalY × s
```

Using the same scale in both axes preserves proportions and centers the unused space. Mouse conversion is:

```text
logicalX = (clientX - ox) / s
```

`TViewport.ToLogicalX` performs this inversion, then the engine clamps paddle movement. At destination size 1000 × 453, scale is 1 and horizontal offset is 156. Client X=481 maps to logical X=325. This transform exists already; the main window remains fixed. Testing bitmaps at 125%, 150%, or 200% does not validate actual DPI transitions between monitors.

## What counts as a frame here

`TRenderMetrics.PaintCount` increments after a `Paint` call completes composition and presentation. Each such painting can be called a frame produced by the renderer. It does not tell us how many frames the monitor actually displayed.

| Metric | Meaning |
| --- | --- |
| `DrawMs` | Cost of composing the bitmap. |
| `PresentMs` | Duration of the destination `BitBlt` call. |
| `IntervalMs` | Time between starts of consecutive paint calls. |
| `PaintCount` | Cumulative number of completed paint calls. |
| Physics steps/s | Executed 1/120 s quanta, counted separately. |
| Callbacks/s | Actual frequency of timer-handler calls. |

Durations come from `TStopwatch`. `DrawMs + PresentMs` describes measured CPU-side graphics work; `IntervalMs` also includes time between calls. Painting may cost 1.8 ms while occurring every 17.5 ms. Inverting that 1.8 ms cost describes theoretical throughput under that load, not observed FPS.

## FPS formulas

An instantaneous estimate from the last valid interval is:

```text
instantaneousFPS = 1000 / IntervalMs
```

The first painting has no preceding interval. Guard against division by zero and do not treat that first sample as a valid cadence measurement.

For an observation window lasting `T` seconds:

```text
averageFPS = (finalCount - initialCount) / T
```

Use count divided by phase duration for aggregate throughput. If measuring from the first paint start to the last, `N` paintings span `N-1` intervals: use `(N-1)/(lastStart-firstStart)`. Keep sample boundaries consistent.

The arithmetic mean of instantaneous `1000/interval` values differs from the aggregate rate. To characterize irregular delivery, record interval distributions, median, and percentiles. The p95 is the value at or below which approximately 95% of samples fall; it is neither the maximum nor a guarantee for every frame.

## A 15 ms timer does not promise 66.67 FPS

`1000/15 ≈ 66.67` is the requested nominal timer frequency. Windows schedules messages, coalesces invalidations, and may repaint for other reasons, such as window restoration. The accumulator retains 120 steps per simulated second while presentation follows its own cadence.

The E4 sample with a 15 ms timer produced about **57.20 paintings/s without diagnostics** and **56.05 with diagnostics**. Composition plus presentation p95 was about **1.86 ms**. These results describe that machine, run, and load. The [full report](../e4-results.md) includes raw data, a 16 ms timer comparison, and seed/CPU limitations. Monitor delivery was not measured.

## Reproduce a collection

Build BaselineRunner as Win32/Debug, then run from the repository root:

```powershell
.\tools\e0\BaselineRunner.exe --benchmark build\study\benchmark 15
```

Keep the window active for about 40 s: 20 s without diagnostics, then 20 s with diagnostics. A runner-only controller follows the ball with the paddle. This supports sustained rendering observation, but different seeds do not represent identical workloads.

`timer.csv` records callbacks/simulation; `paint.csv` records painting; `resources.csv` records CPU and process resources. The [runner instructions](../../tools/e4/README.md) explain collection, and the [summary script](../../tools/e4/summarize.py) implements E4 analysis. Compare cost, cadence, variability, and resources together. Less perceived flicker or more FPS alone does not demonstrate lower CPU use.
