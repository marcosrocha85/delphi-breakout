# Visual tuning after playtesting — 2026-10-23

- Fade: 350→250 ms.
- Score interval: 20→10 ms per point, increment one; 100 points in one active second.
- Marcos's rewards: green 100, yellow 150, cyan 200, red 250, silver 400, gold 500.

IDE builds: main/runner Win32 Debug, console Win64 Debug. Main-game F2039 was resolved with Clean only on Breakout in Projects, then Build. Group Build All passed afterward.

Results: 46 engine + 104 physics + 41 presentation = 191 passing console cases; 47 passing VCL/bitmap checks. Expectations cover new rewards/timing, configurable 250/350/500 ms fades, and default-effect start/half/end bitmaps.

This complements the original four-configuration matrix in ../e4-2026-10-22; that matrix was not fully repeated for this tuning. Earlier measurements remain historical. The later 5 ms counter is documented separately under ../e4-docs-2026-10-23.
