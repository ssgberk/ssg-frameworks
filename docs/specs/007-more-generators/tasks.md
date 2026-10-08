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

---

## Wave 3

Same Global Constraints, Standard steps, local smoke and shared-machine rules. Toolchains for Swift and Haskell are large: build the site binary in a builder stage and keep only the runtime pieces needed for the timed build, so the image stays small; never leave intermediate images behind.

### Task 13: Publish (`Swift/publish`, #99)

Swift toolchain (pinned swift.org release for Ubuntu 24.04, amd64 and arm64). A Swift package using JohnSundell/Publish (pinned tag) with a minimal custom `HTMLFactory` theme: post item page renders only its post, the section/index page lists all posts; no tag pages, RSS or sitemap steps. Posts in `Content/posts/*.md`, content type `3minus` (Publish reads YAML-ish front matter: check `date` format; Publish expects `date: yyyy-MM-dd HH:mm`, so pick `metadata_dateslug` and verify parsing). Compile the site generator executable in the image (untimed); the timed `build_command` runs the compiled binary (`.build/release/<Site>`), which is what a Publish site does on each build. Output `Output/`. Caches: none beyond output (confirm).

### Task 14: dumi (`JavaScript/dumi`, #122)

dumi 2 (pinned), docs in `docs/posts/*.md`, content type `3minus`. Disable the default theme chrome (navbar, sidebar, TOC, search, footer, demo previews) via theme config or a minimal local theme so a post page renders only its post; one index page lists all posts. `dumi build`, output `dist`. Caches: `.dumi/tmp*`, `node_modules/.cache`. `ENV DUMI_TELEMETRY_DISABLED=1` or equivalent if it exists.

### Task 15: Observable Framework (`JavaScript/observable-framework`, #123)

