# Quartz

Quartz 5.0.0 (tag `v5.0.0`, 2026-03-14) on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. Quartz is distributed as a repository template rather than an npm package, so the tag's sources are vendored into `src/` (the `quartz/` folder, `quartz.ts`, `package.json`, `package-lock.json`, `quartz.lock.json`, `tsconfig.json`). GitHub's "latest release" marker still points at v4.0.8 (2023); v5.0.0 is the newest tag and the default branch (`v5`), so it is the version pinned here.

`build.sh` generates the posts into `content/posts` (Markdown with `title`/`date` front matter, content type `3minus`), then times `npx quartz build`; each post must render to `public/posts/<name>.html`. `output_glob` is `posts/[0-9]*.html`, which matches the dated post pages only and not the folder listing `posts/index.html`.

Setup:
- Quartz 5 loads its features as git plugins. The image runs `npx quartz plugin install` at build time, pinned to the commits in `src/quartz.lock.json` (trimmed to the plugins used), so the timed build needs no network.
- `src/quartz.config.yaml` enables only: `note-properties` (front matter parser, mandatory; its properties panel is hidden), `created-modified-date` (front matter dates only), `github-flavored-markdown`, `crawl-links`, `remove-draft`, `content-page`, `folder-page` and `article-title`. Explorer, graph, search, backlinks, table of contents, recent notes, tag pages, RSS, sitemap, alias redirects, content index and OG images are not installed. A post page renders only its title and body; `posts/index.html` (the folder page) lists every post, and `content/index.md` links to it.
- Two small patches to the vendored sources: `quartz/components/Head.tsx` no longer imports the (uninstalled) og-image plugin, and `quartz/plugins/loader/config-loader.ts` falls back to an empty footer when the footer plugin is absent.
- `cache_folders` clears `.quartz-cache` and `quartz/.quartz-cache` (where the build writes its transpiled bundle) between timed runs.
- Reference assets live in `content/assets/` and are copied to `public/assets/` by Quartz.

The timed command is the realistic invocation (`npx quartz build`), including the esbuild transpile step Quartz runs on every build. Run it with `./ssgberk --test quartz -nf 10` from the toolset repository.
