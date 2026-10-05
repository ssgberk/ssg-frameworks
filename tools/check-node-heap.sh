#!/bin/bash
# Fails if a Node generator's dockerfile does not set the shared V8 heap cap (BT spec 008).
set -euo pipefail
cd "$(dirname "$0")/.."
expected='ENV NODE_OPTIONS=--max-old-space-size=6144'
status=0
for f in */*/*.dockerfile; do
    grep -q '^ARG NODE_VERSION=' "$f" || continue
    if ! grep -qx "$expected" "$f"; then echo "missing: $f"; status=1; fi
done
exit $status
