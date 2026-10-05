# More Generators (wave 1)

- **Repo:** `ssgberk/ssg-frameworks`
- **Date:** 2026-10-05
- **Status:** aprovado (2026-10-05, maintainer: "implemente os maiores", top 6 by GitHub stars)
- **Siblings:** `plan.md` (how), `tasks.md` (one task per generator)
- **Issues:** #92, #93, #95, #96, #97, #118 (tracking #116)

## Context

The benchmark has 17 generators. The open `new-generator` issues list 46 more, collected from jamstack.org and the GitHub `static-site-generator` topic. This wave adds the six most-starred web site generators among them. Quarkdown (Kotlin typesetting), TanStack Start (application framework) and Quartz (Obsidian-vault clone) rank higher than some picks but are deferred: none of them fits the "markdown folder in, static HTML out" contract without a custom harness.

## Requirements

| Issue | Generator | Directory | Language | Stars (2026-10-05) |
|---|---|---|---|---|
| #92 | Docusaurus 3.x | `JavaScript/docusaurus` | JavaScript | 66k |
| #93 | Nuxt 4.x + Nuxt Content 3.x | `JavaScript/nuxt-content` | JavaScript | 61k |
| #95 | mdBook 0.4.x | `Rust/mdbook` | Rust | 22k |
| #96 | SvelteKit 2.x + adapter-static + mdsvex | `JavaScript/sveltekit` | JavaScript | 21k |
| #118 | Nextra 4.x (on Next.js) | `JavaScript/nextra` | JavaScript | 14k |
| #97 | Sphinx 8.x + MyST-Parser | `Python/sphinx` | Python | 8k |

- **R-1** Each generator follows the contract in `docs/specs/001-canonical-build-runner` (dockerfile skeleton, byte-identical `build.sh`, `benchmark_config.json` schema, markers) and the Global Constraints of `docs/specs/003-new-generators/tasks.md`.
- **R-2** Each site has a base layout, a post page that renders only its own post, and one index page that lists every post (no pagination, tags, archives, feeds, search, sidebar or table of contents listing other posts). Where the generator forces navigation chrome, a minimal custom theme or layout removes it.
- **R-3** The generator renders the spec 005 rich markdown content without errors at `-cs 0.500` and `-cs 5`, including the image reference `/assets/ssgberk.png`. Each generator ships byte-identical copies of `reference/assets/ssgberk.css` and `reference/assets/ssgberk.png` in its static/public folder so the image resolves.
- **R-4** Versions are the latest stable release on 2026-10-05, pinned exactly in the manifest and lockfile (`package-lock.json`, full `pip freeze`, or a pinned release binary).
- **R-5** Every Node generator image sets `ENV NODE_OPTIONS=--max-old-space-size=6144` (spec 001 constraint) and disables telemetry where the tool has it.
- **R-6** Each generator has `generator.json` (schema `schema/generator.schema.json`), a `README.md` (version, content folder, output glob, run command, deviations), and appears in `generators.json` (`tools/build_index.py`).
- **R-7** Cold builds: every cache the tool writes between runs is listed in `cache_folders`.

## Acceptance criteria

1. For each generator, a direct image run at `number_of_files=10` prints `SSGBERK_VERIFY_OK expected=10 got=10` for `content_size=0.500` and for `content_size=5` (got equals expected, never more).
2. `tools/check-build-sh.sh`, `tools/check-node-heap.sh` and the metadata tests (`pytest tests/metadata`) pass.
3. The PR's CI smoke job passes for all six on `ubuntu-24.04` and `ubuntu-24.04-arm`.
4. One commit per generator.

## Out of scope

- The other 40 issues (later waves).
- The spec 006 conformance check (generators migrate in 006 like the existing 17).
- Benchmark rounds with the new generators (benchmark-tool, after merge).
