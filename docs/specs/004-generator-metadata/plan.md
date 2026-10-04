# Generator Metadata — Plan

Spec: `spec.md`. Tasks: `tasks.md`.

## File layout

```
<Lang>/<name>/generator.json        curated, one per generator (source of truth)
schema/generator.schema.json        schema for generator.json
schema/generators.schema.json       schema for the index
tools/build_index.py                generator, validator, checker (stdlib only)
tools/proposed.json                 curated list of generators not yet in the repo
generators.json                     generated index (committed; consumers read it raw)
tests/metadata/test_build_index.py  pytest suite; fixtures are built in tmp dirs
.github/workflows/metadata.yml      CI: --check + tests
.claude/agents/generator-docs.md    documentation agent
docs/metadata/README.md             consumer docs
docs/metadata/CHANGELOG.md          schema changelog
```

A generator directory is any `<Lang>/<name>/` that contains `benchmark_config.json`. That is the same glob the toolset uses (`frameworks/*/*/benchmark_config.json`), so `_wip/<Lang>/<name>` (three levels deep) is excluded automatically.

## Format

### `generator.json` (curated)

```json
{
  "id": "hugo",
  "name": "Hugo",
  "description": "…one sentence…",
  "homepage": "https://gohugo.io",
  "repository": "https://github.com/gohugoio/hugo",
  "license": "Apache-2.0",
  "language": "Go",
  "runtime": "Go binary (Hugo extended)",
  "templateEngines": ["Go html/template"],
  "contentFormats": ["markdown", "html", "org"],
  "category": "general",
  "firstRelease": 2013,
  "maintained": true,
  "benchmark": {"status": "active"},
  "links": {"issue": "https://github.com/ssgberk/ssg-frameworks/issues/…"},
  "notes": "…"
}
```

The optional `versionFrom` field is `{"source": "dockerfile|npm|gem|composer|pip", "name": "<ARG or package name>"}`. Use it only when the convention below fails, for example `nextjs-export`, whose package is `next`.

### Derived fields (added by `tools/build_index.py`)

| Field | Derivation |
|---|---|
| `path` | `<Lang>/<name>` |
| `version` | The pinned generator version; see below. A leading `v` is stripped. |
| `benchmark.displayName` | `tests[0].default.display_name` |
| `benchmark.versus` | `tests[0].default.versus` |
| `benchmark.contentType` | `content[0].type` |
| `benchmark.contentFolder` | `content[0].folder` |
| `benchmark.buildCommand` | `config[0].build_command` |
| `benchmark.outputFolder` | `config[0].output_folder` |
| `benchmark.outputGlob` | `config[0].output_glob` |
| `benchmark.cacheFolders` | `config[0].cache_folders`, or `[]` |
| `files.dockerfile` | `<rawBase><path>/<name>.dockerfile` |
| `files.benchmarkConfig` | `<rawBase><path>/benchmark_config.json` |
| `files.readme` | `<rawBase><path>/README.md` |
| `files.generatorJson` | `<rawBase><path>/generator.json` |

The default `rawBase` is `https://raw.githubusercontent.com/ssgberk/ssg-frameworks/master/`. `--raw-base URL` overrides it; the URL must end in `/`.

#### Version extraction

The candidate names are `[id, id-before-first-dash]`, for example `metalsmith-handlebars` gives `metalsmith-handlebars` and `metalsmith`. The sources below are tried in order, and the first match wins. Every file is read from the generator directory.

1. **dockerfile:** `ARG <CANDIDATE>_VERSION=<v>` in `<name>.dockerfile`. The candidate is upper-cased and `-` becomes `_`.
2. **npm:** in `package-lock.json`, `packages["node_modules/<cand>"].version` (lockfile v2/v3), with a fallback to `dependencies[<cand>].version` (lockfile v1). If there is no lockfile, `package.json` is used, but only when its `dependencies[<cand>]` is an exact version.
3. **gem:** in `Gemfile.lock`, the line `    <cand> (<v>)`, with exactly four spaces under `specs:`.
4. **composer:** in `composer.lock`, `packages[]` whose `name` is `<cand>` or ends with `/<cand>`.
5. **pip:** in `requirements.txt`, `<cand>==<v>`. Names are compared after PEP 503 normalisation (case-insensitive; `-`, `_` and `.` are equal).

`versionFrom` limits extraction to one source with an exact name. A generator with no version found fails validation.

### Index (`generators.json`)

```json
{
  "schemaVersion": "1.0.0",
  "generatedFrom": "<40-hex sha> | null",
  "source": "https://github.com/ssgberk/ssg-frameworks",
  "generators": [ …entries sorted by id… ],
  "proposed": [ {"id", "name", "language", "repository", "status": "proposed|planned", "issue"?, "spec"?, "notes"?} … sorted by id ]
}
```

`proposed[].status` is `proposed` when the entry comes from a `new-generator` issue, and `planned` when it comes from a spec (spec 003) but has no issue.

### Serialisation

- Keys follow the property order in the schema, so the order is stable and human-friendly.
- `json.dumps(indent=2, ensure_ascii=False)` plus a trailing `\n`, written as UTF-8.

### Semantic checks (beyond the schema)

