#!/usr/bin/env bash
# Render one illuminated-manuscript panel per commit, for the chronicle page.
#
# usage:  scripts/gen_devlog.sh [version]
#         version defaults to "v1" — produces devlog/<version>/<commit>.jpeg
#
# Reads seed/devlog.tsv (commit \t short_title \t scene_prompt) and wraps
# each scene in a shared illuminated-manuscript style envelope. Fires the
# whole batch in parallel via xAI Grok. No-clobber; bump version to re-roll.

set -euo pipefail

ver="${1:-v1}"
cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERROR: .env not found at repo root." >&2; exit 1; }
set -a; source .env; set +a
: "${XAI_API_KEY:?XAI_API_KEY not set in .env}"

outdir="devlog/$ver"
mkdir -p "$outdir"

ENVELOPE_PREFIX='Beautiful illuminated medieval manuscript miniature painting, single small framed panel in the tradition of the Très Riches Heures du Duc de Berry, jewel-tone tempera-on-vellum palette of deep lapis blue, vermillion red, emerald green, gold leaf accents, the whole panel framed in an ornate gilded Celtic-knotwork border on aged cream parchment with slight age-spotting, careful flat painterly quality with no photographic realism, figures small and stylized in medieval-monk garb, dramatic single candle or window light. Landscape orientation 3:2 aspect. A small cream banner at the bottom of the panel bears the title in serif Roman capitals reading: '
ENVELOPE_SUFFIX='. The banner has no other text. The panel itself shows: '

gen_one() {
  local commit="$1" title="$2" scene="$3" out="$outdir/$commit.jpeg"
  if [ -f "$out" ]; then echo "skip:  $out (exists)"; return 0; fi
  local prompt="${ENVELOPE_PREFIX}${title}${ENVELOPE_SUFFIX}${scene}."
  local body
  body=$(python3 -c "import json,sys; print(json.dumps({'model':'grok-imagine-image','prompt':sys.argv[1],'n':1,'response_format':'url'}))" "$prompt")
  local resp
  resp=$(curl -sS https://api.x.ai/v1/images/generations \
    -H "Authorization: Bearer $XAI_API_KEY" \
    -H "Content-Type: application/json" \
    --data "$body")
  local url
  url=$(echo "$resp" | python3 -c "import json,sys; r=json.load(sys.stdin); print(r.get('data',[{}])[0].get('url',''))")
  [ -z "$url" ] && { echo "ERROR ($commit): no url. Response: $resp" >&2; return 1; }
  curl -sS -o "$out" "$url"
  [ -s "$out" ] || { rm -f "$out"; echo "ERROR ($commit): empty output" >&2; return 1; }
  echo "done:  $out ($(wc -c < "$out" | tr -d ' ') bytes)"
}

pids=()
while IFS=$'\t' read -r commit title scene; do
  [ "$commit" = "commit" ] && continue
  [ -z "$commit" ] && continue
  gen_one "$commit" "$title" "$scene" &
  pids+=($!)
done < seed/devlog.tsv

fail=0
for pid in "${pids[@]}"; do wait "$pid" || fail=$((fail+1)); done
echo "---"
echo "batch complete: $((${#pids[@]} - fail))/${#pids[@]} succeeded → $outdir/"
exit $fail
