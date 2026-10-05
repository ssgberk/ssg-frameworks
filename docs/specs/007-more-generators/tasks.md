# More Generators (wave 1) — Tasks

> **For agentic workers:** each task is one generator, implemented in its own worktree (see `plan.md` "Parallel work") and verified with the local smoke in `plan.md`, under the shared-machine rules there.

**Spec:** `docs/specs/007-more-generators/spec.md`, `plan.md`. Contracts: `docs/specs/001-canonical-build-runner/plan.md`. Global Constraints: `docs/specs/003-new-generators/tasks.md` (all apply) plus the ones below.

## Global Constraints (additions)

- Pin the latest stable release on 2026-10-05; record the exact version in `README.md` and `generator.json`.
- Node 24.21.0 (as in the other Node images), `ENV NPM_CONFIG_UPDATE_NOTIFIER=false`, `ENV NODE_OPTIONS=--max-old-space-size=6144`; lockfile generated inside the generator image (`docker run --rm -v "$PWD":/w -w /w <image> npm install --package-lock-only`, or `npm install` then copy the lock out).
- Python: `python3 -m venv /opt/venv` as in the skeleton; `requirements.txt` is the full `pip freeze` taken inside the built image.
- Ship `reference/assets/ssgberk.css` and `ssgberk.png` byte-identical in the generator's static/public folder under `assets/`.
- `output_glob` matches exactly the post pages (`got == expected`).
- Commit message: `feat(<dir name>): add <generator> <version>` with the Co-Authored-By trailer.

## Standard steps (every task)

1. Copy `Go/hugo/build.sh` into the generator dir (`tools/check-build-sh.sh` passes).
2. Dockerfile from the skeleton with the task's runtime and generator blocks.
3. Manifest + lockfile (inside the image) or pinned binary.
4. `benchmark_config.json` (`content`, `config` incl. `cache_folders`), site files, assets.
5. Local smoke at `content_size=0.500` and `content_size=5`, both `SSGBERK_VERIFY_OK expected=10 got=10`.
6. `generator.json`, `README.md`.
7. `tools/check-build-sh.sh`, `tools/check-node-heap.sh`, `pytest tests/metadata` pass.
8. Commit.

---

### Task 1: Docusaurus (`JavaScript/docusaurus`, #92)

Blog-only site: `@docusaurus/preset-classic` with `docs: false`, `pages: false` (or a minimal index), `blog` with `routeBasePath: 'posts'`, `postsPerPage: 'ALL'`, `blogSidebarCount: 0`, tags/archive/feeds/authors pages disabled, `showReadingTime: false`. Content type `3minus` in `blog/` (rename to the configured path). Disable the navbar/footer chrome or swizzle a bare layout so a post page shows only its post. Watch: Docusaurus treats `YYYY-MM-DD-` filename prefixes as dates and builds `posts/YYYY/MM/DD/<slug>/`. Caches: `.docusaurus`, `node_modules/.cache`.

### Task 2: Nuxt Content (`JavaScript/nuxt-content`, #93)

Nuxt 4 with `@nuxt/content` 3, `nuxt generate` (static). One collection over `content/posts/*.md`, a `pages/posts/[...slug].vue` rendering one post, `pages/index.vue` listing all posts. `ENV NUXT_TELEMETRY_DISABLED=1`. Nuxt Content 3 uses a SQLite database at build time (native `better-sqlite3` or the Node 22+ built-in `node:sqlite`); prefer the option that needs no native build. Caches: `.nuxt`, `.output`, `.data`, `node_modules/.cache`, `node_modules/.vite`.

### Task 3: mdBook (`Rust/mdbook`, #95)

Pinned release binary for both arches (`x86_64`/`aarch64-unknown-linux-gnu` or `-musl`). `build_command` is a shell line that writes `src/SUMMARY.md` (`# Summary` + `[Index](README.md)` + one `- [<title>](posts/<file>)` line per post, titles from the front matter or the file name) and then runs `mdbook build`. Content type: the one whose front matter mdBook tolerates best (`none` keeps the body only; a `3minus` block would render as text, so prefer `none` and take titles from the file name). Remove the sidebar/TOC listing other chapters with a minimal `theme/index.hbs`; disable search (`[output.html.search] enable = false`), print page, and fonts.

### Task 4: SvelteKit (`JavaScript/sveltekit`, #96)

`@sveltejs/kit` 2 + `@sveltejs/adapter-static` + `mdsvex` (markdown → Svelte). `src/routes/posts/[slug]/+page.js` loads one post via `import.meta.glob('/src/posts/*.md')`, `+page.svelte` renders it; `src/routes/+page.svelte` lists all; `export const prerender = true`, `trailingSlash: 'always'`. Content type `3minus` in `src/posts`. Caches: `.svelte-kit`, `node_modules/.vite`.

### Task 5: Nextra (`JavaScript/nextra`, #118)

