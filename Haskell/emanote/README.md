# Emanote

Emanote 1.4.0.0 on Ubuntu 24.04, benchmarked by SSGBerk. There is no static upstream binary (the GitHub release has no assets and the `sridca/emanote` Docker image is an empty amd64-only stub), so a multi-stage image compiles it: the builder stage installs GHC 9.8.4 with ghcup (Emanote 1.4.0.0's dependency set does not solve on GHC 9.10) and unpacks `emanote-1.4.0.0` from Hackage and builds it with `cabal build`, untimed; the runtime stage carries the stripped binary, its data files (default templates) and the benchmark skeleton.

`build.sh` generates the posts into `site/posts/` (`3minus` front matter), then times `mkdir -p _site && emanote -L site gen _site` (Emanote refuses to write into a missing directory, and the harness removes `_site` before each run). `site/index.md` lists every post with a ```` ```query ```` block (`path:posts/*`); each post renders to `_site/posts/*.html` with its title as `h1`. `templates/hooks/more-head.tpl` links the shared stylesheet `/assets/ssgberk.css` (byte-identical copy of `reference/assets/ssgberk.css`) from every page. `index.yaml` turns off the sidebar, breadcrumbs and table of contents, so a post page shows only that post.

Dependencies are pinned by `src/cabal.project` (`index-state: 2026-10-01`, `allow-newer`) and `src/cabal.project.freeze` (generated with `cabal freeze` in the builder), plus `EMANOTE_VERSION`. Workarounds in the builder: `allow-newer: tailwind:base` (the `tailwind` package caps `base` at 4.17), empty `tailwind`/`stork` stubs for the Template Haskell `staticWhich` splices, and on aarch64 a gcc wrapper adding `-march=armv8.2-a+sha3` for `crypton`. The cabal store is a BuildKit cache mount, a local speed-up only (a cold build compiles everything, about 50 minutes on arm64); the arm64 binary needs a CPU with the ARMv8.2 SHA3 extension.

## Extra outputs that remain

- `tailwind.css`: Emanote runs the real Tailwind CSS 3.4.17 standalone CLI during `gen` (included in the timing, as in a normal build).
- `-/stork.st` is empty: the `stork` binary (no arm64 release) is replaced by a stub, so no search index is built. A real build would also index every post.
- Folder, tag, task, calendar and export pages (`posts.html`, `-/tags/*`, `-/all.html`, `-/export.md`, `-/export.json`, `tags.html`, `tasks.html`): Emanote has no switch to disable them.
- Static assets: `_emanote-static/` (fonts, Stork JS/wasm), `favicon.svg`, `assets/ssgberk.png`.

The timed build is offline (verified with `docker run --network none`). Emanote keeps no cache on disk (`cache_folders` is empty). Run it with `./ssgberk --test emanote -nf 10` from the toolset repository.
