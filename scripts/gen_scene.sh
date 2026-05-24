#!/usr/bin/env bash
# Generate a single supporting scene image via xAI Grok.
#
# usage:  scripts/gen_scene.sh <output-path-rel-to-repo> <full-prompt>
#
# Refuses to clobber existing files. Used for one-off art (wagon interior,
# card back, gypsy figure) that doesn't belong in the seed-driven card batch.

set -euo pipefail

out="$1"; prompt="$2"
cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERROR: .env not found at repo root." >&2; exit 1; }
set -a; source .env; set +a
: "${XAI_API_KEY:?XAI_API_KEY not set in .env}"

mkdir -p "$(dirname "$out")"
if [ -f "$out" ]; then
  echo "ERROR: $out already exists. Pick a different filename (e.g. _v2)." >&2
  exit 1
fi

body=$(python3 -c "import json,sys; print(json.dumps({'model':'grok-imagine-image','prompt':sys.argv[1],'n':1,'response_format':'url'}))" "$prompt")
resp=$(curl -sS https://api.x.ai/v1/images/generations \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -H "Content-Type: application/json" \
  --data "$body")
url=$(echo "$resp" | python3 -c "import json,sys; r=json.load(sys.stdin); print(r.get('data',[{}])[0].get('url',''))")
[ -z "$url" ] && { echo "ERROR: no url from xAI. Response: $resp" >&2; exit 1; }

curl -sS -o "$out" "$url"
[ -s "$out" ] || { rm -f "$out"; echo "ERROR: empty output." >&2; exit 1; }
echo "done: $out ($(wc -c < "$out" | tr -d ' ') bytes)"
