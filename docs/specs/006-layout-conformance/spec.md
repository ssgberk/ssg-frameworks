# 006 Layout Conformance

- **Data:** 2026-10-04
- **Status:** proposto — aguardando revisão
- **Repos afetados:** `ssgberk/ssg-frameworks` (SF): new `tools/check_conformance.py`, its per-generator copies, the canonical `build.sh`, `tools/check-build-sh.sh`, an amendment to `docs/specs/001-canonical-build-runner/plan.md`, and the 17 generator sites. `ssgberk/benchmark-tool` (BT) parses the new marker; that change is owned by `benchmark-tool/docs/specs/008-benchmark-methodology` (Task 3) and is only referenced here.
- **Siblings:** `plan.md` (rules, normalizations, checker design, contract drafts), `tasks.md`. Related: `docs/specs/005-reference-site-design` (what the site is), `benchmark-tool/docs/specs/008-benchmark-methodology` (how it is benchmarked).

## Context

`build.sh` today verifies one thing after the untimed build: the number of files matching `output_glob` equals `number_of_files` (`SSGBERK_VERIFY_OK`/`SSGBERK_VERIFY_FAIL`, 001 contract). That count catches a missing post template. It does not catch a generator that renders an empty body, skips the table extension, lists every post on every post page, forgets the 404 page, processes the stylesheet, or sorts the index differently. Any of these changes the amount of work timed, so the comparison stops being fair.

Spec 005 defines the reference site. This spec turns 005 into a machine check: `tools/check_conformance.py`, run by `build.sh` after the verification build, before anything is timed. A non-conformant build never produces a timing.

## Contract ownership

| Contract | Owner |
|---|---|
| Conformance rules, failure codes, normalizations, sampling, checker CLI and exit codes | **this spec** (`plan.md`) |
| Marker strings `SSGBERK_CONFORMANCE_OK`, `SSGBERK_CONFORMANCE_FAIL`, `SSGBERK_CONFORMANCE_PENDING`, `SSGBERK_PROFILE_UNSUPPORTED`; the `benchmark_config.json` keys `static_folder`, `allow_extra_html`, `conformance`, `profiles` | `docs/specs/001-canonical-build-runner/plan.md`. This spec drafts the text (plan.md, "Contract drafts for 001") and Task 8 adds it to 001 |
| What the reference site contains (selectors, counts, content model) | `docs/specs/005-reference-site-design/plan.md` |
| How the toolset treats the markers (`failed` with a reason, `unsupported`) | `benchmark-tool/docs/specs/008-benchmark-methodology` |

## Goals & success criteria

1. A build that violates any Core rule of 005 fails before timing. *Measured by:* each mutation fixture in `tests/conformance/` (one per failure code, plan.md "Mutation fixtures") makes the checker exit 1 with that code, and the tolerated-variation fixtures exit 0.
2. All 17 generators pass Core with `conformance: enforce`. *Measured by:* the 001 smoke procedure at `-nf 10 -cs 0.500` and at `-nf 100 -cs 500` shows `SSGBERK_CONFORMANCE_OK profile=core` in `raw.txt` for hugo, gatsby, jigsaw, nikola-mako, jekyll, nanoc, middleman, metalsmith-handlebars, metalsmith-nunjucks, zola, astro, eleventy, hexo, nextjs-export, vitepress, pelican and mkdocs.
3. The checker is cheap enough not to dominate untimed run time. *Measured by:* at `-nf 10000 -cs 500` (5.12 GB of sources) the checker reads at most 50 MB of post HTML (byte-budget sampling) plus the index, and finishes in under 120 s on the CI runner.
4. No new dependencies. *Measured by:* `tools/check_conformance.py` imports only Python 3.12 stdlib modules (a test greps the imports against an allowlist).

## Requirements

### Checker

