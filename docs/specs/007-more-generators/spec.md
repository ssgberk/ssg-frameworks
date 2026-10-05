# More Generators (waves 1 to 3)

- **Repo:** `ssgberk/ssg-frameworks`
- **Date:** 2026-10-05
- **Status:** aprovado (2026-10-05, maintainer: "implemente os maiores", top 6 by GitHub stars)
- **Siblings:** `plan.md` (how), `tasks.md` (one task per generator)
- **Issues:** wave 1 #92, #93, #95, #96, #97, #118; wave 2 #98, #100, #101, #102, #119, #120; wave 3 #94, #99, #103, #122, #123, #124 (tracking #116)

## Context

The benchmark has 17 generators. The open `new-generator` issues list 46 more, collected from jamstack.org and the GitHub `static-site-generator` topic. This wave adds the six most-starred web site generators among them. Quarkdown (Kotlin typesetting) and TanStack Start (application framework) rank higher than some picks but are deferred: neither fits the "markdown folder in, static HTML out" contract without a custom harness. Wave 2 (maintainer, 2026-10-05: "lance mais subagents para outros") adds the next six by stars that fit the contract, across more languages. Wave 3 (maintainer, 2026-10-05, same request again) adds the next six; Vike is skipped like TanStack Start (application framework).

## Requirements

| Issue | Generator | Directory | Language | Stars (2026-10-05) |
|---|---|---|---|---|
| #92 | Docusaurus 3.x | `JavaScript/docusaurus` | JavaScript | 66k |
| #93 | Nuxt 4.x + Nuxt Content 3.x | `JavaScript/nuxt-content` | JavaScript | 61k |
| #95 | mdBook 0.4.x | `Rust/mdbook` | Rust | 22k |
| #96 | SvelteKit 2.x + adapter-static + mdsvex | `JavaScript/sveltekit` | JavaScript | 21k |
| #118 | Nextra 4.x (on Next.js) | `JavaScript/nextra` | JavaScript | 14k |
| #97 | Sphinx 8.x + MyST-Parser | `Python/sphinx` | Python | 8k |

Wave 2:

| Issue | Generator | Directory | Language | Stars (2026-10-05) |
|---|---|---|---|---|
| #119 | Quartz 4.x | `JavaScript/quartz` | TypeScript | 13k |
| #98 | Starlight (on Astro) | `JavaScript/starlight` | JavaScript | 9.4k |
| #100 | Quarto (website project) | `Other/quarto` | TypeScript/Lua (pandoc) | 6k |
| #120 | Zensical | `Python/zensical` | Rust core, Python package | 5.8k |
| #101 | DocFX | `CSharp/docfx` | C# | 4.4k |
| #102 | Lektor | `Python/lektor` | Python | 3.9k |

Wave 3:

| Issue | Generator | Directory | Language | Stars (2026-10-05) |
|---|---|---|---|---|
| #99 | Publish | `Swift/publish` | Swift | 5k |
| #122 | dumi | `JavaScript/dumi` | JavaScript | 3.8k |
| #123 | Observable Framework | `JavaScript/observable-framework` | JavaScript | 3.7k |
| #124 | Analog (content routes) | `JavaScript/analog` | TypeScript (Angular) | 3.2k |
| #103 | Hakyll | `Haskell/hakyll` | Haskell | 2.9k |
| #94 | VuePress 2 | `JavaScript/vuepress` | JavaScript | 2.8k (v2), 23k (v1) |

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
3. Each PR's CI smoke job passes for its generator on `ubuntu-24.04` and `ubuntu-24.04-arm`.
4. One commit per generator (plus fix commits), one PR per generator (maintainer, 2026-10-05: "abre pr para cada um a medida que fica pronto").

## Out of scope

- The other 28 issues (later waves).
- The spec 006 conformance check (generators migrate in 006 like the existing 17).
- Benchmark rounds with the new generators (benchmark-tool, after merge).

## Versions as built

| Generator | Version | Note |
|---|---|---|
| mdBook | 0.5.4 | latest stable; the table's 0.4.x was a guess |
| Sphinx | 9.1.0 + MyST-Parser 5.1.0 | latest stable; the table's 8.x was a guess |
| SvelteKit | 3.0.0 (+ adapter-static 4.0.0, mdsvex 0.12.8) | latest stable; config lives in `vite.config.js` (kit 3 dropped `svelte.config.js`) |
| Nuxt / Nuxt Content | 4.5.2 / 3.16.1 | built-in `node:sqlite` connector |
| Nextra | 4.6.1 on Next.js 16.3.8 | bare layout, no theme |
