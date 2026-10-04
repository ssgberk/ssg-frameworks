# 006 Layout Conformance — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `tools/check_conformance.py` validates every build against the 005 reference site before timing. `build.sh` runs it and fails the run on violations. All 17 generators are ported to the reference site and pass Core.

**Architecture:** A single-file Python 3 stdlib checker (tolerant HTML tree, tiny selector engine, source parsers for the three 005 front matter layouts, normalized word-hash body comparison, deterministic sampling) is copied byte-identically into every generator directory and run from the canonical `build.sh` after `SSGBERK_VERIFY_OK`. Rules and formats are in `plan.md`. Generators move from `conformance: pending` to `enforce` one migration task at a time.

**Tech Stack:** Python 3.12 stdlib (`unittest` for tests), bash, jq, Docker (smoke), hyperfine 1.20.0.

**Spec:** `docs/specs/006-layout-conformance/spec.md` and `plan.md`, plus `docs/specs/005-reference-site-design/plan.md` (repo `ssgberk/ssg-frameworks`). Read all three before starting any task.

In this file **BT** = `/Users/jobs/Dev/ssgberk/.worktrees/benchmark-tool-modernize` (repo `ssgberk/benchmark-tool`, branch `chore/modernize-2026`) and **SF** = `BT/frameworks` (repo `ssgberk/ssg-frameworks`, branch `chore/modernize-2026`).

Prerequisites: 005 Tasks 1–2 are done (reference assets and HTML, rich content in `build.sh`, `SSGBERK_GENERATE_ONLY`).

## Global Constraints

- Git author/committer `Matheus Breguêz <matbrgz@gmail.com>`; every commit GPG-signed (repo config already has `commit.gpgsign=true`, key `B6FA8458D5176E83`). Never use `--no-gpg-sign` or `--author`.
- Every commit message ends with the trailer `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Never commit to `master`. Never push, open PRs, or close dependabot branches unless the human explicitly asks.
- `tools/check_conformance.py` imports only these modules: `argparse`, `fnmatch`, `hashlib`, `html`, `html.parser`, `json`, `os`, `pathlib`, `re`, `sys`, `tomllib`, `unicodedata`, `urllib.parse`, `xml.etree.ElementTree`.
- Every generator's `build.sh` is byte-identical to `SF/Go/hugo/build.sh`, and every generator's `check_conformance.py` is byte-identical to `SF/tools/check_conformance.py` (both enforced by `tools/check-build-sh.sh` after Task 9).
- Marker strings are exactly those in `plan.md` "Contract drafts for 001" (owned by 001 after Task 8). Never invent new ones in a task.
- Only ONE smoke run at a time on the machine. Smoke procedure: `docs/specs/001-canonical-build-runner/plan.md` "Generator smoke procedure".
- Generator sites follow 005: no plugins outside the 005 baseline set, no themes, no minification, assets copied verbatim.

## Review Focus

1. **Tolerance that hides missing work.** A normalization that drops too much (for example all `span`s) would let an empty body pass. Pinned by `body-word`, `body-dup-block` and `table-as-text` fixtures in Task 6.
2. **Strictness that rejects real renderers.** Pinned by the `tolerated-*` fixtures in Task 5–6 and by the real-output regression fixtures added in Tasks 10, 14 and 11 (hugo, jekyll, gatsby).
3. **Silent pass when the checker is not run.** `build.sh` must run the checker whenever `conformance` is absent or `enforce`. Pinned by `test_build_sh_runs_conformance` in Task 9.
4. **Sampling determinism.** Pinned by `test_sample_deterministic` and `test_sample_budget` in Task 6.

---

### Task 1: Checker CLI, exit codes and markers

**Files (SF):**
- Create: `tools/check_conformance.py`, `tests/conformance/__init__.py`, `tests/conformance/test_cli.py`

**Interfaces:**
- `main(argv: list[str]) -> int`, with CLI as in spec R-2. Exit 0/1/2 as in spec R-2.
- `class Report: fail(code: str, detail: str)`, `ok(profile, posts, sampled, features)` and `emit(mode) -> int`, which prints per spec R-3 and returns the exit code.

- [ ] **Step 1: Write the failing test** — `test_cli.py`: `test_usage_missing_output` (exit 2, stdout `SSGBERK_CONFORMANCE_FAIL usage …`), `test_usage_bad_posts` (`--posts 0` → exit 2), `test_report_truncates_after_20` (25 fails → 20 lines + `SSGBERK_CONFORMANCE_FAIL truncated 5 more`), `test_report_mode_prints_pending_and_exits_0`, `test_ok_line_format` (exact string `SSGBERK_CONFORMANCE_OK profile=core posts=3 sampled=3 features=-`), `test_detail_single_line_max_300` (newlines become spaces, truncated to 300), `test_imports_allowlist` (parse the file with `ast` and compare imports with the Global Constraints list).
- [ ] **Step 2: Run** `python3 -m unittest discover -s tests/conformance -v` → FAIL.
- [ ] **Step 3: Implement** argparse, `Report` and `main`. Checks are stubs that the following tasks fill in.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(conformance): checker CLI and marker output`.

