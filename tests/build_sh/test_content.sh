#!/bin/bash
# Golden tests for the content generator in the canonical build.sh (spec 005, plan.md "Content model").
# Usage: bash tests/build_sh/test_content.sh   (from anywhere; needs bash, jq, awk)
# Runs with the host awk. For mawk, run it inside ubuntu:24.04:
#   docker run --rm -v "$PWD":/w -w /w ubuntu:24.04 bash -c \
#     'apt-get -qq update && apt-get -qq install -y jq >/dev/null && bash tests/build_sh/test_content.sh'
# Every case uses SSGBERK_GENERATE_ONLY=1, so no generator and no hyperfine are needed.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_SH="${BUILD_SH:-${ROOT}/Go/hugo/build.sh}"   # override to test another copy
GOLDEN="${ROOT}/tests/build_sh/golden"
WORK=$(mktemp -d) || exit 1
trap 'rm -rf "${WORK}"' EXIT

if command -v sha256sum >/dev/null 2>&1; then sha() { sha256sum "$@"; }; else sha() { shasum -a 256 "$@"; }; fi
fsize() { wc -c < "$1" | tr -d ' '; }

passed=0
failed=0
current=""
fail() { echo "FAIL [${current}]: $*"; current_failed=1; }
begin() { current="$1"; current_failed=0; }
finish() {
    if [ "${current_failed}" -eq 0 ]; then echo "PASS ${current}"; passed=$((passed + 1)); else failed=$((failed + 1)); fi
}

# setup <dir> <type> [layout]: a site dir with benchmark_config.json and posts/_index.md
setup() {
    rm -rf "$1" && mkdir -p "$1/posts"
    jq -n --arg t "$2" --arg l "${3:-}" \
        '{framework:"fake", tests:[{default:{}}],
          content:[{folder:"posts", type:$t, extension:"md"}],
          config:[{metadata_dateslug:"date", metadata_layout:$l, build_command:"false",
                   build_verbose:"", output_folder:"out", output_glob:"posts/*.html"}]}' > "$1/benchmark_config.json"
}

# gen <dir> <number_of_files> <content_size>: generate only, keep content
gen() {
    (cd "$1" && SSGBERK_GENERATE_ONLY=1 KEEP_CONTENT=1 number_of_files="$2" content_size="$3" bash "${BUILD_SH}")
}

# --- test_golden_post_1 --------------------------------------------------------
begin test_golden_post_1
for t in 3minus 3plus 2dot; do
    d="${WORK}/golden_${t}"
    setup "$d" "$t"
    gen "$d" 3 0.500 >/dev/null 2>&1 || fail "${t}: generation exited non-zero"
    cmp -s "$d/posts/2025-12-31-1.md" "${GOLDEN}/${t}/2025-12-31-1.md" || fail "${t}: post 1 differs from golden"
done
finish

# --- test_block1_byte_exact (body of post 1 at -cs 0.500 is the literal block 1) ---
begin test_block1_byte_exact
d="${WORK}/block1"
setup "$d" none
gen "$d" 3 0.500 >/dev/null 2>&1 || fail "generation exited non-zero"
# block 1 = last 512 bytes of the 3minus golden (front matter + block)
tail -c 512 "${GOLDEN}/3minus/2025-12-31-1.md" > "${WORK}/block1.expected"
cmp -s "$d/posts/2025-12-31-1.md" "${WORK}/block1.expected" || fail "type none post 1 is not the literal block 1"
head -1 "$d/posts/2025-12-31-1.md" | grep -qx '## Chapter 000001 zebra karma' || fail "block 1 first line"
finish

# --- test_manifest_n3 ----------------------------------------------------------
begin test_manifest_n3
(cd "${WORK}/golden_3minus" && sha posts/2025-12-3*) > "${WORK}/manifest.got"
diff "${GOLDEN}/manifest-n3.sha256" "${WORK}/manifest.got" >/dev/null || { fail "manifest differs"; diff "${GOLDEN}/manifest-n3.sha256" "${WORK}/manifest.got"; }
[ "$(ls "${WORK}/golden_3minus/posts" | grep -c '^2025-')" -eq 3 ] || fail "expected exactly 3 posts"
finish

# --- test_block_is_512_bytes ---------------------------------------------------
begin test_block_is_512_bytes
d="${WORK}/size"
setup "$d" none
gen "$d" 1 500 >/dev/null 2>&1 || fail "cs=500 exited non-zero"
s=$(fsize "$d/posts/2025-12-31-1.md"); [ "$s" -eq 512000 ] || fail "cs=500 size ${s}, want 512000"
setup "$d" none
gen "$d" 1 0.500 >/dev/null 2>&1 || fail "cs=0.500 exited non-zero"
s=$(fsize "$d/posts/2025-12-31-1.md"); [ "$s" -eq 512 ] || fail "cs=0.500 size ${s}, want 512"
finish

