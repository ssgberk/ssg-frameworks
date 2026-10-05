# New Generators — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add eight new generators (zola, astro, eleventy, hexo, nextjs-export, vitepress, pelican, mkdocs), one commit each, each passing the smoke procedure with `got == expected`.

**Architecture:** Each new site has only a base layout, a post template and an index listing posts; dockerfile from the skeleton in `docs/specs/001-canonical-build-runner/plan.md`, canonical `build.sh`, lockfile generated in the runtime image.

**Tech Stack:** Node 24.21.0, Python 3.12, Rust binaries (zola 0.23.6), hyperfine 1.20.0, Ubuntu 24.04.

**Spec:** `docs/specs/003-new-generators/spec.md` and `docs/specs/003-new-generators/plan.md` (same directory, repo `ssgberk/ssg-frameworks`). Read both before starting any task.

In this file **BT** = `/Users/jobs/Dev/ssgberk/.worktrees/benchmark-tool-modernize` (repo `ssgberk/benchmark-tool`, branch `chore/modernize-2026`) and **SF** = `BT/frameworks` (repo `ssgberk/ssg-frameworks`, branch `chore/modernize-2026`). Layout: `docs/specs/ROADMAP.md` in BT.

Prerequisite: `docs/specs/001-canonical-build-runner` Task 1 is complete, and the toolset specs in `ssgberk/benchmark-tool` (`001-python3-toolset`, `002-hyperfine-results`) are complete so the smoke procedure can run.

## Global Constraints

- Git author/committer `Matheus Breguêz <matbrgz@gmail.com>`; every commit GPG-signed (repo config already has `commit.gpgsign=true`, key `B6FA8458D5176E83`). Never use `--no-gpg-sign` or `--author`.
- Every commit message ends with the trailer `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Never commit to `master`. Never push, open PRs, or close dependabot branches unless the human explicitly asks.
- Generator base image `ubuntu:24.04`; architecture detected **inside `RUN`** with `ARCH="$(dpkg --print-architecture)"` (`amd64`|`arm64`). Never rely on `TARGETARCH` (empty under the legacy builder docker-py uses — verified on Docker 29).
- Pinned versions: hyperfine `1.20.0`, dool `v1.3.8`, docker-py `7.1.0`, Node `24.21.0`, hugo `0.167.0`, zola `0.23.6`, jekyll `4.4.1`, nanoc `4.14.8`, middleman `4.6.3`, nikola `8.3.3`, pelican `4.12.0`, mkdocs `1.6.1`, jigsaw `v1.8.8`, metalsmith `2.7.0`, gatsby `5.16.1`, astro `7.3.5`, @11ty/eleventy `3.1.6`, hexo `8.1.2`, next `16.3.8`, vitepress `1.6.4`.
- Generated post filenames are `YYYY-MM-DD-NNN.<ext>` (NNN zero-padded by `seq -w`). `build.sh` only ever deletes entries in the content folder matching `[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*`, so section index files (e.g. `_index.md`, `posts.json`) survive.
- Every generator's `build.sh` is byte-identical to `SF/Go/hugo/build.sh`.
- A generator's directory name equals its `benchmark_config.json` `framework` value and its test name (CI derives the test name from the directory basename).
- No themes, plugins beyond the baseline set, minification or speed tweaks; every site builds the Core reference site of docs/specs/005-reference-site-design (supersedes the former minimal-site rule).

## Standard steps

Standard steps for every task in this file (each its own checkbox when tracking):

- [ ] Copy `Go/hugo/build.sh` into the generator dir; confirm `tools/check-build-sh.sh` no longer lists it.
- [ ] Write the dockerfile from the skeleton (`docs/specs/001-canonical-build-runner/plan.md`) with the task's RUNTIME/GENERATOR blocks.
- [ ] Write/refresh manifest; generate the lockfile inside the runtime image.
- [ ] Write `benchmark_config.json` with the task's exact `content`/`config`, and the site files.
- [ ] Run the Generator smoke procedure (`docs/specs/001-canonical-build-runner/plan.md`); iterate on template errors shown in `raw.txt` until it passes with `got == expected`.
- [ ] Update the generator `README.md` (version, content folder, output glob, run command).
- [ ] Commit in SF.

Details (same as in `docs/specs/002-update-existing-generators/tasks.md`): copy `Go/hugo/build.sh` into the generator dir; start `src/` from the monorepo copy (`/Users/jobs/Dev/ssgberk/StaticSiteGeneratorBenchmark/frameworks/<Lang>/<name>/src`) when it exists there; rewrite the dockerfile from the skeleton; update the manifest + regenerate the lockfile **inside the generator image** (so the lock matches Linux) with `docker run --rm -v "$PWD":/w -w /w <image-with-runtime> <npm install|bundle lock|composer update>`; set `benchmark_config.json` `content`/`config` exactly as given; remove the old `src` sample posts (`build.sh` also removes them at runtime, but don't ship them); run the smoke procedure; commit. Fix template incompatibilities the new major version reports in the verification build log (`/tmp/ssgberk-verify.log` is printed on failure).

Same procedure as `docs/specs/002-update-existing-generators/tasks.md` (Standard steps above, Details below): skeleton dockerfile, `build.sh` copied from `Go/hugo/build.sh`, manifest + lockfile generated inside the runtime image, smoke procedure, one commit per generator (`feat(<name>): add <name> <version>`). Every site: base layout, post template, index listing posts. Each section below gives the exact files.

---

### Task 1: zola 0.23.6 (`Rust/zola`)

Dockerfile: no RUNTIME; GENERATOR:

```dockerfile
ARG ZOLA_VERSION=0.23.6
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) ZARCH=x86_64 ;; arm64) ZARCH=aarch64 ;; esac \
 && curl -fsSL "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-${ZARCH}-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /usr/local/bin && zola --version
