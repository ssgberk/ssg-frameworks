# 005 Reference Site Design — Plan

Spec: `spec.md`. Tasks: `tasks.md`. This plan owns the **reference content model** and the **reference design**: page types, skeleton, selectors, literal reference output, stylesheet, image, template logic, profiles, the baseline dependency sets and the capability matrix. These are referenced, never copied, by:

- `docs/specs/006-layout-conformance`: checks a build against this plan.
- `docs/specs/001-canonical-build-runner/plan.md`: owns `build.sh` mechanics, markers, the `benchmark_config.json` schema and the Dockerfile skeleton. `build.sh` implements "Content model" below.
- `benchmark-tool/docs/specs/008-benchmark-methodology`: runs Core and Extended as separate series.

## Architecture

```
build.sh (001)                              generator site (this plan)               check_conformance.py (006)
 ├─ content generator (awk, "Content model")   ├─ base layout + header/footer partials   ├─ reads content folder (sources)
 │    writes N posts into content.folder       ├─ post / index / 404 templates            ├─ reads output folder
 ├─ untimed verification build ───────────────▶├─ static: assets/ssgberk.{css,png}  ───▶ ├─ validates against this plan
 ├─ count check (SSGBERK_VERIFY_*)             └─ Core switches in site config           └─ prints SSGBERK_CONFORMANCE_*
 ├─ conformance check (006) ──────────────────────────────────────────────────────────────┘
 └─ hyperfine timed builds (cold, --prepare)
```

The canonical copies of the assets and of the literal reference output live in SF at `reference/`:

```
reference/
  assets/ssgberk.css        # literal file from "Stylesheet"
  assets/ssgberk.png        # produced once by tools/make_reference_png.py, then committed
  html/post.html            # literal reference output, post 1, -cs 0.500
  html/index.html           # literal reference output, index with 3 posts
  html/404.html             # literal reference output, 404 page
```

`reference/html/*` is the golden input for the checker's own tests (006). Each generator commits copies of `reference/assets/*` in its static folder. `tools/check-reference-assets.sh` (Task 4) fails CI if any copy differs.

## Content model

### Vocabulary

`V` (32 words, index 0–31, all 5 ASCII letters):

```
amber birch cedar delta ember fjord grove haven inlet jolly karma lemon maple north ocean prism
quart raven solar tiger ultra vivid waltz xenon yield zebra acorn blaze coral dunes eagle flint
```

`TAGS` (16 tag names, index 0–15):

```
alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa
```

`AUTHORS` (index 0–3): `Ada North`, `Ben South`, `Cy East`, `Di West`.

Word function, integer arithmetic only:

```
w(i, k, j) = V[(i*7919 + k*104729 + j*1009) mod 32]
```

Here i is the post index (1..N), k is the block index (1..B, or 0 for front matter values) and j is the slot index. All intermediate values stay below 2^53 for i ≤ 10^7 and k ≤ 2·10^5, so awk (mawk or gawk doubles), Python and JS compute identical results.

### Front matter values

For post i (1-based), with NNN = i zero-padded to the width of `number_of_files`:

| Field | Value | Example (i=1, N=3) |
|---|---|---|
| title | `Post NNN w(i,0,1) w(i,0,2)` | `Post 1 amber raven` |
| date (key = `metadata_dateslug`) | `1767225600 − 60·i` seconds since epoch, formatted `YYYY-MM-DDTHH:MM:SSZ` | `2025-12-31T23:59:00Z` |
| summary | `Summary` + ` w(i,0,j)` for j = 3..14 + `.` | `Summary cedar tiger ember vivid grove xenon inlet zebra karma blaze maple dunes.` |
| author | `AUTHORS[i mod 4]` | `Ben South` |
| tags | `TAGS[(7i) mod 16]`, `TAGS[(7i+3) mod 16]`, `TAGS[(7i+6) mod 16]` (always 3 distinct) | `hotel`, `kilo`, `november` |

`1767225600` is `2026-01-01T00:00:00Z`. The UTC calendar date is computed from days since epoch with the integer `civil_from_days` algorithm (H. Hinnant), because mawk has no `strftime`:

```awk
function civil(z,   era, doe, yoe, y, doy, mp, d, m) {
    z += 719468
    era = int((z >= 0 ? z : z - 146096) / 146097)
    doe = z - era * 146097
    yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
    y = yoe + era * 400
    doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
    mp = int((5 * doy + 2) / 153)
    d = doy - int((153 * mp + 2) / 5) + 1
    m = mp + (mp < 10 ? 3 : -9)
    if (m <= 2) y += 1
    return sprintf("%04d-%02d-%02d", y, m, d)
}
```

File name: `<civil date>-<NNN>.<content.extension>`, for example `2025-12-31-1.md`. The existing reset pattern `[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*` still matches, so section index files still survive (001 constraint). Post 1 is the newest post.

### Front matter layouts per `content.type`

`<dateslug>` is `config[0].metadata_dateslug` and `<layout>` is `config[0].metadata_layout`, as today. Each layout below is literal and shown for i=1, N=3.

`3minus` (YAML; tags as a block sequence indented by 4 spaces; plain scalars, no quotes, so Python-Markdown `meta` in Pelican reads the same strings):

```
---
<layout line, only if metadata_layout is non-empty>
title: Post 1 amber raven
date: 2025-12-31T23:59:00Z
summary: Summary cedar tiger ember vivid grove xenon inlet zebra karma blaze maple dunes.
author: Ben South
tags:
    - hotel
    - kilo
    - november
---
```

`3plus` (TOML; Zola-shaped: the reserved keys stay top-level, custom data goes in `[extra]`):

```
+++
title = "Post 1 amber raven"
date = 2025-12-31T23:59:00Z

[extra]
summary = "Summary cedar tiger ember vivid grove xenon inlet zebra karma blaze maple dunes."
author = "Ben South"
tags = ["hotel", "kilo", "november"]
+++
```

