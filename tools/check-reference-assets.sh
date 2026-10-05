#!/bin/bash
# Fails if any generator's copy of the reference assets differs from reference/assets/.
# Each generator declares config[0].static_folder in benchmark_config.json; the copies are
# <Lang>/<name>/<static_folder>/assets/ssgberk.{css,png}. Generators without static_folder
# print "pending:" and only fail with --strict.
set -euo pipefail
cd "$(dirname "$0")/.."
strict=0
[ "${1:-}" = "--strict" ] && strict=1
status=0
for cfg in */*/benchmark_config.json; do
    [ -e "$cfg" ] || continue
    case "$cfg" in node_modules/*|reference/*|tests/*|tools/*|docs/*|*/node_modules/*) continue ;; esac
    dir="${cfg%/benchmark_config.json}"
    sf=$(jq -r '.config[0].static_folder // empty' "$cfg")
    if [ -z "$sf" ]; then
        echo "pending: $dir"
        [ "$strict" -eq 1 ] && status=1
        continue
    fi
    for name in ssgberk.css ssgberk.png; do
        f="$dir/$sf/assets/$name"
        if [ ! -e "$f" ]; then echo "missing: $f"; status=1
        elif ! cmp -s "reference/assets/$name" "$f"; then echo "differs: $f"; status=1; fi
    done
done
exit $status