Nextra 4 on the pinned Next.js 16.3.x line already used by `nextjs-export` if compatible (else the version Nextra requires), `output: 'export'`, app router with the content directory convention. Use the blog theme or a bare custom layout so post pages render only their post and one index lists all. `ENV NEXT_TELEMETRY_DISABLED=1`. Disable search indexing (pagefind) if it is on by default. Caches: `.next`, `node_modules/.cache`.

### Task 6: Sphinx (`Python/sphinx`, #97)

Sphinx 8 + `myst-parser`, content type `3minus` (MyST reads YAML front matter) in `posts/`. `index.md` with a hidden-free `{toctree}` `:glob:` `posts/*` that lists every post; a minimal theme (`basic`-derived or `html_theme = 'basic'` with a bare `layout.html`) without sidebars, search page or genindex. `-q` build into `_build/html`; `output_glob` `posts/*.html`. Disable `html_copy_source`, `html_show_sourcelink`, search index if possible. Caches: `_build/doctrees`.

---

## Wave 2

Same Global Constraints, Standard steps, local smoke and shared-machine rules as wave 1.

### Task 7: Quartz (`JavaScript/quartz`, #119)

Quartz 4 is distributed as a repository template, not an npm package: vendor the pinned release tag's sources (the `quartz/` folder, `package.json`, lockfile, `quartz.config.ts`, `quartz.layout.ts`) into `src/`, with content in `content/posts`. Configure the layout so a post page renders only its post (no explorer, graph view, backlinks, search, table of contents, recent notes) and an index page lists all posts; disable plugins that emit extra pages (tag pages, folder pages, RSS, sitemap, alias redirects, OG images) unless required for the index. Content type `3minus`. Build command `npx quartz build`; output `public/`. Caches: `.quartz-cache` and any other folder it writes.

### Task 8: Starlight (`JavaScript/starlight`, #98)

`@astrojs/starlight` on the Astro version it requires (prefer the pinned `astro` 7.3.x line if compatible). Docs collection in `src/content/docs/posts`, content type `3minus` (Starlight needs `title` in front matter — build.sh writes it). Turn off sidebar autogeneration of posts, the table of contents, pagination links, search (Pagefind), edit links and social links, so a post page renders only its post; `src/content/docs/index.mdx` (or a custom page) lists all posts. `ENV ASTRO_TELEMETRY_DISABLED=1`. Caches like `JavaScript/astro` (`node_modules/.vite`, `.astro`, `node_modules/.astro`).

### Task 9: Quarto (`Other/quarto`, #100)

Pinned Quarto CLI release `.deb` (or tarball) for amd64 and arm64; it bundles pandoc. A website project (`_quarto.yml`, `project: type: website`) with `posts/*.md`, a listing page (`index.qmd` with `listing:` over `posts`, no pagination: `page-size` ≥ any post count or listing type `table`/`default` with all items), no navbar/sidebar/search (`website: search: false`), `format: html` with minimal theme (`theme: none` or `minimal: true`). Content type `3minus`. Build `quarto render --quiet` (no Jupyter/knitr: plain markdown). Output `_site`. Caches: `.quarto`, `_freeze`.

### Task 10: Zensical (`Python/zensical`, #120)

`pip install zensical` (pinned; full `pip freeze`). Zensical reads `mkdocs.yml`-style config (or `zensical.toml`); mirror `Python/mkdocs`: content type `none` in `docs/posts`, a minimal custom theme or theme overrides that drop navigation, search and TOC, index page listing all posts. Build `zensical build` (quiet flag if any); output `site`. Caches: whatever it writes between runs (check `.cache`).

### Task 11: DocFX (`CSharp/docfx`, #101)

.NET SDK/runtime for both arches (Microsoft install script with a pinned channel, or the `dotnet` tarball) and `dotnet tool install docfx --version <pinned>`; `ENV DOTNET_CLI_TELEMETRY_OPTOUT=1`, `DOTNET_NOLOGO=1`. A conceptual-docs project (`docfx.json`, `toc.yml`) with `posts/*.md` (content type `3minus`, DocFX reads YAML front matter), an index page listing all posts, and a template (the `default` template with overrides, or a minimal custom template) without the navbar/TOC/search/affix panel on post pages. `build_command` `docfx build docfx.json` (no metadata step, no serve). Output `_site`. Caches: `obj/` and any `.cache`.

### Task 12: Lektor (`Python/lektor`, #102)

`pip install Lektor` (pinned; full `pip freeze`). A project with `models/`, `templates/` and `content/`. Lektor needs one `contents.lr` per page, not markdown files: use content type `none` in `content/posts` and a `build_command` that converts each generated `posts/<name>.md` into `content/posts/<name>/contents.lr` (`_model: post`, `title: <name>`, `body:` = the markdown, with Lektor's `---` field separators) in one pass without per-post forks, then runs `lektor build --output-path _site`. That conversion is part of the timed build, as with mdBook. A `posts` model with `markdown` body, a post template rendering only its post, and an index listing all children (no pagination). Output `_site`. Caches: Lektor's build state (`--buildstate-path` if set, or `~/.cache/lektor`/project cache dir) in `cache_folders`.