```

`src/config.toml`:

```toml
base_url = "/"
title = "SSGBerk Zola"
compile_sass = false
build_search_index = false
generate_feeds = false
```

`src/content/posts/_index.md`:

```
+++
title = "Posts"
sort_by = "date"
+++
```

`src/templates/base.html`: `<!doctype html><html><head><title>{% block title %}{{ config.title }}{% endblock %}</title></head><body>{% block content %}{% endblock %}</body></html>`
`src/templates/index.html`: extends base; lists `{% set s = get_section(path="posts/_index.md") %}{% for p in s.pages %}<a href="{{ p.permalink }}">{{ p.title }}</a>{% endfor %}`.
`src/templates/section.html`: extends base; same loop over `section.pages`.
`src/templates/page.html`: extends base; `<h1>{{ page.title }}</h1>{{ page.content | safe }}`.

Config: content `{"folder":"content/posts","type":"3plus","extension":"md"}`, `build_command: "zola build"`, `output_folder: "public"`, `output_glob: "posts/*/index.html"`, `versus: "rust"`, `language: "Rust"`.

Note: zola strips a leading `YYYY-MM-DD-` from filenames for the slug (`2026-10-04-001.md` → `posts/001/`) — glob still matches.

### Task 2: astro 7.3.5 (`JavaScript/astro`)

`package.json`: `{"name":"astro-sample","private":true,"type":"module","scripts":{"build":"astro build"},"dependencies":{"astro":"7.3.5"}}` + `ENV ASTRO_TELEMETRY_DISABLED=1`.
`src/astro.config.mjs`: `import { defineConfig } from 'astro/config'; export default defineConfig({ trailingSlash: 'always', build: { format: 'directory' } });`
`src/src/content.config.ts` — content collection with the glob loader (check `node_modules/astro` types for the v7 import path of `z`; in v5 it was `astro:content`, later versions export it from `astro/zod`):

```ts
import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const posts = defineCollection({
  loader: glob({ pattern: '*.md', base: './src/content/posts' }),
  schema: z.object({ title: z.string(), date: z.coerce.date() }),
});

