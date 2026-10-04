# Update Existing Generators — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the existing generators (gatsby, jigsaw, nikola-mako, jekyll, nanoc, middleman, metalsmith-handlebars, metalsmith-nunjucks) to current versions on the canonical `build.sh` and Ubuntu 24.04 dockerfile skeleton, and remove the five dead ones.

**Architecture:** Each generator gets the canonical `build.sh`, a skeleton dockerfile, a pinned manifest + lockfile generated inside the runtime image, and a `benchmark_config.json` with `output_folder`/`output_glob`/`cache_folders`. Contract, skeleton and smoke procedure: `docs/specs/001-canonical-build-runner/plan.md`.

**Tech Stack:** Node 24.21.0, Ruby 3.2 (apt), PHP 8.4, Python 3.12, hyperfine 1.20.0, Ubuntu 24.04.

**Spec:** `docs/specs/002-update-existing-generators/spec.md` and `docs/specs/002-update-existing-generators/plan.md` (same directory, repo `ssgberk/ssg-frameworks`). Read both before starting any task.

In this file **BT** = `/Users/jobs/Dev/ssgberk/.worktrees/benchmark-tool-modernize` (repo `ssgberk/benchmark-tool`, branch `chore/modernize-2026`) and **SF** = `BT/frameworks` (repo `ssgberk/ssg-frameworks`, branch `chore/modernize-2026`). Layout: `docs/specs/ROADMAP.md` in BT.

Prerequisite: `docs/specs/001-canonical-build-runner` Task 1 is complete (canonical `Go/hugo/build.sh`, `tools/check-build-sh.sh`), and the toolset specs in `ssgberk/benchmark-tool` (`001-python3-toolset`, `002-hyperfine-results`) are complete so the smoke procedure can run.

## Global Constraints

