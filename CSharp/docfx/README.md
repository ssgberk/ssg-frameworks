# DocFX

DocFX 2.81.0 on .NET SDK 10.0.401 (LTS, tarball for amd64 and arm64) on Ubuntu 24.04, benchmarked by SSGBerk. The tool is installed with `dotnet tool install docfx --version 2.81.0`.

`build.sh` generates the posts into `src/posts` (content type `3minus`; DocFX reads the YAML front matter into the page model), then times `bash ./mkindex.sh && docfx build docfx.json --logLevel warning`. Each post must render to `_site/posts/*.html` (the verification step checks the count equals the requested number of files). Run it with `./ssgberk --test docfx -nf 10` from the toolset repository.

DocFX has no way for a page to list other pages, so `src/mkindex.sh` (one bash loop, no per-post forks, one `sort`) writes `src/index.md`: front matter holding title, date and summary of every post, newest first. This step is part of the timed build, as the SUMMARY.md step is for mdBook. `index.md` is generated and not committed.

The custom template `src/templates/ssgberk` replaces the default template: one `conceptual.html.primary.tmpl` plus a small JS preprocessor, with the reference header, footer, post, index and 404 markup. No navbar, TOC, search or affix panel is produced, and there is no `toc.yml` (DocFX only warns about a missing toc when a template renders it). `src/assets/` holds the reference stylesheet and image, copied by the `resource` section of `docfx.json`.

DocFX writes no cache in this setup (`obj/` is not created), so `cache_folders` lists `obj` only as a safeguard. Output: `_site/` holds `index.html`, `404.html`, one `posts/<name>.html` per post, `assets/`, plus DocFX's `manifest.json` and `xrefmap.yml`. `DOTNET_CLI_TELEMETRY_OPTOUT=1`, `DOTNET_NOLOGO=1` and invariant globalization (no ICU) are set in the image.
