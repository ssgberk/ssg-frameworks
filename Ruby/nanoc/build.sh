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
