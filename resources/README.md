# Embedded sprites

The six streams in `provenance.json` were extracted byte-for-byte from revision `2611ded` of `UMain.dfm`. BMP files remove only the VCL TPicture property wrapper; pixels were not redrawn. `Bricks.imagelist` retains the original TImageList atlas and mask.

`Breakout.Sprites.res` is versioned so a clone can build without runtime asset files. The renderer loads resources once and prepares alpha from original black transparency. To rebuild after editing a sprite, run here with Delphi's brcc32 on PATH:

```powershell
brcc32.exe -fo Breakout.Sprites.res Breakout.Sprites.rc
```

The paddle retains three BMPs: 7×15, 36×15, and 7×15. TPaddle width extends only the horizontally striped center; caps preserve proportions. Width-100 tests compare cap pixels against original width 50 and verify every center column.