### Task 2: Tolerant HTML tree and selector engine

**Files (SF):**
- Modify: `tools/check_conformance.py`
- Create: `tests/conformance/test_tree.py`

**Interfaces:**
- `parse_html(text: str) -> Node`; `select(node, selector) -> list[Node]`; `count(node, selector) -> int`; `text(node) -> str`; `children(node) -> list[Node]`; `Node.tag`, `Node.attrs`, `Node.classes` (set).

- [ ] **Step 1: Write the failing test** — `test_tree.py`: void elements (`<img><p>x</p>` gives siblings), implied `</p>` before `<ul>`, implied `</li>`, unmatched end tag ignored, entities decoded (`&amp;` → `&`), attribute order irrelevant, selector grammar (`ol.post-list > li.post-item`, `a[aria-current=page]`, `section#posts.posts`, `link[rel=stylesheet][href="/assets/ssgberk.css"]`, descendant vs child), unsupported selector syntax raises `ValueError`, `text()` collapses whitespace.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** per `plan.md` "Tree building" and "Selector engine".
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(conformance): tolerant html tree and selector engine`.

### Task 3: Source parsing for the 005 layouts

**Files (SF):**
- Modify: `tools/check_conformance.py`
- Create: `tests/conformance/test_sources.py`

**Interfaces:**
- `load_sources(content_dir, ctype, dateslug, ext) -> list[Source]`, sorted by index. `Source(index, path, title, date_iso, date_ymd, summary, author, tags: list[str], body: str, blocks: int)`. Raises `SourceError(code, detail)` with code `source-parse`.

- [ ] **Step 1: Write the failing test** — generate content with `SSGBERK_GENERATE_ONLY=1 KEEP_CONTENT=1 number_of_files=3 content_size=0.500 bash Go/hugo/build.sh` in temp dirs for `3minus`, `3plus` and `2dot` (helper `tests/conformance/helpers.py::generate(tmp, n, cs, ctype)`). Tests: all three types give identical `Source` values for post 1 (title `Post 1 amber raven`, date `2025-12-31T23:59:00Z`, tags `['hotel','kilo','november']`, author `Ben South`, blocks 1); `metadata_layout` lines are skipped; a missing `summary` raises `source-parse`; a body of 513 bytes raises `source-parse`; `-cs 500` gives `blocks == 1000`; `metadata_dateslug: created_at` (nanoc) works.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** per `plan.md` "Source parsing".
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(conformance): parse 005 front matter layouts`.

### Task 4: Reference renderer (test oracle) and fixtures helper

**Files (SF):**
- Create: `tests/conformance/reference_render.py`, `tests/conformance/test_reference_render.py`, `tests/conformance/fixtures.py`

