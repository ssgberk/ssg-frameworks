# New Generators — Plan

Spec: `spec.md`. Tasks: `tasks.md`. Depends on `docs/specs/001-canonical-build-runner` Task 1; the `benchmark_config.json` schema, Dockerfile skeleton, smoke procedure and `_wip/` fallback are in `docs/specs/001-canonical-build-runner/plan.md`.

## Architecture

One task per generator; each follows the Standard steps at the top of `tasks.md`. Each site has only a base layout, a post template and an index listing posts.

## Risks

- **Bundlers dominam o tempo de geradores JS "app-like" (Gatsby, Next.js, Astro, VitePress) com poucos arquivos.** É o comportamento real deles; fica documentado no README, sem ajuste.

## Delivery order (design 7)

5. **ssg-frameworks:** adicionar os 8 novos (1 commit por gerador).
