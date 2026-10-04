# Middleman

Middleman 4.6.3 with middleman-blog (Ruby 3.2 from apt, kramdown + erb) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `src/source/posts` (`YYYY-MM-DD-NNN.md`), then times `bundle exec middleman build`. Each post renders to `build/posts/<NNN>/index.html` (the verification step checks the count equals the requested number of files); `build/index.html` is a single page listing all posts (pagination, tag and calendar pages are disabled). Run it with `./ssgberk --test middleman -nf 10` from the toolset repository.

Timed command uses the realistic invocation (`bundle exec …`), which includes ~0.1–0.4 s wrapper startup.
