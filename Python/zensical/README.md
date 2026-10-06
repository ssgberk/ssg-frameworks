# Zensical

Zensical 0.0.68 (Rust core with a Python front end, MiniJinja templates, minimal theme override in `src/overrides`) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/docs/posts` (plain Markdown, no front matter, content type `none`; the title is derived from the first heading or the file name), then times `zensical build`; each post must render to `site/posts/*/index.html` (the verification step checks the count equals the requested number of files). Run it with `./ssgberk --test zensical -nf 10` from the toolset repository.

`requirements.txt` is the full `pip freeze` of `pip install zensical` taken inside the built image, so every transitive dependency is pinned. Configuration is a `mkdocs.yml` (Zensical reads MkDocs-style config). `theme.custom_dir: overrides` replaces `main.html` with a standalone template: post pages render only the title and content (no navigation, search box or table of contents), and the homepage (`docs/index.md`) lists every post from `nav.items`, so there is a single index listing all posts.

Zensical writes a cache to `.cache` next to the config; it is listed in `cache_folders` so it is removed before each run and stays out of `site/`.

Output after the build: `site/` holds `index.html`, `posts/<name>/index.html` per post, plus files the tool always emits regardless of the theme override: `404.html`, `search.json`, `sitemap.xml` and the built-in `assets/` (images, JavaScript, CSS). These cannot be disabled via configuration (`plugins: []` has no effect), so they count toward `SSGBERK_OUTPUT`.
