# Cecil

> A simple and powerful content-driven static site generator. -- cecil.app

- Version: `cecil/cecil` 9.9.1, installed with Composer (see `composer.json` / `composer.lock`; the lock was generated inside a PHP 8.3 image).
- Runtime: PHP 8.3 from the Ubuntu 24.04 archive on `ubuntu:24.04` (Cecil 9.9.1 requires PHP 8.3 or newer). No Node or asset pipeline.
- Site: `layouts/_default` has one page layout, a bare section list and a home page listing all posts; `cecil.yml` disables taxonomies, feeds, sitemap, robots, 404 and the XSL pages, pagination, fingerprinting and minification.
- Content folder: `pages/posts` (`3minus` front matter, `.md`); posts are served at `posts/<n>/` (Cecil drops the `YYYY-MM-DD-` filename prefix from the slug).
- Static files: `static/assets/ssgberk.css` and `ssgberk.png` (byte-identical to `reference/assets`).
- Output folder: `_site`; output glob: `posts/*/index.html`; cache folder: `.cache`.
- Run command: `vendor/bin/cecil build --quiet` (verbose: `vendor/bin/cecil build -v`).

Run from the benchmark toolset:

```
./ssgberk --test cecil -nf 10 -cs 0.500 -mr 1
```
