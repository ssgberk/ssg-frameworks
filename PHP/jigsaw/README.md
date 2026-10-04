# Jigsaw

> Static sites for Laravel developers. -- jigsaw.tighten.co

- Version: `tightenco/jigsaw` 1.8.8, installed with Composer (see `composer.json` / `composer.lock`).
- Runtime: PHP 8.4 (ondrej PPA) on `ubuntu:24.04`; Jigsaw 1.8.8 supports PHP 8.4. No Node or mix assets.
- Site: base layout + post layout + index listing posts (`src/source`); `posts` collection with `path => posts/{filename}`.
- Content folder: `source/_posts` (`3minus` front matter, `.md`).
- Output folder: `build_local`; output glob: `posts/*/index.html`; cache folder: `cache`.
- Run command: `vendor/bin/jigsaw build --quiet` (verbose: `vendor/bin/jigsaw build -v`).

Run from the benchmark toolset:

```
./ssgberk --test jigsaw -nf 10 -cs 0.500 -mr 1
```
