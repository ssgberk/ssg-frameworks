# 006 Layout Conformance — Plan

Spec: `spec.md`. Tasks: `tasks.md`. This plan owns the conformance rules, failure codes, normalizations, sampling and the checker design. It drafts the 001 contract amendments ("Contract drafts for 001"). After Task 8 those amendments live in `docs/specs/001-canonical-build-runner/plan.md`, and this file only references them. The reference site itself (selectors, counts, content model) is owned by `docs/specs/005-reference-site-design/plan.md` and is never restated here beyond the names the checker needs.

## Architecture

```
build.sh (001)
  generate content (005) ─▶ clean ─▶ verification build ─▶ count check (SSGBERK_VERIFY_*)
                                                             │
                                                             ▼
             python3 ./check_conformance.py --output … --content … --profile $profile …
                ├─ sources.py-like section: parse content folder (3minus / 3plus / 2dot)
                ├─ tree.py-like section: tolerant HTML tree (html.parser) + tiny selector engine
                ├─ checks: skeleton, index, posts (sample), body text + structure, 404, assets, extra HTML, Extended
                └─ prints SSGBERK_CONFORMANCE_OK | _FAIL <code> <detail> | _PENDING …   exit 0 | 1 | 2
                                                             │ (exit ≠ 0 and enforce)
                                                             ▼
                                              reset content, exit 1 — hyperfine never runs
```

The checker is one file (R-1), so it can be copied verbatim into each generator directory like `build.sh`. The "sections" above are top-level functions in that file, grouped by comment banners, not modules.

## Contract drafts for 001

Task 8 adds these drafts to `docs/specs/001-canonical-build-runner/plan.md`, section "Contracts", verbatim.

### Markers (added to the marker contract)

| Marker | Printed by | Meaning |
|---|---|---|
| `SSGBERK_CONFORMANCE_OK profile=<core\|extended> posts=<N> sampled=<k> features=<list\|->` | checker via `build.sh` | conformant; timing follows |
| `SSGBERK_CONFORMANCE_FAIL <code> <detail>` | checker via `build.sh` | non-conformant; `build.sh` exits 1, no `SSGBERK_RESULT_*` |
| `SSGBERK_CONFORMANCE_PENDING <code> <detail>` | checker in `report` mode | migration not finished; informational, timing follows |
| `SSGBERK_PROFILE_UNSUPPORTED <profile>` | `build.sh` | the generator does not declare that profile; `build.sh` exits 3 |

Updated list for the 001 "Result markers" constraint line: `SSGBERK_RESULT_BEGIN`, `SSGBERK_RESULT_END`, `SSGBERK_VERIFY_FAIL`, `SSGBERK_CONFORMANCE_FAIL`, `SSGBERK_PROFILE_UNSUPPORTED`, `STARTTIME <epoch>`, `ENDTIME <epoch>`.

### `benchmark_config.json` additions (`config[0]`, all optional, backward compatible)

```json
{
  "static_folder": "static",
  "allow_extra_html": ["404/index.html"],
  "conformance": "enforce",
  "profiles": {
    "extended": {
      "features": ["E1-tag-pages", "E2-pager", "E3-excerpt", "E4-highlight", "E5-feed"],
      "build_command": "<cmd>",
      "build_verbose": "<cmd>",
      "output_glob": "<glob>",
      "cache_folders": ["<dir>"]
    }
  }
}
```

| Key | Type | Default | Meaning |
|---|---|---|---|
| `static_folder` | string | none | Generator-relative folder whose `assets/ssgberk.{css,png}` are copied verbatim to the output root (`static`, `public`, `source`, `files`, `docs`…) |
| `allow_extra_html` | string[] (globs relative to `output_folder`) | `[]` | Extra HTML the generator cannot switch off; restricted to the 005 table "Unavoidable extra output" |
| `conformance` | `"enforce"` \| `"pending"` | `"enforce"` | `pending` runs the checker in `report` mode (migration only; removed by Task 27) |
| `profiles.extended.features` | string[] | none | Extended feature ids (005 R-27) the generator implements |
| `profiles.extended.*` other keys | as in `config[0]` | Core values | Overrides used when `profile=extended` |

