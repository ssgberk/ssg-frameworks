# soupault

soupault 5.3.0 (release binary, amd64/arm64) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/site/posts` (plain Markdown, no front matter; content type `none`), then times `soupault`; each post must render to `build/posts/*/index.html` (the verification step checks the count equals the requested number of files). Run it with `./ssgberk --test soupault -nf 10` from the toolset repository.

soupault only transforms HTML, so Markdown is converted by the `cmark-gfm` preprocessor declared in `src/soupault.toml` (`md = "cmark-gfm --unsafe -e table"`); cmark-gfm is the pinned Ubuntu 24.04 package 0.29.0.gfm.6-6build1 (GFM table extension needed by the reference content).

Deviations: soupault has no front matter parser, so posts carry none (content type `none`) and the page title comes from the first `h2` through the `title` widget. `src/templates/main.html` is the reference layout; the body is inserted into `<main>`. `clean_urls` gives `posts/<name>/index.html`. No index page and no caches (`cache_folders` is empty).
