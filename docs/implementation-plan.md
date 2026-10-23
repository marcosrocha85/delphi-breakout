# Delphi Breakout implementation plan

Created: 2026-10-22. Updated: 2026-10-23. Runtime environment: Delphi 13, Windows.

Status: incremental implementation; **E0–E4 completed on 2026-10-22**. [E0](e0-baseline.md) records the baseline; [E1](e1-results.md) covers flow fixes; [E2](e2-results.md) extracts the engine and translation-ready text; [E3](e3-results.md) adds fixed-step continuous collision with a circular ball and rounded paddle; [E4](e4-results.md) adds Canvas, layering, animated scoring, fading, and a stretchable paddle. **E5 completed on 2026-10-23** adds a finite campaign and progression feedback; see [E5 results](e5-results.md). Next: **E6, consolidation**.

## 1. Goal and direction

Improve method/function organization, predictable mechanics, and rendering smoothness while keeping the project small, educational, and easy to open/test in Delphi 13. Continue with VCL: repair fragile flow, extract a control-independent engine, then compose a frame on one surface. Every stage must end with a buildable, playable version. Visual additions and new levels follow that foundation.

Scope assumptions:

- Initially preserve existing sprites and visual identity in `images/` and the DFM.
- Keep mouse movement, click/Space launch, F2 restart, F3 pause, and F10 diagnostics. Restrict F1 to controlled diagnostic stepping.
- Use Win32 Debug as the first baseline; also validate Win64 and Release before completion.
- Start with a fixed logical field. Free resizing/fullscreen is later work.
- Prefer the standard library and VCL. A new graphics framework, networking, level editor, and extensive powerup system are outside the first delivery.
- Keep this plan/results in the repository without opening a Gideon session. Implementation proceeds through authorized stages.
- English is the default for source/API comments, documentation, generated reference labels, and paths. Preserve original measurements and evidence provenance when reorganizing documentation.

## 2. Evidence-based legacy diagnosis

Locations below refer to the original sources, before refactoring. They describe historical defects rather than the current implementation. E1–E3 record fixes, including directed regressions for the user-reported side/top rebounds.

| Priority | Legacy evidence | Consequence and action |
| --- | --- | --- |
| High | `UMain.pas:81`, `Timer1Timer` | Bounds, paddle, lives, diagnostics, bricks, disposal, and motion share one method. Extract responsibilities before changing representation. |
| High | `UMain.dfm:481`, 50 ms timer; `UMain.pas:207` | Nominal 20 callbacks/s with displacement per callback. Separate simulation time from painting; lowering only the interval accelerates gameplay. |
| High | `UMain.pas:111–126`, paddle response | X/Y magnitudes are equal: 15/15 at edges, 5/5 at center. Angle stays 45° while speed/direction changes. Compute component ratio from contact offset. |
| High | `UMain.pas:153,166`, brick contact | Intersection before movement and overlapping face conditions lack time of impact/previous position. Handle faces, corners, penetration, and high-speed tunneling. |
| High | `UMain.pas:166–184`, face selection | The outer intersection already guarantees the first vertical condition; matching horizontal conditions make `bY := Up` unreachable. A descending ball destroys a brick and keeps descending. Lateral conditions also fail to distinguish the hit side. |
| High | User report, 2026-10-22: side impact | Sometimes a brick disappears without horizontal rebound. Reproduce both side faces while ascending/descending; reverse X only for isolated face contacts and score once. Fixed and regression-tested in E3. |
| High | `UMain.pas:104,130` | Paddle logic uses ball left edge/fixed margins; life loss also depends on paddle-relative X. Define consistent geometry and an independent lower loss plane. |
| High | `UMain.pas:132` and callback end | Repositioning after loss is followed by more movement in the same call. Exit immediately on terminal step transitions. |
| High | `UMain.pas:30`, click/pause/key handlers | State is spread across booleans and Timer.Enabled. Space relaunches during pause; F1 updates in any state. Centralize command permissions/transitions. |
| High | `UMain.pas:413`, `Application.ProcessMessages` | Scoring permits reentry during collisions/restart/disposal. Remove message pumping; update presentation after the step. |
| High | Direction constants `Left`/`Right`, lines 179/294 | `Left` also names a form property. Remove ambiguity, then use vector velocity. Regress with different window positions and diagnostics open. |
| Medium | `UMain.pas:147,198`, `CreateBars` | Component enumeration/type/Tag act as gameplay state. Replace with identified data records and active flags. |
| Medium | `UMain.pas:361`, `Randomize` | Seed resets per brick. Initialize once and support an explicit seed. |
| Medium | `UMain.pas:327`, `StrZero` | Values longer than nine characters can be concatenated twice. Use minimum-width formatting without truncation. |
| Medium | `UMain.pas:340`, `CreateBars` | Only level 1 exists and clearing all bricks has no transition. Separate generation and completion; legacy grid is 12 × 8. |
| Medium | `UMain.pas:300,316`; `UDM.pas` positions | Entities, HUD, and mouse depend on fixed/external window coordinates. Introduce logical geometry and client conversion. |
| Medium | `UDM.pas:9,42`; `UMain.pas:219` | TLanguage creates labels directly in the form and lacks explicit lifetime ownership. Separate text/presentation and define ownership. |
| Low | `UDM` and `Breakout.dpr` | Empty data module and unused declarations. Remove after decoupling text and checking references. |
| Low | `UDebug.pas:43` versus `UMain.pas:161` | Diagnostic keys differ. Standardize and display a consistent post-step snapshot. |
| Supporting | `UMain.dfm:10`, DoubleBuffered=True | Buffering already exists. Address control movement, scheduling, composition, and measured outcomes. |
| Supporting | `Breakout.dproj:79,94,201` | Shared platform DCU outputs and duplicate targets import. Review through the IDE and separate outputs. |

