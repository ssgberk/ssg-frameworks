# 005 Reference Site Design — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the reference site's shared pieces: the deterministic rich content generator inside the canonical `build.sh`, the reference assets, the literal reference HTML, and the CI check that keeps asset copies identical. Porting each generator's templates is done by `docs/specs/006-layout-conformance` (one task per generator), after this spec's tasks.

**Architecture:** `build.sh` embeds one awk program that writes all N posts (front matter + 512-byte blocks) as specified in `plan.md` "Content model". `reference/` holds the canonical CSS, PNG and reference HTML. `tools/check-reference-assets.sh` compares every generator's asset copies with `reference/assets/`.

**Tech Stack:** bash, mawk (Ubuntu 24.04 default awk), jq, Python 3 stdlib (PNG writer, tests), hyperfine 1.20.0.

**Spec:** `docs/specs/005-reference-site-design/spec.md` and `plan.md` (repo `ssgberk/ssg-frameworks`). Read both before starting any task.

In this file **BT** = `/Users/jobs/Dev/ssgberk/.worktrees/benchmark-tool-modernize` (repo `ssgberk/benchmark-tool`, branch `chore/modernize-2026`) and **SF** = `BT/frameworks` (repo `ssgberk/ssg-frameworks`, branch `chore/modernize-2026`).

## Global Constraints

