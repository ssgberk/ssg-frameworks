# New Generators

- **Repo:** `ssgberk/ssg-frameworks`
- **Date:** 2026-10-04
- **Status:** proposed, awaiting review (approved design redistributed from `2026-10-04-modernize-ssgberk-design.md`)
- **Siblings:** `plan.md` (how), `tasks.md` (executable task list) in this directory; roadmap in `benchmark-tool/docs/specs/ROADMAP.md`

## Context

| Item | Hoje | Problema |
|---|---|---|
| Geradores | `ubuntu:18.04`, Node 10, hugo 0.58.2, hyperfine 1.7.0 | Imagens EOL; binários só amd64; 8 dockerfiles com linha corrompida (`... \| bash - && /\|RUN curl ...`) |

## Requirements

### Add (design 5.3)

**Adicionar:**

| Linguagem | Gerador | Versão alvo | `content.type` | Pasta de conteúdo |
|---|---|---|---|---|
| Rust | zola | 0.23.6 | `3plus` | `content/posts` |
| JavaScript | astro | 7.3.x | `3minus` | `src/content/posts` |
| JavaScript | eleventy | 3.1.x | `3minus` | `posts` |
| JavaScript | hexo | 8.1.x | `3minus` | `source/_posts` |
| JavaScript | nextjs-export | 16.3.x | `3minus` | `content/posts` |
| JavaScript | vitepress | 1.6.x | `3minus` | `posts` |
| Python | pelican | 4.12.x | `3minus` | `content` |
| Python | mkdocs | 1.6.x | `none` | `docs/posts` |

Cada site novo tem só: um layout base, um template de post e uma página índice listando os posts, sem tema, plugins ou otimização de assets. As versões "x" são fixadas no lockfile no momento da implementação.

Total: 17 geradores em 6 linguagens.

## Acceptance criteria

- Every generator in this spec passes the smoke test defined in `docs/specs/001-canonical-build-runner/spec.md` (design 6.2): `./ssgberk --test <name> -nf 10 -cs 500 -mr 1`, with `SSGBERK_VERIFY_OK expected=10 got=10`.
- One commit per generator.

## Out of scope

- Temas, plugins ou otimizações específicas de algum gerador.
- O monorepo `StaticSiteGeneratorBenchmark`.
- Updating existing generators (`docs/specs/002-update-existing-generators`).