## 3. Target organization

Use a few units with explicit responsibilities. Avoid per-sprite class hierarchies, dependency containers, or a generic event bus.

| File | Responsibility |
| --- | --- |
| `UMain.pas/.dfm` | Window lifetime, input, scheduling, coordinate conversion, invalidation; small delegating handlers. |
| `src/Breakout.Types.pas` | Entity/configuration/state/command/snapshot records, extracted in E2. |
| `src/Breakout.Game.pas` | Match rules, state, lives, score, levels, commands; no VCL controls/forms. |
| `src/Breakout.Texts.pas` | Player-facing resource strings, preserving localization intent. |
| `src/Breakout.Physics.pas` | Continuous geometry, impact times/normals, reflection, paddle angle; extracted in E3. |
| `src/Breakout.Loop.pas` | Accumulator, fixed steps, command forwarding, stall diagnostics; no OS clock/VCL. |
| `src/Breakout.Levels.pas` | Seeded level definitions/generation. |
| `src/Breakout.Bricks.pas` | Six explicit classes, sprite indices, rewards; delivered in E4. |
| `src/Breakout.Presentation.pas` | Visual snapshot, score counting, fading, viewport; no VCL, delivered in E4. |
| `src/Breakout.Renderer.Vcl.pas` | Resources, buffer, scene, entities, HUD, overlays. |
| `UDebug.pas/.dfm` | Snapshot-based diagnostics and inspection controls. |
| `tests/Breakout.Tests.dpr` and test units | Engine/physics tests without opening the game UI. |

Keep forms at their original paths initially. Add explicit `.dpr/.dproj` references; avoid global machine search paths. Use English identifiers, private `F` fields, names expressing purpose/units, and explicit configuration. Replace per-callback `bA/bV` displacement with X/Y velocity per second. Separate mutating commands from geometry/formatting; explain decisions/limitations and remove abandoned commented code.

The form owns/frees game and renderer; game owns data; renderer owns bitmaps; diagnostics does not own the game. Replace TLanguage with resource strings and form/renderer presentation, then remove UDM/DM when unreferenced.

## 4. Mechanics and time

### States and commands

| Situation | Required behavior |
| --- | --- |
| Startup/F2 | Restore three lives, zero score, level 1, Ready; ball attached to paddle. |
| Click/Space in Ready | Launch and enter Playing. |
| F3 in Playing/Paused | Toggle pause while preserving position, velocity, score, level. |
| Click/Space in Paused | Stay paused; F3 resumes. |
| Focus loss while Playing | Pause; reactivation still requires F3. |
| Ball fully crosses lower boundary | Lose one life, enter Ready/GameOver, end the step. |
| Last brick | Enter LevelComplete; click/Space loads next level in Ready, preserving lives/score. |
| Last configured level | Enter Victory; F2 starts again. |
| Diagnostic F1 | Exactly one step only while paused; never launch or advance after game over. |
| F10 | Toggle diagnostics without changing gameplay or forcing main-window relocation. |