# --- test_cs_scaling: every -cs value maps to plan.md "Size table" -------------
begin test_cs_scaling
d="${WORK}/scale"
for pair in 0.500:1 5:10 50:100 500:1000 "[500]:1000" 1000:2000 5000:10000 10000:20000; do
    cs="${pair%:*}"; blocks="${pair##*:}"
    setup "$d" none
    gen "$d" 1 "$cs" >/dev/null 2>&1 || fail "cs=${cs} exited non-zero"
    s=$(fsize "$d/posts/2025-12-31-1.md"); [ "$s" -eq $((blocks * 512)) ] || fail "cs=${cs} size ${s}, want $((blocks * 512))"
    n=$(grep -c '^## Chapter ' "$d/posts/2025-12-31-1.md"); [ "$n" -eq "$blocks" ] || fail "cs=${cs} chapters ${n}, want ${blocks}"
    last=$(printf '%06d' "$blocks")
    grep -q "^## Chapter ${last} " "$d/posts/2025-12-31-1.md" || fail "cs=${cs} last chapter ${last} missing"
done
# 100000 (102.4 MB per post) is checked through the announced block count with N=0, to spare disk
setup "$d" none
out=$(gen "$d" 0 100000 2>&1) || fail "cs=100000 exited non-zero"
echo "$out" | grep -q '(100000 KB, 200000 blocks)' || fail "cs=100000 must announce 200000 blocks: ${out}"
finish

# --- test_cs_5_and_50 (2026-10-05, site-size scenarios P/M/G/GG) ---------------
begin test_cs_5_and_50
d="${WORK}/cs550"
for pair in 5:10 50:100; do
    cs="${pair%:*}"; blocks="${pair##*:}"
    setup "$d" none
    gen "$d" 2 "$cs" >/dev/null 2>&1 || fail "cs=${cs} exited non-zero"
    for f in "$d"/posts/2025-12-31-*.md; do
        s=$(fsize "$f"); [ "$s" -eq $((blocks * 512)) ] || fail "cs=${cs} $(basename "$f") body ${s} bytes, want $((blocks * 512))"
        n=$(grep -c '^## Chapter ' "$f"); [ "$n" -eq "$blocks" ] || fail "cs=${cs} $(basename "$f") ${n} blocks, want ${blocks}"
    done
    head -c 512 "$d/posts/2025-12-31-1.md" | cmp -s - "${WORK}/block1.expected" || fail "cs=${cs} block 1 must be the literal block 1"
    setup "$d" 3minus
    gen "$d" 1 "$cs" >/dev/null 2>&1 || fail "cs=${cs} 3minus exited non-zero"
    tail -c $((blocks * 512)) "$d/posts/2025-12-31-1.md" | head -c 512 | cmp -s - "${WORK}/block1.expected" || fail "cs=${cs} 3minus body must start with block 1"
done
for bad in 5.0 50.0 0.5 05; do
    setup "$d" none
    out=$(gen "$d" 1 "$bad" 2>&1) && fail "cs=${bad} must fail"
    echo "$out" | grep -qxF "[ ERROR ] unknown content_size: ${bad}" || fail "cs=${bad} error line, got: ${out}"
done
finish

# --- test_front_matter_per_type (layout lines included) ------------------------
begin test_layout_line
d="${WORK}/layout"
setup "$d" 3minus "layout: post"
gen "$d" 3 0.500 >/dev/null 2>&1 || fail "3minus exited non-zero"
[ "$(sed -n 2p "$d/posts/2025-12-31-1.md")" = "layout: post" ] || fail "3minus line 2 must be the layout"
[ "$(sed -n 3p "$d/posts/2025-12-31-1.md")" = "title: Post 1 amber raven" ] || fail "3minus line 3 must be the title"
setup "$d" 2dot "type: text"
gen "$d" 3 0.500 >/dev/null 2>&1 || fail "2dot exited non-zero"
[ "$(sed -n 1p "$d/posts/2025-12-31-1.md")" = ".. type: text" ] || fail "2dot line 1 must be '.. type: text'"
[ "$(sed -n 2p "$d/posts/2025-12-31-1.md")" = ".. title: Post 1 amber raven" ] || fail "2dot line 2 must be the title"
finish