**Interfaces:**
- `render(sources: list[Source], out_dir: Path, post_url=lambda s: f"/posts/{s.index}/")` writes `index.html`, `posts/<i>/index.html`, `404.html` and `assets/ssgberk.{css,png}` (copied from `reference/assets/`), with whitespace and markup exactly as `reference/html/*`. The markdown subset it renders is exactly the 005 block grammar. It is a test helper and is never copied into generators.
- `fixtures.make(tmp, n=3, mutate=None) -> (content_dir, output_dir)`.

- [ ] **Step 1: Write the failing test** — `test_renderer_matches_reference_html`: for N=3 `-cs 0.500`, `index.html`, `posts/1/index.html` and `404.html` are byte-identical to `reference/html/index.html`, `post.html` and `404.html`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** the renderer: a line-oriented converter for the 005 block template and the page templates as Python f-strings.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `test(conformance): reference renderer oracle`.

### Task 5: Core page checks (skeleton, index, posts, 404, assets, extra HTML)

**Files (SF):**
- Modify: `tools/check_conformance.py`
- Create: `tests/conformance/test_core_checks.py`

**Interfaces:**
- `check_core(ctx) -> None`, which calls `Report.fail` per `plan.md` "Failure codes" for R-5 to R-8, R-11, R-13, R-14. `ctx` holds args, sources, the output dir, the sample and the resolved link map. `resolve_href(page_path, href, output_dir) -> Path | None` per `plan.md` "Href resolution". `ASSET_SHA256 = {"assets/ssgberk.css": "<hex>", "assets/ssgberk.png": "<hex>"}`.

- [ ] **Step 1: Write the failing test** — one test per fixture row of `plan.md` "Mutation fixtures" except the body and Extended rows. Each asserts the exit code and that the first `FAIL` line starts with the expected code. Plus `good`, `tolerated-wrappers` and `tolerated-meta` → exit 0. Plus `test_asset_constants_match_reference` (hashes of `reference/assets/*` equal `ASSET_SHA256`). Plus `test_resolve_href` (trailing slash, `.html` fallback, `/index.html` fallback, external ignored, fragment stripped).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** the checks in the order of spec R-5 to R-15, reading titles, nav and selectors from constants that mirror 005 plan "HTML skeleton and selectors".
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(conformance): core page checks`.

### Task 6: Body text equivalence, body structure and sampling

**Files (SF):**
- Modify: `tools/check_conformance.py`
- Create: `tests/conformance/test_body.py`

**Interfaces:**
- `expected_tokens(md_body: str) -> list[str]`; `actual_tokens(post_body: Node) -> list[str]`; `token_hash(tokens) -> str`; `body_counts(post_body: Node) -> dict[str, int]`; `sample(n, body_bytes_of) -> list[int]` (code in `plan.md` "Sampling").

- [ ] **Step 1: Write the failing test** — `test_expected_tokens_block1` (the literal 005 block 1 gives exactly `chapter 000001 zebra karma text blaze maple dunes ocean flint quart birch solar delta fjord note 000001 waltz haven yield jolly acorn lemon coral north eagle prism amber raven cedar tiger ember vivid grove xenon inlet zebra karma key value blaze maple tail flint quart birch solar delta ultra fjord waltz haven yield jolly acorn lemon coral`); `test_actual_tokens_reference_post` (same list from `reference/html/post.html`); fixtures `tolerated-renderer` → exit 0, `body-word` and `body-dup-block` → `body-text`, `table-as-text` → `body-structure`; `test_body_counts_cs500` (counts for 1000 blocks); `test_sample_deterministic` (same output twice; N=10 gives all 10; N=10000 with 512 000-byte bodies gives `[1, 98+1…]` within 50 MB and includes 1 and 10000); `test_sample_budget` (N=3 with 100 MB bodies gives `[1, 3]`); `test_all_flag`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** per `plan.md` "Normalizations" and "Sampling". The `body-text` detail is the first differing index and the tokens there.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(conformance): body equivalence, structure and sampling`.

### Task 7: Extended checks

**Files (SF):**
- Modify: `tools/check_conformance.py`
- Create: `tests/conformance/test_extended.py`

