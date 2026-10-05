# More Generators (wave 1) — Plan

Spec: `spec.md`. Tasks: `tasks.md`. Contracts are owned by `docs/specs/001-canonical-build-runner/plan.md` (dockerfile skeleton, `benchmark_config.json`, markers, smoke procedure); this plan only adds what is new for parallel work.

## Parallel work

- One worktree and branch per generator, `feat/007-<dir name>`, each based on `feat/007-more-generators` (which holds this spec). The controller opens one PR per generator as soon as it passes review; the first PR to merge carries the spec commits, later ones are rebased on master.
- Implementers never touch files outside their generator directory except their own entry produced by `tools/build_index.py`; the controller removes the generator's entry from `tools/proposed.json` and regenerates `generators.json` in that generator's PR.

## Local smoke (replaces the benchmark-tool run during iteration)

The toolset starts a generator as `docker run ... ssgberk/test.<name> /bin/bash ./build.sh` with the env inputs from spec 001. The direct equivalent, used while iterating:

```bash
docker build -f <name>.dockerfile -t ssgberk/test.<name> .
docker run --rm --ulimit nofile=65535:65535 --cpus 4 --memory 6g \
  -e number_of_files=10 -e content_size=0.500 -e min_runs=1 -e verbose_build=false -e profile=core \
  ssgberk/test.<name> /bin/bash ./build.sh
```

The full toolset smoke (`./ssgberk --test <name> ...`) runs in the PR's CI.

## Shared-machine rules

The development machine has about 10 GiB of free disk and one Docker VM (8 GB).

- **One Docker job at a time.** Every `docker build`/`docker run` happens inside the lock `/Users/jobs/Dev/ssgberk/.docker-smoke.lock` (`mkdir` to take it, `rmdir` to release; wait while it exists).
- **Disk guard.** Before `docker build`, require at least 5 GiB free on `/System/Volumes/Data`; otherwise wait.
- **Clean up only your own image.** After each smoke round, `docker rmi -f ssgberk/test.<name>`. Never prune images, volumes or build cache globally (other projects use this Docker).

## Decisions

- Directory names: `nuxt-content` (Nuxt is an application framework; the content module is what makes it an SSG here) and `sveltekit`.
- mdBook only renders files listed in `SUMMARY.md`. Its `build_command` regenerates `src/SUMMARY.md` from the post files before `mdbook build`; that listing is part of the timed build, as it would be for a real mdBook site.
- Sphinx reads markdown through MyST-Parser, the standard Sphinx markdown extension; it counts as the baseline, not a plugin tweak.