- **R-1** `tools/check_conformance.py` is a single file that uses the Python 3 standard library only (`html.parser`, `hashlib`, `tomllib`, `re`, `unicodedata`, `fnmatch`, `argparse`, `pathlib`, `json`, `sys`, `urllib.parse`, `xml.etree.ElementTree`). Every generator directory holds a byte-identical copy named `check_conformance.py`, and `tools/check-build-sh.sh` fails CI on any difference.
- **R-2** CLI: `python3 check_conformance.py --output DIR --content DIR --type {3minus,3plus,2dot} --dateslug KEY --extension EXT --posts N --post-glob GLOB --profile {core,extended} [--features LIST] [--allow-extra-html LIST] [--mode {enforce,report}] [--all]`. Exit codes: 0 conformant, 1 non-conformant, 2 usage or configuration error.
- **R-3** Output: in `enforce` mode, each violation prints one line `SSGBERK_CONFORMANCE_FAIL <code> <detail>` (detail: one line, at most 300 characters). After 20 lines it prints one `SSGBERK_CONFORMANCE_FAIL truncated <k> more` and stops. On success it prints exactly one `SSGBERK_CONFORMANCE_OK profile=<p> posts=<N> sampled=<k> features=<comma list or ->`. In `report` mode it prints the same lines with `SSGBERK_CONFORMANCE_PENDING` instead of `SSGBERK_CONFORMANCE_FAIL` and exits 0.
- **R-4** The failure codes are exactly those listed in `plan.md` ("Failure codes"). Each has a mutation fixture (Goal 1).

### What is checked (Core)

- **R-5** **Skeleton** on the index, every sampled post page and the 404 page: `header.site-header`, `main.site-main` and `footer.site-footer` each once, in that document order; 3 nav links with the 005 hrefs and texts; exactly one stylesheet link to `/assets/ssgberk.css`; `<title>` text equal to the 005 title for the page type.
- **R-6** **`aria-current`**: exactly one element with `aria-current="page"` on the index, the Home link. None on post or 404 pages.
- **R-7** **Index**: exactly one `ol.post-list`, with exactly N `li.post-item` children. The `datetime` attributes are strictly descending. Each item's title, `datetime`, date text and summary equal the source post's values. Each item's link resolves to an existing output file matching `--post-glob`, and the N links resolve to N distinct files. The set of resolved files equals the set of files matching `--post-glob`. The index contains no `.post-body`.
- **R-8** **Post pages** (every page in the sample, R-12): `article.post` children in the order `h1.post-title`, `p.post-meta`, `ul.post-tags`, `div.post-body`. Title, `time.post-date` (`datetime` and text), `span.post-author` and the three `li.post-tag` texts in order equal the source. The page contains no `.post-list`, no `.post-item`, and no `a[href]` that resolves to another post page (outside `nav.post-pager` in Extended `E2-pager`).
- **R-9** **Body text equivalence**: the token sequence of `div.post-body` (normalized as in `plan.md` "Normalizations") has the same SHA-256 as the token sequence derived from the source markdown body. On mismatch, the detail names the first differing token index and the expected and actual tokens there.
- **R-10** **Body structure**: inside `div.post-body`, exact element counts for B blocks: `h2` B, `h3` B, `blockquote` B, `pre` B, `table` B, `img` B, `hr` B, `em` B, `strong` B, `ol` 2B, `ul` 2B, `li` 12B. B is derived from the source body length (512 bytes per block).
- **R-11** **404 page**: `404.html` at the output root exists and has the skeleton and `section.not-found > h1.page-title` with text `Page not found`.
- **R-12** **Sampling**: the full post-page checks (R-8 to R-10) run on a deterministic sample. Without `--all` the sample is posts 1 and N, then posts at indices `1 + m·step` for `step = max(1, ceil(N / 98))` in increasing order. Posts are added while the cumulative source body bytes stay ≤ 50 000 000, but posts 1 and N are always included and the sample has at most 100 posts. With `--all`, every post is checked. Existence and link resolution (R-7) always cover all N posts.
- **R-13** **Assets**: `assets/ssgberk.css` and `assets/ssgberk.png` exist at the output root, and their SHA-256 equals the constants embedded in the checker. A test asserts those constants equal the hashes of `reference/assets/*`.
- **R-14** **Extra HTML**: every `*.html` file in the output is the index, the 404 page, a post page, a page required by a declared Extended feature, or a match of `--allow-extra-html`. Anything else fails. Non-HTML files are not checked.
- **R-15** **Sources**: the checker parses the content folder files whose names match the 005 file-name pattern, using exactly the 005 front matter layouts for `--type`. A source that does not parse is a `source-parse` failure. A count different from `--posts` is a `source-count` failure.

