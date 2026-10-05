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
