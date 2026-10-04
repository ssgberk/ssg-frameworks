# Generator Metadata — Tasks

**Spec:** `spec.md`. **Plan:** `plan.md`. Read both first.

## Global constraints

- Use only the Python 3 standard library in `tools/build_index.py`. pytest is a dev-only dependency.
- Every commit is GPG-signed and authored by `Matheus Breguêz <matbrgz@gmail.com>`. Never use `--no-gpg-sign` or `--author`.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Never run `./ssgberk` or docker for this spec.

## Task 1: Spec

- [ ] Write `spec.md`, `plan.md` and `tasks.md`.
- [ ] Commit them as `docs(specs): add 004-generator-metadata`.

## Task 2: Schemas, tool and tests (TDD)

- [ ] Write `tests/metadata/test_build_index.py`, with fixtures generated in `tmp_path`, covering:
  - [ ] version extraction from a dockerfile ARG, `package-lock.json` (v3 and v1), `package.json` (exact pin), `Gemfile.lock`, `composer.lock` (with `v` stripped), `requirements.txt` (PEP 503 normalisation), and a `versionFrom` override
  - [ ] validation failures: a missing required field, an extra property, a bad URL, a bad SPDX expression, an id that does not match its directory, an id that does not match `framework`, runtime drift, a proposed id that duplicates a generator
  - [ ] the derived fields: `path`, `version`, `benchmark.*`, `files.*` (default and custom raw base)
  - [ ] deterministic output: two runs give identical bytes; the file ends with a newline and uses a 2-space indent; generators are sorted
  - [ ] `--check` passes on a fresh index, fails on a stale one with a diff, fails on a missing `generator.json`, and ignores `generatedFrom`
  - [ ] `--validate`, and the write mode not rewriting when only `generatedFrom` differs
  - [ ] the validator rejects unknown schema keywords; the `const` equals `SCHEMA_VERSION`; the property definitions of the two schemas stay in sync
- [ ] Run the tests and watch them fail (RED).
- [ ] Write `schema/generator.schema.json`, `schema/generators.schema.json` and `tools/build_index.py`.
- [ ] Run the tests until they pass (GREEN).
- [ ] Commit as `feat(metadata): add schemas, build_index tool and tests`.

## Task 3: Data

- [ ] Verify each upstream repo with `gh api repos/<o>/<r> --jq '.license.spdx_id,.homepage,.archived,.pushed_at'`, and `firstRelease` with registry or tag dates.
- [ ] Write `generator.json` for all 9 generators.
- [ ] Build `tools/proposed.json` from `gh issue list -R ssgberk/ssg-frameworks --label new-generator --state open`, excluding the tracking issue #116, plus the planned generators from spec 003.
- [ ] Run `python3 tools/build_index.py`, then `--check`, which must exit 0.
- [ ] Commit as `feat(metadata): add generator.json for all generators and the index`.

## Task 4: CI, agent and docs

- [ ] Add `.github/workflows/metadata.yml`.
- [ ] Add `.claude/agents/generator-docs.md`.
- [ ] Add `docs/metadata/README.md` and `docs/metadata/CHANGELOG.md`.
- [ ] Add the root `README.md`, a minimal one with a Metadata section, since none exists.
- [ ] Add the `generator.json` line to the 001 plan contract.
- [ ] Commit as `ci,docs(metadata): add workflow, generator-docs agent and consumer docs`.
- [ ] Push with `git push -u origin feat/generator-metadata`. Do not open a PR.
