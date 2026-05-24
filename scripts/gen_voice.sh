#!/usr/bin/env bash
# Render every fixed Gypsy line from seed/script.json into audio/gypsy/*.mp3
# via ElevenLabs. Refuses to clobber existing files; delete or move them
# before re-rolling.
#
# usage:  scripts/gen_voice.sh
#         scripts/gen_voice.sh <VOICE_ID>     # override .env's ELEVENLABS_VOICE_GYPSY
#
# Output mapping:
#   audio/gypsy/entry.mp3
#   audio/gypsy/explanation.mp3
#   audio/gypsy/question_framing.mp3
#   audio/gypsy/after_answer.mp3
#   audio/gypsy/round_1_to_2.mp3
#   audio/gypsy/round_2_to_final.mp3
#   audio/gypsy/before_final.mp3
#   audio/gypsy/whisper.mp3
#   audio/gypsy/closing_<virtue>.mp3   (8 files)

set -euo pipefail

cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERROR: .env not found at repo root." >&2; exit 1; }
set -a; source .env; set +a
: "${ELEVENLABS_API_KEY:?ELEVENLABS_API_KEY not set in .env}"

# Voice: arg > env > Daniel (calm measured British male — sounds ageless with low stability).
VOICE="${1:-${ELEVENLABS_VOICE_GYPSY:-onwK4e9ZLuTAKqWW03F9}}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

outdir="audio/gypsy"
mkdir -p "$outdir"

# Voice settings tuned for ceremonial pacing.
# stability low → more emotional variance per render
# similarity_boost high → stays in-voice
# style mid → some theatrical expression
VOICE_SETTINGS='{"stability":0.38,"similarity_boost":0.85,"style":0.45,"use_speaker_boost":true}'

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
    echo "ERROR ($key): HTTP $http_code. Response:" >&2
    cat "$out" >&2 || true
    rm -f "$out"
    return 1
  fi
  if [ ! -s "$out" ]; then rm -f "$out"; echo "ERROR ($key): empty output" >&2; return 1; fi
  echo "done:  $out ($(wc -c < "$out" | tr -d ' ') bytes)"
}

# Read every phase + closing from seed/script.json into a TSV temp file.
tsv=$(mktemp)
trap 'rm -f "$tsv"' EXIT
python3 - "$tsv" <<'PY'
import json, sys
out = open(sys.argv[1], "w")
s = json.load(open("seed/script.json"))
order = ["entry","explanation","question_framing","after_answer","round_1_to_2","round_2_to_final","before_final","whisper"]
for k in order:
    v = s.get(k)
    if isinstance(v, str):
        out.write(f"{k}\t{v}\n")
for vname, line in s.get("closing", {}).items():
    out.write(f"closing_{vname}\t{line}\n")
out.close()
PY

n_lines=$(wc -l < "$tsv" | tr -d ' ')
echo "voice : $VOICE"
echo "model : $MODEL"
echo "lines : $n_lines"
echo "---"

# Parallelize, throttled to 4 concurrent (ElevenLabs rate-limits hard).
pids=()
running=0
MAX_CONCURRENT=4
fail=0
while IFS=$'\t' read -r key text; do
  [ -z "$key" ] && continue
  render_one "$key" "$text" &
  pids+=($!)
  running=$((running+1))
  if [ "$running" -ge "$MAX_CONCURRENT" ]; then
    if ! wait "${pids[0]}"; then fail=$((fail+1)); fi
    pids=("${pids[@]:1}")
    running=$((running-1))
  fi
done < "$tsv"
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then fail=$((fail+1)); fi
done

echo "---"
echo "batch complete: $((n_lines - fail))/$n_lines succeeded → $outdir/"
exit $fail