**Interfaces:**
- `check_extended(ctx, features: list[str])`. Feature ids exactly as 005 R-27. An unknown id is `usage` (exit 2).

- [ ] **Step 1: Write the failing test** — extend `reference_render.render(..., features=[...])` to emit each Extended feature per 005 plan "Extended features" (tag pages, pager, excerpt, highlight spans, `feed.xml` RSS 2.0). Tests: each feature rendered → exit 0 with `features=<id>`; each feature declared but missing → `extended-<name>`; `tags/alpha/index.html` present with `--profile core` → `extra-html`; with `--profile extended --features E1-tag-pages` → allowed; pager links count as the C9 exception only inside `nav.post-pager`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(conformance): extended feature checks`.

### Task 8: Amend the 001 contract

**Files (SF):**
- Modify: `docs/specs/001-canonical-build-runner/plan.md` (Contracts: marker table, schema block, skeleton common packages and `COPY` line; new subsection "Conformance (spec 006)"), `docs/specs/001-canonical-build-runner/tasks.md` (Global Constraints "Result markers" line), `docs/specs/002-hyperfine-results` is in BT and is **not** edited here.

**Interfaces:**
- Produces: the texts of `plan.md` "Contract drafts for 001" inside 001, verbatim. 006 `plan.md` keeps the drafts until this task, then replaces them with a pointer to 001 ("Owned by 001 since Task 8").

- [ ] **Step 1: Write the failing check** — `grep -c "SSGBERK_CONFORMANCE_FAIL" docs/specs/001-canonical-build-runner/plan.md` prints `0`, and `grep -c "check_conformance.py benchmark_config.json" docs/specs/001-canonical-build-runner/plan.md` prints `0`.
- [ ] **Step 2: Run** → both `0`.
- [ ] **Step 3: Implement** — insert the drafts. In the 001 schema JSON add `static_folder`, `allow_extra_html`, `conformance`, `profiles`. In 006 `plan.md` replace the drafts section body with `Owned by docs/specs/001-canonical-build-runner/plan.md since 006 Task 8.`
- [ ] **Step 4: Run** → `grep -c` prints ≥ 1 for both. `grep -c "Contract drafts for 001" docs/specs/006-layout-conformance/plan.md` still finds the heading, which now only points to 001.
- [ ] **Step 5: Commit** `docs(specs): add conformance markers and schema keys to 001`.

### Task 9: `build.sh` integration and canonical-copy check

**Files (SF):**
- Modify: `Go/hugo/build.sh` (then every `*/*/build.sh`), `tools/check-build-sh.sh`, `tests/build_sh/test_build_sh.sh`, every `*/*/<name>.dockerfile` (skeleton changes from Task 8)
- Create: `*/*/check_conformance.py` (copies), `tests/build_sh/test_conformance_integration.sh`

**Interfaces:**
- `build.sh` after `SSGBERK_VERIFY_OK`:

  ```bash
  profile="${profile:-core}"
  conformance=$(jq -r '.config[0].conformance // "enforce"' "${cfg}")
  mode=enforce; [ "${conformance}" = pending ] && mode=report
  features=$(jq -r '(.config[0].profiles.extended.features // []) | join(",")' "${cfg}")
  allow=$(jq -r '(.config[0].allow_extra_html // []) | join(",")' "${cfg}")
  python3 ./check_conformance.py --output "${output_folder}" --content "${content_folder}" \
      --type "${content_type}" --dateslug "${metadata_dateslug}" --extension "${content_extension}" \
      --posts "${number_of_files}" --post-glob "${output_glob}" --profile "${profile}" \
      ${features:+--features "${features}"} ${allow:+--allow-extra-html "${allow}"} --mode "${mode}"
  conformance_status=$?
  if [ "${conformance_status}" -ne 0 ]; then
      [ -z "${KEEP_CONTENT:-}" ] && reset_content
      exit 1
  fi
  ```

  With `profile=extended`, the overrides from `profiles.extended` are applied right after reading `cfg`. Without `profiles.extended`, `build.sh` prints `SSGBERK_PROFILE_UNSUPPORTED extended` and exits 3 before generating content. `--features` is passed only when `profile=extended`.
- `tools/check-build-sh.sh` also `cmp`s `*/*/check_conformance.py` against `tools/check_conformance.py`.

- [ ] **Step 1: Write the failing test** — `test_conformance_integration.sh` uses the fake generator from `tests/build_sh/test_build_sh.sh` whose "build" runs `python3 tests/conformance/reference_render.py`. `test_build_sh_runs_conformance` expects `SSGBERK_CONFORMANCE_OK` before `STARTTIME`. `test_fail_stops_timing`: a renderer flag drops `aria-current`, so the output has `SSGBERK_CONFORMANCE_FAIL aria-current`, no `STARTTIME`, and exit 1. `test_pending_reports_and_times`: `SSGBERK_CONFORMANCE_PENDING` then `STARTTIME`. `test_extended_unsupported`: `profile=extended` without `profiles` gives `SSGBERK_PROFILE_UNSUPPORTED extended` and exit 3. `test_check_build_sh_flags_checker_copy`: a modified copy makes `tools/check-build-sh.sh` exit 1.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Set `"conformance": "pending"` in every existing generator's `benchmark_config.json`, so nothing breaks before its migration task. Copy `tools/check_conformance.py` into every generator dir. Update every dockerfile (common packages `python3`, the `COPY` line).
- [ ] **Step 4: Run** the tests → PASS; `tools/check-build-sh.sh` → exit 0; smoke one generator (hugo) and confirm `SSGBERK_CONFORMANCE_PENDING` lines and a normal `SSGBERK_RESULT_BEGIN`.
- [ ] **Step 5: Commit** `feat(build.sh): run conformance checker before timing`.

---

## Migration tasks (one per generator)

Standard migration steps. Every task below runs them, each as its own checkbox when tracking:

- [ ] **Failing test:** in the generator dir, `KEEP_CONTENT=1 number_of_files=10 content_size=0.500 min_runs=1 bash build.sh` inside the built image (`docker run --rm ssgberk/test.<name> …`, or the smoke procedure) shows `SSGBERK_CONFORMANCE_PENDING` lines. Save them to the task notes.
- [ ] **Run:** confirm the pending codes list is non-empty (this is the failing state).
- [ ] **Implement:** port the templates to 005 plan "Template structure and logic" using the guidance for the generator's template language. Apply the 005 "Core switches" row. Copy `reference/assets/ssgberk.{css,png}` into `<static_folder>/assets/`. Set `static_folder`, `allow_extra_html` (only entries the 005 table allows) and `"conformance": "enforce"` in `benchmark_config.json`. Remove any leftover pre-005 template (sample links, "News 'n' Updates", Google Fonts).
- [ ] **Pass:** smoke at `-nf 10 -cs 0.500 -mr 1` and at `-nf 100 -cs 500 -mr 1`. `raw.txt` contains `SSGBERK_CONFORMANCE_OK profile=core`, `SSGBERK_VERIFY_OK expected=<n> got=<n>`, and `results.json` lists the generator in `succeeded.datarate`. `tools/check-reference-assets.sh` no longer lists the generator as `pending`.
- [ ] **Record:** in the generator `README.md`, add a "Reference site (005)" section with the template files, the Core switches applied, the resolution of any 005 open question the task names, and any README-level fairness note. Update the 005 capability matrix cell if it was ⚠️ or carried an OQ (separate commit `docs(specs): resolve 005 OQ<n> (<name>)`).
- [ ] **Commit:** `feat(<name>): build the 005 reference site`.

### Task 10: hugo (`Go/hugo`)

**Files:** `src/config.toml`, `src/layouts/_default/baseof.html`, `src/layouts/partials/{header,footer}.html`, `src/layouts/index.html`, `src/layouts/post/single.html`, `src/layouts/404.html`, `src/static/assets/ssgberk.{css,png}`. Delete `src/content/about.md`, `src/data/links.toml`, `src/i18n/en.toml`, `src/layouts/partials/head.html`, `src/static/css/style.css`, `src/layouts/_default/single.html`.
**Interfaces:** `static_folder: "src/static"`; content `3minus`; Core switches row "hugo".
- Steps: Standard migration steps. Extra: capture the real `public/index.html` and one post page into `tests/conformance/real/hugo/` as a regression fixture (exit 0 expected), together with a test case in `test_core_checks.py`.

### Task 11: gatsby (`JavaScript/gatsby`)

**Files:** `src/gatsby-node.js`, `src/src/components/{Layout,Header,Footer}.js`, `src/src/pages/index.js`, `src/src/pages/404.js`, `src/src/templates/post.js`, `src/static/assets/ssgberk.{css,png}`. Delete `src/src/components/PostList.js`, `src/src/css/style.css` (CSS is linked, not imported).
**Interfaces:** `static_folder: "src/static"`; `allow_extra_html: ["404/index.html"]`; `Head` exports set `<html lang="en">`, `<title>` and the stylesheet link.
- Steps: Standard migration steps. Extra: real-output regression fixture `tests/conformance/real/gatsby/` (wrappers `div#___gatsby`).

