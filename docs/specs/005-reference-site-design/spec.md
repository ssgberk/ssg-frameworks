# 005 Reference Site Design

- **Data:** 2026-10-04
- **Status:** proposto — aguardando revisão
- **Repos afetados:** `ssgberk/ssg-frameworks` (SF): every generator site under `<Lang>/<name>/src`, the content generator inside the canonical `build.sh`, the new `reference/` directory. `ssgberk/benchmark-tool` (BT) is not changed by this spec.
- **Siblings:** `plan.md` (formats, literal reference output, template guidance, capability matrix), `tasks.md`. Related: `docs/specs/006-layout-conformance` (how conformance is checked) and `benchmark-tool/docs/specs/008-benchmark-methodology` (how the benchmark is run).

## Context

SSGBerk times how long each static site generator takes to build N generated markdown posts. Until now every generator built a "minimal site": base layout, post template and an index listing posts (`001-canonical-build-runner` Out of scope, `002`/`003` Global Constraints). The minimal site has three problems:

1. **The sites are not the same site.** Hugo renders a header, footer and Google Fonts link. Metalsmith renders a bare `<h1>` with the body. Zola renders links with no list. Nikola renders a `<ul>`. The timed work differs between generators, so the comparison measures template choices as much as generators.
2. **The content is one Lorem Ipsum paragraph, repeated.** It exercises only paragraph parsing. Real posts have headings, lists, code, tables, links and images. Those are the expensive and divergent parts of a markdown renderer.
3. **The front matter has only `title` and `date`, and every post has the same date.** Nothing sorts, formats or loops over metadata, so collection handling and template logic are barely exercised. The index order is undefined.

This spec defines one **reference site**. Every generator builds it with the same pages, the same HTML structure and the same static assets from the same deterministic content. The site is designed to make each generator do as much representative build work as possible while staying fair, meaning no generator gets work that another can skip.

The reference site supersedes the "minimal site" rule of `001`/`002`/`003` (Global Constraints: "base layout + post template + index listing posts"). The fairness invariants of those specs stay in force: no themes or plugins beyond the reference templates and the per-generator baseline dependency set (plan, "Baseline dependency set"), no minification, no speed tweaks, and a post page that lists no other posts.

## Contract ownership

| Contract | Owner |
|---|---|
| Reference content model: body grammar, word selection, front matter fields, dates, file names, `-cs` block semantics | **this spec** (`plan.md`, "Content model") |
| Page types, HTML skeleton, stable selectors, literal reference output, static assets, template logic, profiles and the Core/Extended feature lists | **this spec** (`plan.md`) |
| Marker strings printed by `build.sh`, `benchmark_config.json` schema, Dockerfile skeleton | `docs/specs/001-canonical-build-runner/plan.md` |
| Conformance rules, normalizations, `tools/check_conformance.py`, `SSGBERK_CONFORMANCE_*` semantics | `docs/specs/006-layout-conformance` |
| Suites, metrics, protocol, statistics, results schema | `benchmark-tool/docs/specs/008-benchmark-methodology` |

`build.sh` remains the single owner of content generation at runtime (001 contract). This spec defines *what* it must generate, and Task 2 implements that inside `build.sh`.

## Goals & success criteria

1. All 17 generators build the same Core reference site: hugo, gatsby, jigsaw, nikola-mako, jekyll, nanoc, middleman, metalsmith-handlebars, metalsmith-nunjucks, zola, astro, eleventy, hexo, nextjs-export, vitepress, pelican and mkdocs. *Measured by:* `tools/check_conformance.py --profile core` (spec 006) exits 0 for each generator at `-nf 10 -cs 0.500` and `-nf 100 -cs 500`.
2. Content is deterministic. *Measured by:* two runs of the `build.sh` content generator with the same `number_of_files`, `content_size` and `content.type` produce byte-identical content folders (SHA-256 of the sorted file list and contents).
3. Every Core feature is natively implementable by all 17 generators. *Measured by:* the capability matrix in `plan.md` has ✅ in every Core cell. A cell whose open question resolves negatively moves its feature to Extended (Requirement R-30).
4. The `-cs` size semantics are unchanged. *Measured by:* body bytes per post = 512 × blocks, with blocks = 1 / 10 / 100 / 1000 / 2000 / 10000 / 20000 / 200000 for `-cs` 0.500 / 5 / 50 / 500 / 1000 / 5000 / 10000 / 100000.

