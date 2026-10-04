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