### Task 12: jigsaw (`PHP/jigsaw`)

**Files:** `src/config.php` (collection `posts` with `'sort' => '-date'`, `path`), `src/source/_layouts/base.blade.php`, `src/source/_partials/{header,footer}.blade.php`, `src/source/_layouts/post.blade.php`, `src/source/index.blade.php`, `src/source/404.blade.php` (`permalink: 404.html`), `src/source/assets/ssgberk.{css,png}`. Delete `_includes/*`, `_layouts/{master,page}.blade.php`, `about.md`, `css/style.css`, the `links` config.
**Interfaces:** `static_folder: "src/source"`; `metadata_layout: "extends: _layouts.post"` (unchanged).
- Steps: Standard migration steps. Extra: dates with `gmdate()` from the timestamp; confirm PHP Markdown Extra renders the tilde fence with `class="language-text"`.

### Task 13: nikola-mako (`Python/nikola-mako`)

**Files:** `src/conf.py` (Core switches row "nikola-mako"; `PAGES = (("pages/*.md", "", "page.tmpl"),)`), `src/templates/{base,header,footer,index,post,page}.tmpl`, `src/pages/404.md` (`.. slug: 404`, `.. pretty_url: False`, `.. title: Page not found`), `src/files/assets/ssgberk.{css,png}`, `requirements.txt` (re-frozen if deps change).
**Interfaces:** `static_folder: "src/files"`; content `2dot`.
- Steps: Standard migration steps. Resolves 005 open question 3 (Nikola 404). Confirm the base theme copies no extra HTML (theme assets are non-HTML and allowed).

