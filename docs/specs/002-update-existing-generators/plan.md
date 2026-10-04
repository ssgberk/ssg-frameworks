# Update Existing Generators — Plan

Spec: `spec.md`. Tasks: `tasks.md`. Depends on `docs/specs/001-canonical-build-runner` Task 1 (canonical `build.sh`, `tools/check-build-sh.sh`); the `benchmark_config.json` schema, Dockerfile skeleton, smoke procedure and `_wip/` fallback are in `docs/specs/001-canonical-build-runner/plan.md`.

## Architecture

One task per generator (plus metalsmith pair and removal of the dead generators). Each follows the Standard steps at the top of `tasks.md`.

## Risks

- **Gems nativas em Ruby 3.2 (Middleman, Nanoc):** se não compilarem, o gerador volta para `frameworks_WIP/` com o motivo no README dele, sem bloquear os demais. O critério de sucesso 1 passa a contar os geradores restantes, e a exceção é registrada no PR.

## Delivery order (design 7)

4. **ssg-frameworks:** atualizar os outros 5 geradores ativos (gatsby, jigsaw, nikola-mako, jekyll, nanoc), atualizar e ativar os 3 do WIP (metalsmith-handlebars, metalsmith-nunjucks, middleman), remover os 5 mortos.
