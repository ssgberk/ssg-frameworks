# Eleventy

Eleventy (@11ty/eleventy) 3.1.6 with Nunjucks templates on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. `build.sh` generates the posts into `src/posts`, then times `npx @11ty/eleventy --quiet`; each post must render to `_site/posts/*/index.html` (the verification step checks the count equals the requested number of files). A single `_site/index.html` lists all posts. Dependencies are installed with `npm ci` from the committed `package-lock.json`. Run it with `./ssgberk --test eleventy -nf 10` from the toolset repository.

Timed command uses the realistic invocation (`npx @11ty/eleventy …`), which includes ~0.1–0.4 s wrapper startup.
