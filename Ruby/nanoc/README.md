# Nanoc

Nanoc 4.14.8 (Ruby 3.2 from apt, kramdown + erubi) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/content/posts`, then times `bundle exec nanoc compile`. The checksum/incremental state in `tmp/` is wiped before every timed run. Each post compiles to `output/posts/<name>/index.html` (the verification step checks the count equals the requested number of files); `output/index.html` is a single page listing all posts. Run it with `./ssgberk --test nanoc -nf 10` from the toolset repository.