Timer.Enabled is scheduling detail; engine state permits simulation. Reset/pause/loss/level transitions also update clock/accumulator to prevent catch-up jumps.

### Simulation

- Use floating-point positions/velocity, rounding only for rendering.
- Measure elapsed time with explicitly initialized [TStopwatch](https://docwiki.embarcadero.com/Libraries/Florence/en/System.Diagnostics.TStopwatch).
- Start at 1/120 s fixed steps with an accumulator and roughly 16 ms timer; these are initial tuning values. E4 measured and adopted 15 ms.
- The timer requests work; measured time determines steps. [TTimer](https://docwiki.embarcadero.com/Libraries/Florence/en/Vcl.ExtCtrls.TTimer) uses WM_TIMER messages rather than an exact physics clock.
- Initially accept at most 100 ms and twelve steps/callback; explicitly count discarded excess. Never compensate an entire long suspension in one jump.
- Keep updating/drawing on the main thread; remove ProcessMessages and avoid busy waiting.
- Add interpolation only if movement evaluation justifies it; reset both interpolated states across transitions. No interpolation is currently implemented.
- Legacy 5/5 and 15/15 displacements at nominal 50 ms correspond to speeds about 141/424 units/s. Use as initial feel references, not assumed actual cadence.

### Collision and paddle response

Use a circle for the ball, rectangles for bricks, and a horizontal capsule for the paddle. E3 confirmed rounded caps from the sprite and live game.

1. Find the earliest impact over remaining step time, including walls/paddle/active bricks.
2. Sweep a circle against face segments and corner arcs. A rectangular expansion alone creates false corner contacts.
3. Move to contact, reflect by its normal, and separate using a small geometric tolerance.
4. Immediately deactivate/score bricks once; resolve ties deterministically.
5. Consume remaining time within a bounded impact count. If exhausted, stop/discard the remainder and record it.
6. Treat life loss/level completion as terminal for the current step; inactive bricks never collide again.

Accept paddle contact from above while descending. Normalize center offset to [-1,+1], map continuously to at most 60° from vertical, and preserve difficulty-defined speed. At center, use a configurable minimum absolute angle, initially 5°, retaining prior horizontal sign. Evaluate feel while playing and retain a minimum upward component to prevent near-horizontal movement.

## 5. Rendering, input, and feedback

Compose the whole frame on one VCL surface, preserving original art. The initial proposal used a TPaintBox and persistent TBitmap. E4 uses the form's Canvas directly: another TPaintBox would not add a responsibility. Painting reads state; Invalidate requests repaint after updates and normal restoration/occlusion events, including pause.

Load sprites once; resize buffers only when needed. Avoid creating controls/bitmaps per frame or collision. Draw lower **layer 2** (field, bricks, paddle, ball, destruction effects), then upper **layer 1** (score, lives, UI messages), using opaque backing so overlap cannot cover the HUD. Remove entity controls and labels after equivalence checks.

Embed DFM sprites as executable resources with preserved transparency/colors, independent of working directory. Reuse buffering where needed and measure copies rather than stacking buffers. Start at logical 688 × 453 with a separate HUD band. Fit uniformly, center margins, invert the same transform for mouse input, and do not double-apply DPI scale. Clamp paddle X to [0, fieldWidth-paddleWidth]; eliminate manual subtraction of outer window coordinates.

Use one surface input path; if drag capture is introduced, release it on pause/deactivation/close. Do not lock the cursor to a monitor by default. Ready centers the ball over the paddle; pause freezes paddle movement. Check 100/125/150/200% scaling, sharpness, HUD readability, and real monitor transitions. Confirm effective PerMonitorV2 behavior before changing manifests.

### Block classification

Before E4, six sprite variants scored `(SpriteIndex+1)*10`, or 10–60. E4 initially proposed/delivered 100–600. Marcos rebalanced them on 2026-10-23:

| Class | Sprite | Current points |
| --- | --- | --- |
| Green | 0 | 100 |
| Yellow | 1 | 150 |
| Cyan | 2 | 200 |
| Red | 3 | 250 |
| Silver | 4 | 400 |
| Gold | 5 | 500 |

Keep identity, sprite, and reward explicit in one table; test each class and summed scores. This defines rewards, not armor or special collision abilities. Such mechanics require separate scope.

### Animated score

Real engine score changes immediately, once per destroyed brick. Presentation advances its displayed value by one-point increments toward the target, e.g. 10150→10151→…→10250. Use elapsed time and centralized parameters without waiting, per-point repaint loops, or ProcessMessages. New hits accumulate in the target without restarting progress; clamp displayed score to actual score. Rules/diagnostics consult real score.

The initial interval was 20 ms (50 points/s), reduced to 10 ms and then **5 ms** by Marcos on 2026-10-23. Current rate is **200 points/s**: 100 points take 0.5 active seconds, 500 take 2.5. Painting shows the current counter at available cadence; intermediate integers need not each appear as a separate frame. Showing 100 distinct increments at 60 frames/s would require about 1.67 s.

### Destroyed-block fading

Deactivate immediately for collision/scoring/completion; retain only a temporary visual copy with ID, sprite, geometry, and age on the lower layer. Opacity falls linearly to zero over BrickFadeDurationMs. Initial proposal: 350 ms, comparing 250/350/500 ms. Marcos selected **250 ms** on 2026-10-23. Keep this configurable in one place and leave no residues.

Capture every destroyed brick since the previous presentation update, including several impacts/steps per callback. LastHitBrickId alone is insufficient. Use stable transitions or explicit events; never create effects in OnPaint. Bound temporary state by board size and reuse sprites/buffer. The ball may pass through a fading image because its collider is already gone.

Both animations use independent visual time. Pause/inactivity freeze it; resume resets the reference. In Ready after loss, LevelComplete, Victory, and GameOver, keep scheduling while feedback remains. F2 clears displayed debt/effects; a new level clears old-board effects but retains points. A level command need not wait for animation completion. Consider bounded glow/particles later; sounds/new art remain optional later work.

## 6. Implementation stages

Each stage ends with a reviewable change, build, and verification. Do not combine wholesale file movement and a complete physics rewrite in one batch.

### E0 — Record the baseline (completed)

Build through Delphi 13 and record actual version/platform/configuration, errors/warnings. Exercise launch, pause, focus, F2/F1/F10, lives, suspicious collisions. Capture the current game separately from the historical screenshot. Measure cadence/resources with/without diagnostics. Check Git before each batch: initial README edits and a local branch one commit behind origin/main required reconciliation without overwriting work. The runner is integrated in DelphiBlocks.groupproj.

Output: [reproducible baseline](e0-baseline.md), distinguishing observed bugs from source inferences.

### E1 — Organize methods and local flow fixes (completed)

Extract bounds/paddle/bricks/loss/movement/debug methods while still in the form. Centralize startup/launch/pause; remove ProcessMessages; fix score formatting, random initialization, immediate loss exit, ambiguous directions, diagnostic keys, and transitional text ownership. Remove unused/dead declarations while retaining legacy controls.

Output: [readable flow and verified fixes](e1-results.md), with restart/large-score/pause checks. Physics and graphics remain E3/E4 work.

### E2 — Extract engine and states (completed)

Create TGame/entity/configuration records, stable brick IDs and active flags, explicit commands/states, and snapshots. Keep a temporary control adapter without collision/scoring rules in synchronization. Introduce explicit seeds and generation, separating gameplay randomness from effects. Decouple text/remove TLanguage/DM. Check DUnitX availability before adding dependencies; RTL/JSON was selected because usable Win32 framework sources were unavailable.

Output: [VCL-independent rules](e2-results.md), 46 engine cases on Win32/Win64, 52 Win32 integration checks, console integrated into the IDE group.

### E3 — Correct timing and physics (completed)

Introduce measured time, fixed-step accumulator, and velocity per second. Extract geometry and earliest-impact resolution including corners, ties, penetration, remaining time, and budgets. Reproduce both reported side faces while ascending/descending (reverse X only for isolated faces) and top impacts while descending (rebound upward). Add proportional capsule-paddle response, independent loss plane, deterministic geometry tests, and equivalent-time schedules. Validate the existing adapter before replacing rendering.

Output: [stable mechanics](e3-results.md), 150 non-VCL cases across Win32/Win64 Debug/Release and 63 Win32 Debug adapter checks; one score per block and one life per fall.

### E4 — Compose and draw frames (completed)

Introduce one surface, persistent buffer, resource cache, viewport, HUD/messages; remove entity controls and the temporary adapter after visual checks. Keep HUD layer 1 above layer 2. Centralize block classes, animate unit score counting, and fade destroyed blocks under section 5's rules. Preserve three paddle parts: scale caps proportionally, extend the striped center using model width, preparing size powerups without implementing collection/rules. Add interpolation only if needed by observed motion.

Measure simulation, composition, presentation, and paint intervals separately. Refresh diagnostics around 5 Hz while open without throttling physics. E4 adopted 15 ms timer after measurement; physics remains 120 Hz.

Output: [Canvas/feedback results](e4-results.md), 191 non-VCL cases per configuration and 47 VCL/bitmap checks. Initial builds covered Win32/Win64 Debug/Release. Real DPI/multiple monitors and prolonged evaluation remain E6. Graphics speed/flicker claims require observation/measurement rather than technology assumptions.

### E5 — Complete progression and feedback (completed)

- Preserve the current generator as level 1 and add two small data-defined levels with understandable layouts.
- Complete LevelComplete/Victory progression and load levels through explicit transitions.
- Propose an initial 5% speed increase per level, capped by configuration and revised after playtesting.
- Preserve lives/score across levels; F2 resets everything.
- Refine ready/pause/game-over/victory feedback using E4's score/fade foundation.
- Consider arrows/A/D later through the same movement intent with an explicit simultaneous-input policy.

Output: a finite three-board match with explicit Ready transitions, lives/score preservation, 5% compounded level speed capped at 300 units/s, localized state feedback, and a level HUD. See [E5 results](e5-results.md) and [progression chapter](study/levels-and-progression.md) for validation and human playtesting limits.

### E6 — Consolidate project and documentation

- Separate executable/DCU outputs by platform/configuration, e.g. build/Win32/Debug and build/Win64/Release.
- Review duplicate targets imports/legacy project settings with before/after builds; preserve resources/icon.
- Remove remaining magic numbers as requested on 2026-10-23. Start in TGameRenderer.DrawHud: HUD/text coordinates, margins, life icon position/spacing/dimensions, font size, and message band. Use named constants/layout configuration; derive related positions from logical geometry and avoid duplication across renderer/viewport/model.
- Verify visual/functional equivalence after extraction: layers, alignment, scales, mouse. Separate parameter extraction from intentional appearance/mechanics changes.
- Use UTF-8 for new files; avoid incidental mass encoding/line-ending changes to legacy sources.
- Keep README/study guide and PasDoc API generation aligned with implemented behavior, incorporating authorized local changes.
- Run clean Debug/Release builds on Win32/Win64, engine tests, and the manual matrix; record final settings/measurements.

Output: a project another compatible installation can open, build, test, and understand.

## 7. Validation for each delivery

Test rules/geometry rather than duplicating handler internals or mechanically testing renames.

| Area | Minimum cases and expected outcome |
| --- | --- |
| States | Ready→Playing→Paused→Playing; click/Space preserve pause; F2 in all states; F1 requires paused diagnostics. |
| Lives | Exactly one life per fall; no launch at zero; no extra post-reset motion. |
| Score | Each brick scores once; F2 clears; format 0,42,999999999,1000000000 without duplication/truncation. |
| Classes | Sprite/reward follow centralized definitions; verify each class and mixed-class sums. |
| Animated score | Actual 10150→10250 immediately; displayed units reach target without overshoot. Accumulate hits; timing independent of paints; cover restart/pause/resume/loss/completion. |
| Layers/fading | Deliberate overlap cannot cover HUD. Test 250/350/500 ms fading, immediate deactivation, multiple hits, final brick, paused repaint, cleanup. |
| Walls | Side/top contacts remain in bounds and reflect the correct component. |
| Blocks | Descending top hit exits upward; ascending bottom hit exits downward. Left/right contacts reverse horizontal motion only, preserve Y, score once; repeat ascending/descending. Cover corners, seams, high speed, overlaps, and inactive blocks. |
| Paddle | Center/intermediate/edge offsets give proportional mirrored angles with constant speed. Cover ascending ball and ball below paddle to reject inappropriate rebounds. |
| Time | Same seed/configuration/per-step inputs at 30/60/144 callbacks/s yield equivalent states for equal steps; excessive delays follow discard policy. |
| Levels | Same seed regenerates board; final brick completes once; progression preserves lives/score; final level wins. |
| Resources | Repeated restart/debug toggles show no continuous handle/object growth; closing frees game/resources. |

Inject elapsed time for temporal tests and call Step with known inputs for rules. Compare floating-point values with explicit tolerance. Reproduction needs configuration/seed/input sequence, not seed alone.

Manual Delphi 13 matrix:

1. Open the group/project, select Win32 Debug, Build, and run.
2. Move to paddle extremes; launch by click/Space; check initial ball placement.
3. Pause, try click/Space, resume; switch apps and verify focus-loss pause.
4. Lose all lives, reject game-over launch, restart; repeat during motion/pause.
5. Open F10, pause, step impacts with F1; move the window and verify unchanged physics.
6. Use a small diagnostic board for level completion/victory.
7. Minimize/restore and cover/uncover during play/pause; check repaint and resume jumps.
8. Test DPI scales and real monitor movement where available; verify mouse/paddle correspondence.
9. Play at least ten minutes with/without diagnostics; record smoothness, CPU, memory, resources.
10. Repeat essential checks in Win64 and Release, distinguishing configuration from behavior defects.

Initial targets: approach 60 paintings/s on the reference machine, sampled p95 combined simulation/drawing below 16.7 ms, and no visible collision/control-disposal stalls. Record processing cost and inter-paint cadence separately. These are validation targets, not assumed results or monitor-sync guarantees.

## 8. Completion criteria and order

E0–E4 deliver organized code, separated engine, predictable physics, and composed rendering. E5/E6 finish experience/distribution.

- Timer handler coordinates measurement, steps, and invalidation without collision/component-scanning rules.
- State/geometry do not depend on TImage/TPanel/labels/window position.
- Each command/transition has one tested policy.
- Tested collisions do not tunnel or duplicate score; each fall loses one life.
- Painting does not mutate rules; pause/focus/DPI/repaint satisfy their tested scenarios.
- Preserve art and demonstrate smoothness changes by comparison/measurement.
- Declared builds/tests pass with evidence and without overwriting local user work.

With E0–E5 completed, proceed to E6. Keep simulation boundaries clear before graphics changes so regressions can be located. Speed, angle, cadence, and difficulty remain playtesting parameters.

## 9. Desires after E6

Recorded by Marcos on 2026-10-22 for exploration after the established stages. Preserve the control/rebound feel inspired by playing Arkanoid on a 386XT while expanding presentation and match duration.

| Desire | Future direction |
| --- | --- |
| Scaling/larger window | Resize while preserving proportions, logical geometry, readability, and mouse mapping. Presentation size stays independent of simulation speed/rules. |
| Paddle size powerup | Define collection, duration, stacking, bounds, and repositioning. Preserve rounded caps and extend only the striped center, following the original TPanel/three-TImage composition. E4 prepares drawing only. |
| Initial menu | Start a match/access implemented options with localization-ready text. Define navigation/transitions before integration. |
| Fullscreen | Evaluate borderless and traditional/exclusive modes, transitions, focus/resume, available monitors; decide supported options after testing. |
| Canvas/OpenGL | Use E4 as baseline for a comparable prototype retaining engine/sprites. Choose by observed smoothness/flicker, frame intervals, simulation/drawing cost, resources, and compatibility. |
| Template levels/endless progression | Seeded templates/variations allowing progression beyond a finite set. Evaluate diversity, bounded difficulty, playable layouts; lives can still end a match. Define completion policy when implementing. |

These are recorded desires rather than implemented features or a selected graphics technology. E5 remains finite progression with completion/victory. Existing E4–E6 acceptance criteria remain in force; detail later experiments after E6.
