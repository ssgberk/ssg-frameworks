# Quarkdown

Quarkdown 2.6.3 (release zip, JVM) on Ubuntu 24.04, benchmarked by SSGBerk. `build.sh` generates the posts into `posts/` (content type `none`: body only), then times a single `quarkdown c index.qd -o output --timeout 0` process. `index.qd` lists `posts/` with `.listfiles` and links each post with `.subdocument`; Quarkdown compiles every referenced post as a subdocument of the same project, writing `output/SSGBerk/<date>-<NNN>/index.html` per post plus `output/SSGBerk/index.html`. Output glob: `*/20*/index.html`. Run it with `./ssgberk --test quarkdown -nf 10` from the toolset repository.

Deviations:
- The Linux release zip only exists for x64 and bundles an x64 JRE. The jars are platform independent, so the image deletes the bundled runtime and uses Ubuntu's `openjdk-17-jre-headless` (same major as the bundled JRE 17) on amd64 and arm64.
- The `plain` document type is used (no paged or docs chrome). Quarkdown still emits its per-page heading outline in a `<template>` sidebar (own headings only) and theme assets under `output/SSGBerk/{theme,lib,script}`.
- Posts have no front matter, so every page has the document title `SSGBerk`.
- The `/assets/ssgberk.png` reference is not resolved by the media storage (a warning is printed); the file is copied unchanged from `public/assets/`, so the URL works on the served site.

Caches: none outside `output/` (verified). Output: `output/`.