### Task 14: jekyll (`Ruby/jekyll`)

**Files:** `src/_config.yml` (`timezone: UTC`, `kramdown.syntax_highlighter_opts.disable: true`), `src/_layouts/{base,post}.html`, `src/_includes/{header,footer}.html`, `src/index.html`, `src/404.html`, `src/assets/ssgberk.{css,png}`. Delete `src/_layouts/default.html`.
**Interfaces:** `static_folder: "src"`; `metadata_layout: "layout: post"`.
- Steps: Standard migration steps. Extra: real-output regression fixture `tests/conformance/real/jekyll/` (kramdown ids, `<p>`-wrapped images).

### Task 15: nanoc (`Ruby/nanoc`)

**Files:** `src/Rules` (posts: `filter :kramdown, syntax_highlighter: nil`; `layout '/post.*'`; index and 404 through `/base.*`; passthrough `/assets/**/*`), `src/lib/default.rb` (`include Nanoc::Helpers::Rendering`), `src/layouts/{base,header,footer,post}.erb`, `src/content/index.html`, `src/content/404.html`, `src/content/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/content"`; `metadata_dateslug: "created_at"`, `metadata_layout: "kind: article"`.
- Steps: Standard migration steps. Extra: sort by `Time` of `created_at` descending.

### Task 16: middleman (`Ruby/middleman`)

