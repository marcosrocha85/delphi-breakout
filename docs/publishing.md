# Publishing the documentation

The public entry point is [Delphi Breakout documentation](https://marcosrocha85.github.io/delphi-breakout/). The generated reference is available under [API](https://marcosrocha85.github.io/delphi-breakout/api/).

GitHub Pages publishes the **`/docs` directory on `main`**. Changes become public after they are merged into `main` and the Pages deployment completes. A separate documentation branch is not required. The repository setting is **Settings → Pages → Deploy from a branch → main → /docs**.

`docs/index.html` is the site entry point. `docs/api/index.html` is PasDoc's entry point. Publishing `/docs` also publishes its subdirectories, so `/api/` works without selecting a deeper directory in the Pages settings.

The `.nojekyll` file serves the checked-in HTML, CSS, and JavaScript as static files. Study chapters remain Markdown on GitHub, where they are rendered with links to the source. The landing page explicitly links to those chapters.

## Updating the API

Run the [PasDoc generator](api/README.md), review its output, and commit the generated files together with the source comments. The generator creates its output directory if needed and overwrites files with matching names. It does not delete the output directory or unrelated files; obsolete generated files must be reviewed separately.

Keep the output at `docs/api/`. Pointing PasDoc at `docs/` would overwrite the site's own `index.html`. Publishing does not compile Delphi or regenerate PasDoc automatically: Pages serves the generated files included in the merged commit.

To preview the complete site locally, run from the repository root:

```powershell
python -m http.server 8769 --bind 127.0.0.1 --directory docs
```

Open `http://127.0.0.1:8769/` and follow the API link. Check the landing page at a narrow viewport and verify that API styles, scripts, and navigation load. After a merge, check the repository's **Actions** page for the Pages deployment status.
