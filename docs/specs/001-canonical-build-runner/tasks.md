# Canonical build.sh and Runner — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One canonical `build.sh` that generates the posts, verifies the output, times the build with hyperfine and prints the result markers; Hugo migrated onto it end to end; CI for `ssg-frameworks`.

**Architecture:** Every generator directory carries a byte-identical copy of `Go/hugo/build.sh`; `benchmark_config.json` describes the content, build command, output folder/glob and cache folders. Contract and Dockerfile skeleton are in `docs/specs/001-canonical-build-runner/plan.md`.

**Tech Stack:** bash, jq, moreutils (`sponge`), hyperfine 1.20.0, Ubuntu 24.04, hugo 0.167.0, GitHub Actions.

**Spec:** `docs/specs/001-canonical-build-runner/spec.md` and `docs/specs/001-canonical-build-runner/plan.md` (same directory, repo `ssgberk/ssg-frameworks`). Read both before starting any task.

In this file **BT** = `/Users/jobs/Dev/ssgberk/.worktrees/benchmark-tool-modernize` (repo `ssgberk/benchmark-tool`, branch `chore/modernize-2026`) and **SF** = `BT/frameworks` (repo `ssgberk/ssg-frameworks`, branch `chore/modernize-2026`). Layout: `docs/specs/ROADMAP.md` in BT.

## Global Constraints