`@observablehq/framework` (pinned), `src/posts/*.md` (Framework markdown with YAML front matter: content type `3minus`), `observablehq.config.js` with `pager: false`, `sidebar: false`, `toc: false`, `search: false`, `footer: ""`, explicit `pages` or default. `src/index.md` lists all posts (static markdown list generated at build time is not allowed — use Framework's data loader or a JS cell that imports the file list; if that is not possible without timed pre-processing, use a single-loop pre-processing step as in mdBook). `observable build`, output `dist`. Caches: `src/.observablehq/cache`, `node_modules/.cache`. `ENV OBSERVABLE_TELEMETRY_DISABLE=true`.

### Task 16: Analog (`JavaScript/analog`, #124)

Analog (pinned `@analogjs/platform`, `@analogjs/content`, Angular per Analog's peer requirements) with markdown content routes: `src/content/posts/*.md` (`3minus`), `injectContentFiles` for the index, `injectContent` + `MarkdownComponent` for the post page, static prerender of every post route (`prerender.routes` from the content files, no SSR server). `ng build` or `vite build`, output `dist/analog/public`. Caches: `node_modules/.vite`, `.angular/cache`, `node_modules/.cache`. `NG_CLI_ANALYTICS=false`.

### Task 17: Hakyll (`Haskell/hakyll`, #103)

GHC + cabal (pinned, via ghcup or distro) in a builder stage; compile a `site` executable against pinned Hakyll (cabal freeze file). The runtime image carries the compiled `site` binary (and its shared libs) only. Rules: `posts/*.md` → pandoc → post template rendering only its post; `index.html` lists all posts (`loadAll "posts/*"`), no tags/archive/feeds. Content type `3minus`. Timed `build_command`: `./site build` (untimed compile, as a real Hakyll site compiles once). Output `_site`. Caches: `_cache` (Hakyll's store).

### Task 18: VuePress 2 (`JavaScript/vuepress`, #94)

`vuepress@2` (latest stable or the current release candidate if no 2.x stable exists — report which), with `@vuepress/bundler-vite` and a minimal local theme (no navbar/sidebar/search; layout renders only the page content); posts in `docs/posts/*.md` (`3minus`), `docs/README.md` lists all posts using the pages data (`usePages` / a client data file) without timed pre-processing if possible. `vuepress build docs`, output `docs/.vuepress/dist`. Caches: `docs/.vuepress/.cache`, `docs/.vuepress/.temp`, `node_modules/.vite`.

---

## Wave 4

Same Global Constraints, Standard steps, local smoke and shared-machine rules; the implementer rules learned in waves 1–3 apply (ignored files force-added, no per-post forks in timed steps, caches out of the output folder, `versionFrom` when needed, timed build offline under `--network none`, compile-once toolchains compiled untimed in a builder stage). Upstream repository and the entry point are in each issue.

### Task 19: Lume (`JavaScript/lume`, #104)

Upstream https://github.com/lumeland/lume, entry point `deno task build`. Deno runtime (pinned release binary); `deno task build` with a pinned Lume version in deno.json/import map; vendor or pre-cache Deno deps at image build so the timed build is offline (`DENO_DIR` cache kept, like node_modules).

### Task 20: rspress (`JavaScript/rspress`, #105)

Upstream https://github.com/web-infra-dev/rspress, entry point `rspress build`. rspress (latest stable), docs root with posts; disable search/nav/sidebar via theme config or a minimal custom theme.

### Task 21: Statiq (`CSharp/statiq`, #106)

Upstream https://github.com/statiqdev/Statiq.Web, entry point `dotnet run (Statiq.Web)`. Statiq.Web as a small .NET console app compiled in the image (untimed); the timed build runs the compiled app (`dotnet <app>.dll` or published binary).

### Task 22: Sculpin (`PHP/sculpin`, #107)

Upstream https://github.com/sculpin/sculpin, entry point `vendor/bin/sculpin generate`. PHP + Composer, `composer.lock` generated in the image; `vendor/bin/sculpin generate --env=prod`; output `output_prod`.

### Task 23: Bridgetown (`Ruby/bridgetown`, #108)

Upstream https://github.com/bridgetownrb/bridgetown, entry point `bin/bridgetown build`. Ruby + Bundler, `Gemfile.lock` generated in the image; `bin/bridgetown build` (no esbuild frontend bundling unless required — disable/skip the frontend step if Bridgetown allows).

### Task 24: JBake (`Java/jbake`, #109)

Upstream https://github.com/jbake-org/jbake, entry point `jbake -b`. JBake binary distribution (pinned zip) on a JRE; `jbake -b <src> <out>`; templates in a minimal engine (freemarker/thymeleaf).

### Task 25: Cryogen (`Clojure/cryogen`, #110)

Upstream https://github.com/cryogen-project/cryogen, entry point `lein run / clojure -M:build`. Cryogen via Clojure CLI or Leiningen; dependencies resolved in the image (offline timed build); timed command compiles the site (JVM start included, as real use).

### Task 26: Franklin (`Julia/franklin`, #111)

Upstream https://github.com/tlienart/Franklin.jl, entry point `julia -e 'using Franklin; optimize()'`. Pinned Julia release + Franklin.jl (Manifest.toml), packages precompiled in the image; timed `julia --project -e 'using Franklin; optimize(minify=false, prerender=false)'` or `serve`-free build equivalent.

### Task 27: Antora (`JavaScript/antora`, #112)

Upstream https://gitlab.com/antora/antora, entry point `antora antora-playbook.yml`. Antora reads AsciiDoc from git repositories: build.sh writes markdown, so use a content type and a timed one-loop pre-step only if unavoidable, or use Antora's asciidoc for the generated text (markdown blocks are valid AsciiDoc-ish? check); a local playbook pointing at a local git component created in the image is acceptable; document deviations.

### Task 28: Cecil (`PHP/cecil`, #113)

Upstream https://github.com/Cecilapp/Cecil, entry point `cecil build`. Cecil pinned phar or Composer package; `cecil build`; minimal theme without menus/taxonomies.

### Task 29: soupault (`OCaml/soupault`, #114)

Upstream https://github.com/PataphysicalSociety/soupault, entry point `soupault`. soupault pinned release binary (amd64/arm64) with a markdown preprocessor (cmark/pandoc pinned) as soupault requires; `soupault`.

### Task 30: TanStack Start (`JavaScript/tanstack-start`, #115)

Upstream https://github.com/TanStack/router, entry point `vite build with static prerender`. TanStack Start with static prerender of every post route and a markdown loader; deferred in wave 1 as an app framework — implement if a static prerender path exists, else `_wip` with the reason.

### Task 31: Quarkdown (`Kotlin/quarkdown`, #117)

Upstream https://github.com/iamgio/quarkdown, entry point `quarkdown c (website target)`. Quarkdown pinned release (JVM); website/docs target producing static HTML per post; deferred earlier (typesetting tool) — implement if it can emit one HTML page per post and an index, else `_wip`.

### Task 32: Vike (`JavaScript/vike`, #121)

Upstream https://github.com/vikejs/vike, entry point `vike build with prerender`. Vike with prerender (`vike build` + prerender) and a markdown pipeline; same caveat as TanStack Start.

### Task 33: docmd (`JavaScript/docmd`, #125)

Upstream https://github.com/docmd-io/docmd, entry point `docmd build`. docmd (latest stable), markdown docs; disable navigation/search via config.

### Task 34: Zine (`Zig/zine`, #126)

Upstream https://github.com/kristoff-it/zine, entry point `zine release`. Zine pinned release binary for both arches; content in SuperMD (Zine's markdown dialect with Ziggy front matter: build.sh's front matter may need a timed one-loop conversion — avoid if `3plus`/other type fits); `zine release`.

### Task 35: vite-ssg (`JavaScript/vite-ssg`, #127)

Upstream https://github.com/antfu-collective/vite-ssg, entry point `vite-ssg build (+ unplugin-vue-markdown)`. vite-ssg + Vue + unplugin-vue-markdown, routes generated from the posts directory (vite-plugin-pages or glob), `vite-ssg build`.

### Task 36: Cobalt (`Rust/cobalt`, #128)

Upstream https://github.com/cobalt-org/cobalt.rs, entry point `cobalt build`. cobalt pinned release binary; `cobalt build`; liquid templates minimal.

### Task 37: îles (`JavaScript/iles`, #129)

Upstream https://github.com/ElMassimo/iles, entry point `iles build`. îles (latest stable), pages from markdown, `iles build`.

### Task 38: Ink (`Go/ink`, #130)

Upstream https://github.com/InkProject/ink, entry point `ink build`. InkProject/ink pinned release binary (or `go install` at a tag in a builder stage); `ink build`.

### Task 39: Plenti (`Go/plenti`, #131)

Upstream https://github.com/plentico/plenti, entry point `plenti build`. Plenti pinned release binary; Svelte-based layouts; `plenti build` (it may need Node at build — include pinned Node).

### Task 40: Emanote (`Haskell/emanote`, #132)

Upstream https://github.com/srid/emanote, entry point `emanote gen`. Emanote: prefer a pinned prebuilt binary/static release or nix-free build; `emanote gen <out>`; if no feasible build within the shared-machine limits, `_wip` with the reason.

### Task 41: Marmite (`Rust/marmite`, #133)

Upstream https://github.com/rochacbruno/marmite, entry point `marmite <input> <output>`. marmite pinned release binary; `marmite <input> <output>`; disable feeds/tags/search pages via config if possible.

### Task 42: Nesta (`Ruby/nesta`, #134)

Upstream https://github.com/gma/nesta, entry point `nesta build`. Nesta (Sinatra-based CMS) static export (`nesta build`); Gemfile.lock in the image.

### Task 43: Laika (`Scala/laika`, #135)

Upstream https://github.com/typelevel/Laika, entry point `sbt laikaSite`. Laika as a library via sbt plugin or a small Scala CLI app compiled in the image (untimed); timed run of the compiled app or `sbt laikaSite` with a warm, offline dependency cache (document which and why).

### Task 44: Tableau (`Elixir/tableau`, #136)

Upstream https://github.com/elixir-tools/tableau, entry point `mix tableau.build`. Elixir/Erlang pinned, Tableau project with deps fetched and compiled in the image; timed `mix tableau.build` (offline).

### Task 45: nimib (`Nim/nimib`, #137)

Upstream https://github.com/pietroppeter/nimib, entry point `nim r (nimib publish)`. nimib is a notebook/publishing library: one nimib document per post rendered to HTML via a compiled Nim program (compile untimed); if it cannot render arbitrary markdown files per post, `_wip` with the reason.

### Task 46: Lustre SSG (`Gleam/lustre-ssg`, #138)

Upstream https://github.com/lustre-labs/ssg, entry point `gleam run -m build`. Gleam + Erlang pinned; lustre/ssg project reading the markdown posts at build time; deps fetched and compiled in the image; timed `gleam run -m build` (offline).
