# Pelican

Pelican 4.12.0 (Jinja2 templates, minimal custom theme in `src/theme`) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/content` (YAML-style `---` front matter with `date` and `title`, parsed by Python-Markdown's `meta` extension), then times `pelican -q`; each post must render to `output/posts/*/index.html` (the verification step checks the count equals the requested number of files). The `cache` and `__pycache__` folders are cleared before every timed run. Run it with `./ssgberk --test pelican -nf 10` from the toolset repository.

`requirements.txt` is the full `pip freeze` of `pip install "pelican[markdown]==4.12.0"` taken inside the built image, so every transitive dependency is pinned. A custom theme is used instead of the default notmyidea so that no static assets or sidebars are produced; archives, categories, tags, authors, pagination and all feeds are disabled in `pelicanconf.py`, so only `index.html` lists posts and each article page renders only that post. Titles keep their literal quotes because the `3minus` front matter quotes them; the slug is still valid and unique.

Note: titles keep their literal quotes in the output (the `3minus` front matter quotes them).