**Files:** `src/config.rb` (`set :markdown, syntax_highlighter: nil`, `page "/404.html", directory_index: false`, `Time.zone = "UTC"`), `src/source/layouts/{layout,post}.erb`, `src/source/partials/_{header,footer}.erb`, `src/source/index.html.erb`, `src/source/404.html.erb`, `src/source/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/source"`; blog sources `posts/{year}-{month}-{day}-{title}` (the file name date equals the front matter date, 005 Task 2).
- Steps: Standard migration steps. Extra: confirm that middleman's asset handling copies the CSS byte-identically with no extensions activated.

### Task 17: metalsmith-handlebars (`JavaScript/metalsmith-handlebars`)

**Files:** `src/index.js` (post list sorted by date descending, `engineOptions: { partials, helpers: { isoDate, ymd, eq } }`, 404 excluded from permalinks), `src/layouts/{base,post,index,404}.hbs`, `src/layouts/partials/{header,footer}.hbs`, `src/content/404.html`, `src/content/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/content"`.
- Steps: Standard migration steps. Resolves 005 open question 4 for Handlebars. Layout inheritance via a `{{#> base}}` partial block.

### Task 18: metalsmith-nunjucks (`JavaScript/metalsmith-nunjucks`)

**Files:** as Task 17 with `.njk` templates (`{% extends "base.njk" %}`), filters `isoDate`/`ymd` through `engineOptions.filters`.
**Interfaces:** `static_folder: "src/content"`.
- Steps: Standard migration steps. Resolves 005 open question 4 for Nunjucks. If `jstransformer-nunjucks` ignores `filters`, pass a configured `nunjucks.Environment` (005 plan Risk 2).

### Task 19: zola (`Rust/zola`)

**Files:** `src/config.toml`, `src/content/posts/_index.md` (`sort_by = "date"`), `src/templates/{base,header,footer,index,section,page,404}.html`, `src/static/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/static"`; content `3plus` (fields under `page.extra`). `section.html` renders the same index markup only if Zola emits `posts/index.html`. Otherwise set `render = false` on the section. If Zola cannot suppress `posts/index.html`, the task records the evidence and adds the path to the 005 "Unavoidable extra output" table (a 005 revision).
- Steps: Standard migration steps. Resolves 005 open question 8.

### Task 20: astro (`JavaScript/astro`)

**Files:** `src/astro.config.mjs` (`markdown: { syntaxHighlight: false }`), `src/src/content.config.ts` (schema: title, date, summary, author, tags), `src/src/layouts/Base.astro`, `src/src/components/{Header,Footer}.astro`, `src/src/pages/index.astro`, `src/src/pages/posts/[id].astro`, `src/src/pages/404.astro`, `src/public/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/public"`.
- Steps: Standard migration steps.

### Task 21: eleventy (`JavaScript/eleventy`)

**Files:** `src/eleventy.config.js` (filters `isoDate`, `ymd`; `addPassthroughCopy("assets")`), `src/_includes/{base,post,header,footer}.njk`, `src/index.njk`, `src/404.njk` (`permalink: /404.html`), `src/posts/posts.json`, `src/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src"`. Front matter `tags` merge with the directory-data tag `posts` (Eleventy deep data merge). The task verifies `collections.posts` still has N items.
- Steps: Standard migration steps.

### Task 22: hexo (`JavaScript/hexo`)

**Files:** `src/_config.yml` (`timezone: UTC`, `syntax_highlighter: ''`, `index_generator: { path: '', per_page: 0, order_by: -date }`), `src/themes/minimal/layout/{layout,index,post}.ejs`, `src/themes/minimal/layout/_partial/{header,footer}.ejs`, `src/source/404.md` (`permalink: /404.html`), `src/source/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/source"`.
- Steps: Standard migration steps. Extra: confirm Hexo copies `source/assets/*.css` without a renderer touching it.

### Task 23: nextjs-export (`JavaScript/nextjs-export`)

Runs after 003 Task 5 has added the generator.

