# Bridgetown

Bridgetown 2.2.2 (Ruby 3.4.9 built from source on Ubuntu 24.04, Liquid + kramdown) benchmarked by SSGBerk. Bridgetown 2.2 needs Ruby 3.3 or newer, which Ubuntu 24.04 does not package, hence the source build. `build.sh` generates the posts into `src/content/_posts` (`YYYY-MM-DD-NNN.md`, YAML `---` front matter), then times `bundle exec bridgetown build`. Each post renders to `output/posts/<NNN>/index.html` (the verification step checks the count equals the requested number of files); `output/index.html` lists all posts and `output/404.html` is the 404 page. The site has no frontend bundler (no esbuild, no Node), pagination is off, and the Rouge highlighter is disabled. Run it with `./ssgberk --test bridgetown -nf 10` from the toolset repository.

The Bridgetown source folder is `content` (`source: content` in `bridgetown.config.yml`); layouts are in `content/_layouts`, the header and footer are Liquid components in `content/_components` (rendered with `{% render %}`), and `content/assets/` holds the reference stylesheet and image.

`BRIDGETOWN_ENV=production` is set in the image. Timed command uses the realistic invocation (`bundle exec …`), which includes Bundler startup. Caches: `.bridgetown-cache` (cleaned between runs). Output: `output/`.