- Git author/committer `Matheus Breguêz <matbrgz@gmail.com>`; every commit GPG-signed (repo config already has `commit.gpgsign=true`, key `B6FA8458D5176E83`). Never use `--no-gpg-sign` or `--author`.
- Every commit message ends with the trailer `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Never commit to `master`. Never push, open PRs, or close dependabot branches unless the human explicitly asks.
- Every generator's `build.sh` is byte-identical to `SF/Go/hugo/build.sh` (`tools/check-build-sh.sh`).
- `-cs` values and meaning: `0.500`=1 block, `5`=10, `50`=100, `500`=1000, `1000`=2000, `5000`=10000, `10000`=20000, `100000`=200000 blocks of exactly 512 bytes. Any other value exits non-zero.
- Content is deterministic: no `$RANDOM`, no `rand()`, no `date` call in content generation. The only inputs are `number_of_files`, `content_size` and `benchmark_config.json`.
- Generated post file names match `[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*`; section index files (e.g. `_index.md`, `posts.json`) survive resets.
- No themes, plugins, minification or speed tweaks; the reference assets are copied verbatim, never processed.
- Only ONE smoke run at a time on the machine (fixed container naming before BT-004).

## Review Focus

1. **Byte-exact blocks.** One extra space in the template breaks the `-cs` semantics and the 006 golden fixtures. Pinned by `test_block_is_512_bytes` and `test_golden_post_1` in Task 2.
2. **Portability of awk.** gawk-only features (`strftime`, `gensub`, `--` options) would break under mawk. Pinned by running the content test under `mawk` explicitly (Task 2 Step 2) as well as the default `awk`.
3. **Dates and file names agree.** middleman-blog rejects a file name date that differs from the front matter date. Pinned by `test_filename_date_matches_front_matter` in Task 2.

---

### Task 1: Reference assets and reference HTML

**Files (SF):**
- Create: `reference/assets/ssgberk.css`, `reference/assets/ssgberk.png`, `reference/html/post.html`, `reference/html/index.html`, `reference/html/404.html`, `reference/README.md`, `tools/make_reference_png.py`, `tests/reference/test_reference.py`

**Interfaces:**
- Produces: `reference/assets/*` (copied by every generator), `reference/html/*` (golden input for `docs/specs/006-layout-conformance` checker tests).
- `tools/make_reference_png.py <out-path>` writes a 64×64 RGB PNG and exits 0.

- [x] **Step 1: Write the failing test** — `tests/reference/test_reference.py` (stdlib `unittest`):
  - `test_css_is_literal`: `reference/assets/ssgberk.css` equals the fenced block under "Stylesheet" in `docs/specs/005-reference-site-design/plan.md`. The test extracts the first ```` ```css ```` block after the heading `## Stylesheet` and compares the bytes, with a trailing newline.
  - `test_css_rules`: no `@import`, no `url(`, no `-webkit-`/`-moz-`, and it starts with a comment followed by `:root {`.
  - `test_png_header`: the PNG starts with `\x89PNG\r\n\x1a\n`, the IHDR is 64×64, bit depth 8, colour type 2, and the chunk types are exactly `IHDR`, `IDAT`, `IEND`.
  - `test_reference_html_literal`: each `reference/html/*.html` equals the corresponding fenced `html` block in `plan.md`. For `404.html`, the base layout and the `main` fragment are assembled as described there. The test asserts the file exists and contains `<section class="not-found">` and `<title>Page not found | SSGBerk Reference</title>`.
- [x] **Step 2: Run** `python3 -m unittest tests/reference/test_reference.py -v` → FAIL (files missing).
- [x] **Step 3: Implement** — write `ssgberk.css` from plan.md. Write `tools/make_reference_png.py`: rows of 64 pixels; rows 0–15 `#2f5bd3`, 16–31 `#f2f4f8`, 32–47 `#1d2330`, 48–63 `#d8dde7`; each scanline prefixed with filter byte 0; `zlib.compress(raw, 9)`; chunks written with `struct.pack('>I', len)` + type + data + CRC32. Run it once to produce `reference/assets/ssgberk.png`. Write the three reference HTML files. `reference/README.md` says what each file is and that copies must stay byte-identical.
- [x] **Step 4: Run** the test → PASS.
- [x] **Step 5: Commit** `feat(reference): add reference assets and reference HTML`.

### Task 2: Rich deterministic content in the canonical `build.sh`

**Files (SF):**
- Modify: `Go/hugo/build.sh` (then copy to every `*/*/build.sh`)
- Create: `tests/build_sh/test_content.sh`, `tests/build_sh/golden/3minus/2025-12-31-1.md`, `tests/build_sh/golden/3plus/2025-12-31-1.md`, `tests/build_sh/golden/2dot/2025-12-31-1.md`, `tests/build_sh/golden/manifest-n3.sha256`

**Interfaces:**
- Consumes: env `number_of_files`, `content_size`; `benchmark_config.json` `content[0].{folder,type,extension}`, `config[0].{metadata_dateslug,metadata_layout}` (001 schema, unchanged).
- Produces: N files `<YYYY-MM-DD>-<NNN>.<ext>` in `content[0].folder` per `plan.md` "Content model". The `today`, `paragraph`, `content` and `header_for` code in `build.sh` is removed. `KEEP_CONTENT` keeps working.
- Env `SSGBERK_GENERATE_ONLY=1` (new): generate the content and exit 0 before any build. This lets tests and 006 fixtures produce content without a generator.

- [x] **Step 1: Write the failing test** — `tests/build_sh/test_content.sh` creates a temp dir with a `benchmark_config.json` per content type (`folder: posts`, `extension: md`, `metadata_dateslug: date`, `metadata_layout: ""`) and runs `SSGBERK_GENERATE_ONLY=1 KEEP_CONTENT=1 number_of_files=3 content_size=0.500 bash Go/hugo/build.sh` in it. Then:
  - `test_golden_post_1`: for each of `3minus`, `3plus` and `2dot`, `posts/2025-12-31-1.md` is byte-identical to `tests/build_sh/golden/<type>/2025-12-31-1.md`. The golden files hold exactly the plan.md literals: the front matter layout followed by the literal block 1.
  - `test_manifest_n3`: `sha256sum posts/*` for `3minus` equals `golden/manifest-n3.sha256`.
  - `test_block_is_512_bytes`: with `type: none`, `content_size=500`, `number_of_files=1`, the file is exactly 512000 bytes. With `0.500` it is 512 bytes.
  - `test_filename_date_matches_front_matter`: with N=1500, for every file the `YYYY-MM-DD` prefix equals the date part of its `date:` line. File 1441 has prefix `2025-12-30`.
  - `test_dates_strictly_decreasing`: the `date:` values for N=50 are strictly decreasing in i.
  - `test_layout_line`: with `metadata_layout: "layout: post"`, line 2 of a `3minus` file is `layout: post`. With `2dot` and `metadata_layout: "type: text"`, line 1 is `.. type: text`.
  - `test_content_size_unknown_fails`: `content_size=42` exits non-zero and prints `[ ERROR ] unknown content_size: 42`. This keeps the existing assertion in `tests/build_sh/test_build_sh.sh`.
  - `test_deterministic`: two runs give identical `sha256sum` manifests.
  - `test_reset_keeps_section_files`: an existing `posts/_index.md` survives generation.
- [x] **Step 2: Run** `bash tests/build_sh/test_content.sh` → FAIL (old generator). Also run it inside `ubuntu:24.04`, where `awk` is mawk (`docker run --rm -v "$PWD":/w -w /w ubuntu:24.04 bash -c 'apt-get -qq update && apt-get -qq install -y jq moreutils >/dev/null && bash tests/build_sh/test_content.sh'`). The tests may skip the hyperfine dependency because `SSGBERK_GENERATE_ONLY` exits first, so the `command -v hyperfine` check must move after the generate-only exit.
- [x] **Step 3: Implement** — in `build.sh`, embed the awk program as `content_awk=$(cat <<'AWK' … AWK)`. It is the prototype below, which was checked to emit the plan.md literals. Invoke it once:

  ```bash
  width=${#number_of_files}
  awk -v n="${number_of_files}" -v reps="${repetitions}" -v width="${width}" \
      -v outdir="${content_folder}" -v type="${content_type}" \
      -v dateslug="${metadata_dateslug}" -v layout="${metadata_layout}" \
      -v ext="${content_extension}" "${content_awk}" || { echo "[ ERROR ] content generation failed"; exit 1; }
  ```

  Awk program body (functions `civil`, `w`, `pad` from plan.md; main loop):

  ```awk
  BEGIN {
      split("amber birch cedar delta ember fjord grove haven inlet jolly karma lemon maple north ocean prism quart raven solar tiger ultra vivid waltz xenon yield zebra acorn blaze coral dunes eagle flint", tmp, " ")
      for (q = 1; q <= 32; q++) V[q - 1] = tmp[q]
      split("alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa", tmp, " ")
      for (q = 1; q <= 16; q++) T[q - 1] = tmp[q]
      split("Ada North|Ben South|Cy East|Di West", tmp, "|")
      for (q = 1; q <= 4; q++) A[q - 1] = tmp[q]
      if (type != "3minus" && type != "3plus" && type != "2dot" && type != "none") { print "[ ERROR ] unknown content type: " type > "/dev/stderr"; exit 1 }
      anchor = 1767225600
      for (i = 1; i <= n; i++) {
          e = anchor - 60 * i; days = int(e / 86400); sod = e - days * 86400; day = civil(days)
          iso = sprintf("%sT%02d:%02d:%02dZ", day, int(sod / 3600), int((sod % 3600) / 60), sod % 60)
          nnn = pad(i, width)
          title = "Post " nnn " " w(i, 0, 1) " " w(i, 0, 2)
          summary = "Summary"; for (j = 3; j <= 14; j++) summary = summary " " w(i, 0, j); summary = summary "."
          author = A[i % 4]; t0 = T[(i * 7) % 16]; t1 = T[(i * 7 + 3) % 16]; t2 = T[(i * 7 + 6) % 16]
          f = outdir "/" day "-" nnn "." ext
          if (type == "3minus") {
              printf "---\n" > f
              if (layout != "") printf "%s\n", layout > f
              printf "title: %s\n%s: %s\nsummary: %s\nauthor: %s\ntags:\n    - %s\n    - %s\n    - %s\n---\n", title, dateslug, iso, summary, author, t0, t1, t2 > f
          } else if (type == "3plus") {
              printf "+++\ntitle = \"%s\"\n%s = %s\n\n[extra]\nsummary = \"%s\"\nauthor = \"%s\"\ntags = [\"%s\", \"%s\", \"%s\"]\n+++\n", title, dateslug, iso, summary, author, t0, t1, t2 > f
          } else if (type == "2dot") {
              if (layout != "") printf ".. %s\n", layout > f
              printf ".. title: %s\n.. slug: %s\n.. %s: %s\n.. summary: %s\n.. author: %s\n.. tags: %s, %s, %s\n\n", title, day "-" nnn, dateslug, iso, summary, author, t0, t1, t2 > f
          }
          for (k = 1; k <= reps; k++) {
              K = pad(k, 6)
              for (j = 1; j <= 52; j++) x[j] = w(i, k, j)
              printf "## Chapter %s %s %s\n\nText %s *%s* %s **%s** %s `%s` %s [%s %s](https://example.com/%s/) %s.\n\n", K, x[1], x[2], x[3], x[4], x[5], x[6], x[7], x[8], x[9], x[10], x[11], x[12], x[13] > f
              printf "### Note %s %s %s\n\n- %s %s\n    - %s %s\n- %s %s\n\n1. %s %s\n    1. %s %s\n2. %s %s\n\n", K, x[14], x[15], x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23], x[24], x[25], x[26], x[27] > f
              printf "> %s %s %s %s.\n\n~~~ text\n%s = %s + %s\n~~~\n\n| Key | Value |\n|-----|-------|\n| %s | %s |\n\n", x[28], x[29], x[30], x[31], x[32], x[33], x[34], x[35], x[36] > f
              printf "![%s %s](/assets/ssgberk.png)\n\nTail", x[37], x[38] > f
              for (j = 39; j <= 52; j++) printf " %s", x[j] > f
              printf ".\n\n* * *\n\n" > f
          }
          close(f)
      }
  }
  ```

  For `none` the `if` chain writes no header, only the body. Write the golden files from the plan.md literals by hand, not from the implementation output, then compare.
- [x] **Step 4: Run** `bash tests/build_sh/test_content.sh` (host awk and mawk) and `bash tests/build_sh/test_build_sh.sh` → PASS.
- [x] **Step 5: Propagate** — `for f in */*/build.sh; do cp Go/hugo/build.sh "$f"; done`; `tools/check-build-sh.sh` exits 0.
- [x] **Step 6: Smoke every existing generator** with the 001 smoke procedure (`./ssgberk --test <name> -nf 10 -cs 0.500 -mr 1`, one at a time). Each must still report `SSGBERK_VERIFY_OK expected=10 got=10`. The templates are not ported yet, so only the count check applies. A generator that now fails on the new front matter (for example Pelican tags) gets the minimal config fix needed to build, recorded in its README. The full port is its 006 task.
- [x] **Step 7: Commit** `feat(build.sh): generate deterministic rich reference content (005)`.

### Task 3: Point the old "minimal site" rule at the reference site

**Files (SF):**
- Modify: `docs/specs/001-canonical-build-runner/tasks.md`, `docs/specs/002-update-existing-generators/tasks.md`, `docs/specs/003-new-generators/tasks.md` (Global Constraints line "No themes, plugins, minification or speed tweaks in generator sites: base layout + post template + index listing posts.")
- Modify: `docs/specs/001-canonical-build-runner/spec.md` (Out of scope bullet "Temas, plugins…" gets a pointer)

**Interfaces:**
- Produces: the replacement line, used verbatim in all three files: `No themes, plugins beyond the baseline set, minification or speed tweaks; every site builds the Core reference site of docs/specs/005-reference-site-design (supersedes the former minimal-site rule).`

- [x] **Step 1: Write the failing check** — `grep -c "base layout + post template + index listing posts" docs/specs/00[123]-*/tasks.md` prints non-zero counts (the check fails while the old line exists).
- [x] **Step 2: Run** it → non-zero.
- [x] **Step 3: Implement** — replace the line in the three `tasks.md` files with the replacement line. Append `See docs/specs/005-reference-site-design for the reference site that every generator builds.` to the 001 spec bullet.
- [x] **Step 4: Run** the grep → `0` for every file; `grep -l "005-reference-site-design" docs/specs/00[123]-*/tasks.md | wc -l` prints `3`.
- [x] **Step 5: Commit** `docs(specs): point minimal-site rule at 005 reference site`.

### Task 4: CI check for byte-identical asset copies

**Files (SF):**
- Create: `tools/check-reference-assets.sh`, `tests/reference/test_check_reference_assets.sh`
- Modify: `.github/workflows/` (the job that runs `tools/check-build-sh.sh` also runs this script)

**Interfaces:**
- `tools/check-reference-assets.sh` reads each `*/*/benchmark_config.json` `config[0].static_folder` (string, path relative to the generator dir where `assets/ssgberk.{css,png}` live). Schema amendment: 006 Task 8 adds `static_folder` to the 001 schema together with `profiles` and `allow_extra_html`. For every generator it `cmp`s `<Lang>/<name>/<static_folder>/assets/ssgberk.css` and `.png` against `reference/assets/`. It prints `differs: <path>` or `missing: <path>` and exits 1 on any problem. Generators without `static_folder` print `pending: <Lang>/<name>` and do not fail until 006 migration is complete; the flag `--strict` makes `pending` fail.

- [x] **Step 1: Write the failing test** — `tests/reference/test_check_reference_assets.sh` builds a temp tree with `reference/assets/*`, one generator with identical copies (expects exit 0), one with a modified CSS byte (expects `differs:` and exit 1), one with a missing PNG (expects `missing:`), and one without `static_folder` (expects `pending:` with exit 0, and exit 1 with `--strict`).
- [x] **Step 2: Run** → FAIL (script missing).
- [x] **Step 3: Implement** the script with `jq` and `cmp -s`, following `tools/check-build-sh.sh` style (`set -euo pipefail`, `cd "$(dirname "$0")/.."`). Add the CI step.
- [x] **Step 4: Run** the test → PASS; `tools/check-reference-assets.sh` on the repo exits 0 (all `pending`).
- [x] **Step 5: Commit** `ci: check reference asset copies are byte-identical`.