**Files:** `src/lib/posts.js` (fields, sort descending, date formatting), `src/app/layout.js`, `src/app/components/{Header,Footer}.js`, `src/app/page.js`, `src/app/posts/[slug]/page.js`, `src/app/not-found.js`, `src/public/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/public"`; `allow_extra_html: ["404/index.html", "_not-found.html", "_not-found/index.html"]` (only those Next actually emits).
- Steps: Standard migration steps. Records the 005 open question 1 decision in the README.

### Task 24: vitepress (`JavaScript/vitepress`)

Runs after 003 Task 6 has added the generator.

**Files:** `src/.vitepress/config.mjs` (`head` stylesheet link, `titleTemplate`, `markdown.highlight` identity), `src/.vitepress/theme/index.js`, `src/.vitepress/theme/{Layout,Header,Footer}.vue`, `src/posts.data.js`, `src/index.md`, `src/public/assets/ssgberk.{css,png}`.
**Interfaces:** `static_folder: "src/public"`; `output_glob: "posts/*.html"` (unchanged).
- Steps: Standard migration steps. Resolves 005 open questions 5 and 6. If Shiki cannot be bypassed, the README documents it as an unavoidable cost, and the task notifies 008's validity-threat list through a README link.

### Task 25: pelican (`Python/pelican`)

Runs after 003 Task 7 has added the generator.

**Files:** `src/pelicanconf.py` (Core switches row "pelican"; `THEME = "theme"`; `STATIC_PATHS = ["assets"]`), `src/theme/templates/{base,header,footer,index,article,page}.html`, `src/content/pages/404.md` (`save_as: 404.html`), `src/content/assets/ssgberk.{css,png}`, `requirements.txt` (pip freeze).
**Interfaces:** `static_folder: "src/content"`; content `3minus`.
- Steps: Standard migration steps. Resolves 005 open question 2 (tags through Python-Markdown `meta`). The task also adds a `3minus`-under-Pelican fixture to `tests/conformance/test_sources.py`.

### Task 26: mkdocs (`Python/mkdocs`)

Runs after 003 Task 8 has added the generator.

**Files:** `src/mkdocs.yml` (`theme: { name: null, custom_dir: theme }`, `plugins: []`, `use_directory_urls: true`), `src/theme/{main,base,header,footer,index,404}.html`, `src/docs/index.md` (`template: index.html`), `src/docs/assets/ssgberk.{css,png}`, `benchmark_config.json` content `type` `none` → `3minus` (005 R-11), `requirements.txt` (pip freeze).
**Interfaces:** `static_folder: "src/docs"`.
- Steps: Standard migration steps. Resolves 005 open question 7. Confirm no `sitemap.xml` or `search/` output.

### Task 27: Enforce everywhere and CI

**Files (SF):**
- Modify: `Go/hugo/build.sh` (drop `pending` handling), every `*/*/build.sh`, `tools/check_conformance.py` (drop `--mode report`) and its copies, `docs/specs/001-canonical-build-runner/plan.md` (remove `pending` and `SSGBERK_CONFORMANCE_PENDING`), `.github/workflows/*` (smoke matrix asserts `SSGBERK_CONFORMANCE_OK`), `tools/check-reference-assets.sh` invoked with `--strict` in CI.

**Interfaces:**
- After this task, `conformance` accepts only `enforce`, and any other value is a `usage` failure.

- [ ] **Step 1: Write the failing test** — `test_pending_rejected`: `conformance: pending` → `SSGBERK_CONFORMANCE_FAIL usage …` and exit 1. `grep -l '"pending"' */*/benchmark_config.json` prints nothing.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement**, and add a CI step that runs `python3 -m unittest discover -s tests/conformance`.
- [ ] **Step 4: Run** the unit tests, `tools/check-build-sh.sh`, `tools/check-reference-assets.sh --strict`, and one smoke per language (hugo, gatsby, jigsaw, nikola-mako, jekyll, zola) → all pass.
- [ ] **Step 5: Commit** `feat(conformance): enforce for all generators`.
