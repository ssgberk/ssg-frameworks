# Sphinx

Sphinx 9.1.0 with MyST-Parser 5.1.0 (Jinja2 templates, minimal custom theme in `src/_theme/minimal`) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/posts` (content type `3minus`, YAML front matter read by MyST), then times `sphinx-build -q -d _build/doctrees -b html . _build/html`; each post must render to `_build/html/posts/*.html` (the verification step checks the count equals the requested number of files). Run it with `./ssgberk --test sphinx -nf 10` from the toolset repository.

`requirements.txt` is the full `pip freeze` of `pip install sphinx==9.1.0 myst-parser==5.1.0` taken inside the built image, so every transitive dependency is pinned. The doctree cache (`-d _build/doctrees`, outside the output folder) is cleared before every timed run (`cache_folders`).

The theme is a single `page.html` that renders only the page body. `index.md` holds a `{toctree}` with `:glob:` over `posts/*` (`:maxdepth: 1`, `:titlesonly:`), the only page listing posts. A `source-read` hook in `conf.py` prepends the front-matter title as the H1 of each post, because MyST keeps it as metadata only and the `## Chapter` headings would otherwise become top-level sections. A `builder-inited` hook turns off the search page and search index. `html_copy_source`, `html_show_sourcelink`, the general index and domain indices are off.

Deviations: the spec brief said Sphinx 8; the latest stable on 2026-10-05 is 9.1.0 and is pinned instead (R-4). Sphinx still emits `_images/ssgberk.png` (the post image, resolved from `src/assets/`), `_static/pygments.css`, `.buildinfo` and `objects.inv`. docutils warns "Document may not end with a transition" for the trailing `* * *` of each post; the build still succeeds.
