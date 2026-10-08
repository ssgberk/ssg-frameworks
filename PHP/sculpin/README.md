# Sculpin

> Static site generator for PHP developers. -- sculpin.io

- Version: `sculpin/sculpin` 3.3.1, installed with Composer (see `composer.json` / `composer.lock`, lock generated inside the image). 3.3.1 is the latest stable release; 4.0 is alpha only.
- Runtime: PHP 8.4 (ondrej PPA) on `ubuntu:24.04`.
- Site: Twig default layout + post layout + index listing posts (`src/source`); reference assets under `source/assets`.
- Content folder: `source/_posts` (`3minus` front matter with `layout: post`, `.md`).
- Output folder: `output_prod`; output glob: `20*/index.html` (default permalink `YYYY/MM/DD/slug`); no cache folder is written.
- Run command: `vendor/bin/sculpin generate --env=prod --quiet` (verbose: `-v`). Offline.

Run from the benchmark toolset:

```
./ssgberk --test sculpin -nf 10 -cs 0.500 -mr 1
```
