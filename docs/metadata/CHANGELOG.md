# Metadata schema changelog

This file covers `schema/generator.schema.json`, `schema/generators.schema.json` and the `generators.json` format. See `README.md` for the versioning policy. Every major version has a migration note.

## 1.0.0 (2026-10-04)

- Initial format: curated `generator.json` per generator, plus the aggregated `generators.json` with derived `path`, `version`, `benchmark.*` and `files.*`, and the `proposed[]` list.
