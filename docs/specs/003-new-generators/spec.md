# New Generators

- **Repo:** `ssgberk/ssg-frameworks`
- **Date:** 2026-10-04
- **Status:** concluído (2026-10-04)
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

Cada site novo tem só: um layout base, um template de post (título + conteúdo, sem listar outros posts) e uma única página índice listando todos os posts, sem tema, plugins ou otimização de assets extras. As versões "x" são fixadas no lockfile no momento da implementação.

Total: 17 geradores em 6 linguagens.

## Acceptance criteria

- Every generator in this spec passes the smoke test defined in `docs/specs/001-canonical-build-runner/spec.md` (design 6.2): `./ssgberk --test <name> -nf 10 -cs 500 -mr 1`, with `SSGBERK_VERIFY_OK expected=10 got=10`.
- One commit per generator.

## Out of scope

- Temas, plugins ou otimizações específicas de algum gerador.
- O monorepo `StaticSiteGeneratorBenchmark`.
- Updating existing generators (`docs/specs/002-update-existing-generators`).

## Deviations (as built)

- **vitepress:** the index lists posts through a `createContentLoader` data file (`posts.data.js`), and a minimal custom theme (bare layout, no nav/sidebar/search) is used.
- **mkdocs:** custom minimal theme (`src/theme`) and `plugins: []` (search disabled); an empty `theme/sitemap.xml` suppresses the sitemap.
- **pelican:** custom theme; all list pages (archives, categories, tags, authors, pagination, feeds) disabled; titles keep literal quotes.
- **astro:** `node_modules/.vite` (and `.astro`, `node_modules/.astro`) added to `cache_folders` for cold builds.
- **Python generators:** `requirements.txt` is the full `pip freeze` taken inside the built image.
- **gatsby:** `node_modules/.cache` added to `cache_folders` (gatsby's own `clean` treats babel-loader/terser caches there as build caches).
- **Mid-spec rules adopted:** cold-build rule (every surviving tool cache listed in `cache_folders`), metadata rule (`generator.json` per generator plus `generators.json` index), and single-index rule (post pages render only their post; one index lists all posts, pagination disabled).
- **Final fix wave (2026-10-04):** zola section no longer renders (`render = false`, `section.html` removed) and sitemap/robots/404 are empty overrides; mkdocs sitemap removed; `NPM_CONFIG_UPDATE_NOTIFIER=false` in all Node images; README notes added. `vitepress build` has no `--debug` flag in 1.6.4, so `build_verbose` is unchanged.
- **`-cs 500` acceptance:** verified locally for zola and mkdocs only (host disk limits). The other six (astro, eleventy, hexo, nextjs-export, vitepress, pelican) are verified through a CI `workflow_dispatch` run with `content_size=500`; run id: to be recorded by the controller.