## Requirements

### Profiles

- **R-1** There are exactly two profiles. **Core** is mandatory for every generator. **Extended** is optional, is reported as a separate result series (008), and is Core plus one or more Extended features from R-27.
- **R-2** The Core feature list is exactly: C1 layout inheritance with header and footer partials; C2 rich markdown body; C3 front matter fields rendered; C4 date formatting; C5 single full index sorted by date descending; C6 per-page conditional (nav `aria-current`) and the tag loop; C7 404 page; C8 verbatim static assets; C9 post page isolation. Each is defined in `plan.md` ("Core features").
- **R-3** A Core build uses only the generator, its baseline dependency set (`plan.md`) and site files: templates, configuration and user code in the generator's own configuration language. "User code" means code such as `gatsby-node.js`, metalsmith `index.js`, `eleventy.config.js`, nanoc `Rules` or Hugo templates. Enabling a built-in renderer extension is allowed and is not a plugin, for example Python-Markdown `tables` or kramdown GFM input. Adding any package outside the baseline set is not allowed.
- **R-4** Core disables any work the reference site does not need, where the generator does it by default and a configuration switch exists. This covers syntax highlighting, RSS/Atom feeds, sitemaps, taxonomy/tag/category/author/archive pages, index pagination, search indexes and image processing. The per-generator switches are listed in `plan.md` ("Core switches").
- **R-5** No minification, asset fingerprinting, CSS/JS bundling of the reference stylesheet, or image processing in either profile. Assets are copied verbatim.

### Content (generated by `build.sh`)

- **R-6** Each post body is the concatenation of B identical-shape **blocks**. B depends only on `content_size`: `0.500`→1, `5`→10, `50`→100, `500`→1000, `1000`→2000, `5000`→10000, `10000`→20000, `100000`→200000. Any other value exits non-zero, as today.
- **R-7** Every block is exactly 512 bytes of ASCII and contains, in this order: an h2, a paragraph with emphasis, strong, inline code and an inline link, an h3, a nested unordered list, a nested ordered list, a blockquote, a tilde-fenced code block with info string `text`, a two-column pipe table, an image referencing `/assets/ssgberk.png`, a closing paragraph and a thematic break. The exact template is in `plan.md` ("Block template").
- **R-8** Words in titles, summaries and blocks come from a fixed 32-word vocabulary. The word index is `(i*7919 + k*104729 + j*1009) mod 32`, where i is the post index (1-based), k the block index (1-based, 0 for front matter) and j the slot index. No random number generator is used.
- **R-9** Post i has date `2026-01-01T00:00:00Z − i minutes`, written as `YYYY-MM-DDTHH:MM:SSZ` (UTC). Dates are unique and strictly decreasing in i, and all are in the past. The file name is `<YYYY-MM-DD of that date>-<NNN>.<extension>`, where NNN is i zero-padded to the width of `number_of_files` (as `seq -w`).
- **R-10** Every post carries the fields `title`, the date field (key `metadata_dateslug`), `summary`, `author` and `tags`, with the values defined in `plan.md` ("Front matter values"). Each content type carries them in the exact layout given there: `3minus` YAML, `3plus` TOML with an `[extra]` table, `2dot` reST-comment style. `none` carries no fields.
- **R-11** A Core-conformant generator does not use `content.type: none`. mkdocs moves from `none` to `3minus` in its 006 migration task.
- **R-12** Everything in the body that renders as text uses only ASCII letters, digits, space, `.`, `=` and `+`. Markdown syntax characters appear only as syntax, and the only URLs are link destinations `https://example.com/<word>/` and the image path. There are no quotes, dashes, ellipses, braces, `<`, `&`, `$`, `@`, `_`, `:word:` patterns or bare URLs. This keeps typographers (kramdown, Hugo, Astro and Hexo smart quotes), template engines that pre-process markdown (Liquid in Jekyll and Eleventy, Nunjucks in Hexo, Vue in VitePress), autolinkers (goldmark linkify), emoji shortcodes and attribute-list syntaxes (kramdown IAL, Python-Markdown `attr_list`) from changing the text.
- **R-13** Heading text is unique within a post: each heading carries the zero-padded block number. This prevents id de-duplication loops that are quadratic in the number of equal headings (Python-Markdown `toc`) from dominating large `-cs` builds.

### Pages and HTML

