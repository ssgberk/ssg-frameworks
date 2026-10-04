# ssg-frameworks

Static site generators benchmarked by [SSGBerk](https://github.com/ssgberk). Each generator lives in `<Lang>/<name>/` with a dockerfile, a `benchmark_config.json`, the canonical `build.sh`, a minimal site in `src/` and a `generator.json`. The generator contract is in `docs/specs/001-canonical-build-runner/plan.md`.

## Metadata

[`generators.json`](generators.json) is a machine-readable index of every generator, including name, homepage, license, pinned version, benchmark settings and raw file URLs. It also lists the generators proposed in issues.

- Raw URL: `https://raw.githubusercontent.com/ssgberk/ssg-frameworks/master/generators.json`
- The format, field reference, versioning policy and examples are in [`docs/metadata/README.md`](docs/metadata/README.md).
- To regenerate it, run `python3 tools/build_index.py`. CI runs `--check`.
