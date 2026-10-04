# Jekyll

Jekyll 4.4.1 (Ruby 3.2 from apt) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/_posts`, then times `bundle exec jekyll build --quiet` (never `--incremental`); each post must render to `_site/posts/*/index.html` (the verification step checks the count equals the requested number of files). Run it with `./ssgberk --test jekyll -nf 10` from the toolset repository.

Timed command uses the realistic invocation (`bundle exec …`), which includes ~0.1–0.4 s wrapper startup.
