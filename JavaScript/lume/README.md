# Lume

Lume 3.3.2 (Vento templates) on Deno 2.9.7 (pinned release binary, sha256-verified) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/site/posts`, then times `LUME_LOGS=ERROR deno task build`; each post must render to `_site/posts/*/index.html` (the verification step checks the count equals the requested number of files). A single `_site/index.html` lists all posts and `_site/404.html` is the not-found page.

Lume is pinned in the import map of `src/deno.json` and in `src/deno.lock` (generated inside the image). The Dockerfile builds a sample post once so every remote and npm module lands in `DENO_DIR=/opt/lume/deno`; the build task runs `deno run -A --frozen --cached-only`, so the timed build never touches the network. `DENO_NO_UPDATE_CHECK=1` disables Deno's update check. Run it with `./ssgberk --test lume -nf 10` from the toolset repository.