- `id` equals the directory name and `benchmark_config.json` `framework`.
- `<name>.dockerfile` and `README.md` exist, so every `files` URL resolves.
- If `runtime` starts with a runtime the dockerfile pins (`Node.js`→`NODE_VERSION`, `Python`→`PYTHON_VERSION`, `Ruby`→`RUBY_VERSION`, `Go`→`GO_VERSION`, `PHP`→`PHP_VERSION`, `Deno`→`DENO_VERSION`, `Bun`→`BUN_VERSION`, `Rust`→`RUST_VERSION`) and `runtime` has a version token, that token must equal the ARG. This keeps the curated runtime string from drifting when the dockerfile is bumped.
- `proposed[].id` values are unique and none equals a generator `id`. When a generator lands, its proposed entry must be moved.

## Validator (stdlib subset)

The validator supports exactly these keywords: `$schema`, `$id`, `$defs`, `$ref` (local `#/$defs/...` only), `title`, `description`, `type` (a string or a list), `properties`, `required`, `additionalProperties` (`false` only), `items`, `enum`, `const`, `pattern`, `format` (`uri`), `minLength`, `minItems`, `uniqueItems`, `minimum`, `maximum`. Any other keyword raises `SchemaError`, so the schema cannot silently outgrow the validator; a test enforces this. Errors are reported as `<file>: <json-pointer>: <message>`.

## Versioning and compatibility policy

`schemaVersion` is semver and applies to both the index and `generator.json`. The two schemas move together, and the index schema `const` equals `SCHEMA_VERSION` in `tools/build_index.py`. A test checks this.

- **PATCH:** wording, descriptions or docs only. The accepted documents do not change.
- **MINOR:** additive changes, such as a new optional field, a new derived field or a new enum value. Existing fields keep their name, type and meaning.
- **MAJOR:** anything else: removing or renaming a field, changing a type, making an optional field required, or removing an enum value. A major bump must have a migration note in `docs/metadata/CHANGELOG.md`.

Consumers must ignore unknown fields and tolerate unknown enum values within a major version. Strict validators should use the schema at the same ref as the index.

## Generation pipeline

```
<Lang>/<name>/generator.json ─┐
<Lang>/<name>/benchmark_config.json ─┤
<name>.dockerfile / lockfiles ─┤──► build_index.py ──► validate ──► generators.json
tools/proposed.json ─┘
```

- **Write (default):** discovers, validates, builds and writes the index. It prints errors and exits 1 if validation fails, and in that case writes nothing. If the existing file differs only in `generatedFrom`, the file is left untouched, so regenerating does not churn the index.
- **`--check`:** does the same as write but never writes. It compares the built index with `generators.json` with `generatedFrom` set to `null` on both sides, prints a `difflib.unified_diff` and exits 1 on any difference or validation error.
- **`--validate`:** runs discovery and validation only.
- **`generatedFrom`:** comes from `--ref REF` (resolved with `git rev-parse --verify REF^{commit}`). Without it, the write mode uses `git rev-parse HEAD`, or `null` when git is unavailable. The committed value is therefore the commit the index was generated from, which is normally the parent of the commit that contains it.
- **Other flags:** `--root DIR` (default: the repo root containing `tools/`) and `--raw-base URL`.

## CI

`.github/workflows/metadata.yml` runs on `push` and `pull_request` with `permissions: contents: read`, on `ubuntu-24.04` with Python 3.12. The job:

1. `python3 tools/build_index.py --check`
2. `pip install pytest`
3. `python3 -m pytest tests/metadata -q`

## Documentation agent

`.claude/agents/generator-docs.md` has the frontmatter `name: generator-docs`, a description that says when to use the agent (a generator was added, changed, bumped or removed, or a `new-generator` issue was opened), and the tools `Read, Edit, Write, Glob, Grep, Bash, WebFetch`.

Its procedure:

1. Read `AGENTS.md`, if present, then this plan.
2. Research the facts with `gh api repos/<o>/<r>`, the package registries and the generator's site. It never guesses; unverifiable optional fields are omitted, and required ones are explained in `notes`.
3. Write `generator.json`.
4. Move the entry out of `tools/proposed.json` when the generator lands.
5. Run `python3 tools/build_index.py`, then `--check`, then the tests.
6. Update the README generator table, if one exists.
7. Apply the versioning policy and update `CHANGELOG.md` on any schema change.

The prompt includes a worked example (`Rust/zola`).

## Decisions

- **Version detection by convention, with an optional `versionFrom` override.** Without the override, every current generator needs no version hint at all. With it, odd cases like `nextjs-export` stay possible.
- **`runtime` stays a curated string, as the spec asks, with a consistency check against the dockerfile ARGs.** This avoids silent drift without adding a second field.
- **`generatedFrom` is ignored by `--check`, and the write mode does not rewrite the file when only it would change.** The check stays stable, and regeneration does not churn.
- **The two schemas are kept by hand.** A test asserts that every `generator.schema.json` property appears with the same definition in the index entry schema. `benchmark` is the exception: the index extends it.

## Risks

- **Raw URLs cache.** `raw.githubusercontent.com` caches for about 5 minutes, so consumers may see a stale index briefly. This is documented.
- **Concurrent generator branches.** A branch that adds a generator without `generator.json` will fail `--check` after merge. That is intended, and the agent fixes it.
