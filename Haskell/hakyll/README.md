# Hakyll

Hakyll 4.17.0.0 (GHC 9.10, Pandoc linked in) on Ubuntu 24.04, benchmarked by SSGBerk. A multi-stage image: the builder stage (`haskell:9.10-slim-bookworm`) compiles the `site` executable once, untimed, as a real Hakyll site does; the runtime stage carries only the stripped binary, the templates and the benchmark skeleton. `build.sh` generates the posts into `posts/` (`3minus` front matter), then times `./site build`; each post must render to `_site/posts/*.html` (the verification step checks the count equals the requested number of files).

`posts/*.md` go through Pandoc and the post template, which renders only the post. `index.html` lists every post with `loadAll "posts/*"`; there are no tags, archive or feeds. Hakyll's store is `_cache` (listed in `cache_folders`, cleaned before each timed run). The preview server, watch server and external link checker are compiled out (`cabal.project` flags) because the benchmark only uses `build`.

Dependencies are pinned by `src/cabal.project.freeze` and `index-state`. On aarch64 a gcc wrapper in the builder adds `-march=armv8.2-a+sha3` because `crypton`'s SHA-3 C code does not compile with gcc 12 otherwise. Run it with `./ssgberk --test hakyll -nf 10` from the toolset repository.
