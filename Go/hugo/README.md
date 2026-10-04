# Hugo

Hugo 0.167.0 (extended) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/content/post`, then times `hugo --quiet`; each post must render to `public/post/*/index.html` (the verification step checks the count equals the requested number of files). Run it with `./ssgberk --test hugo -nf 10` from the toolset repository.