- Git author/committer `Matheus Breguêz <matbrgz@gmail.com>`; every commit GPG-signed (repo config already has `commit.gpgsign=true`, key `B6FA8458D5176E83`). Never use `--no-gpg-sign` or `--author`.
- Every commit message ends with the trailer `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Never commit to `master`. Never push, open PRs, or close dependabot branches unless the human explicitly asks.
- Generator base image `ubuntu:24.04`; architecture detected **inside `RUN`** with `ARCH="$(dpkg --print-architecture)"` (`amd64`|`arm64`). Never rely on `TARGETARCH` (empty under the legacy builder docker-py uses — verified on Docker 29).
- Pinned versions: hyperfine `1.20.0`, dool `v1.3.8`, docker-py `7.1.0`, Node `24.21.0`, hugo `0.167.0`, zola `0.23.6`, jekyll `4.4.1`, nanoc `4.14.8`, middleman `4.6.3`, nikola `8.3.3`, pelican `4.12.0`, mkdocs `1.6.1`, jigsaw `v1.8.8`, metalsmith `2.7.0`, gatsby `5.16.1`, astro `7.3.5`, @11ty/eleventy `3.1.6`, hexo `8.1.2`, next `16.3.8`, vitepress `1.6.4`.
- `-cs` values and meaning (KB per post): `0.500`=1 paragraph, `500`=1000, `1000`=2000, `5000`=10000, `10000`=20000, `100000`=200000 paragraphs. Default `0.500`.
- Result markers printed by `build.sh`, consumed by `Results.parse_test`: `SSGBERK_RESULT_BEGIN`, `SSGBERK_RESULT_END`, `SSGBERK_VERIFY_FAIL`, `STARTTIME <epoch>`, `ENDTIME <epoch>`.
- Generated post filenames are `YYYY-MM-DD-NNN.<ext>` (NNN zero-padded by `seq -w`). `build.sh` only ever deletes entries in the content folder matching `[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*`, so section index files (e.g. `_index.md`, `posts.json`) survive.
- Every generator's `build.sh` is byte-identical to `SF/Go/hugo/build.sh`.
- A generator's directory name equals its `benchmark_config.json` `framework` value and its test name (CI derives the test name from the directory basename).
- No themes, plugins beyond the baseline set, minification or speed tweaks; every site builds the Core reference site of docs/specs/005-reference-site-design (supersedes the former minimal-site rule).

## Review Focus

1. **Incremental builds masking timings** — a generator reusing its previous output (jekyll `--incremental`, gatsby cache, astro cache) reports near-zero times after run 1. Expect `build.sh` to delete the output folder and known caches before every hyperfine run via `--prepare`. Pinned by the `prepare` assertion in Task 1's `test_build_sh.bats`-style shell test (`tests/build_sh/test_build_sh.sh`) and per-generator `cache_folders`.
2. **Glob matching more than the posts** — `output_glob` that also matches index/tag pages makes a broken post template look "OK". Expect verification to require `got == expected` for an empty site. Pinned by `test_verify_counts_exact` in Task 1.
3. **Sample posts shipped in `src/`** — old sample content (e.g. jekyll `_posts/2014-*.md`) inflates the workload and the count. Expect `build.sh` to remove date-named entries before generating. Pinned by `test_reset_removes_only_dated_entries` in Task 1.
4. **Unknown / legacy `-cs` value** — `[500]` from old scripts or `0.500` must keep their meaning; an unknown value must fail loudly, not silently fall back to one paragraph. Pinned by `test_content_size_unknown_fails` in Task 1 and `test_cs_rejects_unknown` in `benchmark-tool` `docs/specs/001-python3-toolset/tasks.md` Task 3.

---

### Task 1: Canonical `build.sh` + Hugo end-to-end

**Files (SF):**
- Create: `Go/hugo/build.sh` (canonical), `tools/check-build-sh.sh`, `tests/build_sh/test_build_sh.sh`, `.gitignore`
- Modify: `Go/hugo/hugo.dockerfile`, `Go/hugo/benchmark_config.json`, `Go/hugo/src/config.toml`, `Go/hugo/README.md`; copy newer `src/` from monorepo where it differs (`/Users/jobs/Dev/ssgberk/StaticSiteGeneratorBenchmark/frameworks/Go/hugo/src`)

**Interfaces:**
- Consumes: env vars from `DatarateTestType.get_script_variables()`: `number_of_files`, `content_size`, `min_runs`, `verbose_build` (strings; `verbose_build` is `"True"`/`"False"` from Python bool → treat `True|true` as true).
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

- [ ] **Step 1: Write the shell test** — `tests/build_sh/test_build_sh.sh` runs `Go/hugo/build.sh` against a fake generator whose "build command" is a tiny shell script, inside `ubuntu:24.04` with jq/moreutils/hyperfine:

```bash
#!/bin/bash
# Usage: tests/build_sh/test_build_sh.sh   (from SF root; needs docker)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
docker run --rm -v "$ROOT":/sf -w /work ubuntu:24.04 bash -c '
set -euo pipefail
apt-get -qq update >/dev/null && apt-get -qq install -y --no-install-recommends jq moreutils curl ca-certificates >/dev/null
ARCH=$(dpkg --print-architecture)
curl -fsSL -o /tmp/h.deb https://github.com/sharkdp/hyperfine/releases/download/v1.20.0/hyperfine_1.20.0_${ARCH}.deb && dpkg -i /tmp/h.deb >/dev/null
fail() { echo "FAIL: $*"; exit 1; }

setup() {
  rm -rf /work/* && mkdir -p /work/posts && cd /work
  cp /sf/Go/hugo/build.sh .
  echo keep > posts/_index.md
  echo old > posts/2014-01-01-sample.md
  # fake generator: one html per post into out/posts/<name>.html, plus an index.html
  cat > gen.sh <<"EOF"
#!/bin/bash
mkdir -p out/posts; for f in posts/[0-9]*.md; do b=$(basename "$f" .md); echo "<h1>$b</h1>" > "out/posts/$b.html"; done; echo idx > out/index.html
[ -f out/stale.marker ] && echo "STALE_OUTPUT_SEEN"; touch out/stale.marker
EOF
  chmod +x gen.sh
  cat > benchmark_config.json <<EOF
{"framework":"fake","tests":[{"default":{}}],
 "content":[{"folder":"posts","type":"$1","extension":"md"}],
 "config":[{"metadata_dateslug":"date","metadata_layout":"","build_command":"./gen.sh","build_verbose":"",
            "output_folder":"out","output_glob":"$2"}]}
EOF
}

# test_verify_counts_exact + happy path + markers
setup 3minus "posts/*.html"
out=$(number_of_files=5 content_size=0.500 min_runs=2 verbose_build=True bash build.sh)
echo "$out" | grep -q "SSGBERK_VERIFY_OK expected=5 got=5" || fail "verify ok line"
echo "$out" | grep -q "^SSGBERK_RESULT_BEGIN$" || fail "begin marker"
echo "$out" | grep -q "^SSGBERK_RESULT_END$" || fail "end marker"
echo "$out" | grep -qE "^STARTTIME [0-9]+$" || fail "starttime"
echo "$out" | grep -qE "^ENDTIME [0-9]+$" || fail "endtime"
echo "$out" | sed -n "/^SSGBERK_RESULT_BEGIN$/,/^SSGBERK_RESULT_END$/p" | sed "1d;\$d" | jq -e ".results[0].times | length == 2" >/dev/null || fail "json times"
# prepare wipes output before each timed run (verbose => --show-output, so gen.sh output is visible)
echo "$out" | grep -q STALE_OUTPUT_SEEN && fail "output not cleaned between runs"

# test_reset_removes_only_dated_entries
[ -f posts/_index.md ] || fail "_index.md must survive"
[ ! -e posts/2014-01-01-sample.md ] || fail "sample post must be removed"
[ -z "$(ls posts | grep -E "^[0-9]{4}-")" ] || fail "generated posts must be removed at end"

# glob that also matches index.html -> got > expected -> VERIFY_FAIL
setup 3minus "*.html"
out=$(number_of_files=5 content_size=0.500 min_runs=1 verbose_build=False bash build.sh || true)
echo "$out" | grep -q "SSGBERK_VERIFY_FAIL expected=5 got=6" || fail "over-count must fail"
echo "$out" | grep -q SSGBERK_RESULT_BEGIN && fail "no result after verify fail"

# test_content_size_unknown_fails
setup 3minus "posts/*.html"
out=$(number_of_files=1 content_size=7 min_runs=1 verbose_build=False bash build.sh 2>&1 || true)
echo "$out" | grep -q "unknown content_size" || fail "unknown cs must fail loudly"

# legacy [500] accepted and sizes are right
setup none "posts/*.html"
number_of_files=1 content_size="[500]" min_runs=1 verbose_build=False KEEP_CONTENT=1 bash build.sh >/dev/null
size=$(stat -c %s posts/[0-9]*.md); [ "$size" -gt 500000 ] || fail "500 => ~550KB, got $size"

# 3plus header
setup 3plus "posts/*.html"
number_of_files=1 content_size=0.500 min_runs=1 verbose_build=False KEEP_CONTENT=1 bash build.sh >/dev/null
head -1 posts/[0-9]*.md | grep -qx "+++" || fail "3plus header"
echo "ALL build.sh TESTS PASSED"
'
```

`KEEP_CONTENT=1` is a test-only switch: when set, `build.sh` skips the final cleanup so the test can inspect generated files.

- [ ] **Step 2: Run it against the old build.sh to see it fail**

```bash
cp /Users/jobs/Dev/ssgberk/StaticSiteGeneratorBenchmark/frameworks/Go/hugo/build.sh Go/hugo/build.sh
chmod +x tests/build_sh/test_build_sh.sh && tests/build_sh/test_build_sh.sh
```

Expected: `FAIL: verify ok line`.

- [ ] **Step 3: Write the canonical `Go/hugo/build.sh`** (full replacement):

```bash
#!/bin/bash
# SSGBerk canonical build.sh — every generator directory carries an identical copy.
# Inputs (env): number_of_files, content_size, min_runs, verbose_build
# Reads: ./benchmark_config.json   Prints: SSGBERK_* markers parsed by the toolset.
export LANG=C.UTF-8
set -u

for cmd in jq sponge hyperfine; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "[ ERROR ] required command not installed: ${cmd}"
        exit 1
    fi
done

number_of_files="${number_of_files:-100}"
content_size="${content_size:-0.500}"
content_size="${content_size//[\[\]]/}"
min_runs="${min_runs:-3}"
verbose_build="${verbose_build:-false}"
case "${verbose_build}" in True|true|1) verbose_build=true ;; *) verbose_build=false ;; esac

cfg="${PWD}/benchmark_config.json"
build_command=$(jq -r '.config[0].build_command' "${cfg}")
build_verbose=$(jq -r '.config[0].build_verbose // ""' "${cfg}")
metadata_layout=$(jq -r '.config[0].metadata_layout // ""' "${cfg}")
metadata_dateslug=$(jq -r '.config[0].metadata_dateslug // "date"' "${cfg}")
output_folder=$(jq -r '.config[0].output_folder // ""' "${cfg}")
output_glob=$(jq -r '.config[0].output_glob // ""' "${cfg}")
cache_folders=$(jq -r '(.config[0].cache_folders // []) | join(" ")' "${cfg}")
content_type=$(jq -r '.content[0].type' "${cfg}")
content_folder=$(jq -r '.content[0].folder' "${cfg}")
content_extension=$(jq -r '.content[0].extension' "${cfg}")
[ -z "${build_verbose}" ] && build_verbose="${build_command}"

today=$(date +%F)
dated_pattern='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*'

# Remove generated (date-named) posts only; section index files survive.
reset_content()
{
    mkdir -p "${content_folder}"
    find "${content_folder}" -mindepth 1 -maxdepth 1 -name "${dated_pattern}" -exec rm -rf {} +
}

clean_output()
{
    [ -n "${output_folder}" ] && rm -rf "${output_folder}"
    for d in ${cache_folders}; do rm -rf "${d}"; done
    return 0
}

paragraph="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum euismod luctus massa. Pellentesque porta augue non varius semper. In vitae pulvinar dolor. Nunc erat sem, facilisis eu augue in, aliquam viverra magna. Quisque porttitor sodales diam, a vestibulum sem semper vel. Integer tempus quam eu ex egestas, sed auctor neque venenatis. Fusce mattis metus pellentesque iaculis euismod. Vestibulum a dictum lectus, a porta odio. Etiam sit amet lobortis lorem. Mauris iaculis ornare risus, at dictum nullam."

case "${content_size}" in
    0.500)  repetitions=1 ;;
    500)    repetitions=1000 ;;
    1000)   repetitions=2000 ;;
    5000)   repetitions=10000 ;;
    10000)  repetitions=20000 ;;
    100000) repetitions=200000 ;;
    *) echo "[ ERROR ] unknown content_size: ${content_size}"; exit 1 ;;
esac
content=$(yes "${paragraph}" | head -n "${repetitions}" | tr -d '\n')

header_for()
{
    local title="${1}"
    case "${content_type}" in
    3minus)
        printf -- '---\n'
        [ -n "${metadata_layout}" ] && printf '%s\n' "${metadata_layout}"
        printf '%s: %s\ntitle: "%s"\n---\n' "${metadata_dateslug}" "${today}" "${title}"
        ;;
    3plus)
        printf '+++\ntitle = "%s"\n%s = %s\n+++\n' "${title}" "${metadata_dateslug}" "${today}"
        ;;
    2dot)
        [ -n "${metadata_layout}" ] && printf '.. %s\n' "${metadata_layout}"
        printf '.. title: %s\n.. slug: %s\n.. %s: %s\n\n' "${title}" "${title}" "${metadata_dateslug}" "${today}"
        ;;
    none) ;;
    *) echo "[ ERROR ] unknown content type: ${content_type}" >&2; exit 1 ;;
    esac
}

reset_content
echo "Generating ${number_of_files} posts (${content_size} KB) in ${content_folder}"
for i in $(seq -w 1 "${number_of_files}"); do
    name="${today}-${i}"
    { header_for "${name}"; printf '%s\n' "${content}"; } | sponge "${content_folder}/${name}.${content_extension}"
done
[ "${verbose_build}" = true ] && ls -sh "${content_folder}"

if [ "${verbose_build}" = true ]; then
    command="${build_verbose}"
else
    command="${build_command}"
fi

# Untimed verification build: the site must contain exactly one page per post.
clean_output
eval "${command}" > /tmp/ssgberk-verify.log 2>&1
verify_status=$?
if [ "${verify_status}" -ne 0 ]; then
    cat /tmp/ssgberk-verify.log
    echo "SSGBERK_VERIFY_FAIL build exited ${verify_status}"
    [ -z "${KEEP_CONTENT:-}" ] && reset_content
    exit 1
fi
if [ -n "${output_folder}" ] && [ -n "${output_glob}" ]; then
    got=$(find "${output_folder}" -type f -path "${output_folder}/${output_glob}" | wc -l | tr -d ' ')
    if [ "${got}" -ne "${number_of_files}" ]; then
        cat /tmp/ssgberk-verify.log
        echo "SSGBERK_VERIFY_FAIL expected=${number_of_files} got=${got}"
        [ -z "${KEEP_CONTENT:-}" ] && reset_content
        exit 1
    fi
    echo "SSGBERK_VERIFY_OK expected=${number_of_files} got=${got}"
else
    echo "[ WARN ] output_folder/output_glob not set; skipping output verification"
fi

show_output=""
[ "${verbose_build}" = true ] && show_output="--show-output"
prepare_cmd="true"
if [ -n "${output_folder}" ] || [ -n "${cache_folders}" ]; then
    prepare_cmd="rm -rf ${output_folder} ${cache_folders}"
fi

echo "STARTTIME $(date +%s)"
hyperfine --time-unit second --min-runs "${min_runs}" --max-runs "${min_runs}" \
    --prepare "${prepare_cmd}" ${show_output} \
    --export-json /tmp/ssgberk-hyperfine.json "${command}"
hyperfine_status=$?
echo "ENDTIME $(date +%s)"
echo "Number of files: ${number_of_files} | content size: ${content_size} KB | runs: ${min_runs}"

if [ "${hyperfine_status}" -eq 0 ]; then
    echo "SSGBERK_RESULT_BEGIN"
    cat /tmp/ssgberk-hyperfine.json
    echo
    echo "SSGBERK_RESULT_END"
fi

[ -z "${KEEP_CONTENT:-}" ] && reset_content
exit "${hyperfine_status}"
```

Why the stale check works: `gen.sh` prints `STALE_OUTPUT_SEEN` only if `out/` survived from a previous build. The first test case runs with `verbose_build=True`, so hyperfine runs with `--show-output` and that line would reach the captured output if `--prepare` failed to remove `output_folder` between runs.

- [ ] **Step 4: Run** — `tests/build_sh/test_build_sh.sh` → `ALL build.sh TESTS PASSED`.

- [ ] **Step 5: `tools/check-build-sh.sh`**

```bash
#!/bin/bash
# Fails if any generator's build.sh differs from the canonical Go/hugo/build.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
for f in */*/build.sh; do
    if ! cmp -s Go/hugo/build.sh "$f"; then echo "differs: $f"; status=1; fi
done
exit $status
```

(It will fail until `docs/specs/002-update-existing-generators/tasks.md` Task 7 is done; that's expected. Do not copy build.sh into other generators in this task.)

- [ ] **Step 6: Hugo**

`Go/hugo/hugo.dockerfile`: skeleton (from `docs/specs/001-canonical-build-runner/plan.md`) with `<name>`=`hugo`, no RUNTIME block, GENERATOR block:

```dockerfile
ARG HUGO_VERSION=0.167.0
RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hugo.deb \
      "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${ARCH}.deb" \
 && dpkg -i /tmp/hugo.deb && rm /tmp/hugo.deb && hugo version
```

`Go/hugo/src/`: start from the monorepo copy (`cp -R /Users/jobs/Dev/ssgberk/StaticSiteGeneratorBenchmark/frameworks/Go/hugo/src/. Go/hugo/src/`). In `config.toml`: rename to `hugo.toml` is NOT required; remove the `config = "config.toml"` line; set `disableKinds = ["taxonomy", "term", "RSS", "sitemap", "robotsTXT", "404"]` (keeps `page`, `home`, `section`); `baseURL = "/"` (Hugo ≥0.60 key casing). Replace deprecated template calls Hugo 0.167 rejects (check build output: `.Site.RSSLink`, `.Hugo`, `.RSSLink`, `.Data.Pages` → `.Site.RegularPages`, `.UniqueID`, `{{ template "_internal/..." }}` that no longer exist). Ensure `layouts/_default/single.html` renders `.Content`.

`Go/hugo/benchmark_config.json`: keep `tests`; `content`: `{"folder": "content/post", "type": "3minus", "extension": "md"}`; `config`: `{"metadata_dateslug": "date", "metadata_layout": "", "build_command": "hugo --quiet", "build_verbose": "hugo --logLevel debug", "output_folder": "public", "output_glob": "post/*/index.html", "cache_folders": ["resources/_gen"]}` (drop `layout: post` unless the theme uses it).

`Go/hugo/README.md`: one paragraph: generator, version, content folder, output glob, how to run (`./ssgberk --test hugo -nf 10`).

`.gitignore` (SF root): `node_modules/`, `public/`, `_site/`, `.DS_Store`.

- [ ] **Step 7: End-to-end** — run the Generator smoke procedure (`docs/specs/001-canonical-build-runner/plan.md`) for `hugo`. Expected: pass; `got=10`.

- [ ] **Step 8: Commit (SF)** — `git add -A Go/hugo tools tests .gitignore && git commit -m "feat(hugo): canonical build.sh with result markers; hugo 0.167.0" -m "The previous config disabled the page kind, so hugo never rendered posts. Output verification now catches that." -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"`

### Task 2: `ssg-frameworks` CI

**Prerequisite:** run this task after `docs/specs/002-update-existing-generators` and `docs/specs/003-new-generators` are complete (step 3 needs every `build.sh` to equal the canonical one, and the README lists all 17 generators).

**Files (SF):** `.github/workflows/ci.yml`, `README.md` (new, short), `LICENSE` (keep).

- [ ] **Step 1:** `.github/workflows/ci.yml`:

```yaml
name: ci
on:
  push:
    branches: [master]
  pull_request:

jobs:
  checks:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - run: tools/check-build-sh.sh
      - run: tests/build_sh/test_build_sh.sh

  changed:
    runs-on: ubuntu-24.04
    outputs:
      tests: ${{ steps.diff.outputs.tests }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          path: frameworks
      - uses: actions/checkout@v4
        with:
          repository: ssgberk/benchmark-tool
          path: bt
      - id: diff
        run: |
          base=${{ github.event.pull_request.base.sha || 'HEAD~1' }}
          tests=$(python3 bt/toolset/github_actions/github_actions_diff.py --base "$base" --repo frameworks \
                  | xargs -n1 basename | jq -R . | jq -cs .)
          echo "tests=$tests" >> "$GITHUB_OUTPUT"

  smoke:
    needs: changed
    if: needs.changed.outputs.tests != '[]'
    strategy:
      fail-fast: false
      matrix:
        test: ${{ fromJson(needs.changed.outputs.tests) }}
        runner: [ubuntu-24.04, ubuntu-24.04-arm]
    runs-on: ${{ matrix.runner }}
    steps:
      - uses: actions/checkout@v4
        with:
          repository: ssgberk/benchmark-tool
      - uses: actions/checkout@v4
        with:
          path: frameworks
      - run: ./ssgberk --test ${{ matrix.test }} -nf 10 -cs 0.500 -mr 1
      - run: |
          R=$(ls -td results/*/ | head -1)
          jq -e --arg t "${{ matrix.test }}" '.succeeded.datarate | index($t)' "$R/results.json"
          jq -e --arg t "${{ matrix.test }}" '.rawData.datarate[$t][0].mean > 0' "$R/results.json"
```

Note: `./ssgberk` uses `docker run -i -t` only when stdout is a TTY, so it works in Actions. Until `benchmark-tool`'s branch is merged, the `bt` checkout gets the old toolset; the `smoke` job is expected to fail on PRs opened before the `benchmark-tool` branch `chore/modernize-2026` (`docs/specs/001-python3-toolset` and `docs/specs/002-hyperfine-results` in that repo) is merged — say so in the PR description.

- [ ] **Step 2:** `README.md` (SF): table of the 17 generators (language, name, version, content type, output glob) and "how to add a generator" (copy canonical `build.sh`, follow the dockerfile skeleton, set `output_folder`/`output_glob`, run `./ssgberk --test <name> -nf 10`).

- [ ] **Step 3:** `tools/check-build-sh.sh && tests/build_sh/test_build_sh.sh` → pass. Commit `ci: add build.sh checks and per-generator smoke tests`.