`2dot` (reST-comment style, Nikola; tags comma-separated; one blank line after the header; `slug` kept from today's format):

```
.. <layout, only if metadata_layout is non-empty>
.. title: Post 1 amber raven
.. slug: 2025-12-31-1
.. date: 2025-12-31T23:59:00Z
.. summary: Summary cedar tiger ember vivid grove xenon inlet zebra karma blaze maple dunes.
.. author: Ben South
.. tags: hotel, kilo, november

```

`none`: no header, body only. This layout cannot carry the Core fields (spec R-11).

### Block template

A block is exactly **512 bytes**. `K` is the block index zero-padded to 6 digits, and `x[j] = w(i, k, j)` for j = 1..52. The template is literal, every line ends with `\n`, and the block ends with one empty line after `* * *`:

```
## Chapter K x1 x2

Text x3 *x4* x5 **x6** x7 `x8` x9 [x10 x11](https://example.com/x12/) x13.

### Note K x14 x15

- x16 x17
    - x18 x19
- x20 x21

1. x22 x23
    1. x24 x25
2. x26 x27

> x28 x29 x30 x31.

~~~ text
x32 = x33 + x34
~~~

| Key | Value |
|-----|-------|
| x35 | x36 |

![x37 x38](/assets/ssgberk.png)

Tail x39 x40 x41 x42 x43 x44 x45 x46 x47 x48 x49 x50 x51 x52.

* * *

```

Block 1 of post 1, literal (this is the whole body at `-cs 0.500`):

```
## Chapter 000001 zebra karma

Text blaze *maple* dunes **ocean** flint `quart` birch [solar delta](https://example.com/ultra/) fjord.

### Note 000001 waltz haven

- yield jolly
    - acorn lemon
- coral north

1. eagle prism
    1. amber raven
2. cedar tiger

> ember vivid grove xenon.

~~~ text
inlet = zebra + karma
~~~

| Key | Value |
|-----|-------|
| blaze | maple |

![dunes ocean](/assets/ssgberk.png)

Tail flint quart birch solar delta ultra fjord waltz haven yield jolly acorn lemon coral.

* * *

```

Why each syntax choice, for portability across renderers:

| Element | Choice | Reason |
|---|---|---|
| Nested lists | 4-space indent | Python-Markdown and PHP Markdown Extra require 4 spaces. CommonMark, kramdown and markdown-it accept them. |
| Fenced code | `~~~ text` (tildes) | kramdown's standard parser (nanoc, middleman) and PHP Markdown Extra (Jigsaw) support tilde fences natively. Backtick fences need kramdown GFM input. |
| Thematic break | `* * *` | `---` after a paragraph is a setext h2 in CommonMark. |
| Emphasis | `*`/`**`, never `_` | Intra-word underscore rules differ between renderers. |
| Lists, tables, quote | blank line before and after | Python-Markdown does not start a list or table without one. |
| Headings | include `K` | Unique text, so id de-duplication stays O(1) per heading (spec R-13). |
| Link | in brackets, `https://example.com/<word>/` | No bare URLs, so linkify (goldmark) has nothing to do. External links, so the post page links to no other post. |

### Size table (`-cs` semantics, unchanged in meaning)

| `-cs` | Blocks B | Body bytes per post |
|---|---|---|
| `0.500` | 1 | 512 |
| `500` | 1000 | 512 000 |
| `1000` | 2000 | 1 024 000 |
| `5000` | 10000 | 5 120 000 |
| `10000` | 20000 | 10 240 000 |
| `100000` | 200000 | 102 400 000 |

### Generator implementation in `build.sh`

The content generator is one `awk` program (mawk in `ubuntu:24.04`, which every generator image has). It is invoked once per build with `-v n= reps= width= outdir= type= dateslug= layout= ext=`, and it writes all N files itself. This replaces today's per-post `printf | sponge` loop and the `yes | head` paragraph. The prototype is in `tasks.md` Task 2 and was checked to emit exactly 512 bytes per block and the literal block above.

### Renderer notes

| Generator | Markdown renderer (version family) | Tables | Tilde fences | Nested 4-space lists | Action for Core |
|---|---|---|---|---|---|
| hugo | goldmark | default on | yes | yes | `markup.highlight.codeFences = false` |
| gatsby | remark (gatsby-transformer-remark) | GFM default on | yes | yes | none |
| jigsaw | PHP Markdown Extra (`JigsawMarkdownParser extends MarkdownExtra`) | yes | yes | yes | none |
| nikola-mako | Python-Markdown | via built-in `extra` (includes `tables`) | `fenced_code` | yes | `MARKDOWN_EXTENSIONS = ['markdown.extensions.fenced_code', 'markdown.extensions.extra']` (drops the default `codehilite`) |
| jekyll | kramdown + kramdown-parser-gfm (Jekyll default `input: GFM`) | yes | yes | yes | `kramdown: { syntax_highlighter_opts: { disable: true } }` |
| nanoc | kramdown (standard input) | yes | yes | yes | `filter :kramdown, syntax_highlighter: nil` |
| middleman | kramdown | yes | yes | yes | `set :markdown, syntax_highlighter: nil` |
| metalsmith-* | marked (`@metalsmith/markdown`) | GFM default on | yes | yes | none |
| zola | pulldown-cmark | default on | yes | yes | none (`highlight_code` defaults to false) |
| astro | remark (GFM on) | yes | yes | yes | `markdown: { syntaxHighlight: false }` |
| eleventy | markdown-it | yes | yes | yes | none |
| hexo | marked (hexo-renderer-marked) | yes | yes | yes | `syntax_highlighter: ''` |
| nextjs-export | marked | GFM default on | yes | yes | none |
| vitepress | markdown-it + Shiki | yes | yes | yes | `markdown.highlight` identity function (spec open question 5) |
| pelican | Python-Markdown | via built-in `extra` | via `extra` | yes | `MARKDOWN = {'extension_configs': {'markdown.extensions.extra': {}, 'markdown.extensions.meta': {}}}` (drops the default `codehilite`) |
| mkdocs | Python-Markdown | built-in `tables` is a MkDocs default | `fenced_code` default | yes | `plugins: []` (drops the default `search`) |

## Pages, URLs and titles

| Page | Output path | `<title>` |
|---|---|---|
| index | `index.html` | `SSGBerk Reference` |
| post | free per generator, within `config[0].output_glob` (for example `posts/<slug>/index.html` or `posts/<slug>.html`) | `<post title> \| SSGBerk Reference` |
| 404 | `404.html` | `Page not found \| SSGBerk Reference` |

Post URLs are not fixed. Jekyll and middleman need dated file names, MkDocs cannot override the output path natively, and nothing in Core needs a fixed URL. The checker resolves every `a.post-item-title`-style link from the index to an output file (006). Every link the templates generate is root-relative (`/…`).

### Unavoidable extra output

Non-HTML files (JS bundles, JSON payloads, theme assets) are allowed in both profiles and counted in output bytes (008). Extra `*.html` files are allowed only if they match the generator's `config[0].allow_extra_html` (schema amendment drafted by 006). That list may contain only these entries:

| Generator | Allowed extra HTML |
|---|---|
| gatsby | `404/index.html` (Gatsby writes the 404 page twice) |
| nextjs-export | `404/index.html`, `_not-found.html`, `_not-found/index.html` |
| all others | none |

## HTML skeleton and selectors

Base layout (every page):

```
html[lang=en]
  head: meta[charset=utf-8], title, link[rel=stylesheet][href="/assets/ssgberk.css"]
  body
    header.site-header            (header partial)
      a.site-title[href="/"]      "SSGBerk Reference"
      nav.site-nav > ul > li × 3 > a
    main.site-main                (page template)
    footer.site-footer            (footer partial)
      p                           "Built for the SSGBerk build-time benchmark."
```

Selector table (normative; counts per page; "child" means direct child):

| Page | Selector | Count | Content |
|---|---|---|---|
| all | `header.site-header`, `main.site-main`, `footer.site-footer` | 1 each, in this document order | |
| all | `nav.site-nav a` | 3 | hrefs `/`, `/#posts`, `https://github.com/ssgberk`; text `Home`, `Posts`, `Source` |
| all | `link[rel=stylesheet][href="/assets/ssgberk.css"]` | 1 | |
| index | `nav.site-nav a[aria-current=page]` | 1 (the Home link) | |
| post, 404 | `[aria-current]` | 0 | |
| post | `main.site-main article.post` | 1 | |
| post | `article.post` children in order: `h1.post-title`, `p.post-meta`, `ul.post-tags`, `div.post-body` | 1 each | |
| post | `p.post-meta time.post-date[datetime]` | 1 | datetime ISO, text `YYYY-MM-DD` |
| post | `p.post-meta span.post-author` | 1 | author |
| post | `ul.post-tags > li.post-tag` | 3 | tag names in front matter order (Core: plain text; Extended `E1`: one `a[href]` inside each) |
| post | `.post-list`, `.post-item` | 0 | |
| index | `section#posts.posts` | 1 | |
| index | `section#posts > h1.page-title` | 1 | `Posts` |
| index | `ol.post-list` | 1 | |
| index | `ol.post-list > li.post-item` | N | ordered by datetime descending |
| index | `li.post-item > h2.post-item-title > a[href]` | 1 per item | post title; href resolves to that post's page |
| index | `li.post-item > time.post-item-date[datetime]` | 1 per item | |
| index | `li.post-item > p.post-item-summary` | 1 per item | summary |
| index | `.post-body` | 0 | |
| 404 | `main.site-main section.not-found > h1.page-title` | 1 | `Page not found` |
| 404 | `section.not-found a[href="/"]` | 1 | |

Wrappers inserted by a generator between `body` and `header.site-header`, or between `main.site-main` and its child, are allowed (Gatsby `div#___gatsby`, VitePress `div#app`). The checker in 006 uses descendant matching for these two levels and child matching inside `article.post`, `ol.post-list` and `li.post-item`.

### Rendered body structure

Per post with B blocks, `div.post-body` contains exactly: `h2` B, `h3` B, `blockquote` B, `pre` B, `table` B, `img` B, `hr` B, `em` B, `strong` B, `ol` 2B, `ul` 2B, `li` 12B. Element counts are checked by 006, and text is compared by word-sequence hash (006). Attributes (ids, classes) and extra wrapper elements inside the body are not compared.

## Literal reference output

Normative for structure and text, not for whitespace or attribute order (006 defines equivalence). Hrefs to posts (`/posts/1/` and so on) are illustrative, because post URLs are free.

### Post page (post 1, N=3, `-cs 0.500`) — `reference/html/post.html`

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Post 1 amber raven | SSGBerk Reference</title>
<link rel="stylesheet" href="/assets/ssgberk.css">
</head>
<body>
<header class="site-header">
<a class="site-title" href="/">SSGBerk Reference</a>
<nav class="site-nav">
<ul>
<li><a href="/">Home</a></li>
<li><a href="/#posts">Posts</a></li>
<li><a href="https://github.com/ssgberk">Source</a></li>
</ul>
</nav>
</header>
<main class="site-main">
<article class="post">
<h1 class="post-title">Post 1 amber raven</h1>
<p class="post-meta"><time class="post-date" datetime="2025-12-31T23:59:00Z">2025-12-31</time> by <span class="post-author">Ben South</span></p>
<ul class="post-tags">
<li class="post-tag">hotel</li>
<li class="post-tag">kilo</li>
<li class="post-tag">november</li>
</ul>
<div class="post-body">
<h2>Chapter 000001 zebra karma</h2>
<p>Text blaze <em>maple</em> dunes <strong>ocean</strong> flint <code>quart</code> birch <a href="https://example.com/ultra/">solar delta</a> fjord.</p>
<h3>Note 000001 waltz haven</h3>
<ul>
<li>yield jolly
<ul>
<li>acorn lemon</li>
</ul>
</li>
<li>coral north</li>
</ul>
<ol>
<li>eagle prism
<ol>
<li>amber raven</li>
</ol>
</li>
<li>cedar tiger</li>
</ol>
<blockquote>
<p>ember vivid grove xenon.</p>
</blockquote>
<pre><code class="language-text">inlet = zebra + karma
</code></pre>
<table>
<thead>
<tr><th>Key</th><th>Value</th></tr>
</thead>
<tbody>
<tr><td>blaze</td><td>maple</td></tr>
</tbody>
</table>
<p><img src="/assets/ssgberk.png" alt="dunes ocean"></p>
<p>Tail flint quart birch solar delta ultra fjord waltz haven yield jolly acorn lemon coral.</p>
<hr>
</div>
</article>
</main>
<footer class="site-footer">
<p>Built for the SSGBerk build-time benchmark.</p>
</footer>
</body>
</html>
```

### Index (N=3) — `reference/html/index.html`

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SSGBerk Reference</title>
<link rel="stylesheet" href="/assets/ssgberk.css">
</head>
<body>
<header class="site-header">
<a class="site-title" href="/">SSGBerk Reference</a>
<nav class="site-nav">
<ul>
<li><a href="/" aria-current="page">Home</a></li>
<li><a href="/#posts">Posts</a></li>
<li><a href="https://github.com/ssgberk">Source</a></li>
</ul>
</nav>
</header>
<main class="site-main">
<section class="posts" id="posts">
<h1 class="page-title">Posts</h1>
<ol class="post-list">
<li class="post-item">
<h2 class="post-item-title"><a href="/posts/1/">Post 1 amber raven</a></h2>
<time class="post-item-date" datetime="2025-12-31T23:59:00Z">2025-12-31</time>
<p class="post-item-summary">Summary cedar tiger ember vivid grove xenon inlet zebra karma blaze maple dunes.</p>
</li>
<li class="post-item">
<h2 class="post-item-title"><a href="/posts/2/">Post 2 prism amber</a></h2>
<time class="post-item-date" datetime="2025-12-31T23:58:00Z">2025-12-31</time>
<p class="post-item-summary">Summary raven cedar tiger ember vivid grove xenon inlet zebra karma blaze maple.</p>
</li>
<li class="post-item">
<h2 class="post-item-title"><a href="/posts/3/">Post 3 eagle prism</a></h2>
<time class="post-item-date" datetime="2025-12-31T23:57:00Z">2025-12-31</time>
<p class="post-item-summary">Summary amber raven cedar tiger ember vivid grove xenon inlet zebra karma blaze.</p>
</li>
</ol>
</section>
</main>
<footer class="site-footer">
<p>Built for the SSGBerk build-time benchmark.</p>
</footer>
</body>
</html>
```

### 404 page — `reference/html/404.html`

The base layout as above, without `aria-current`, `<title>Page not found | SSGBerk Reference</title>`, and:

```html
<main class="site-main">
<section class="not-found">
<h1 class="page-title">Page not found</h1>
<p><a href="/">Back to the posts</a></p>
</section>
</main>
```

## Stylesheet — `reference/assets/ssgberk.css`

Literal file (LF line endings, trailing newline):

```css
/* SSGBerk reference stylesheet. Copied verbatim by every generator; never processed. */
:root {
  --ssg-color-text: #1d2330;
  --ssg-color-muted: #5b6475;
  --ssg-color-accent: #2f5bd3;
  --ssg-color-surface: #ffffff;
  --ssg-color-subtle: #f2f4f8;
  --ssg-color-border: #d8dde7;
  --ssg-font-body: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --ssg-font-mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  --ssg-size-base: 1rem;
  --ssg-size-small: 0.875rem;
  --ssg-size-h1: 2rem;
  --ssg-size-h2: 1.5rem;
  --ssg-size-h3: 1.25rem;
  --ssg-space-1: 0.25rem;
  --ssg-space-2: 0.5rem;
  --ssg-space-3: 1rem;
  --ssg-space-4: 2rem;
  --ssg-measure: 42rem;
  --ssg-radius: 0.375rem;
}
* { box-sizing: border-box; }
body { margin: 0; color: var(--ssg-color-text); background: var(--ssg-color-surface); font: var(--ssg-size-base)/1.6 var(--ssg-font-body); }
.site-header, .site-main, .site-footer { max-width: var(--ssg-measure); margin: 0 auto; padding: var(--ssg-space-3); }
.site-header { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--ssg-color-border); }
.site-title { font-weight: 700; color: var(--ssg-color-text); text-decoration: none; }
.site-nav ul { display: flex; gap: var(--ssg-space-3); margin: 0; padding: 0; list-style: none; }
.site-nav a { color: var(--ssg-color-accent); text-decoration: none; }
.site-nav a[aria-current="page"] { font-weight: 700; text-decoration: underline; }
.site-footer { border-top: 1px solid var(--ssg-color-border); color: var(--ssg-color-muted); font-size: var(--ssg-size-small); }
h1 { font-size: var(--ssg-size-h1); line-height: 1.2; }
h2 { font-size: var(--ssg-size-h2); }
h3 { font-size: var(--ssg-size-h3); }
a { color: var(--ssg-color-accent); }
.post-meta, .post-item-date { color: var(--ssg-color-muted); font-size: var(--ssg-size-small); }
.post-tags { display: flex; flex-wrap: wrap; gap: var(--ssg-space-2); margin: 0 0 var(--ssg-space-3); padding: 0; list-style: none; }
.post-tag { padding: 0 var(--ssg-space-2); border: 1px solid var(--ssg-color-border); border-radius: var(--ssg-radius); font-size: var(--ssg-size-small); }
.post-list { padding-left: var(--ssg-space-4); }
.post-item { margin-bottom: var(--ssg-space-3); }
.post-item-title { margin: 0; font-size: var(--ssg-size-h3); }
.post-item-summary { margin: var(--ssg-space-1) 0 0; }
.post-body img { max-width: 100%; height: auto; }
.post-body blockquote { margin: var(--ssg-space-3) 0; padding-left: var(--ssg-space-3); border-left: 4px solid var(--ssg-color-border); color: var(--ssg-color-muted); }
.post-body pre, .post-body code { font-family: var(--ssg-font-mono); font-size: var(--ssg-size-small); }
.post-body pre { padding: var(--ssg-space-3); overflow-x: auto; background: var(--ssg-color-subtle); border-radius: var(--ssg-radius); }
.post-body table { border-collapse: collapse; }
.post-body th, .post-body td { padding: var(--ssg-space-1) var(--ssg-space-2); border: 1px solid var(--ssg-color-border); }
.post-body hr { border: 0; border-top: 1px solid var(--ssg-color-border); }
.not-found { text-align: center; }
```

## Image — `reference/assets/ssgberk.png`

A 64×64 8-bit RGB PNG with no ancillary chunks, so there is no timestamp or gamma metadata. It is four horizontal bands in `--ssg-color-accent`, `--ssg-color-subtle`, `--ssg-color-text` and `--ssg-color-border`. It is written by `tools/make_reference_png.py` (stdlib `zlib` + `struct`, Task 1) once and then committed. Byte identity of the copies comes from copying the committed file, not from re-running the script. Format: PNG, not SVG, because some bundlers inline or transform SVG references.

## Template structure and logic

Required files (names per generator convention):

| Role | Purpose | Inputs |
|---|---|---|
| base layout | `<html>`, `<head>`, includes header partial, page slot, footer partial | page title, page kind |
| header partial | site title, nav, `aria-current` conditional | page kind (`index` / `post` / `404`) or the current path |
| footer partial | static footer | none |
| post template | `article.post` (inherits base) | post fields + rendered body |
| index template | `section#posts` (inherits base) | all posts |
| 404 template | `section.not-found` (inherits base) | none |

Template logic that must run during the timed build (spec R-25):

1. **Sort** all posts by date descending (index). The sort may be native to the collection (Jekyll `site.posts`, Hugo `.ByDate.Reverse`, Zola `sort_by = "date"`, Pelican's default `reversed-date`) or explicit in the template or site-local code.
2. **Loop** over all posts (index) and over the 3 tags (post page).
3. **Conditional:** `aria-current="page"` on the Home link only when the page kind is `index`.
4. **Date formatting** twice per `<time>`: `YYYY-MM-DDTHH:MM:SSZ` for `datetime` and `YYYY-MM-DD` for the text, both in UTC.
5. **Escaping:** titles, summaries, tags and author are emitted through the template engine's escaping path. The values contain nothing to escape, so the output is unchanged, but the work is done.

### Per-template-language guidance

Principles: use the engine's own inheritance and include mechanism; pass the page kind into the header partial; never hard-code a post list; format dates in UTC explicitly (do not rely on the container TZ). Examples are fragments, not full ports.

**Go templates (hugo).** `layouts/_default/baseof.html` with `{{ block "main" . }}`. Partials: `{{ partial "header.html" (dict "kind" "index") }}`. Index: `{{ range (where .Site.RegularPages "Section" "posts").ByDate.Reverse }}`. Dates: `{{ .Date.UTC.Format "2006-01-02T15:04:05Z" }}` / `{{ .Date.UTC.Format "2006-01-02" }}`. Tags: `{{ range .Params.tags }}<li class="post-tag">{{ . }}</li>{{ end }}`. 404: `layouts/404.html` (remove `"404"` from `disableKinds`).

**Liquid (jekyll).** `_layouts/base.html`; `post.html` and `index.html` use `layout: base`. `{% include header.html kind="index" %}`, and in the partial `{% if include.kind == "index" %} aria-current="page"{% endif %}`. `site.posts` is already date-descending. `{{ post.date | date: "%Y-%m-%dT%H:%M:%SZ" }}` with `timezone: UTC` in `_config.yml`. `404.html` with `permalink: /404.html`.

**Nunjucks (eleventy, metalsmith-nunjucks).** `{% extends "base.njk" %}`, `{% set kind = "index" %}` before `{% include "header.njk" %}`. Eleventy: `collections.posts | reverse` (collections are date-ascending), filters registered in `eleventy.config.js`: `addFilter("isoDate", d => d.toISOString().replace(/\.\d{3}Z$/, "Z"))` and `addFilter("ymd", d => d.toISOString().slice(0, 10))`. Metalsmith: the same filters passed through `@metalsmith/layouts` `engineOptions.filters` to `jstransformer-nunjucks`, and the posts list built and sorted in site-local `index.js`.

**Handlebars (metalsmith-handlebars).** No inheritance, so use a partial block: post and index layouts are `{{#> base}}…{{/base}}`, and `base` includes `{{> header kind="post"}}` and `{{> footer}}`. Partials and helpers (`isoDate`, `ymd`, `eq`) are passed through `engineOptions` to `jstransformer-handlebars`. Sorting happens in site-local `index.js`, because Handlebars has no sort.

**Blade (jigsaw).** `@extends('_layouts.base')`, `@include('_partials.header', ['kind' => 'index'])`. Collection `posts` with `'sort' => '-date'`. Dates: `gmdate('Y-m-d\TH:i:s\Z', $post->date)` (Jigsaw parses YAML dates to Unix timestamps). 404: `source/404.blade.php` with `permalink: 404.html`.

**Mako (nikola-mako).** `<%inherit file="base.tmpl"/>`. Header: `<%include file="header.tmpl" args="kind='index'"/>` with `<%page args="kind=''"/>` in the partial. Fields: `post.title()`, `post.date.strftime('%Y-%m-%dT%H:%M:%SZ')` (`TIMEZONE = "UTC"`), `post.author()`, `post.tags`, `post.meta('summary')`. Index posts are date-descending by default. 404: a page under `PAGES` with `.. slug: 404` and `.. pretty_url: False`.

**Jinja2 (pelican, mkdocs).** `{% extends "base.html" %}`, `{% set kind = "index" %}` then `{% include "header.html" %}`. Pelican: `articles` (date-descending by default), `article.date.strftime(...)`, `article.summary|striptags`, `DIRECT_TEMPLATES = ['index']`, 404 as `content/pages/404.md` with `save_as: 404.html`. MkDocs: custom theme (`theme: {name: null, custom_dir: theme}`); index = `docs/index.md` with `template: index.html`, which loops `{% for f in pages|sort(attribute='page.meta.date', reverse=True) if f.src_uri.startswith('posts/') %}`; 404 = theme `404.html`.

**ERB (nanoc, middleman).** nanoc: `Rules` lays out posts with `layout '/post.*'`, which renders inside `/base.*` (`layout '/base.*'` nested via `render`), and `include Nanoc::Helpers::Rendering` in `lib/default.rb` for `<%= render '/header.*', kind: 'index' %>`. Index: `@items.find_all('/posts/*').sort_by { |p| p[:date] }.reverse`. middleman: `wrap_layout :layout`, `<%= partial "header", locals: { kind: "index" } %>`, `blog.articles` (date-descending), `page "/404.html", directory_index: false`. Dates: `t.utc.strftime('%Y-%m-%dT%H:%M:%SZ')`.

**Tera (zola).** `{% extends "base.html" %}`, `{% include "header.html" %}`, with the conditional on `current_path == "/"` because Tera includes take no arguments. Section `posts/_index.md` with `sort_by = "date"` (descending). Dates: `{{ page.date | date(format="%Y-%m-%dT%H:%M:%SZ") }}`. Fields under `page.extra`. 404: `templates/404.html`.

**JSX (gatsby, nextjs-export).** Components `Layout`, `Header({ kind })` and `Footer`. Body: `<div className="post-body" dangerouslySetInnerHTML={{ __html: html }} />`. Stylesheet as `<link rel="stylesheet" href="/assets/ssgberk.css" />`, never `import`ed (an import would be bundled, which violates R-5). Gatsby: GraphQL `allMarkdownRemark(sort: { frontmatter: { date: DESC } })`, `Head` export for `<title>` and the link, assets in `static/`, `src/pages/404.js`. Next: sort in `lib/posts.js`, `metadata` export for `<title>`, assets in `public/`, `app/not-found.js`. Dates: `d.toISOString().replace(/\.\d{3}Z$/, "Z")` and `.slice(0, 10)`.

**Vue SFC (vitepress).** Custom theme: `.vitepress/theme/index.js` exports `{ Layout }`. `Layout.vue` switches on `frontmatter.layout` or `page.relativePath` to render the post, index or 404 markup, and wraps `<Content />` in `div.post-body`. Index data comes from `posts.data.js` with `createContentLoader('posts/*.md')`, sorted in `transform`. `Header.vue` takes a `kind` prop. Stylesheet through `head: [['link', { rel: 'stylesheet', href: '/assets/ssgberk.css' }]]`, assets in `public/`.

**Astro (astro).** `src/layouts/Base.astro` with `<Header kind={kind} />`, `<slot />` and `<Footer />`. Index: `(await getCollection('posts')).sort((a, b) => b.data.date - a.data.date)`. Post: `const { Content } = await render(post)` inside `<div class="post-body">`. `src/pages/404.astro`. Assets in `public/`.

**EJS (hexo).** Theme `layout.ejs` with `<%- partial('_partial/header', { kind: page.__index ? 'index' : 'post' }) %>`. `index_generator: { per_page: 0, order_by: -date }`. Dates: `post.date.clone().utc().format('YYYY-MM-DD[T]HH:mm:ss[Z]')` (moment). 404: `source/404.md` with `permalink: /404.html`.

## Core features

| Id | Feature | Definition (checked by 006) |
|---|---|---|
| C1 | Layout inheritance and partials | Base layout, header and footer partials, page templates per R-24; skeleton selectors on every page |
| C2 | Rich markdown body | `div.post-body` element counts and word hash match the source |
| C3 | Front matter fields | title, date, summary, author and tags rendered with the selectors above |
| C4 | Date formatting | `datetime` ISO and text `YYYY-MM-DD`, UTC |
| C5 | Single full index | one `ol.post-list` with N items, datetime-descending, fields present, links resolve |
| C6 | Per-page conditional and loops | `aria-current` only on the index; 3 `li.post-tag` per post |
| C7 | 404 page | `404.html` at the output root with the skeleton |
| C8 | Verbatim static assets | `assets/ssgberk.css` and `assets/ssgberk.png` byte-identical; one stylesheet link per page |
| C9 | Post page isolation | no post list and no link to another post on post pages |

### Core switches (spec R-4)

| Generator | Switches |
|---|---|
| hugo | `disableKinds = ["taxonomy", "term", "rss", "sitemap", "robotsTXT"]`; `[markup.highlight] codeFences = false` |
| gatsby | none (no plugins beyond the baseline) |
| jigsaw | none |
| nikola-mako | `GENERATE_RSS = False`, `GENERATE_ATOM = False`; `DISABLED_PLUGINS` adds `classify_taxonomies`-family plugins (tags, categories, authors, archive, sections), `sitemap`, `robots`; `INDEX_DISPLAY_POST_COUNT = 10**9`; `MARKDOWN_EXTENSIONS` without `codehilite` |
| jekyll | `kramdown.syntax_highlighter_opts.disable: true`; no `paginate` |
| nanoc | `filter :kramdown, syntax_highlighter: nil` |
| middleman | `blog.paginate = false`, tag/year/month/day pages off (already), `set :markdown, syntax_highlighter: nil` |
| metalsmith-* | none |
| zola | `generate_feeds = false`, `build_search_index = false`, no `taxonomies` |
| astro | `markdown.syntaxHighlight: false` |
| eleventy | none |
| hexo | `syntax_highlighter: ''`, `index_generator.per_page: 0` |
| nextjs-export | `images.unoptimized: true` (already) |
| vitepress | `markdown.highlight` identity (open question 5); default `sitemap`/`search` are off |
| pelican | `DIRECT_TEMPLATES = ['index']`, `TAG_SAVE_AS = CATEGORY_SAVE_AS = AUTHOR_SAVE_AS = ''` (and their `*S_SAVE_AS`), all `FEED_*` = `None`, `DEFAULT_PAGINATION = False`, `MARKDOWN` without `codehilite` |
| mkdocs | `plugins: []`; theme without `sitemap.xml` |

## Extended features

| Id | Output | Selectors |
|---|---|---|
| E1-tag-pages | `tags/<tag>/index.html` for each of the 16 tags that occur | `ol.post-list > li.post-item` (index format) with the tag's posts, datetime-descending; on post pages each `li.post-tag` contains `a[href]` resolving to its tag page |
| E2-pager | post pages | `nav.post-pager` with `a[rel=prev]` (older post, absent on the oldest) and `a[rel=next]` (newer post, absent on post 1). This is the one allowed exception to C9 |
| E3-excerpt | index | `li.post-item > p.post-item-excerpt`, whose words equal the first `<p>` of the post's rendered body |
| E4-highlight | post pages | the `pre` in each block contains at least one element with a class (the highlighter's token spans); the text is unchanged |
| E5-feed | `feed.xml` | well-formed XML, RSS 2.0 `<item>` or Atom `<entry>` × N, newest first |

## Baseline dependency set (defines "native", spec R-3)

| Generator | Baseline (pinned in lockfile / dockerfile) |
|---|---|
| hugo | `hugo` extended binary |
| gatsby | `gatsby`, `react`, `react-dom`, `gatsby-source-filesystem`, `gatsby-transformer-remark` (first-party) |
| jigsaw | `tightenco/jigsaw` |
| nikola-mako | `Nikola` (its dependency closure, frozen by `pip freeze`) |
| jekyll | `jekyll` |
| nanoc | `nanoc`, `kramdown`, `erubi` |
| middleman | `middleman`, `middleman-blog` (first-party), `webrick`, `tzinfo-data` |
| metalsmith-handlebars | `metalsmith`, `@metalsmith/markdown`, `@metalsmith/layouts`, `@metalsmith/permalinks` (first-party), `jstransformer-handlebars` |
| metalsmith-nunjucks | as above with `jstransformer-nunjucks` |
| zola | `zola` binary |
| astro | `astro` |
| eleventy | `@11ty/eleventy` |
| hexo | `hexo`, `hexo-renderer-marked`, `hexo-renderer-ejs`, `hexo-generator-index` (first-party, all in `hexo-starter`) |
| nextjs-export | `next`, `react`, `react-dom`, `gray-matter`, `marked` (spec open question 1) |
| vitepress | `vitepress` |
| pelican | `pelican[markdown]` |
| mkdocs | `mkdocs` |

## Capability matrix

Legend: ✅ native: core, baseline and site files, including site-local code. 🔌 needs a first-party plugin, allowed only in Extended (R-28). ❌ needs a third-party package. ⚠️ uncertain. A superscript `OQn` points to spec open question n. A ✅ with an OQ means the documented mechanism exists but has not yet been exercised in this repo.

| Generator | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | E1 | E2 | E3 | E4 | E5 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| hugo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| gatsby | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔌 | ✅ |
| jigsaw | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ❌ | ✅ |
| nikola-mako | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ OQ3 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| jekyll | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| nanoc | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| middleman | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔌 | ⚠️ |
| metalsmith-handlebars | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ OQ4 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| metalsmith-nunjucks | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ OQ4 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| zola | ✅ | ✅ | ✅ OQ8 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| astro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| eleventy | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔌 | ✅ |
| hexo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔌 | ✅ | ✅ | ✅ | 🔌 |
| nextjs-export | ✅ OQ1 | ✅ OQ1 | ✅ OQ1 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| vitepress | ✅ OQ6 | ✅ OQ5 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| pelican | ✅ | ✅ | ✅ OQ2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| mkdocs | ✅ | ✅ | ✅ | ✅ | ✅ OQ7 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ❌ | ✅ |

Notes on the non-✅ cells and the less obvious ✅ cells:

- **E1:** Jekyll ✅ through a site-local `_plugins/` generator (Ruby in the site), not `jekyll-archives`. MkDocs ✅ through `hooks:` (site-local Python, MkDocs ≥ 1.4). Jigsaw ⚠️ because Jigsaw has no taxonomy feature; a tags collection built in `config.php` is the documented community pattern, but it is unproven here. Hexo 🔌 `hexo-generator-tag`.
- **E2:** Pelican ⚠️ because prev/next article variables are provided by the `neighbors` plugin in older Pelican releases, and whether 4.12 core exposes them is unverified. MkDocs ⚠️ because `page.previous_page`/`next_page` follow nav order (file-name order), which is not date order inside a day.
- **E3:** ✅ everywhere because the excerpt is defined as the first `<p>` of the rendered body. That needs native excerpt support or a string operation on the rendered HTML, both available in every engine.
- **E4:** ❌ where no highlighter ships with the generator and the only highlighters are third-party libraries: Jigsaw (highlight.php), nanoc (rouge is not a nanoc dependency), metalsmith (no first-party highlighter), Next.js and MkDocs (Pygments is not a MkDocs dependency). 🔌 Gatsby `gatsby-remark-prismjs`, middleman `middleman-syntax`, Eleventy `@11ty/eleventy-plugin-syntaxhighlight`.
- **E5:** middleman ⚠️ because `feed.xml.builder` needs the `builder` gem, whose presence in the middleman 4.6 dependency closure is unverified. Hexo 🔌 `hexo-generator-feed`. The other cells use a template that outputs XML, or site-local code.
- **Verdict:** C1–C9 are ✅ for all 17, so all stay Core. The five Extended candidates, tag links, pager, excerpts, highlighting and RSS, have at least one non-✅ cell (E1, E2, E4, E5) or are not needed for the Core comparison (E3), and are Extended. No candidate Core feature had to be moved.

## Stress rationale

| Element | Subsystem exercised | Scales with |
|---|---|---|
| Rich block (13 constructs) | markdown block and inline parsing: headings, emphasis, code spans, links, nested lists, blockquote, fences, tables, images, thematic breaks; HTML rendering and escaping | N × B |
| Unique headings | heading-id generation (where on by default) without pathological de-duplication | N × B |
| Five front matter fields, YAML block list / TOML table / reST comments | front matter parsing, date parsing, list types | N |
| Distinct dates | date parsing and collection sorting with a total order | N log N |
| Base layout + header/footer partials + page template | template inheritance and partial resolution on every page | N + 2 |
| `aria-current` conditional, tag loop, double date formatting | per-page template logic and escaping | N |
| Single index with N items and summaries | collection access, full sort, one large write | N |
| 404 page | a non-collection page through the same layout | 1 |
| Stylesheet + image | static file copy | 1 |
| `-cs` blocks | parser throughput independent of per-file overhead | B |

Why this is fair while maximising work: every element is something all 17 generators implement natively (capability matrix), so no generator can skip work another must do. Optional work that only some generators do by default (highlighting, feeds, sitemaps, taxonomy pages, search indexes) is switched off in Core (R-4). Work a generator always does and cannot switch off (JS bundling and hydration payloads, VitePress Shiki if open question 5 fails) is its real cost and stays in. The text avoids features whose handling differs semantically (smart quotes, autolinks, template syntax), so every renderer produces the same words. Post pages never list other posts, which keeps output O(N) rather than O(N²) (the 2026-10-04 site-shape rule).

## Decisions

| Decision | Chosen | Alternatives considered |
|---|---|---|
| Block size | Fixed 512 bytes, all words 5 letters, block number fixed-width | Variable ~0.5 KB (breaks exact `-cs` semantics); one big 2 KB rich block (makes `0.500` mean 2 KB) |
| Word selection | Affine hash mod 32 | LCG / PRNG (mawk vs gawk `rand()` differ; overflow above 2^53); Lorem Ipsum (no variation between posts, compresses trivially) |
| Generator language | One awk process writes all files | bash loop with `printf \| sponge` per post (≈N forks; minutes at N = 100000); Python (not in every image at generation time) |
| Dates | Minute steps back from 2026-01-01 | Day steps (reach year 1752 at N = 100000, with negative epochs and pre-Gregorian dates); all dates equal (today: undefined order) |
| Fence style | `~~~` | ```` ``` ```` (kramdown standard parser needs GFM input) |
| Post URLs | Free, resolved through index links | Fixed `/posts/NNN/` (MkDocs cannot set output paths; Jekyll and middleman derive paths from dated file names) |
| Tags in Core | Plain text | Links (need tag pages, which are not native everywhere: Extended E1) |
| 404 in Core | Yes | Extended. Rejected: the capability matrix shows native support in all 17 |
| Stylesheet delivery | `<link>` to a copied file | `import` in JS generators (bundled and fingerprinted, violates R-5) |
| `3plus` shape | `[extra]` table | Top-level custom keys (reserved by Zola) |
| Markdown pre-processing (Liquid, Nunjucks, Vue) | Keep defaults | Disable per generator (a speed tweak; spec open question 9) |

## Risks

1. **Content generation time at large cells.** `-nf 10000 -cs 500` writes 5.12 GB. The awk prototype wrote 51 MB in about 18 s with macOS BWK awk. mawk in the images is expected to be faster, but the cell will still take minutes. Generation is untimed (before `STARTTIME`), so this affects wall-clock run time only. 008 records it under suite cost.
2. **Template engines without date or sort facilities.** These are Handlebars, Nunjucks via jstransformer, and Tera includes without arguments. Mitigation: helpers or filters through `engineOptions`, and conditionals on `current_path`. If `jstransformer-nunjucks` does not accept `filters`, metalsmith-nunjucks registers them on an `nunjucks.Environment` passed through `engineOptions`.
3. **Framework wrappers and injected markup** (Gatsby, Next.js, VitePress). Mitigation: descendant matching at the two wrapper levels, and normalizations in 006.
4. **A renderer emits a different structure** (for example an image not wrapped in `<p>`, or a table without `<thead>`). Element counts in 006 count only the 13 element types listed, never `p`, `thead` or `tbody`.
5. **Huge single index page at N = 100000** (about 30 MB of HTML). This is intended stress and the same for all generators. Generators that keep the whole page in memory may hit the 008 memory limit, which 008 reports as `oom`.

## Cross-references

- Markers, `benchmark_config.json` schema, Dockerfile skeleton, smoke procedure: `docs/specs/001-canonical-build-runner/plan.md`.
- Conformance rules, normalizations, checker, `allow_extra_html` and `profiles` schema drafts: `docs/specs/006-layout-conformance/plan.md`.
- Site-shape rule (single index, no lists on post pages) and pinned Python deps: `.superpowers/sdd/tasks-002-update-existing-generators/generator-common.md` (2026-10-04 rules), now normative here as C5 and C9.
- Suites, profiles as series, metrics, validity threats: `benchmark-tool/docs/specs/008-benchmark-methodology/plan.md`.
- Generator metadata (`generators.json`): `docs/specs/004-generator-metadata` (branch `feat/generator-metadata`).