- **R-14** The site has exactly these generated HTML pages: one **index** at the output root (`index.html`), one **post page** per post, and one **404 page** at `404.html` in the output root. In Core, any other HTML page is a conformance failure, except files the generator always emits and cannot switch off. Those are listed per generator in `plan.md` ("Unavoidable extra output") and the checker in 006 ignores them.
- **R-15** Every page uses the base layout, with document order `header.site-header`, then `main.site-main`, then `footer.site-footer`, each exactly once. The header contains `a.site-title` and `nav.site-nav` with exactly 3 links, in this order: Home `/`, Posts `/#posts`, Source `https://github.com/ssgberk`. On the index only, the Home link has `aria-current="page"`.
- **R-16** The `<head>` has `<meta charset="utf-8">`, the `<title>` given in `plan.md` for that page type, and exactly one `<link rel="stylesheet" href="/assets/ssgberk.css">`. Generator-injected `<script>`, `<meta>`, `<link rel="preload|modulepreload|icon">` and wrapper elements are allowed and ignored by the checker (006).
- **R-17** The post page contains `article.post` with the children `h1.post-title`, `p.post-meta` (with `time.post-date[datetime]` and `span.post-author`), `ul.post-tags` (one `li.post-tag` per tag, in front matter order, as plain text in Core) and `div.post-body` (the rendered markdown). The values are formatted as in `plan.md`.
- **R-18** A Core post page contains no `ol.post-list`, no `li.post-item` and no link to any other post page.
- **R-19** The index contains `section#posts.posts` with `h1.page-title` "Posts" and exactly one `ol.post-list` holding N `li.post-item` elements, ordered by date descending, so post 1 comes first. Each item has `h2.post-item-title > a[href]` resolving to that post's page, `time.post-item-date[datetime]` and `p.post-item-summary`. The index renders no post body.
- **R-20** The 404 page contains `section.not-found` with `h1.page-title` "Page not found" and one link to `/`.
- **R-21** `<time>` elements have `datetime` = the post date as `YYYY-MM-DDTHH:MM:SSZ` and text content = `YYYY-MM-DD`, both in UTC.

### Static assets

- **R-22** The output contains `assets/ssgberk.css` and `assets/ssgberk.png`, byte-identical to `reference/assets/ssgberk.css` and `reference/assets/ssgberk.png`. Each generator directory commits byte-identical copies in its static folder, and CI enforces this (Task 4).
- **R-23** The stylesheet is the literal file in `plan.md` ("Stylesheet"). Its tokens are CSS custom properties on `:root`, and it has no `@import`, no web fonts, no `url()` and no vendor prefixes.

### Templates

- **R-24** Every generator implements the partial structure: one base layout, a `header` partial and a `footer` partial included from the base layout, plus one page template per page type that inherits from or wraps the base layout. Where the template language has no inheritance (Handlebars, JSX, Vue, Astro), composition with components or partial blocks satisfies this.
- **R-25** Template logic required at build time: a loop over all posts with a sort by date descending (index), a loop over tags (post page), a conditional for `aria-current` (header partial, parameterized by page type) and date formatting to both fixed formats (R-21). All of it runs during the build, in templates, helpers, filters or site-local code. Where the template language has no date or sort facility (Handlebars, Nunjucks), a helper, a filter or site-local code does the work. `build.sh` must not pre-render these values into the content, and no committed file may contain them pre-rendered.
- **R-26** The rendered HTML is structurally equivalent to the literal reference output in `plan.md`. Equivalence is defined and checked by 006. Byte equality is not required.

### Extended

- **R-27** The Extended feature ids are: `E1-tag-pages` (one page per tag at `tags/<tag>/index.html` listing its posts in index format, with post tags rendered as links to them), `E2-pager` (`nav.post-pager` with prev/next links on post pages), `E3-excerpt` (`p.post-item-excerpt` on the index, holding the first paragraph of the body extracted by the generator), `E4-highlight` (syntax highlighting of fenced code at build time) and `E5-feed` (an RSS 2.0 or Atom feed at `feed.xml` with N entries). Exact selectors are in `plan.md` ("Extended features").
- **R-28** In Extended, a first-party plugin is allowed when the generator has no native mechanism for a declared feature. First-party means published by the generator's own organisation. Each such plugin is listed in the generator README. Third-party plugins are not allowed in either profile.
- **R-29** A generator declares the Extended features it implements in `benchmark_config.json` (`config[0].profiles.extended.features`). The schema amendment is owned by 001 and drafted by 006.

