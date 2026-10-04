# Gatsby

Gatsby 5.16.1 (React 18, gatsby-source-filesystem, gatsby-transformer-remark) on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. `build.sh` generates the posts into `src/src/pages/posts`, then times `npm run --silent build`; each post must render to `public/posts/*/index.html` (the verification step checks the count equals the requested number of files). Dependencies are installed with `npm ci` from the committed `package-lock.json`. Run it with `./ssgberk --test gatsby -nf 10` from the toolset repository.

Timed command uses the realistic invocation (`npm run …`), which includes ~0.1–0.4 s wrapper startup.