export const collections = { posts };
```

`src/src/pages/index.astro`: `getCollection('posts')` → list links `/posts/${p.id}/`.
`src/src/pages/posts/[id].astro`: `getStaticPaths` from `getCollection('posts')`; `const { Content } = await render(post)`; render `<h1>{post.data.title}</h1><Content />`.
Config: content `{"folder":"src/content/posts","type":"3minus","extension":"md"}`, `build_command: "npx astro build --silent"`, `build_verbose: "npx astro build --verbose"`, `output_folder: "dist"`, `output_glob: "posts/*/index.html"`, `cache_folders: [".astro", "node_modules/.astro"]`.

### Task 3: eleventy 3.1.6 (`JavaScript/eleventy`)

`package.json`: `{"name":"eleventy-sample","private":true,"type":"module","dependencies":{"@11ty/eleventy":"3.1.6"}}`.
`src/eleventy.config.js`:

```js
export default function (eleventyConfig) {
  eleventyConfig.ignores.add('README.md');
  return { dir: { input: '.', includes: '_includes', output: '_site' } };
}
```

`src/posts/posts.json`: `{"layout":"post.njk","tags":"posts","permalink":"/posts/{{ page.fileSlug }}/"}`
`src/_includes/post.njk`: `<!doctype html><html><head><title>{{ title }}</title></head><body><h1>{{ title }}</h1>{{ content | safe }}</body></html>`
`src/index.njk`: `---\npermalink: /\n---\n<ul>{% for p in collections.posts %}<li><a href="{{ p.url }}">{{ p.data.title }}</a></li>{% endfor %}</ul>`
Config: content `{"folder":"posts","type":"3minus","extension":"md"}`, `build_command: "npx @11ty/eleventy --quiet"`, `build_verbose: "DEBUG=Eleventy* npx @11ty/eleventy"`, `output_folder: "_site"`, `output_glob: "posts/*/index.html"`, `cache_folders: [".cache"]`.

Note: Eleventy also strips a leading date from `fileSlug` (`2026-10-04-001` → `001`); glob still matches.

### Task 4: hexo 8.1.2 (`JavaScript/hexo`)

`package.json`: `{"name":"hexo-sample","private":true,"hexo":{"version":"8.1.2"},"dependencies":{"hexo":"8.1.2","hexo-renderer-marked":"^7.0.0","hexo-renderer-ejs":"^2.0.0","hexo-generator-index":"^4.0.0"}}`.
`src/_config.yml`:

```yaml
title: SSGBerk Hexo
url: http://localhost
permalink: posts/:title/
source_dir: source
public_dir: public
theme: minimal
new_post_name: :title.md
```

Theme `src/themes/minimal/layout/layout.ejs`: `<!doctype html><html><head><title><%= page.title || config.title %></title></head><body><%- body %></body></html>`; `post.ejs`: `<h1><%= page.title %></h1><%- page.content %>`; `index.ejs`: `<% page.posts.each(function(p){ %><a href="<%- url_for(p.path) %>"><%= p.title %></a><% }) %>`.
Config: content `{"folder":"source/_posts","type":"3minus","extension":"md"}`, `build_command: "npx hexo generate --silent"`, `build_verbose: "npx hexo generate --debug"`, `output_folder: "public"`, `output_glob: "posts/*/index.html"`, `cache_folders: ["db.json"]` (hexo's db.json makes runs incremental).

### Task 5: next.js 16.3.8 static export (`JavaScript/nextjs-export`)

`package.json`: `{"name":"nextjs-export-sample","private":true,"scripts":{"build":"next build"},"dependencies":{"next":"16.3.8","react":"^19.2.0","react-dom":"^19.2.0","gray-matter":"^4.0.3","marked":"^16.0.0"}}` + `ENV NEXT_TELEMETRY_DISABLED=1`.
`src/next.config.mjs`: `export default { output: 'export', trailingSlash: true, images: { unoptimized: true } };`
`src/lib/posts.js`:

```js
import fs from 'node:fs';
import path from 'node:path';
import matter from 'gray-matter';
import { marked } from 'marked';

const dir = path.join(process.cwd(), 'content/posts');