### Dockerfile skeleton changes

Common packages line gains `python3`:

```dockerfile
      build-essential ca-certificates curl git jq moreutils python3 tree wget xz-utils \
```

Last line becomes:

```dockerfile
COPY build.sh check_conformance.py benchmark_config.json /opt/<name>/src/
```

### `build.sh` environment

New optional env var `profile` (`core` | `extended`, default `core`), set by the toolset (`benchmark-tool` 008 Task 2).

## Failure codes

| Code | Rule | Detail example |
|---|---|---|
| `usage` | bad CLI or config (exit 2) | `--posts must be a positive integer` |
| `source-count` | R-15 | `expected=10 got=9` |
| `source-parse` | R-15 | `file=2025-12-31-03.md missing field summary` |
| `skeleton` | R-5 | `page=index.html header.site-header count=0` |
| `nav` | R-5 | `page=posts/1/index.html link=2 href=/posts/ expected=/#posts` |
| `title` | R-5 | `page=404.html got="404" expected="Page not found \| SSGBerk Reference"` |
| `stylesheet` | R-5 | `page=index.html links=2` |
| `aria-current` | R-6 | `page=posts/1/index.html count=1 expected=0` |
| `index-missing` | R-7 | `index.html not found` |
| `index-count` | R-7 | `li.post-item expected=10 got=9` |
| `index-order` | R-7 | `position=4 2025-12-31T23:55:00Z !> 2025-12-31T23:54:00Z` |
| `index-field` | R-7 | `position=2 field=summary` |
| `index-link` | R-7 | `position=3 href=/posts/3/ unresolved` |
| `index-has-body` | R-7 | `.post-body count=10` |
| `post-missing` | R-7 | `glob matched 9 files, index links resolve to 10` |
| `post-structure` | R-8 | `page=… article.post children=h1,div expected=h1,p,ul,div` |
| `post-field` | R-8 | `page=… field=tags got=hotel,kilo expected=hotel,kilo,november` |
| `post-lists-posts` | R-8 | `page=… .post-item=10` |
| `post-links-post` | R-8 | `page=… href=/posts/2/` |
| `body-text` | R-9 | `page=… token=17 expected=quart got=` |
| `body-structure` | R-10 | `page=… table expected=1 got=0` |
| `404-missing` | R-11 | `404.html not found` |
| `404-structure` | R-11 | `section.not-found h1.page-title count=0` |
| `asset-missing` | R-13 | `assets/ssgberk.png` |
| `asset-mismatch` | R-13 | `assets/ssgberk.css sha256=…` |
| `extra-html` | R-14 | `tags/alpha/index.html` |
| `extended-tag-pages` / `extended-pager` / `extended-excerpt` / `extended-highlight` / `extended-feed` | R-16 | feature-specific |
| `truncated` | R-3 | `<k> more` |

## Tree building

`html.parser.HTMLParser(convert_charrefs=True)` feeds a minimal tree builder (`Node(tag, attrs: dict, children, parent)`; text nodes are strings):

- Tag and attribute names are lower-cased by the parser. Attribute order is irrelevant because attrs is a dict, and duplicate attributes keep the first value.
- Void elements never get children: `area base br col embed hr img input link meta source track wbr`.
- Implied end tags, the subset of the HTML spec that the renderers in this repo produce:
  - a `p` start closes an open `p`;
  - a start of `address article aside blockquote div dl fieldset footer form h1 h2 h3 h4 h5 h6 header hr main nav ol p pre section table ul` closes an open `p`;
  - an `li` start closes the nearest open `li` up to the nearest `ul`/`ol`;
  - `tr`, `td` and `th` likewise close their open siblings within the nearest `table`.
