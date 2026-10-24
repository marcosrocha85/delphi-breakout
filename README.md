# Delphi Blocks

A Breakout inspired by the Arkanoid I played on a 386XT, originally written in Delphi around 2009–2010. Today, it also serves as a study project for developers building a 2D game engine and learning what happens between player input, simulation, and drawing a frame.

<img src="images/main%20game.jpg" width="400" alt="Original Delphi Breakout appearance">

The current refactoring preserves the game's visual identity while moving its rules into code that can be studied and tested without opening a window. Rendering uses the VCL Canvas and a persistent bitmap for frame composition.

Download the Windows executables and offline documentation from [release 1.0.1.0](https://github.com/marcosrocha85/delphi-breakout/releases/tag/v1.0.1.0). See the [release notes](docs/releases/1.0.1.0.md) for changes and validation.

## Learn how the engine works

**[Online documentation](https://marcosrocha85.github.io/delphi-breakout/)** · **[Browse the API](https://marcosrocha85.github.io/delphi-breakout/api/)**

Start with the [study guide](docs/study/README.md). It connects the mathematics to the units, methods, and tests implementing each technique.

| Topic | Read |
| --- | --- |
| Responsibilities, states, clocks, and a 120 Hz fixed step | [Architecture and loop](docs/study/architecture-and-loop.md) |
| Trajectory, paddle angle, circles, capsules, and continuous collision | [Physics and collisions](docs/study/physics-and-collisions.md) |
| Canvas, buffering, sprites, layers, scaling, and FPS calculation | [Rendering and measurement](docs/study/rendering-and-fps.md) |
| Animated score, fading, deterministic tests, and experiments | [Presentation and validation](docs/study/presentation-and-tests.md) |
| Finite maps, explicit transitions, and capped difficulty | [Levels and progression](docs/study/levels-and-progression.md) |
| Classes, functions, parameters, units, and ownership contracts | [PasDoc API reference](docs/api/README.md) |

The HTML reference is generated from `{** ... }` comments in the Pascal interfaces. Use GitHub Pages for online browsing, or open [`docs/api/index.html`](docs/api/index.html) locally after cloning. The [PasDoc instructions](docs/api/README.md) explain generation; [publishing instructions](docs/publishing.md) describe the site. Pages publishes the checked-in files after they are merged into `main`.

## Build and play

The validated environment is **Delphi 13 Community Edition, Windows, VCL**, targeting Win32 and Win64. There is no external physics or rendering library. PasDoc is an optional documentation tool and does not participate in the game build.

1. Open [`DelphiBlocks.groupproj`](DelphiBlocks.groupproj) in the IDE.
2. In **Projects**, activate `Breakout.exe`, select the platform/configuration, and choose **Build**.
3. Run from the IDE. Game executables go to `build/<Platform>/<Config>/` (for example `build/Win64/Release/`); sprites are embedded in the executable.

The group also contains `BaselineRunner.exe` for VCL checks and measurements, and `Breakout.Tests.exe` for tests without a UI. All three executables use `build/<Platform>/<Config>/`; DCUs are additionally separated by project. See the [engine tests](tests/README.md), [VCL runner](tools/e5/README.md), and [build consolidation](tools/e6/README.md). Builds in this Community Edition installation were performed through the IDE. The repository and executable retain the Breakout names; the application title is Delphi Blocks.

| Input | Action |
| --- | --- |
| Mouse movement | Move the paddle center, clamped to the field boundaries. |
| Left click or Space | Launch in Ready; after level completion, load the next board in Ready, then launch with another click/Space. |
| F2 | Restart the match, score, and effects. |
| F3 | Pause or resume. |
| F10 | Show or hide diagnostics. |
| F1, with diagnostics open and the game paused | Advance physics, brick fading, and score counting by one 1/120 s step; move the mouse to reposition the paddle between steps. |

The cursor is hidden over the game, but the mouse can still leave the window. Losing focus pauses the match; return to the window and press F3 to resume.

## Techniques already implemented

- An engine independent of VCL, with commands, explicit states, snapshots, and seeded generation.
- A fixed-step accumulator with bounded catch-up and discarded-time diagnostics.
- Continuous circle collision against block faces and corners; a capsule-shaped paddle.
- Paddle rebound proportional to the impact location, preserving speed magnitude.
- Canvas composition, cached sprites, transparency, and a HUD drawn above the field.
- A three-part paddle with a stretchable center for a future size powerup.
- Immediate gameplay scoring and a visual counter at **200 points/s**; block fading over **250 ms**.
- Seeded class balance by formation height: cheaper blocks are more likely below; silver/gold are more likely above and never occupy side-neighboring cells. Diagonals are allowed.
- A finite three-level campaign: the legacy grid, twin gates, and diamond; lives/score carry over, and the HUD identifies the current level.
- Initial speeds of **240 / 252 / 264.6 units/s**: 5% compounded per level, capped by configuration at 300 units/s.
- Tests that control elapsed time and measurements that distinguish simulation, callbacks, and painting.

The current implementation includes **E6 consolidation** of the [evolution plan](docs/implementation-plan.md): separate build outputs, consistent project settings, and named HUD layout. See [E6 results](docs/e6-results.md), [progression results](docs/e5-results.md), and [VCL checks](tools/e5/README.md). Marcos accepted E6 after completing the manual route and confirming both diagnostic fixes. The window remains fixed; menus, fullscreen, template-based levels, powerups, and an OpenGL comparison are planned. The [E4 results](docs/e4-results.md) retain the rendering measurements and their limits. The published 1.0.1.0 binaries above precede E5; build this branch to try the campaign.

## From a USB backup to a study project

This was my first “game” in Delphi. Its original code comes from the beginning of my learning journey and does not represent my current development practices. I published it to move beyond keeping everything on a USB drive. The current refactoring retains that history and documents techniques added later.

The idea of publishing came after showing the project to [@eimigueloliveir](https://github.com/eimigueloliveir), who encouraged me to share it. My first contact with Delphi came from a PDF shared by [@davidferreirafz](https://github.com/davidferreirafz) in 2008 and from lessons at work.

The goal is to learn, experiment, and exchange knowledge. Improvements and questions are welcome through PRs and [Discussions](https://github.com/marcosrocha85/delphi-breakout/discussions). More about me: [Marcos Rocha](https://beacons.ai/marcosrochagpm).

The code is distributed under the [MIT license](LICENSE). Arkanoid is acknowledged as the project's inspiration, without affiliation with its creators.
