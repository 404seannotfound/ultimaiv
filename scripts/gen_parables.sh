#!/usr/bin/env bash
# Render each parable's `scene` line into audio/parables/<pair-key>.mp3
# via ElevenLabs, using the same Gypsy voice as scripts/gen_voice.sh.
#
# usage:  scripts/gen_parables.sh
#         scripts/gen_parables.sh <VOICE_ID>     # override .env's ELEVENLABS_VOICE_GYPSY
#
# Refuses to clobber existing files. Delete or move them before re-rolling.

set -euo pipefail

cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERROR: .env not found at repo root." >&2; exit 1; }
set -a; source .env; set +a
: "${ELEVENLABS_API_KEY:?ELEVENLABS_API_KEY not set in .env}"

VOICE="${1:-${ELEVENLABS_VOICE_GYPSY:-onwK4e9ZLuTAKqWW03F9}}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"
VOICE_SETTINGS='{"stability":0.38,"similarity_boost":0.85,"style":0.45,"use_speaker_boost":true}'

outdir="audio/parables"
mkdir -p "$outdir"

render_one() {
  local key="$1" text="$2" out="$outdir/$key.mp3"
  if [ -f "$out" ]; then echo "skip:  $out (exists)"; return 0; fi
  local body
  body=$(python3 -c "
import json,sys
print(json.dumps({
  'text': sys.argv[1],
  'model_id': sys.argv[2],
  'voice_settings': json.loads(sys.argv[3])
}))
" "$text" "$MODEL" "$VOICE_SETTINGS")
  local http_code
  http_code=$(curl -sS -o "$out" -w "%{http_code}" \
    -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: audio/mpeg" \
    --data "$body")
  if [ "$http_code" != "200" ]; then
    echo "ERROR ($key): HTTP $http_code." >&2
    cat "$out" >&2 || true
    rm -f "$out"
    return 1
  fi
  if [ ! -s "$out" ]; then rm -f "$out"; echo "ERROR ($key): empty output" >&2; return 1; fi
  echo "done:  $out ($(wc -c < "$out" | tr -d ' ') bytes)"
}

# Extract (key, scene) TSV from seed/parables.json.
tsv=$(mktemp); trap 'rm -f "$tsv"' EXIT
python3 - "$tsv" <<'PY'
import json, sys
out = open(sys.argv[1], "w")
data = json.load(open("seed/parables.json"))
for key, p in data.get("parables", {}).items():
    scene = p.get("scene", "").strip()
    if scene:
        out.write(f"{key}\t{scene}\n")
out.close()
PY

n_lines=$(wc -l < "$tsv" | tr -d ' ')
echo "voice : $VOICE"
echo "model : $MODEL"
echo "lines : $n_lines"
echo "---"

pids=(); running=0; MAX_CONCURRENT=4; fail=0
while IFS=$'\t' read -r key text; do
  [ -z "$key" ] && continue
  render_one "$key" "$text" &
  pids+=($!); running=$((running+1))
  if [ "$running" -ge "$MAX_CONCURRENT" ]; then
    if ! wait "${pids[0]}"; then fail=$((fail+1)); fi
    pids=("${pids[@]:1}"); running=$((running-1))
  fi
done < "$tsv"
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then fail=$((fail+1)); fi
done

echo "---"
echo "batch complete: $((n_lines - fail))/$n_lines succeeded → $outdir/"
exit $fail
