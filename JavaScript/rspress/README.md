# Rspress

Rspress 2.0.23 (`@rspress/core`, latest stable on 2026-10-05; the unscoped `rspress` npm package is still 1.x) on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. `build.sh` generates the posts into `src/docs/posts` (Markdown with `title`/`date` front matter), then times `npx rspress build`; each post renders to `doc_build/posts/<name>.html` (`output_glob` `posts/*.html`; the verification step checks the count equals the requested number of files; `index.html` and `404.html` sit outside `posts/`).

The site replaces the default theme `Layout` with a bare one (`theme/index.tsx`: no nav, sidebar, outline, search or footer, so a post page renders only its title and content). `docs/index.md` is a `pageType: custom` page rendered by the same layout as a list of all posts, built from Rspress's `usePages()` route metadata (links carry the `.html` suffix, since the default build writes `posts/<name>.html`). Search and `llms` output are disabled in `rspress.config.ts`.

Dependencies are installed with `npm ci` from the committed `package-lock.json`. `cache_folders` clears `node_modules/.cache` and `node_modules/.rspress` between timed runs (defensive; see the cold-build notes below). The timed build makes no network requests. Reference assets are force-added under `src/docs/public/assets`. Run it with `./ssgberk --test rspress -nf 10` from the toolset repository.

Timed command uses the realistic invocation (`npx rspress build`). A build runs the Rspack client and SSR bundling passes plus MDX compilation, which dominates the time even for small sites.