export function slugs() {
  return fs.readdirSync(dir).filter((f) => f.endsWith('.md')).map((f) => f.slice(0, -3));
}

export function post(slug) {
  const { data, content } = matter(fs.readFileSync(path.join(dir, `${slug}.md`), 'utf8'));
  return { title: data.title, html: marked.parse(content) };
}
```

`src/app/layout.js`: `export default function RootLayout({ children }) { return <html lang="en"><body>{children}</body></html>; }`
`src/app/page.js`: imports `slugs`, renders `<ul>` of `<a href={`/posts/${s}/`}>`.
`src/app/posts/[slug]/page.js`:

```js
import { slugs, post } from '../../../lib/posts';

export const dynamicParams = false;
export function generateStaticParams() { return slugs().map((slug) => ({ slug })); }

export default async function Post({ params }) {
  const { slug } = await params;
  const p = post(slug);
  return (<article><h1>{p.title}</h1><div dangerouslySetInnerHTML={{ __html: p.html }} /></article>);
}
```

`content/posts/.gitkeep`. If `generateStaticParams` returning `[]` breaks the build when the folder is empty, that's fine — build.sh always generates posts first.
Config: content `{"folder":"content/posts","type":"3minus","extension":"md"}`, `build_command: "npx next build"`, `output_folder: "out"`, `output_glob: "posts/*/index.html"`, `cache_folders: [".next"]`, `display_name: "next.js (export)"`.

### Task 6: vitepress 1.6.4 (`JavaScript/vitepress`)

`package.json`: `{"name":"vitepress-sample","private":true,"type":"module","dependencies":{"vitepress":"1.6.4"}}`.
`src/.vitepress/config.mjs`: `export default { title: 'SSGBerk VitePress', srcExclude: ['README.md'] };`
`src/index.md`: `# Posts` + a `<script setup>` using `createContentLoader` is optional — keep it static: `# SSGBerk VitePress`.
`src/posts/.gitkeep`.
Config: content `{"folder":"posts","type":"3minus","extension":"md"}`, `build_command: "npx vitepress build ."`, `output_folder: ".vitepress/dist"`, `output_glob: "posts/*.html"`, `cache_folders: [".vitepress/cache"]`.

### Task 7: pelican 4.12.0 (`Python/pelican`)

Python RUNTIME; `requirements.txt`: `pelican[markdown]==4.12.0`.
`src/pelicanconf.py`:

```python
AUTHOR = "SSGBerk"
SITENAME = "SSGBerk Pelican"
SITEURL = ""
PATH = "content"
OUTPUT_PATH = "output"
TIMEZONE = "UTC"
DEFAULT_LANG = "en"
ARTICLE_URL = "posts/{slug}/"
ARTICLE_SAVE_AS = "posts/{slug}/index.html"
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None
DEFAULT_PAGINATION = False
MARKDOWN = {"extension_configs": {"markdown.extensions.meta": {}}}
```

`src/content/.gitkeep`. Python-Markdown's `meta` extension accepts the `---` YAML-style delimiters that `3minus` produces.
Config: content `{"folder":"content","type":"3minus","extension":"md"}`, `build_command: "pelican -q"`, `build_verbose: "pelican -v"`, `output_folder: "output"`, `output_glob: "posts/*/index.html"`, `cache_folders: ["cache", "__pycache__"]`.
If titles come out with literal quotes (`"2026-…"`) the slug still matches the glob; acceptable.

### Task 8: mkdocs 1.6.1 (`Python/mkdocs`)

Python RUNTIME; `requirements.txt`: `mkdocs==1.6.1`.
`src/mkdocs.yml`: `site_name: SSGBerk MkDocs` / `docs_dir: docs` / `site_dir: site` / `use_directory_urls: true`.
`src/docs/index.md`: `# SSGBerk MkDocs`. `src/docs/posts/.gitkeep`.
Config: content `{"folder":"docs/posts","type":"none","extension":"md"}`, `build_command: "mkdocs build -q"`, `build_verbose: "mkdocs build -v"`, `output_folder: "site"`, `output_glob: "posts/*/index.html"`.
