# PasDoc API reference

The [HTML reference](index.html) is generated with **PasDoc 1.0.4** from the nine units in `src/`. It includes the public APIs for types, engine, loop, geometry, presentation, renderer, bricks, levels, and text. The [study guide](../study/README.md) explains `UMain` and test probes outside this engine API.

After cloning, open `index.html` in a local browser. GitHub displays HTML source rather than automatically publishing a website. Generated files are checked in so the reference can be read without installing the generator.

## Regenerate

Download official [PasDoc 1.0.4](https://github.com/pasdoc/pasdoc/releases/tag/v1.0.4) and extract it outside source directories, for example under `build/tools/`. The Win64 archive used here has SHA-256 `9ff6e8ee023250951715c7f97e759545411ae1e86ce37bb466bee5d082fdd270`. Its executable is `pasdoc/bin/pasdoc.exe` inside the archive.

From the repository root:

```powershell
python tools/docs/generate.py --pasdoc build/tools/pasdoc-1.0.4/pasdoc/bin/pasdoc.exe
```

If `pasdoc` is on PATH, use `python tools/docs/generate.py`. The script requires only Python 3's standard library. `--output build/docs/api` generates a temporary copy. It requires the pinned version and fails on generator errors or warnings. Documentation generation does not modify or compile the game.

## Document contracts next to declarations

Use `{** ... }` comments before public declarations. `staronly` excludes ordinary implementation comments from the reference. API comments use ASCII to preserve existing Pascal source encoding. English is the default for documentation, generated labels, and paths.

```pascal
{** Maps the impact offset to an upward velocity.
    @param(Offset Contact offset divided by paddle half-width.)
    @param(Speed Magnitude in logical units per second.) }
```

Describe intent, units, ownership, preconditions, and effects. Use `@param`, `@returns`, and `@link` where useful. RTL exceptions are named with `@code` in prose because RTL units are not included in this reference; `@raises` would request unresolved links. Edit Pascal comments and regenerate instead of editing HTML. Syntax follows official PasDoc [comment documentation](https://pasdoc.github.io/WritingDocumentation) and [command-line documentation](https://pasdoc.github.io/CommandLine).

Options are in [`pasdoc.options`](../../tools/docs/pasdoc.options); the introduction is [`introduction.txt`](../../tools/docs/introduction.txt). Variable timestamps are omitted. Regenerate after changing signatures/comments, and review the reference diff alongside the code.
