# VitePress

VitePress 1.6.4 on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. `build.sh` generates the posts into `src/posts` (Markdown with `title`/`date` front matter), then times `npx vitepress build .`; each post must render to `.vitepress/dist/posts/*.html` (the verification step checks the count equals the requested number of files; `404.html` and `index.html` sit outside `posts/` and do not match the glob). The site uses a minimal custom theme (`.vitepress/theme`, a bare layout that renders the post title and content, with no nav, sidebar or search) and one index page (`index.md`) listing every post through a build-time `createContentLoader('posts/*.md')` data file (`posts.data.js`). Dependencies are installed with `npm ci` from the committed `package-lock.json`. `cache_folders` clears `.vitepress/cache` and `node_modules/.vite` between timed runs; a production build does not create either in 1.6.4 (only `.vitepress/dist` is created), so they are defensive. Run it with `./ssgberk --test vitepress -nf 10` from the toolset repository.

Timed command uses the realistic invocation (`npx vitepress …`), which includes ~0.1–0.4 s wrapper startup.

The timed build includes the Vite client and SSR bundling pass (VitePress emits per-page `.js`/`.lean.js` chunks under `assets/`); this is inherent to the generator and allowed.