begin test_dateslug_key
d="${WORK}/dateslug"
setup "$d" 3minus
jq '.config[0].metadata_dateslug = "created_at"' "$d/benchmark_config.json" > "$d/c.json" && mv "$d/c.json" "$d/benchmark_config.json"
gen "$d" 1 0.500 >/dev/null 2>&1 || fail "exited non-zero"
grep -qx 'created_at: 2025-12-31T23:59:00Z' "$d/posts/2025-12-31-1.md" || fail "date key must be metadata_dateslug"
finish

begin test_none_has_no_header
d="${WORK}/none"
setup "$d" none
gen "$d" 2 0.500 >/dev/null 2>&1 || fail "exited non-zero"
for f in "$d"/posts/2025-*; do head -1 "$f" | grep -q '^## Chapter 000001 ' || fail "$(basename "$f") must start with the body"; done
finish

# --- test_filename_date_matches_front_matter (N=1500, width 4) -----------------
begin test_filename_date_matches_front_matter
d="${WORK}/n1500"
setup "$d" 3minus
gen "$d" 1500 0.500 >/dev/null 2>&1 || fail "exited non-zero"
n=$(ls "$d/posts" | grep -c '^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]\.md$')
[ "$n" -eq 1500 ] || fail "expected 1500 files named YYYY-MM-DD-NNNN.md, got ${n}"
bad=$(cd "$d/posts" && awk 'FNR == 1 { pre = substr(FILENAME, 1, 10) }
    /^date: / { if (substr($2, 1, 10) != pre) print FILENAME }' 2*.md | head -3)
[ -z "$bad" ] || fail "file prefix != date: ${bad}"
[ -f "$d/posts/2025-12-30-1441.md" ] || fail "file 1441 must be 2025-12-30-1441.md"
[ -f "$d/posts/2025-12-31-1440.md" ] || fail "file 1440 must be 2025-12-31-1440.md"
grep -qx 'date: 2025-12-31T00:00:00Z' "$d/posts/2025-12-31-1440.md" || fail "1440 date"
grep -qx 'date: 2025-12-30T23:59:00Z' "$d/posts/2025-12-30-1441.md" || fail "1441 date"
grep -qx 'title: Post 0001 amber raven' "$d/posts/2025-12-31-0001.md" || fail "NNN padded to width of N in title"
finish

# --- test_dates_strictly_decreasing (N=50) --------------------------------------
begin test_dates_strictly_decreasing
d="${WORK}/n50"
setup "$d" 3minus
gen "$d" 50 0.500 >/dev/null 2>&1 || fail "exited non-zero"
# order files by post index i (the NNN suffix), then dates must strictly decrease
dates=$(cd "$d/posts" && for i in $(seq -w 1 50); do sed -n 's/^date: //p' 2*-"$i".md; done)
[ "$(echo "$dates" | wc -l | tr -d ' ')" -eq 50 ] || fail "expected 50 dates"
echo "$dates" | awk 'NR > 1 && !($0 < prev) { print "not decreasing at line " NR ": " prev " -> " $0; bad = 1 } { prev = $0 } END { exit bad }' \
    || fail "dates not strictly decreasing"
[ "$(echo "$dates" | sed -n 50p)" = "2025-12-31T23:10:00Z" ] || fail "post 50 date"
finish

# --- test_tags_author_formula (N=50): AUTHORS[i mod 4], TAGS[7i, 7i+3, 7i+6 mod 16] ---
begin test_tags_author_formula
d="${WORK}/n50"
TAGS="alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa"
AUTHORS="Ada North|Ben South|Cy East|Di West"
tag() { echo "$TAGS" | cut -d' ' -f$(( $1 % 16 + 1 )); }
for i in $(seq 1 50); do
    f=$(ls "$d"/posts/2*-"$(printf '%02d' "$i")".md)
    want_author=$(echo "$AUTHORS" | cut -d'|' -f$(( i % 4 + 1 )))
    grep -qx "author: ${want_author}" "$f" || fail "post ${i} author, want ${want_author}"
    got_tags=$(sed -n '2,/^---$/s/^    - //p' "$f" | tr '\n' ' ')
    want_tags="$(tag $((7 * i))) $(tag $((7 * i + 3))) $(tag $((7 * i + 6))) "
    [ "$got_tags" = "$want_tags" ] || fail "post ${i} tags '${got_tags}', want '${want_tags}'"
done
# 3plus and 2dot carry the same values in their own syntax (post 2: Cy East; TAGS[14], TAGS[1], TAGS[4])
grep -qx 'author = "Cy East"' "${WORK}/golden_3plus/posts/2025-12-31-2.md" || fail "3plus post 2 author"
grep -qx 'tags = \["oscar", "bravo", "echo"\]' "${WORK}/golden_3plus/posts/2025-12-31-2.md" || fail "3plus post 2 tags"
grep -qx '.. author: Cy East' "${WORK}/golden_2dot/posts/2025-12-31-2.md" || fail "2dot post 2 author"
grep -qx '.. tags: oscar, bravo, echo' "${WORK}/golden_2dot/posts/2025-12-31-2.md" || fail "2dot post 2 tags"
grep -qx '.. slug: 2025-12-31-2' "${WORK}/golden_2dot/posts/2025-12-31-2.md" || fail "2dot post 2 slug"
finish

# --- test_content_size_unknown_fails -------------------------------------------
begin test_content_size_unknown_fails
d="${WORK}/badcs"
setup "$d" 3minus
out=$(gen "$d" 1 42 2>&1); st=$?
[ "$st" -ne 0 ] || fail "content_size=42 must exit non-zero"
echo "$out" | grep -qxF '[ ERROR ] unknown content_size: 42' || fail "missing error line, got: ${out}"
finish

begin test_content_type_unknown_fails
d="${WORK}/badtype"
setup "$d" 4hash
out=$(gen "$d" 1 0.500 2>&1); st=$?
[ "$st" -ne 0 ] || fail "unknown type must exit non-zero"
echo "$out" | grep -qF '[ ERROR ] unknown content type: 4hash' || fail "missing error line, got: ${out}"
finish

# --- test_deterministic --------------------------------------------------------
begin test_deterministic
for r in 1 2; do
    d="${WORK}/det${r}"
    setup "$d" 3minus
    gen "$d" 20 500 >/dev/null 2>&1 || fail "run ${r} exited non-zero"
    (cd "$d" && sha posts/2*) > "${WORK}/det${r}.sha"
done
cmp -s "${WORK}/det1.sha" "${WORK}/det2.sha" || fail "two runs differ"
[ "$(wc -l < "${WORK}/det1.sha" | tr -d ' ')" -eq 20 ] || fail "expected 20 files"
# two different posts differ (content varies per post)
[ "$(cut -d' ' -f1 "${WORK}/det1.sha" | sort -u | wc -l | tr -d ' ')" -eq 20 ] || fail "posts must differ from each other"
finish

# --- test_reset_keeps_section_files --------------------------------------------
begin test_reset_keeps_section_files
d="${WORK}/reset"
setup "$d" 3minus
echo keep > "$d/posts/_index.md"
echo old > "$d/posts/2014-01-01-sample.md"
gen "$d" 3 0.500 >/dev/null 2>&1 || fail "exited non-zero"
[ "$(cat "$d/posts/_index.md")" = keep ] || fail "_index.md must survive"
[ ! -e "$d/posts/2014-01-01-sample.md" ] || fail "old dated post must be removed"
[ "$(ls "$d/posts" | grep -c '^2025-')" -eq 3 ] || fail "expected 3 posts"
# a second run with a smaller N leaves no stale posts
gen "$d" 2 0.500 >/dev/null 2>&1 || fail "second run exited non-zero"
[ "$(ls "$d/posts" | grep -c '^2025-')" -eq 2 ] || fail "stale posts left after smaller N"
finish

# --- test_generate_only_needs_no_hyperfine -------------------------------------
begin test_generate_only_exits_before_build
d="${WORK}/gonly"
setup "$d" 3minus
jq '.config[0].build_command = "touch BUILD_RAN"' "$d/benchmark_config.json" > "$d/c.json" && mv "$d/c.json" "$d/benchmark_config.json"
out=$(cd "$d" && PATH="$(dirname "$(command -v jq)"):/usr/bin:/bin" SSGBERK_GENERATE_ONLY=1 number_of_files=1 content_size=0.500 bash "${BUILD_SH}" 2>&1); st=$?
[ "$st" -eq 0 ] || fail "generate-only must exit 0, got ${st}: ${out}"
[ ! -e "$d/BUILD_RAN" ] || fail "generate-only must not run the build"
[ -f "$d/posts/2025-12-31-1.md" ] || fail "generate-only must keep the content"
echo "$out" | grep -q STARTTIME && fail "no timed run in generate-only"
finish

awk_version=$(awk --version </dev/null 2>/dev/null | head -1)
[ -n "${awk_version}" ] || awk_version=$(awk -W version </dev/null 2>&1 | head -1)
echo "awk: ${awk_version}"
echo "content tests: ${passed} passed, ${failed} failed"
[ "${failed}" -eq 0 ]