- An end tag pops to the nearest open element with that name. An unmatched end tag is ignored.
- `<!doctype>`, comments and processing instructions are dropped.

### Selector engine

This is not CSS: the supported grammar is exactly the following, which is enough for every 005 selector. A compound is `tag?` + any number of `.class`, `#id`, `[attr]`, `[attr=value]` (value unquoted or double-quoted). Combinators are descendant (whitespace) and child (`>`). Functions: `select(root, sel) -> list[Node]` in document order, `count`, `text(node)` (text nodes in the subtree joined with a space, whitespace collapsed, stripped) and `children(node) -> list[Node]` (element children only).

## Href resolution

For a link `href` on any page:

1. Ignore links whose scheme or authority is set (`https://…`) and pure fragments (`#…`).
2. Strip `?query` and `#fragment`, then percent-decode.
3. Root-relative (`/a/b/`) maps to `output/a/b/`. A relative href resolves against the page's directory.
4. A trailing `/` gets `index.html` appended. Otherwise try, in order, the path as is, `<path>.html` and `<path>/index.html`. The first existing regular file wins. The second form covers VitePress clean URLs.
5. Unresolved means a failure where the rule needs the target (`index-link`). Otherwise the link is ignored.

Post-page identity is the set of files matching `--post-glob` (`fnmatch` on the path relative to `--output`, the same semantics as 001 `find -path`).

## Source parsing

The checker parses only the 005 layouts (it is not a general front matter parser):

- `3minus`: the first line is `---`, then an optional layout line, then `key: value` lines and the `tags:` block (`    - <tag>` lines) up to the closing `---`. The date field is `--dateslug`. Values are taken verbatim; no YAML typing is applied.
- `3plus`: the text between the `+++` lines is parsed with `tomllib`. `title` and the dateslug key are top-level (the date becomes a `datetime`, re-formatted `%Y-%m-%dT%H:%M:%SZ`), and `extra.summary`, `extra.author`, `extra.tags` hold the rest.
- `2dot`: leading `.. key: value` lines up to the first blank line. A line without `:` is the layout line and is skipped. `tags` is split on `, `.
- Post index i: the integer value of the `NNN` part of the file name. The body is everything after the header. B = body bytes / 512 (it must divide exactly, or the failure is `source-parse`).

## Normalizations

These are applied only to the body text comparison (R-9). Fields compared in R-7 and R-8 use `text()` with whitespace collapsing only.

**Expected tokens, from the source body:**

1. Delete lines matching `^~~~` (fence lines, including the info string `text`), `^\|[-|]+\|$` (table delimiter row) and `^\* \* \*$` (thematic break).
2. Delete list markers at line start: `^\s*(?:\d+\.|-)\s`.
3. Delete images `!\[[^\]]*\]\([^)]*\)` (alt text is an attribute in HTML, not text).
4. Replace links `\[([^\]]*)\]\([^)]*\)` with `\1` (link text stays; the destination is an attribute).
5. Tokens = `re.findall(r"[0-9A-Za-z]+", text)`, each `casefold()`ed.

**Actual tokens, from `div.post-body` in the output:**

1. Entities are decoded by the parser (`convert_charrefs=True`), so `&amp;`, `&#39;`, `&quot;` and `&#x2014;` compare as their characters.
2. Drop entire subtrees of `script`, `style`, `template`, `noscript`, `button` and `svg`; of elements with `aria-hidden="true"`; and of elements whose class list contains `header-anchor`, `headerlink`, `anchor` or `lang`. These cover VitePress header anchors and the code-language label, Python-Markdown `toc` permalinks when enabled, and highlighter chrome.
3. Text nodes are joined with a single space, so element boundaries separate tokens (`<td>blaze</td><td>maple</td>` gives two tokens).
4. Apply `unicodedata.normalize("NFKC", …)`, then delete U+200B, U+200C, U+200D, U+2060 and U+FEFF.
5. Tokens = `re.findall(r"[0-9A-Za-z]+", text)`, each `casefold()`ed.