### What is checked (Extended)

- **R-16** With `--profile extended`, the Core checks run unchanged, plus one check per feature listed in `--features`, as defined in 005 plan "Extended features": tag pages (`extended-tag-pages`), pager (`extended-pager`), excerpt (`extended-excerpt`), highlighting (`extended-highlight`) and feed (`extended-feed`, parsed with `xml.etree.ElementTree`). An Extended feature not listed is not checked, and its output (for example `tags/*/index.html`) counts as extra HTML under R-14.

### Integration with `build.sh`

- **R-17** After `SSGBERK_VERIFY_OK`, `build.sh` runs the checker with arguments from `benchmark_config.json` and the env var `profile` (default `core`). It prints the checker's output verbatim. If the checker exits non-zero in `enforce` mode, `build.sh` resets the content (unless `KEEP_CONTENT`) and exits 1 without running hyperfine, as on `SSGBERK_VERIFY_FAIL`.
- **R-18** `config[0].conformance` is `enforce` or `pending`. `pending` runs the checker with `--mode report`, which is the state of a generator whose migration task is not done. The last task of this spec removes `pending` from the schema. Absent means `enforce`.
- **R-19** With `profile=extended`, `build.sh` uses `config[0].profiles.extended` (`features`, plus optional `build_command`, `build_verbose`, `output_glob`, `cache_folders` overriding the Core values). If `profiles.extended` is absent, it prints `SSGBERK_PROFILE_UNSUPPORTED extended` and exits 3 before generating content.
- **R-20** Every generator image has `python3` (Dockerfile skeleton common packages) and copies `check_conformance.py` next to `build.sh` (skeleton `COPY` line). This is a change to the 001 skeleton (Task 8).
- **R-21** BT treats `SSGBERK_CONFORMANCE_FAIL` exactly like `SSGBERK_VERIFY_FAIL`: the generator goes to `failed.datarate`, and the first fail line is recorded as its failure reason. `SSGBERK_PROFILE_UNSUPPORTED` makes the generator `unsupported` for that profile, not failed. Both are owned and implemented by `benchmark-tool/docs/specs/008-benchmark-methodology` Task 3.

### Migration

- **R-22** Each of the 17 generators gets one migration task (`tasks.md` Tasks 10–26) that ports its templates to 005, applies the 005 Core switches, sets `static_folder`, `allow_extra_html` and `conformance: enforce`, and passes the smoke at `-nf 10 -cs 0.500` and `-nf 100 -cs 500`.

## Out of scope

- Pixel or visual comparison, CSS rendering, accessibility audits.
- Validating HTML against the HTML standard. The checker builds a tolerant tree (plan.md, "Tree building").
- Checking JS bundles, hydration payloads or client routing.
- Running the checker during timed runs. It runs once, on the verification build.
- Statistical reporting of conformance (008).

## Open questions

1. **Sampling versus completeness.** Byte-budget sampling (R-12) means a generator could in principle render post 37 wrong at `-nf 10000` and pass. *Proposal:* accept this for benchmark runs. CI and `smoke` use `--all` (N = 10), and the sample always includes the first and last post plus an even spread.
2. **VitePress normalization.** Dropping elements with class `lang` and `header-anchor` (plan.md, "Normalizations") is VitePress-specific knowledge inside a generic checker. *Alternative:* a per-generator `ignore_text_selectors` key in `benchmark_config.json`. Rejected for now, because it lets a generator hide text. To be revisited if a fourth generator needs a rule.
3. **`python3` in every image.** Adding `python3` (about 25 MB) to Go, Rust, PHP, Ruby and Node images increases image build time. Image build time is reported separately by 008 and never timed with the build. The alternative is running the checker in the toolset container on an exported output tree, which would require copying the output out of the container (`docker cp` of up to tens of GB at large cells). Rejected.
4. **Exit code 3 for unsupported profile.** `build.sh` today exits 0 or 1 (or hyperfine's code). A distinct code 3 plus the marker lets BT distinguish "unsupported" from "failed" even if the marker is lost. To be confirmed with the BT 008 parser.
5. **Strictly descending `datetime`.** 005 dates are unique, so strict order is required. A generator whose collection sort is unstable cannot hide behind ties.
