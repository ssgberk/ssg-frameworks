# Canonical build.sh and Runner — Plan

Spec: `spec.md`. Tasks: `tasks.md`. This plan owns the marker contract, the `benchmark_config.json` schema, the Dockerfile skeleton and the smoke procedure; `docs/specs/002-update-existing-generators`, `docs/specs/003-new-generators` and `benchmark-tool/docs/specs/002-hyperfine-results` reference this file rather than copying it.

## Architecture

Every generator directory carries a byte-identical copy of `Go/hugo/build.sh`. The script generates the posts, runs an untimed verification build, then times the build with hyperfine and prints the markers below for the toolset to parse.

## Contracts

### Marker contract between `build.sh` and the toolset (design 4.3)

- `build.sh` roda `hyperfine ... --export-json /tmp/ssgberk-hyperfine.json` e, ao final, imprime no stdout:

  ```
  SSGBERK_RESULT_BEGIN
  <conteúdo de /tmp/ssgberk-hyperfine.json>
  SSGBERK_RESULT_END
  ```

Verification markers (design 5.4): `SSGBERK_VERIFY_FAIL expected=<n> got=<m>` (also `SSGBERK_VERIFY_FAIL build exited <code>` when the verification build fails) and `SSGBERK_VERIFY_OK expected=<n> got=<m>`.

- Parse de estatísticas do `dool` (`__parse_stats`) continua igual, chamado com `startTime`/`endTime` vindos de linhas `STARTTIME <epoch>` / `ENDTIME <epoch>` que o `build.sh` imprime antes e depois do hyperfine.

- Result markers printed by `build.sh`, consumed by `Results.parse_test`: `SSGBERK_RESULT_BEGIN`, `SSGBERK_RESULT_END`, `SSGBERK_VERIFY_FAIL`, `STARTTIME <epoch>`, `ENDTIME <epoch>`.

### `benchmark_config.json` schema

- Produces: `benchmark_config.json` schema used by every generator task:
  ```json
  {
    "framework": "<name>",
    "tests": [{"default": {"approach": "Realistic", "classification": "Micro", "framework": "<name>",
                "language": "<Lang>", "display_name": "<name>", "notes": "", "versus": "<lang-lower>"}}],
    "content": [{"folder": "<dir>", "type": "3minus|3plus|2dot|none", "extension": "md"}],
    "config": [{"metadata_dateslug": "date", "metadata_layout": "", "build_command": "<cmd>",
                "build_verbose": "<cmd>", "output_folder": "<dir>", "output_glob": "<find -path pattern>",
                "cache_folders": ["<dir>", "..."]}]
  }
  ```
  `output_glob` is matched with `find <output_folder> -type f -path "<output_folder>/<output_glob>"`. `cache_folders` is optional.

### Generator image and architecture

- Generator base image `ubuntu:24.04`; architecture detected **inside `RUN`** with `ARCH="$(dpkg --print-architecture)"` (`amd64`|`arm64`). Never rely on `TARGETARCH` (empty under the legacy builder docker-py uses — verified on Docker 29).

## Generator Dockerfile skeleton (used by `002-update-existing-generators`, `003-new-generators` and Task 1 of this spec)

Every `<name>.dockerfile` has exactly this shape; tasks fill in the RUNTIME and GENERATOR blocks and `<name>`:

```dockerfile
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      build-essential ca-certificates curl git jq moreutils tree wget xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

# ---- RUNTIME block (per task) ----

WORKDIR /opt/<name>/src

# ---- GENERATOR block (per task): copy manifests, install deps ----

COPY src/ /opt/<name>/src/
COPY build.sh benchmark_config.json /opt/<name>/src/
```

Node RUNTIME block (JS generators):

```dockerfile
ARG NODE_VERSION=24.21.0
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) NARCH=x64 ;; arm64) NARCH=arm64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NARCH}.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1 \
 && node --version && npm --version
```

Ruby RUNTIME block:

```dockerfile
RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends ruby ruby-dev zlib1g-dev libffi-dev libyaml-dev \
 && rm -rf /var/lib/apt/lists/* \
 && gem install bundler --no-document
```

Python RUNTIME block:

```dockerfile
RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends python3 python3-venv python3-dev \
 && rm -rf /var/lib/apt/lists/* \
 && python3 -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
```

## Generator smoke procedure (used by `002-update-existing-generators`, `003-new-generators` and Task 1 of this spec)

From BT, after `benchmark-tool` specs `001-python3-toolset` and `002-hyperfine-results` are done:

```bash
cd /Users/jobs/Dev/ssgberk/.worktrees/benchmark-tool-modernize
./ssgberk --test <name> -nf 10 -cs 0.500 -mr 1
R=$(ls -td results/*/ | head -1)
jq -e '.succeeded.datarate | index("<name>")' "$R/results.json"
jq -e '.rawData.datarate["<name>"][0].mean > 0' "$R/results.json"
grep -c SSGBERK_VERIFY_FAIL "$R/<name>/datarate/raw.txt"   # must print 0
```

Expected: both `jq -e` exit 0; grep prints `0`. Also confirm the glob is exact: run the generator image by hand with `-nf 10` and check the verify line in `raw.txt` reads `SSGBERK_VERIFY_OK expected=10 got=10` (got must equal expected, not exceed it — if it exceeds, the glob matches non-post pages; tighten it).

Commit per generator inside SF:

```bash
cd /Users/jobs/Dev/ssgberk/.worktrees/benchmark-tool-modernize/frameworks
git add -A <Lang>/<name>
git commit -m "feat(<name>): <update to|add> <version> on ubuntu 24.04

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

If a generator cannot be made to pass after a genuine attempt (native gem fails to build, upstream bug): inside SF run `git mv <Lang>/<name> _wip/<Lang>/<name>`, add `_wip/<Lang>/<name>/WIP.md` with the exact error output, commit, and report the task as DONE_WITH_CONCERNS. `Metadata.gather_tests` globs `frameworks/*/*/benchmark_config.json`, so `_wip/<Lang>/<name>` (three levels) is not picked up.

## Decisions

- Architecture is detected with `dpkg --print-architecture`, never `TARGETARCH` (design 5.2).
- `hyperfine` runs without `--ignore-failure`; `--prepare` wipes `output_folder` and `cache_folders` before each timed run so incremental builds cannot mask timings.
- Hugo's `Go/hugo/src/config.toml` stops disabling the `page` kind (see spec); output verification prevents the regression.

## Risks

See **Review Focus** in `tasks.md` (incremental builds, over-matching globs, sample posts in `src/`, unknown `-cs` values).

## Delivery order (design 7)

3. **ssg-frameworks:** `build.sh` canônico + dockerfile base + `Go/hugo`, validado de ponta a ponta com o toolset do passo 2.

Task 2 (CI) runs after `docs/specs/002-update-existing-generators` and `docs/specs/003-new-generators` are complete (see Roadmap).
