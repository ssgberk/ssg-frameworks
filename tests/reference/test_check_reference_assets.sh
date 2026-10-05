#!/bin/bash
# Tests for tools/check-reference-assets.sh (spec 005). Usage: bash tests/reference/test_check_reference_assets.sh
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK=$(mktemp -d) || exit 1
trap 'rm -rf "${WORK}"' EXIT

passed=0
failed=0
current=""
fail() { echo "FAIL [${current}]: $*"; current_failed=1; }
begin() { current="$1"; current_failed=0; }
finish() {
    if [ "${current_failed}" -eq 0 ]; then echo "PASS ${current}"; passed=$((passed + 1)); else failed=$((failed + 1)); fi
}

# fresh <dir>: a temp repo with the script, reference/assets and no generators
fresh() {
    rm -rf "$1" && mkdir -p "$1/tools" "$1/reference/assets"
    cp "${ROOT}/tools/check-reference-assets.sh" "$1/tools/"
    printf 'body{color:red}\n' > "$1/reference/assets/ssgberk.css"
    printf '\211PNG-fake-bytes\n' > "$1/reference/assets/ssgberk.png"
}

# gen <repo> <Lang/name> [static_folder]: generator with identical asset copies
gen() {
    local d="$1/$2"
    mkdir -p "$d"
    if [ -n "${3:-}" ]; then
        jq -n --arg s "$3" '{config:[{static_folder:$s}]}' > "$d/benchmark_config.json"
        mkdir -p "$d/$3/assets"
        cp "$1"/reference/assets/ssgberk.* "$d/$3/assets/"
    else
        echo '{"config":[{}]}' > "$d/benchmark_config.json"
    fi
}

run() { out=$(bash "$1/tools/check-reference-assets.sh" "${@:2}" 2>&1); st=$?; }

begin test_identical_passes
d="${WORK}/ok"; fresh "$d"; gen "$d" Go/site src/public
run "$d"
[ "${st}" -eq 0 ] || fail "want exit 0, got ${st}: ${out}"
finish

begin test_differs
d="${WORK}/diff"; fresh "$d"; gen "$d" Go/site static
printf 'body{color:blue}\n' > "$d/Go/site/static/assets/ssgberk.css"
run "$d"
[ "${st}" -eq 1 ] || fail "want exit 1, got ${st}"
echo "${out}" | grep -qxF 'differs: Go/site/static/assets/ssgberk.css' || fail "missing differs line: ${out}"
finish

begin test_missing
d="${WORK}/miss"; fresh "$d"; gen "$d" Go/site static
rm "$d/Go/site/static/assets/ssgberk.png"
run "$d"
[ "${st}" -eq 1 ] || fail "want exit 1, got ${st}"
echo "${out}" | grep -qxF 'missing: Go/site/static/assets/ssgberk.png' || fail "missing line absent: ${out}"
finish

begin test_pending_and_strict
d="${WORK}/pend"; fresh "$d"; gen "$d" Rust/old
run "$d"
[ "${st}" -eq 0 ] || fail "pending must exit 0, got ${st}"
echo "${out}" | grep -qxF 'pending: Rust/old' || fail "pending line absent: ${out}"
run "$d" --strict
[ "${st}" -eq 1 ] || fail "--strict must exit 1, got ${st}"
echo "${out}" | grep -qxF 'pending: Rust/old' || fail "strict pending line absent: ${out}"
finish

begin test_skips_excluded_dirs
d="${WORK}/skip"; fresh "$d"; gen "$d" Go/site static
for x in node_modules/pkg tests/fixture tools/x docs/y reference/z; do gen "$d" "$x"; done
run "$d" --strict
[ "${st}" -eq 0 ] || fail "excluded dirs must be skipped, got ${st}: ${out}"
finish

echo "reference asset tests: ${passed} passed, ${failed} failed"
[ "${failed}" -eq 0 ]
