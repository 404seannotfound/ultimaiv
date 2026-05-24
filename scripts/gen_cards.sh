#!/usr/bin/env bash
# Generate the eight tarot Cards of Virtue via xAI Grok image gen.
#
# usage:  scripts/gen_cards.sh [version] [virtue ...]
#         version defaults to "v1" — produces cards/<version>/<virtue>.jpeg
#         optional virtue list re-rolls only those names from seed/cards.tsv
#         e.g.  scripts/gen_cards.sh v2_fix honor compassion
#
# Reads seed/cards.tsv, wraps each figure prompt in the shared style envelope,
# and fires generations in parallel. Refuses to clobber existing files;
# bump the version arg (v2, v3…) to re-roll.

set -euo pipefail

ver="${1:-v1}"
shift || true
# Remaining args are the optional virtue allowlist.
allow=("$@")
cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERROR: .env not found at repo root." >&2; exit 1; }
set -a; source .env; set +a
: "${XAI_API_KEY:?XAI_API_KEY not set in .env}"

outdir="cards/$ver"
mkdir -p "$outdir"

# Shared style envelope — keeps all 8 cards visually consistent.
# Each card gets its own dominant color (the virtue's stone color) but the
# border ornament, banner placement, and painterly register stay uniform.
ENVELOPE_PREFIX='Beautiful tarot card, portrait orientation 2:3 aspect, uniform border of interwoven Britannian-runic knotwork in antique gold against a deep '
ENVELOPE_SUFFIX=' field, with a single small stylized runic glyph in each of the four corners. Painterly oil-painting finish in the tradition of the Rider-Waite tarot but with medieval illuminated-manuscript ornament. Centered figure on a richly textured ground, dramatic single-source lighting, slight aged patina. The virtue name is lettered in serif Roman capitals on a small cream banner at the bottom of the card. NO other text anywhere on the card except the mantra inscription described in the subject. Subject: '

gen_one() {
  local virtue="$1" stone_color="$2" figure="$3" out="$outdir/$virtue.jpeg"
  if [ -f "$out" ]; then
    echo "skip:  $out (exists — bump version to re-roll)"
    return 0
  fi
  local upper; upper=$(printf '%s' "$virtue" | tr '[:lower:]' '[:upper:]')
  local prompt="${ENVELOPE_PREFIX}${stone_color}${ENVELOPE_SUFFIX}${figure}. The bottom title banner reads: ${upper}."
  local body
  body=$(python3 -c "import json,sys; print(json.dumps({'model':'grok-imagine-image','prompt':sys.argv[1],'n':1,'response_format':'url'}))" "$prompt")
  local resp
  resp=$(curl -sS https://api.x.ai/v1/images/generations \
    -H "Authorization: Bearer $XAI_API_KEY" \
    -H "Content-Type: application/json" \
    --data "$body")
  local url
  url=$(echo "$resp" | python3 -c "import json,sys; r=json.load(sys.stdin); print(r.get('data',[{}])[0].get('url',''))")
  if [ -z "$url" ]; then
    echo "ERROR ($virtue): no url from xAI. Response: $resp" >&2
    return 1
  fi
  curl -sS -o "$out" "$url"
  if [ ! -s "$out" ]; then rm -f "$out"; echo "ERROR ($virtue): empty output" >&2; return 1; fi
  echo "done:  $out ($(wc -c < "$out" | tr -d ' ') bytes)"
}

# Fire selected virtues in parallel; wait for the batch.
pids=()
while IFS=$'\t' read -r virtue principles class mantra stone_color town symbol figure; do
  [ "$virtue" = "virtue" ] && continue        # skip header
  [ -z "$virtue" ] && continue
  if [ ${#allow[@]} -gt 0 ]; then
    skip=1
    for a in "${allow[@]}"; do [ "$a" = "$virtue" ] && skip=0 && break; done
    [ $skip -eq 1 ] && continue
  fi
  gen_one "$virtue" "$stone_color" "$figure" &
  pids+=($!)
done < seed/cards.tsv

fail=0
for pid in "${pids[@]}"; do
  wait "$pid" || fail=$((fail+1))
done

echo "---"
echo "batch complete: $((${#pids[@]} - fail))/${#pids[@]} succeeded → $outdir/"
exit $fail
