# Nikola + Mako

Nikola 8.3.3 (Mako templates, `base` theme with minimal site templates) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/posts` (reST-style `.. title:` / `.. slug:` / `.. date:` header in `.md` files), then times `nikola build -q`; each post must render to `output/posts/*/index.html` (the verification step checks the count equals the requested number of files). Doit state (`cache`, `.doit.db*`) is cleared before every timed run so runs are not incremental. Run it with `./ssgberk --test nikola-mako -nf 10` from the toolset repository.

`requirements.txt` is the full `pip freeze` of `pip install Nikola==8.3.3` (no extras) taken inside the built image, so every transitive dependency is pinned. The archive, categories, tags, authors and page-index classifier plugins are disabled so that only the index lists all posts.
