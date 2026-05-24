# ultimaiv

A love letter to *Ultima IV: Quest of the Avatar*'s character creation —
the wagon, the Gypsy, the cards of virtue, the abacus of stones.

A single-page recreation of the 7-question virtue bracket, in original art
and voice. Eight tarot cards laid on a velvet table; an otherworldly voice
weighs your soul against itself; one stone stays lit while the others go
dark; the chosen virtue is named, and the wagon fades.

Not the game. Just the ceremony.

## What's here

```
.
├── index.html          single-file prototype (open via local server)
├── seed/
│   ├── virtues.json    canonical bundle for each of the 8 virtues
│   ├── script.json     the Gypsy's fixed lines (locked)
│   ├── parables.json   28 short medieval-parable dilemmas, one per pairing
│   ├── cards.tsv       art-prompt seeds for the 8 tarot cards
│   └── gypsy_script.md draft markdown of the script (authoring notes)
├── cards/
│   ├── v1/             first-pass deck (kept as archive)
│   ├── v2/             current deck — virtue + mantra + stone + town setting
│   └── v2_fix/         targeted re-rolls of Honor + Compassion
├── scenes/
│   ├── wagon_interior.jpeg
│   ├── card_back.jpeg
│   └── gypsy.jpeg
├── audio/
│   └── gypsy/          16 ElevenLabs mp3s (8 phase lines + 8 per-virtue closings)
└── scripts/
    ├── gen_cards.sh    parallel xAI Grok render of the deck from seed/cards.tsv
    ├── gen_scene.sh    one-off scene image
    ├── gen_voice.sh    ElevenLabs render of every line in seed/script.json
    └── deploy.sh       Cloudflare Pages deploy (stages dist/, then wrangler)
```

## Stack

- **Front-end:** vanilla HTML / CSS / JS, single file
- **Hosting:** Cloudflare Pages (free tier)
- **Art:** xAI Grok image generation (~$0.10/card)
- **Voice:** ElevenLabs (default voice = Daniel, swappable via `.env`)
- **Future:** D1 for permalink/session storage and live LLM parables

## Run locally

```sh
cp .env.example .env       # fill in your own keys
python3 -m http.server 8765
open http://localhost:8765
```

`file://` doesn't work for the audio (browser CORS); use any local server.

## Regenerate the art

```sh
./scripts/gen_cards.sh v3                # full deck → cards/v3/
./scripts/gen_cards.sh v3 honor valor    # just those two
./scripts/gen_scene.sh scenes/foo.jpeg "prompt..."
```

## Regenerate the voice

```sh
./scripts/gen_voice.sh                                    # uses default voice
./scripts/gen_voice.sh <ELEVENLABS_VOICE_ID>              # swap voice
# or set ELEVENLABS_VOICE_GYPSY in .env and re-run
```

Browse the ElevenLabs library; copy any voice ID and you can re-roll all 16
lines in seconds. Settings are tuned for ceremonial pacing
(low stability, high similarity, mid style).

## Deploy

```sh
./scripts/deploy.sh
```

Requires `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `PAGES_PROJECT`
in `.env`. The token needs the `Cloudflare Pages → Edit` permission for the
account; if you've restricted it to an IP allowlist, deploy from that network.

## Canonical Britannian bundle

| Virtue | Principles | Class | Mantra | Stone | Town | Symbol |
|---|---|---|---|---|---|---|
| Honesty | Truth | Mage | AHM | sapphire | Moonglow | open hand |
| Compassion | Love | Bard | MU | yellow | Britain | heart in roses |
| Valor | Courage | Fighter | RA | red | Jhelom | upraised sword |
| Justice | Truth + Love | Druid | BEH | emerald | Yew | balanced scales |
| Sacrifice | Love + Courage | Tinker | CAH | amber | Minoc | falling tear |
| Honor | Courage + Truth | Paladin | SUMM | amethyst | Trinsic | golden chalice |
| Spirituality | all three | Ranger | OM | white diamond | Skara Brae | luminous ankh |
| Humility | Void (absence of Pride) | Shepherd | LUM | black | New Magincia | shepherd's staff |

## Status

Prototype. The bracket runs, art and voice are present, the ceremony works
end-to-end. The "permalink" at the end is a placeholder — D1-backed session
persistence and live LLM-generated parables (so every reading is one-of-one)
are the next milestones.

## Credits & inspiration

Ultima IV: Quest of the Avatar by Richard Garriott / Origin Systems, 1985.
This is a personal, non-commercial homage with original art, original
dialogue, and original parable text. Nothing here is affiliated with EA or
the Ultima property.