Hash = `sha256("\n".join(tokens).encode())`. Why this tolerates the known renderer differences while still catching dropped or duplicated content:

| Difference | Why it is tolerated |
|---|---|
| heading ids, `class="language-text"`, attribute order, `rel`/`target` on links | attributes never become tokens |
| smart quotes, en/em dashes, ellipses, `&nbsp;` | non-alphanumeric, so they never become tokens; 005 R-12 keeps the source free of them |
| entity encoding | decoded before tokenizing |
| whitespace, line breaks, indentation, loose vs tight lists (`<li><p>`) | tokens ignore whitespace and wrappers |
| generator meta tags, injected scripts, preload links | outside `div.post-body`, or dropped subtrees |
| VitePress anchors (`<a class="header-anchor">​</a>`) and `<span class="lang">text</span>` | dropped subtrees (rule 2) and zero-width removal (rule 4) |
| highlighting spans (Extended E4) | text is unchanged, only wrapped |
| ordered list numbers | CSS counters, not text; source markers are removed by rule 2 |

Not tolerated, by design: a missing or duplicated block, a table rendered as literal pipes (extra tokens `key value` stay equal but `body-structure` fails on `table` = 0), unrendered emphasis (`*maple*` stays as text: equal tokens, but `em` = 0 fails `body-structure`), raw markdown in the output, and truncated bodies.

## Sampling (R-12)

```python
def sample(n, body_bytes_of):            # body_bytes_of(i) -> int
    step = max(1, -(-n // 98))           # ceil(n / 98)
    order = [1, n] + [i for i in range(1, n + 1, step) if i not in (1, n)]
    chosen, used = [], 0
    for i in order:
        b = body_bytes_of(i)
        if i in (1, n) or (used + b <= 50_000_000 and len(chosen) < 100):
            chosen.append(i); used += b
    return sorted(set(chosen))
```

With `--all`, every post is chosen. Index, 404, assets, extra-HTML and link resolution always cover the whole site.

## Mutation fixtures

`tests/conformance/reference_render.py` is a stdlib-only renderer of the 005 reference site for the 005 content grammar. It is the oracle that turns a content folder into an output tree. Its output for N = 3 is byte-identical to `reference/html/*` (pinned by `test_renderer_matches_reference_html`). Every fixture starts from `generate(N=3)` + `render()` into a temp dir, then applies one mutation:

| Fixture | Mutation | Expected |
|---|---|---|
| `good` | none | exit 0, `SSGBERK_CONFORMANCE_OK profile=core posts=3 sampled=3 features=-` |
| `tolerated-wrappers` | wrap body content in `div#___gatsby > div#gatsby-focus-wrapper` and `main` content in `div` | exit 0 |
| `tolerated-renderer` | add heading ids, `rel="noopener"`, smart-quote entities between words, reorder attributes, emit `<li><p>…</p></li>`, insert VitePress `a.header-anchor` (U+200B text) and `span.lang` | exit 0 |
| `tolerated-meta` | add `<meta name="generator">`, `<script>`, `<link rel="modulepreload">` | exit 0 |
| `no-aria-current` | remove `aria-current` from index | `aria-current` |
| `aria-on-post` | add `aria-current` on a post page | `aria-current` |
| `index-swapped` | swap items 2 and 3 | `index-order` |
| `index-short` | drop one `li.post-item` | `index-count` |
| `index-bad-summary` | change one summary word | `index-field` |
| `index-dangling` | point a link at a missing file | `index-link` |
| `post-list-on-post` | add the full `ol.post-list` to post 1 | `post-lists-posts` |
| `post-link-on-post` | add `<a href="/posts/2/">` to post 1 | `post-links-post` |
| `missing-tag` | drop one `li.post-tag` | `post-field` |
| `wrong-date-format` | `time` text `Dec 31, 2025` | `post-field` |
| `body-word` | change one body word | `body-text` |
| `body-dup-block` | duplicate block 1 | `body-text` |
| `table-as-text` | replace `<table>` with `<p>| Key | Value |…</p>` | `body-structure` |
| `no-404` | delete `404.html` | `404-missing` |
| `css-modified` | append a byte to the CSS | `asset-mismatch` |
| `png-missing` | delete the PNG | `asset-missing` |
| `extra-tag-page` | add `tags/alpha/index.html` | `extra-html` |
| `two-stylesheets` | add a second stylesheet link | `stylesheet` |
| `no-footer` | delete `footer.site-footer` | `skeleton` |
| `bad-title` | change `<title>` on 404 | `title` |
| `source-missing-field` | drop `summary:` from a source | `source-parse` |
| `extended-feed-missing` | `--profile extended --features E5-feed` without `feed.xml` | `extended-feed` |