- Git author/committer `Matheus Breguêz <matbrgz@gmail.com>`; every commit GPG-signed (repo config already has `commit.gpgsign=true`, key `B6FA8458D5176E83`). Never use `--no-gpg-sign` or `--author`.
- Every commit message ends with the trailer `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Never commit to `master`. Never push, open PRs, or close dependabot branches unless the human explicitly asks.
- Generator base image `ubuntu:24.04`; architecture detected **inside `RUN`** with `ARCH="$(dpkg --print-architecture)"` (`amd64`|`arm64`). Never rely on `TARGETARCH` (empty under the legacy builder docker-py uses — verified on Docker 29).
- Pinned versions: hyperfine `1.20.0`, dool `v1.3.8`, docker-py `7.1.0`, Node `24.21.0`, hugo `0.167.0`, zola `0.23.6`, jekyll `4.4.1`, nanoc `4.14.8`, middleman `4.6.3`, nikola `8.3.3`, pelican `4.12.0`, mkdocs `1.6.1`, jigsaw `v1.8.8`, metalsmith `2.7.0`, gatsby `5.16.1`, astro `7.3.5`, @11ty/eleventy `3.1.6`, hexo `8.1.2`, next `16.3.8`, vitepress `1.6.4`.
- Generated post filenames are `YYYY-MM-DD-NNN.<ext>` (NNN zero-padded by `seq -w`). `build.sh` only ever deletes entries in the content folder matching `[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*`, so section index files (e.g. `_index.md`, `posts.json`) survive.
- Every generator's `build.sh` is byte-identical to `SF/Go/hugo/build.sh`.
- A generator's directory name equals its `benchmark_config.json` `framework` value and its test name (CI derives the test name from the directory basename).
- No themes, plugins, minification or speed tweaks in generator sites: base layout + post template + index listing posts.

## Standard steps

Standard steps for every task in this file (each its own checkbox when tracking):

- [ ] Copy `Go/hugo/build.sh` into the generator dir; confirm `tools/check-build-sh.sh` no longer lists it.
- [ ] Write the dockerfile from the skeleton (`docs/specs/001-canonical-build-runner/plan.md`) with the task's RUNTIME/GENERATOR blocks.
- [ ] Write/refresh manifest; generate the lockfile inside the runtime image.
- [ ] Write `benchmark_config.json` with the task's exact `content`/`config`, and the site files.
- [ ] Run the Generator smoke procedure (`docs/specs/001-canonical-build-runner/plan.md`); iterate on template errors shown in `raw.txt` until it passes with `got == expected`.
- [ ] Update the generator `README.md` (version, content folder, output glob, run command).
- [ ] Commit in SF.

Details for every task in this file: copy `Go/hugo/build.sh` into the generator dir; start `src/` from the monorepo copy (`/Users/jobs/Dev/ssgberk/StaticSiteGeneratorBenchmark/frameworks/<Lang>/<name>/src`) when it exists there; rewrite the dockerfile from the skeleton; update the manifest + regenerate the lockfile **inside the generator image** (so the lock matches Linux) with `docker run --rm -v "$PWD":/w -w /w <image-with-runtime> <npm install|bundle lock|composer update>`; set `benchmark_config.json` `content`/`config` exactly as given; remove the old `src` sample posts (`build.sh` also removes them at runtime, but don't ship them); run the smoke procedure; commit. Fix template incompatibilities the new major version reports in the verification build log (`/tmp/ssgberk-verify.log` is printed on failure).

---

### Task 1: gatsby 5.16.1 (`JavaScript/gatsby`)

- `git rm -r --cached JavaScript/gatsby/node_modules && rm -rf JavaScript/gatsby/node_modules`.
- `package.json` dependencies: `"gatsby": "5.16.1"`, `"gatsby-source-filesystem": "^5"`, `"gatsby-transformer-remark": "^6"`, `"react": "^18.3.1"`, `"react-dom": "^18.3.1"`; remove eslint/typescript/gatsby-link/gatsby-plugin-catch-links. Scripts: `"build": "gatsby build"`, `"build-verbose": "gatsby build --verbose"`.
- `gatsby-config.js`: drop `pathPrefix` and `gatsby-plugin-catch-links`; point `gatsby-source-filesystem` at `${__dirname}/src/pages/posts`.
- `gatsby-node.js`: `createPages` querying `allMarkdownRemark { nodes { id fields { slug } } }` and creating `/posts/<slug>/` from `src/templates/post.js`; `onCreateNode` adds `slug` = file base name. Update `src/templates/post.js` to a function component with a `query` export by `id`.
- Dockerfile: Node RUNTIME; GENERATOR: `COPY package.json package-lock.json /opt/gatsby/src/` + `RUN npm ci` + `ENV GATSBY_TELEMETRY_DISABLED=1`.
- Config: content `{"folder":"src/pages/posts","type":"3minus","extension":"md"}` — move the content folder out of `src/pages` if gatsby tries to render `.md` as pages; use `content/posts` then and update the filesystem source path. `config`: `build_command: "npm run --silent build"`, `build_verbose: "npm run build-verbose"`, `output_folder: "public"`, `output_glob: "posts/*/index.html"`, `cache_folders: [".cache"]`.

### Task 2: jigsaw v1.8.8 (`PHP/jigsaw`)

- RUNTIME: PHP only (drop the Node/yarn install and any mix/webpack assets from `src`):
  ```dockerfile
  RUN apt-get -yqq update && apt-get -yqq install --no-install-recommends software-properties-common gpg-agent \
   && add-apt-repository -y ppa:ondrej/php && apt-get -yqq update \
   && apt-get -yqq install --no-install-recommends php8.4-cli php8.4-mbstring php8.4-xml php8.4-curl php8.4-zip unzip \
   && rm -rf /var/lib/apt/lists/* \
   && curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  ```
- `composer.json` at the generator root: `{"require": {"tightenco/jigsaw": "1.8.8"}}`; GENERATOR: `COPY composer.json composer.lock /opt/jigsaw/src/` + `RUN composer install --no-interaction --no-progress`. Build command `vendor/bin/jigsaw build` (not a global `jigsaw`).
- `config.php`: collection `posts` with `'path' => 'posts/{filename}'`; remove `baseUrl` subpath.
- Config: content `{"folder":"source/_posts","type":"3minus","extension":"md"}`, `metadata_layout: "extends: _layouts.post"`, `build_command: "vendor/bin/jigsaw build --quiet"`, `build_verbose: "vendor/bin/jigsaw build -v"`, `output_folder: "build_local"`, `output_glob: "posts/*/index.html"`, `cache_folders: ["cache"]`.

### Task 3: nikola 8.3.3 (`Python/nikola-mako`)

- Python RUNTIME; `requirements.txt`: `Nikola[extras]==8.3.3`; GENERATOR: `COPY requirements.txt /opt/nikola/src/` + `RUN pip install --no-cache-dir -r requirements.txt` (move `requirements.txt` to the generator root and adjust the COPY path accordingly; skeleton's `COPY src/` stays).
- Remove `opentimestamps-client yuicompressor` (not needed).
- `conf.py`: `POSTS = (("posts/*.md", "posts", "post.tmpl"),)`, `PAGES = ()`, `COMPILERS["markdown"] = ('.md',)`, `OUTPUT_FOLDER = "output"`, `PRETTY_URLS = True`, disable RSS/sitemap/archives/tags if they add pages (they don't affect the post glob, but keep the build lean: `GENERATE_RSS = False`).
- Config: content `{"folder":"posts","type":"2dot","extension":"md"}`, `build_command: "nikola build -q"`, `build_verbose: "nikola build -v 2"`, `output_folder: "output"`, `output_glob: "posts/*/index.html"`, `cache_folders: ["cache", ".doit.db", ".doit.db.dat", ".doit.db.dir", ".doit.db.bak"]` (nikola's doit state would make runs incremental).

### Task 4: jekyll 4.4.1 (`Ruby/jekyll`)

- Ruby RUNTIME; `Gemfile` (generator root): `source "https://rubygems.org"` + `gem "jekyll", "4.4.1"`; `bundle lock` inside the image → `Gemfile.lock`; GENERATOR: `COPY Gemfile Gemfile.lock /opt/jekyll/src/` + `RUN bundle install`.
- `_config.yml`: `path: ''`, `url: ''`, `permalink: /posts/:title/`, `exclude: [build.sh, benchmark_config.json, Gemfile, Gemfile.lock, README.md]`.
- Config: content `{"folder":"_posts","type":"3minus","extension":"md"}`, `metadata_layout: "layout: post"`, `build_command: "bundle exec jekyll build --quiet"` (**no `--incremental`**), `build_verbose: "bundle exec jekyll build --verbose"`, `output_folder: "_site"`, `output_glob: "posts/*/index.html"`, `cache_folders: [".jekyll-cache", ".jekyll-metadata"]`.

### Task 5: nanoc 4.14.8 (`Ruby/nanoc`)

- `Gemfile`: `gem "nanoc", "4.14.8"`, `gem "kramdown"`, `gem "erubi"`; `bundle lock` in image.
- Remove the `Gemfile` inside `src/` (monorepo has one there too) so there's a single Gemfile at `/opt/nanoc/src`.
- `Rules`: compile `/posts/*.md` with `filter :kramdown` + `layout '/post.*'`, route to `/posts/<basename>/index.html`; compile `/index.*` similarly; ignore other data.
- Config: content `{"folder":"content/posts","type":"3minus","extension":"md"}`, `metadata_dateslug: "created_at"`, `metadata_layout: "kind: article"`, `build_command: "bundle exec nanoc compile"`, `build_verbose: "bundle exec nanoc compile --verbose"`, `output_folder: "output"`, `output_glob: "posts/*/index.html"`, `cache_folders: ["tmp"]` (nanoc's checksum store would make runs incremental).

### Task 6: middleman 4.6.3 (`Ruby/middleman`, from WIP)

- Start from `SF/Ruby/middleman` (it's WIP in the monorepo but already in SF at `Ruby/middleman`).
- `Gemfile`: `gem "middleman", "4.6.3"`, `gem "middleman-blog", "~> 4.0"`, `gem "webrick"`, `gem "tzinfo-data"`; drop `execjs`.
- `config.rb`: `activate :blog do |blog| blog.sources = "posts/{year}-{month}-{day}-{title}.html"; blog.permalink = "posts/{title}/index.html"; blog.layout = "post"; end`.
- Config: content `{"folder":"source/posts","type":"3minus","extension":"md"}`, `metadata_layout: ""`, `build_command: "bundle exec middleman build"`, `build_verbose: "bundle exec middleman build --verbose"`, `output_folder: "build"`, `output_glob: "posts/*/index.html"`, `cache_folders: [".sass-cache"]`.
- If native extensions fail on Ruby 3.2 after a genuine attempt, apply the `_wip/` fallback from the Generator smoke procedure (`docs/specs/001-canonical-build-runner/plan.md`).

### Task 7: metalsmith 2.7.0 handlebars + nunjucks; remove dead generators; build.sh check passes

**Files (SF):** `JavaScript/metalsmith-handlebars/*`, `JavaScript/metalsmith-nunjucks/*`; delete `JavaScript/harp-ejs`, `JavaScript/harp-jade`, `JavaScript/phenomic-react`, `JavaScript/cuttlebelle`, `Ruby/webgen`.

- [ ] **Step 1: Metalsmith (both variants; only the engine differs)**

`package.json` (handlebars; nunjucks swaps the last dep for `"jstransformer-nunjucks": "^1.2.0"`):

```json
{
  "name": "metalsmith-handlebars-sample",
  "private": true,
  "type": "module",
  "scripts": { "build": "node index.js" },
  "dependencies": {
    "metalsmith": "2.7.0",
    "@metalsmith/markdown": "^1.10.0",
    "@metalsmith/layouts": "^3.0.0",
    "@metalsmith/permalinks": "^3.2.0",
    "jstransformer-handlebars": "^1.2.0"
  }
}
```

`src/index.js`:

```js
import Metalsmith from 'metalsmith'
import markdown from '@metalsmith/markdown'
import permalinks from '@metalsmith/permalinks'
import layouts from '@metalsmith/layouts'
import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

Metalsmith(dirname(fileURLToPath(import.meta.url)))
  .source('./content')
  .destination('./build')
  .clean(true)
  .use(markdown())
  .use(permalinks({ pattern: ':title' }))
  .use(layouts({ directory: 'layouts', default: 'post.hbs' }))  // nunjucks: 'post.njk'
  .build((err) => { if (err) { console.error(err); process.exit(1) } })
```

Layout `src/layouts/post.hbs`: `<!doctype html><html><head><title>{{title}}</title></head><body><h1>{{title}}</h1>{{{contents}}}</body></html>` (nunjucks `post.njk`: same with `{{ title }}` and `{{ contents | safe }}`). Content dir `src/content/posts/` with a `.gitkeep`. Permalink `:title` gives `build/posts/<title>/index.html` because the source path is `posts/…` — if `@metalsmith/permalinks` v3 flattens, use `pattern: 'posts/:title'`.

Drop `Makefile`, `lighttpd.conf`, old deps. Node RUNTIME; `package.json`/`package-lock.json` live at the generator root; GENERATOR: `COPY package.json package-lock.json /opt/<name>/src/` + `RUN npm ci`.

Config: content `{"folder":"content/posts","type":"3minus","extension":"md"}`, `metadata_layout: ""`, `build_command: "node index.js"`, `output_folder: "build"`, `output_glob: "posts/*/index.html"`.

Smoke both (`metalsmith-handlebars`, `metalsmith-nunjucks`), commit each.

- [ ] **Step 2: Remove dead generators**

```bash
git rm -r -q JavaScript/harp-ejs JavaScript/harp-jade JavaScript/phenomic-react JavaScript/cuttlebelle Ruby/webgen
git commit -m "chore: remove unmaintained generators (harp, phenomic, cuttlebelle, webgen)" -m "Harp was rewritten and abandoned, Phenomic is archived, Cuttlebelle has been inactive since 2023, webgen has no meaningful usage." -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 3: Verify** — `tools/check-build-sh.sh` exits 0 (every remaining `*/*/build.sh` equals the canonical one; copy it where missing).
