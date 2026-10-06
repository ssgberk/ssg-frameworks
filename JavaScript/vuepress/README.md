# VuePress

VuePress 2.0.0-rc.31 (`vuepress` with `@vuepress/bundler-vite`; Vue 3.5.43) on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. No stable 2.x release exists on 2026-10-05 (npm `latest` is 1.9.10), so the latest release candidate is pinned. `build.sh` generates the posts into `docs/posts` (Markdown with `title`/`date` front matter), then times `npx vuepress build docs`; each post must render to `docs/.vuepress/dist/posts/*.html` (the verification step checks the count equals the requested number of files; `404.html` and `index.html` sit outside `posts/`). The site uses a minimal local theme (`docs/.vuepress/theme`, one layout that renders the post title and content, with no navbar, sidebar or search) and one index page (`docs/README.md`) that lists every post: the theme's `onPrepared` hook writes the post list to a temp module (`@temp/posts.js`) that the layout imports. Dependencies are installed with `npm ci` from the committed `package-lock.json`. `cache_folders` clears `docs/.vuepress/.cache`, `docs/.vuepress/.temp` and `node_modules/.vite` between timed runs. Run it with `./ssgberk --test vuepress -nf 10` from the toolset repository.

Timed command uses the realistic invocation (`npx vuepress …`), which includes ~0.1-0.4 s wrapper startup.

The timed build includes the Vite client and SSR bundling passes, which is inherent to the generator and allowed.
