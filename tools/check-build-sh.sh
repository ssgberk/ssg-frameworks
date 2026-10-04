#!/bin/bash
# Fails if any generator's build.sh differs from the canonical Go/hugo/build.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
for f in */*/build.sh; do
    if ! cmp -s Go/hugo/build.sh "$f"; then echo "differs: $f"; status=1; fi
done
exit $status