## Decisions

| Decision | Chosen | Alternatives considered |
|---|---|---|
| Where the checker runs | Inside the generator container, from `build.sh` | In the toolset container after copying the output out (`docker cp` of up to tens of GB; also splits the verification step across repos) |
| Language | Python 3 stdlib | bash + `xmllint`/`pup` (extra packages, weaker HTML handling); Node (absent from 9 of the 17 images) |
| HTML equivalence | selector counts + word-sequence hash + element counts | byte or DOM equality (fails on every renderer difference); visual diffs (needs a browser) |
| Mapping posts | via index links + glob | fixed URLs (005 decided URLs are free) |
| Sampling | deterministic, byte-budget | all posts always (reads 10 GB at `-nf 10000 -cs 500`); random (non-reproducible failures) |
| Rollout | `conformance: pending` → `enforce` per generator | big-bang (blocks all benchmarks until 17 ports are done) |
| Per-generator ignore rules | none (generic list in Normalizations) | config key `ignore_text_selectors` (spec open question 2) |
| Expected tokens | derived from the source files on disk | recomputed from the 005 formulas (a second implementation that could drift) |

## Risks

1. **Tree builder misnests unusual markup** (for example a renderer emitting `<p>` inside `<li>` without closing). Mitigation: the implied-end-tag subset above, the `tolerated-renderer` fixture, and real outputs captured from the first three migrated generators (hugo, jekyll, gatsby) added as regression fixtures in their migration tasks.
2. **A generator legitimately renders a body construct differently** (for example Python-Markdown wrapping `img` without `p`). `body-structure` counts never include `p`, so this passes. If a counted element differs, the migration task records the evidence and either the template config fixes it or 005 is revised for everyone (005 R-30).
3. **Checker runtime at large `-cs`.** One post at `-cs 100000` is about 100 MB of HTML. The byte budget keeps the sample to posts 1 and N (about 200 MB parsed, roughly a minute). Accepted, because the checker is untimed.
4. **The marker is printed but BT ignores it** before BT 008 Task 3 lands. `build.sh` exits 1 anyway, and the missing `SSGBERK_RESULT_*` already sends the generator to `failed` (BT 002 behaviour).

## Cross-references

- Reference site (selectors, counts, titles, content model, extra-HTML allowlist, Core switches): `docs/specs/005-reference-site-design/plan.md`.
- Marker contract, schema, skeleton (after Task 8): `docs/specs/001-canonical-build-runner/plan.md`.
- Toolset parsing of `SSGBERK_CONFORMANCE_FAIL` / `SSGBERK_PROFILE_UNSUPPORTED`, `--profile`: `benchmark-tool/docs/specs/008-benchmark-methodology` Tasks 2–3. Base parser: `benchmark-tool/docs/specs/002-hyperfine-results`.
- Smoke procedure: `docs/specs/001-canonical-build-runner/plan.md`, "Generator smoke procedure".
