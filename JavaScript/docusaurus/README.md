# Docusaurus

Docusaurus 3.10.2 (`@docusaurus/preset-classic`, React 19.3.0) on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. `build.sh` generates the posts into `src/blog` (Markdown with `title`/`date` front matter, `3minus`), then times `npx docusaurus build`. Each post renders to `build/posts/YYYY/MM/DD/<slug>/index.html` (the front matter `date` wins over the filename date); `output_glob` is `posts/????/??/??/*/index.html`, so tag pages and the index do not match.

Site: docs plugin disabled, blog with `routeBasePath: 'posts'`, `postsPerPage: 'ALL'`, `blogSidebarCount: 0`, feeds and archive disabled, no reading time, sitemap off. `src/src/theme/Layout` is a bare layout (theme providers, no navbar/footer); `BlogPostPaginator` is overridden to render nothing so a post page shows only its post. `processBlogPosts` clears every post's tags before the plugin builds its tag map, so no `/posts/tags/*` pages exist, and `blogListComponent` is an empty component so the built-in `/posts/` list renders nothing. A local plugin (`postListPlugin` in `docusaurus.config.js`) passes all post titles/permalinks to `src/src/pages/index.js`, the single index page.

Reference assets are in `src/static/assets/` (served at `/assets/ssgberk.png`). Dependencies are pinned in `package.json`; `package-lock.json` was generated inside the image. `cache_folders`: `.docusaurus`, `node_modules/.cache`. Run: `./ssgberk --test docusaurus -nf 10`.

Deviations: `/posts/index.html` is still emitted (empty). `onBrokenLinks` is `warn`. Docusaurus telemetry is off by default in builds (no env needed).