### Governance

- **R-30** If any Core cell of the capability matrix turns out to be ❌ for a generator (an open question resolves negatively, or a new generator from SF issues #92–#138 cannot implement it), that feature moves to Extended for everyone in a revision of this spec. A generator never gets a Core exemption.
- **R-31** A new generator, including the 46 proposed in #92–#138 (tracking #116), is accepted only if it passes Core conformance.

## Out of scope

- Visual design quality. The stylesheet exists to be copied, not admired, and nothing measures rendering in a browser.
- Client-side behaviour: JS hydration, routing, prefetching. JS generators' runtime bundles are allowed output, but nothing checks them.
- Multi-language sites, pagination of the index, search, comments, analytics, image resizing and MDX/JSX inside content.
- The benchmark protocol (008) and the checker implementation (006).
- Porting the templates of each generator. That is done by the migration tasks of 006, one per generator.

## Open questions

1. **Next.js baseline.** Next.js has no content layer. Its baseline (`gray-matter` + `marked`, already used by 003) is third-party by necessity. Should the baseline instead follow the official Next.js blog example (`gray-matter` + `remark` + `remark-html`), which renders closer to remark in Gatsby? *Proposal:* keep `marked`. It renders CommonMark + GFM tables natively, and the conformance checker validates it.
2. **Pelican tags with YAML block lists.** Python-Markdown `meta` (Pelican's reader) does not parse YAML. `tags:` followed by `    - hotel` lines reaches Pelican as a list of strings with a leading `- ` (for example `"- hotel"`), and `summary` is rendered as markdown. *Proposal:* the Pelican template strips the prefix (`tag.name[2:]`) and uses `article.summary|striptags`. To be confirmed by the Pelican migration task in 006. Fallback: a dedicated `3minus-meta` content type, which would be a revision of R-10.
3. **Nikola 404 page.** Nikola has no special 404 page. The plan uses a page with `.. slug: 404` and `.. pretty_url: False` so it lands at `404.html`. Per-page `pretty_url` is documented in Nikola's metadata list but has not been tried with Nikola 8.3.3.
4. **Metalsmith 404 page.** `@metalsmith/permalinks` must leave `404.html` alone, either with `permalink: false` front matter or a `match` pattern. To be confirmed by the metalsmith migration tasks in 006.
5. **VitePress highlighting.** VitePress always runs Shiki. Overriding `markdown.highlight` with an identity function is believed to bypass it (markdown-it option), but this is not documented in the VitePress site config reference. If it cannot be bypassed, VitePress does extra Core work. That would be recorded as a fairness note in its README and in 008's validity threats, not as an exemption, because highlighting cannot be switched off.
6. **VitePress structure.** The reference markup needs a custom theme (`.vitepress/theme/index.js` exporting a `Layout` component) instead of the default theme. Custom themes are native in VitePress. Whether the `div#app` wrapper and the injected header anchors stay within 006's normalizations is to be confirmed by the VitePress migration task in 006.
7. **MkDocs index.** The index loops over the `pages` template global (`File` objects; `file.page.meta`) and sorts with Jinja `sort(attribute='page.meta.date', reverse=True)`. MkDocs documents `pages` as including all pages. Whether `meta` is populated for every page when the index renders depends on MkDocs reading all pages before rendering any. MkDocs 1.6 does this, but the docs do not promise it.
8. **Zola top-level keys.** `3plus` puts `summary`, `author` and `tags` under `[extra]` because Zola reserves top-level keys and has `[taxonomies]` for tags. Zola also has a native `authors` list. *Proposal:* keep `[extra]` so that one TOML layout serves Core. Extended `E1-tag-pages` in Zola adds `[taxonomies]` through a Zola-only config (`--config`).
9. **Minute-step dates.** Neighbouring posts share the displayed `YYYY-MM-DD` (1440 posts per day). Ordering is checked on the full `datetime` attribute, so this is only cosmetic.

## Decisions log

| Date | Decision | Reason |
|---|---|---|
| 2026-10-04 | Markdown pre-processing stays ON in Core | it is the realistic default cost users pay, and the reference content is safe for it, since the body uses only `[A-Za-z0-9 .=+]` |
| 2026-10-05 | added -cs 5 and 50 (site-size scenarios P/M/G/GG), decided by the maintainer | `5` = 10 blocks (5 120 body bytes), `50` = 100 blocks (51 200); every existing value unchanged |
