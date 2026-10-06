# Quarto

Quarto 1.10.18 (release `.deb`, bundles Pandoc and Deno) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/posts` (YAML `---` front matter), then times `quarto render --quiet`; each post must render to `_site/posts/*.html` (the verification step checks the count equals the requested number of files). The site is a Quarto website project (`_quarto.yml`) with `theme: none` and the reference stylesheet; `index.qmd` uses a `listing:` over `posts` with no pagination. No navbar, sidebar or search. Plain markdown only, so no Jupyter or knitr engine runs. Run it with `./ssgberk --test quarto -nf 10` from the toolset repository.

Caches: `.quarto` and `_freeze` (cleaned between runs). Output: `_site/`.
