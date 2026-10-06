#!/bin/bash
# SSGBerk canonical build.sh — every generator directory carries an identical copy.
# Inputs (env): number_of_files, content_size, min_runs, verbose_build,
#               KEEP_CONTENT (keep generated posts), SSGBERK_GENERATE_ONLY=1 (generate content, exit 0)
# Reads: ./benchmark_config.json   Prints: SSGBERK_* markers parsed by the toolset.
export LANG=C.UTF-8
set -u

require()
{
    for cmd in "$@"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            echo "[ ERROR ] required command not installed: ${cmd}"
            exit 1
        fi
    done
}
require jq awk

tmpdir=$(mktemp -d) || { echo "[ ERROR ] mktemp failed"; exit 1; }
trap 'rm -rf "${tmpdir}"' EXIT

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

dated_pattern='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*'

# Remove generated (date-named) posts only; section index files survive.
reset_content()
{
    mkdir -p "${content_folder}"
    find "${content_folder}" -mindepth 1 -maxdepth 1 -name "${dated_pattern}" -exec rm -rf {} +
}

# Portable (GNU and BSD) size marker: "<files> <bytes>" of the regular files given by find args.
count_files()
{
    local n b
    n=$(find "$@" -type f | wc -l | tr -d ' ')
    b=$(find "$@" -type f -exec cat {} + 2>/dev/null | wc -c | tr -d ' ')
    echo "${n} ${b:-0}"
}

clean_output()
{
    [ -n "${output_folder}" ] && rm -rf "${output_folder}"
    for d in ${cache_folders}; do rm -rf "${d}"; done
    return 0
}

case "${content_size}" in
    0.500)  repetitions=1 ;;
    5)      repetitions=10 ;;
    50)     repetitions=100 ;;
    500)    repetitions=1000 ;;
    1000)   repetitions=2000 ;;
    5000)   repetitions=10000 ;;
    10000)  repetitions=20000 ;;
    100000) repetitions=200000 ;;
    *) echo "[ ERROR ] unknown content_size: ${content_size}"; exit 1 ;;
esac

# Reference content generator (spec 005, plan.md "Content model"). One awk process
# writes all N posts. Integer arithmetic only, so mawk, gawk and BWK awk agree byte for byte.
# Post i: file <YYYY-MM-DD>-<NNN>.<ext>, date 2026-01-01T00:00:00Z minus 60*i seconds,
# body = <repetitions> blocks of exactly 512 bytes, words w(i,k,j) = V[(7919i + 104729k + 1009j) mod 32].
content_awk=$(cat <<'AWK'
function civil(z,   era, doe, yoe, y, doy, mp, d, m) {
    z += 719468
    era = int((z >= 0 ? z : z - 146096) / 146097)
    doe = z - era * 146097
    yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
    y = yoe + era * 400
    doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
    mp = int((5 * doy + 2) / 153)
    d = doy - int((153 * mp + 2) / 5) + 1
    m = mp + (mp < 10 ? 3 : -9)
    if (m <= 2) y += 1
    return sprintf("%04d-%02d-%02d", y, m, d)
}
function w(i, k, j) { return V[(i * 7919 + k * 104729 + j * 1009) % 32] }
function pad(v, width) { return sprintf("%0" width "d", v) }
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
AWK
)

reset_content
echo "Generating ${number_of_files} posts (${content_size} KB, ${repetitions} blocks) in ${content_folder}"
width=${#number_of_files}
awk -v n="${number_of_files}" -v reps="${repetitions}" -v width="${width}" \
    -v outdir="${content_folder}" -v type="${content_type}" \
    -v dateslug="${metadata_dateslug}" -v layout="${metadata_layout}" \
    -v ext="${content_extension}" "${content_awk}" || { echo "[ ERROR ] content generation failed"; exit 1; }
[ "${verbose_build}" = true ] && ls -sh "${content_folder}"
read -r in_files in_bytes <<< "$(count_files "${content_folder}" -maxdepth 1 -name "${dated_pattern}")"
echo "SSGBERK_INPUT files=${in_files} bytes=${in_bytes}"

if [ "${SSGBERK_GENERATE_ONLY:-}" = 1 ]; then
    echo "SSGBERK_GENERATE_ONLY: content generated, skipping build"
    exit 0
fi
require hyperfine

if [ "${verbose_build}" = true ]; then
    command="${build_verbose}"
else
    command="${build_command}"
fi

# Untimed verification build: the site must contain exactly one page per post.
clean_output
eval "${command}" > "${tmpdir}/verify.log" 2>&1
verify_status=$?
if [ "${verify_status}" -ne 0 ]; then
    cat "${tmpdir}/verify.log"
    echo "SSGBERK_VERIFY_FAIL build exited ${verify_status}"
    [ -z "${KEEP_CONTENT:-}" ] && reset_content
    exit 1
fi
if [ -n "${output_folder}" ] && [ -n "${output_glob}" ]; then
    got=$(find "${output_folder}" -type f -path "${output_folder}/${output_glob}" | wc -l | tr -d ' ')
    if [ "${got}" -ne "${number_of_files}" ]; then
        cat "${tmpdir}/verify.log"
        echo "SSGBERK_VERIFY_FAIL expected=${number_of_files} got=${got}"
        [ -z "${KEEP_CONTENT:-}" ] && reset_content
        exit 1
    fi
    echo "SSGBERK_VERIFY_OK expected=${number_of_files} got=${got}"
else
    echo "[ WARN ] output_folder/output_glob not set; skipping output verification"
fi

# SF spec 006's conformance check goes before this marker.
if [ -n "${output_folder}" ]; then
    read -r out_files out_bytes <<< "$(count_files "${output_folder}")"
else
    out_files=0; out_bytes=0
fi
echo "SSGBERK_OUTPUT files=${out_files} bytes=${out_bytes}"

show_output=""
[ "${verbose_build}" = true ] && show_output="--show-output"
prepare_cmd="true"
if [ -n "${output_folder}" ] || [ -n "${cache_folders}" ]; then
    prepare_cmd="rm -rf ${output_folder} ${cache_folders}"
fi

echo "STARTTIME $(date +%s)"
hyperfine --time-unit second --min-runs "${min_runs}" --max-runs "${min_runs}" \
    --prepare "${prepare_cmd}" ${show_output} \
    --export-json "${tmpdir}/hyperfine.json" "${command}"
hyperfine_status=$?
echo "ENDTIME $(date +%s)"
echo "Number of files: ${number_of_files} | content size: ${content_size} KB | runs: ${min_runs}"

if [ "${hyperfine_status}" -eq 0 ]; then
    echo "SSGBERK_RESULT_BEGIN"
    cat "${tmpdir}/hyperfine.json"
    echo
    echo "SSGBERK_RESULT_END"
fi

[ -z "${KEEP_CONTENT:-}" ] && reset_content
exit "${hyperfine_status}"
