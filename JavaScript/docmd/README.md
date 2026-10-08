# docmd

docmd 0.9.7 (`@docmd/core`, latest stable on 2026-10-08) on Ubuntu 24.04 with Node 24.21.0, benchmarked by SSGBerk. `build.sh` generates the posts into `src/docs/posts` (Markdown with `title`/`date` front matter), then times `npx docmd build`; each post renders to `site/posts/<slug>/index.html` (`output_glob` `posts/*/index.html`; `index.html` and `404.html` sit outside `posts/`).

The index page is generated inside the timed `build_command`: docmd has no page-collection feature, so one shell loop (parameter expansion only, no per-post forks) writes `docs/index.md` as a list of links to every post (`posts/<slug>.md`, no pagination) before `npx docmd build`. That listing is part of the timed build.

`docmd.config.js` turns off every bundled plugin (search, seo, sitemap, analytics, llms, mermaid, git, openapi, okf, ai), the sidebar, header, breadcrumbs, page navigation, options menu and SPA mode, so a page renders only its post. `navigation: []` is accepted but docmd still auto-builds a navigation tree internally; with the sidebar disabled it is not rendered. The reference stylesheet and image are force-added under `src/docs/assets` and docmd copies them verbatim to `site/assets`.

`package.json` has `"type": "module"` so the ESM config loads without a reparse warning. Dependencies are installed with `npm ci` from the committed `package-lock.json`. docmd writes no cache, so `cache_folders` is empty. The timed build makes no network requests (verified with `docker run --network none`).

Run it with `./ssgberk --test docmd -nf 10` from the toolset repository.
