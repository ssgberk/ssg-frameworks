# ssg-frameworks

Static site generators benchmarked by [SSGBerk](https://github.com/ssgberk). Each generator lives in `<Lang>/<name>/` with a dockerfile, a `benchmark_config.json`, the canonical `build.sh`, a minimal site in `src/` and a `generator.json`. The generator contract is in `docs/specs/001-canonical-build-runner/plan.md`.

## Generators

| Language | Name | Version | Content type | Output glob |
|---|---|---|---|---|
| Go | [hugo](Go/hugo) | 0.167.0 | `3minus` | `public/post/*/index.html` |
| JavaScript | [astro](JavaScript/astro) | 7.3.5 | `3minus` | `dist/posts/*/index.html` |
| JavaScript | [eleventy](JavaScript/eleventy) | 3.1.6 | `3minus` | `_site/posts/*/index.html` |
| JavaScript | [gatsby](JavaScript/gatsby) | 5.16.1 | `3minus` | `public/posts/*/index.html` |
| JavaScript | [hexo](JavaScript/hexo) | 8.1.2 | `3minus` | `public/posts/*/index.html` |
| JavaScript | [metalsmith-handlebars](JavaScript/metalsmith-handlebars) | 2.7.0 | `3minus` | `build/posts/*/index.html` |
| JavaScript | [metalsmith-nunjucks](JavaScript/metalsmith-nunjucks) | 2.7.0 | `3minus` | `build/posts/*/index.html` |
| JavaScript | [nextjs-export](JavaScript/nextjs-export) | 16.3.8 | `3minus` | `out/posts/*/index.html` |
| JavaScript | [vitepress](JavaScript/vitepress) | 1.6.4 | `3minus` | `.vitepress/dist/posts/*.html` |
| PHP | [jigsaw](PHP/jigsaw) | 1.8.8 | `3minus` | `build_local/posts/*/index.html` |
| Python | [mkdocs](Python/mkdocs) | 1.6.1 | `none` | `site/posts/*/index.html` |
| Python | [nikola-mako](Python/nikola-mako) | 8.3.3 | `2dot` | `output/posts/*/index.html` |
| Python | [pelican](Python/pelican) | 4.12.0 | `3minus` | `output/posts/*/index.html` |
| Ruby | [jekyll](Ruby/jekyll) | 4.4.1 | `3minus` | `_site/posts/*/index.html` |
| Ruby | [middleman](Ruby/middleman) | 4.6.3 | `3minus` | `build/posts/*/index.html` |
| Ruby | [nanoc](Ruby/nanoc) | 4.14.8 | `3minus` | `output/posts/*/index.html` |
| Rust | [zola](Rust/zola) | 0.23.6 | `3plus` | `public/posts/*/index.html` |

Versions come from [`generators.json`](generators.json); content type and output glob (relative to the build's `output_folder`) come from each `benchmark_config.json`.

## How to add a generator

1. Create `<Lang>/<name>/` and copy the canonical `build.sh` from `Go/hugo/build.sh` unchanged (CI fails if any `build.sh` differs).
2. Write `<name>.dockerfile` following the skeleton in `docs/specs/001-canonical-build-runner/plan.md` (`ubuntu:24.04`, architecture via `dpkg --print-architecture`, pinned generator version).
3. Add a minimal site in `src/` and a `benchmark_config.json`; set `output_folder` and `output_glob` so the glob matches exactly one file per post.
4. Add `generator.json` and run `python3 tools/build_index.py`.
5. Run `./ssgberk --test <name> -nf 10` from [benchmark-tool](https://github.com/ssgberk/benchmark-tool) with this repo checked out as `frameworks/`.

## CI

`.github/workflows/ci.yml` checks that every `build.sh` is identical to the canonical one and runs a smoke test (`-nf 10`) for each changed generator on amd64 and arm64 runners.

## Metadata

[`generators.json`](generators.json) is a machine-readable index of every generator, including name, homepage, license, pinned version, benchmark settings and raw file URLs. It also lists the generators proposed in issues.

- Raw URL: `https://raw.githubusercontent.com/ssgberk/ssg-frameworks/master/generators.json`
- The format, field reference, versioning policy and examples are in [`docs/metadata/README.md`](docs/metadata/README.md).
- To regenerate it, run `python3 tools/build_index.py`. CI runs `--check`.
