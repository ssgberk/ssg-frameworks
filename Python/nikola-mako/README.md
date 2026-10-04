# Nikola + Mako

Nikola 8.3.3 (Mako templates, `base` theme with minimal site templates) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/posts` (reST-style `.. title:` / `.. slug:` / `.. date:` header in `.md` files), then times `nikola build -q`; each post must render to `output/posts/*/index.html` (the verification step checks the count equals the requested number of files). Doit state (`cache`, `.doit.db*`) is cleared before every timed run so runs are not incremental. Run it with `./ssgberk --test nikola-mako -nf 10` from the toolset repository.

Dependencies are pinned in `requirements.txt` (`Nikola[extras]==8.3.3`).
