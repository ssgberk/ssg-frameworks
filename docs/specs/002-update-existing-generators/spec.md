# Update Existing Generators

- **Repo:** `ssgberk/ssg-frameworks`
- **Date:** 2026-10-04
- **Status:** concluído (2026-10-04)
- **Siblings:** `plan.md` (how), `tasks.md` (executable task list) in this directory; roadmap in `benchmark-tool/docs/specs/ROADMAP.md`

## Context

| Item | Hoje | Problema |
|---|---|---|
| Geradores | `ubuntu:18.04`, Node 10, hugo 0.58.2, hyperfine 1.7.0 | Imagens EOL; binários só amd64; 8 dockerfiles com linha corrompida (`... \| bash - && /\|RUN curl ...`) |
| Geradores mortos | Harp, Phenomic (arquivado em 2020), Cuttlebelle, webgen | Não instalam ou não têm manutenção |

## Requirements

### Update (design 5.3)

| Linguagem | Gerador | Versão alvo |
|---|---|---|
| Go | hugo | 0.167.0 |
| JavaScript | gatsby | 5.16.x |
| JavaScript | metalsmith-handlebars | metalsmith 2.7.x (sai do WIP) |
| JavaScript | metalsmith-nunjucks | metalsmith 2.7.x (sai do WIP) |
| PHP | jigsaw | 1.8.8 |
| Python | nikola-mako | 8.3.3 |
| Ruby | jekyll | 4.4.1 |
| Ruby | nanoc | 4.14.8 (Gemfile reduzido a `nanoc`, `kramdown`, `erubi`; sai o grupo `:plugins`) |
| Ruby | middleman | 4.6.3 (sai do WIP) |

- Remover `node_modules/` versionado em `JavaScript/gatsby` (558 arquivos).

### Remove (design 5.3)

**Remover:** `JavaScript/harp-ejs`, `JavaScript/harp-jade`, `JavaScript/phenomic-react`, `JavaScript/cuttlebelle`, `Ruby/webgen`.

## Acceptance criteria

- Every generator in this spec passes the smoke test defined in `docs/specs/001-canonical-build-runner/spec.md` (design 6.2): `./ssgberk --test <name> -nf 10 -cs 500 -mr 1`, with `SSGBERK_VERIFY_OK expected=10 got=10`.
- `tools/check-build-sh.sh` exits 0 after the removals.
- **Gems nativas em Ruby 3.2 (Middleman, Nanoc):** se não compilarem, o gerador volta para `frameworks_WIP/` com o motivo no README dele, sem bloquear os demais. O critério de sucesso 1 passa a contar os geradores restantes, e a exceção é registrada no PR.

## Deviations

- middleman: `blog.sources` is configured without a file extension so that the `YYYY-MM-DD-NNN` post names match.
- nikola-mako: Doit state file is `.doit.db.db` (cleared between runs) and `DOIT_CONFIG` selects the `sqlite3` backend so the cache file name is predictable.
- nikola-mako: single index page via a huge `INDEX_DISPLAY_POST_COUNT`; the archive, categories, tags, authors and page-index classifier plugins are disabled (final review fix wave) so only the index lists all posts.
- Added mid-spec (binding for every generator): post-only templates (a post page never lists other posts), a single index page listing all posts, `pip freeze` full pinning for Python generators, and cold-build rules (cache/state cleared before every timed run).
- Final review fix wave: Ruby/nanoc lock gained the `x86_64-linux` platform, Ruby dockerfiles set `BUNDLE_FROZEN=true`, jigsaw copies composer from `composer:2.8` instead of `curl | php`, nikola-mako uses plain `Nikola==8.3.3` with a full freeze, the 9 generators were re-smoked at `-cs 500`, and Ruby/gatsby READMEs document that the timed command includes wrapper startup.

## Out of scope

- Temas, plugins ou otimizações específicas de algum gerador.
- O monorepo `StaticSiteGeneratorBenchmark`.
- Adding generators (`docs/specs/003-new-generators`).
