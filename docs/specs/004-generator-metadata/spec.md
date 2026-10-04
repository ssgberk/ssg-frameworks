# Generator Metadata

- **Repo:** `ssgberk/ssg-frameworks`
- **Date:** 2026-10-04
- **Status:** approved, in implementation (branch `feat/generator-metadata`)
- **Siblings:** `plan.md` (how), `tasks.md` (task list) in this directory. The generator contract is in `docs/specs/001-canonical-build-runner/plan.md`.

## Context

Each generator lives in `<Lang>/<name>/` and has a dockerfile, `benchmark_config.json`, `README.md`, `build.sh` and `src/`. Facts such as the generator's name, homepage, license, pinned version and build command are spread over those files. Some facts (homepage, license, template engine) are written nowhere at all. A service that wants a list of the benchmarked generators has to clone the repo and parse dockerfiles and lockfiles.

## Goal

Publish one machine-readable index of every generator, `generators.json` at the repo root. Consumers fetch it from its raw GitHub URL. The index is generated from:

1. a small curated `generator.json` per generator, which holds only facts that cannot be derived; and
2. facts the script derives from files already in the repo, such as the pinned version and the benchmark settings.

A Claude Code agent (`.claude/agents/generator-docs.md`) keeps the curated files and the index current. CI fails when the index is stale.

## Consumers

- **The benchmark site and report renderers.** They show the name, homepage, license and version next to the results.
- **`ssgberk/benchmark-tool` and other automation.** They list the generators, the versions to bump, and the raw URLs of each generator's files.
- **Agents and humans** that add generators. They use the `proposed` list (one entry per `new-generator` issue or planned spec entry) to see what comes next.

## Requirements

### R1. Per-generator `generator.json` (the source of truth)

Each `<Lang>/<name>/` has a `generator.json` that holds only curated, descriptive fields:

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Equals the directory name and `benchmark_config.json` `framework` |
| `name` | yes | Human-readable name |
| `description` | yes | One sentence |
| `homepage` | yes | http(s) URL |
| `repository` | yes | http(s) URL of the upstream source repository |
| `license` | yes | SPDX expression |
| `language` | yes | Implementation language |
| `runtime` | yes | e.g. `Node.js 24.21.0`, `Ruby 3.2 (Ubuntu 24.04 apt)`, `Go binary` |
| `templateEngines` | yes | Template engine(s) this benchmark setup uses |
| `contentFormats` | yes | Content formats the generator supports natively or through official first-party plugins |
| `category` | yes | `blog`, `docs`, `framework` or `general` |
| `firstRelease` | no | Year of the first public release, only if verified |
| `maintained` | yes | Upstream is maintained: not archived, with commits or releases in the last 12 months |
| `benchmark.status` | yes | `active`, `wip` or `removed` |
| `versionFrom` | no | Override for where the pinned version is read from, used only when the convention fails |
| `links.issue` | no | URL of the issue that tracked adding the generator |
| `notes` | no | Free text, including any field that could not be verified |

`generator.json` never repeats a value the script can derive (the version, the build command, the output folder and so on).

### R2. JSON Schemas

- `schema/generator.schema.json` describes `generator.json`.
- `schema/generators.schema.json` describes the index.
- Both use draft 2020-12, `additionalProperties: false`, `required`, the `uri` format with an http(s) pattern, and an SPDX pattern.
- The index schema pins `schemaVersion` with `const`.

### R3. Aggregated index

`tools/build_index.py` produces `generators.json`. It uses only the Python 3 standard library. It validates with its own validator, which covers exactly the schema keywords the schemas use.

The top level holds:

- `schemaVersion`: semver, starting at `1.0.0`
- `generatedFrom`: a commit SHA or `null`
- `source`: the repo URL
- `generators[]`: sorted by `id`
- `proposed[]`

Each generator entry holds its `generator.json` fields plus these derived fields:

- `path`
- `version`: from the dockerfile `ARG`, `package-lock.json`, `Gemfile.lock`, `composer.lock` or `requirements.txt`
- `benchmark` additions: `displayName`, `versus`, `contentType`, `contentFolder`, `buildCommand`, `outputFolder`, `outputGlob`, `cacheFolders`
- `files`: raw URLs for the dockerfile, `benchmark_config.json`, `README.md` and `generator.json`, built from a configurable base whose default ref is `master`

`proposed[]` comes from `tools/proposed.json`. It is curated from the open `new-generator` issues, excluding the tracking issue #116, and from the generators planned in spec 003 that are not in the repo yet.

The output is deterministic: keys follow schema order, the indent is 2 spaces, the file ends with a newline, and no timestamps are written. Running the script twice gives byte-identical output. The only exception is `generatedFrom`, which `--check` ignores.

### R4. Modes

- **Default (write):** writes `generators.json`.
- **`--check`:** exits 1 and prints a unified diff if `generators.json` is stale. It also exits 1 if any `generator.json` fails validation or a generator directory has no `generator.json`.
- **`--validate`:** validates without writing or diffing.

### R5. Tests

`tests/metadata/test_build_index.py` (pytest) covers:

- version extraction for each manifest kind
- schema failures: a missing required field, an extra property, a bad URL, an id that does not match its directory
- deterministic output
- `--check` staleness and a missing `generator.json`
- the derived fields

### R6. Accurate data

Every current generator gets a filled-in `generator.json`. The homepage, repository, license and maintained status are verified with `gh api repos/<owner>/<repo>`. `firstRelease` is verified from registry or tag dates. Nothing is guessed.

### R7. CI

`.github/workflows/metadata.yml` runs `--check` and the metadata tests on every push and pull request, with `permissions: contents: read`.

### R8. Documentation agent

`.claude/agents/generator-docs.md` is a Claude Code subagent. It creates and updates `generator.json`, regenerates and checks the index, updates the README generator table if one exists, moves a `proposed` entry into the generators when that generator lands, and enforces the versioning policy.

### R9. Consumer docs

- `docs/metadata/README.md` covers the raw URLs, a field reference, the versioning policy and usage examples.
- `docs/metadata/CHANGELOG.md` records schema changes.
- The root `README.md` has a Metadata section.

### R10. Contract

`docs/specs/001-canonical-build-runner/plan.md` states that every generator directory includes `generator.json`.

## Acceptance criteria

- `python3 tools/build_index.py --check` exits 0 on the branch.
- `python3 -m pytest tests/metadata` passes.
- `generators.json` lists the 9 current generators, sorted by id, each with a `version` that matches its dockerfile or lockfile pin.
- Running `python3 tools/build_index.py` twice in a row leaves `git status` clean.
- Removing any `generator.json`, or editing a pin without regenerating, makes `--check` exit 1.
- Every URL in the curated files was checked with `gh api` or a registry API on 2026-10-04.

## Out of scope

- Benchmark results in the index. Those live in `benchmark-tool` results.
- Publishing to a package registry or a CDN other than raw GitHub URLs.
- Adding `Rust/zola` or any other new generator (spec 003). Adding one later needs only a `generator.json` and a regeneration.
- Full JSON Schema support in the stdlib validator. It only supports the keywords the two schemas use, and it rejects any other keyword.
