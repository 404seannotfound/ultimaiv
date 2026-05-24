# ultimaiv

A love letter to *Ultima IV: Quest of the Avatar*'s character creation —
the wagon, the Gypsy, the cards of virtue, the abacus of stones.

Live: **<https://ultimaiv.pages.dev/>**

A single-page recreation of the 7-question virtue bracket, in original art
and voice. Eight tarot cards laid on a velvet table; an otherworldly voice
weighs your soul against itself; one stone stays lit while the others go
dark; the chosen virtue is named, and the wagon fades. Then the deck opens
so you can read about every virtue you didn't become.

Not the game. Just the ceremony.

## The two ways in

- **<https://ultimaiv.pages.dev/>** — full ceremony. Enter the wagon, hear
  the Gypsy's greeting, weigh seven dilemmas, watch your stones go dark
  one by one, see the chosen card revealed and named.
- **<https://ultimaiv.pages.dev/cards/>** — skip the ceremony, just flip
  through the deck. The intro screen also has a small "skip ahead" link.

The end of the ceremony lands you in the same deck browser, with your
chosen virtue selected, a permalink to your reading, and a way back to the
wagon door if you want to begin again.

## What's here

```
.
├── index.html              single-file prototype (open via local server)
├── _redirects              Cloudflare Pages routing for /cards
├── seed/
│   ├── virtues.json        canonical bundle for each of the 8 virtues
│   ├── script.json         the Gypsy's fixed lines (locked)
│   ├── parables.json       28 short medieval-parable dilemmas, one per pairing
│   ├── cards.tsv           art-prompt seeds for the 8 tarot cards
│   └── gypsy_script.md     authoring notes for the script
├── cards/
│   ├── v1/                 first-pass deck (archive)
│   ├── v2/                 current deck — virtue + mantra + stone + town
│   └── v2_fix/             targeted re-rolls of Honor + Compassion
├── scenes/
│   ├── wagon_interior.jpeg
│   ├── card_back.jpeg
│   └── gypsy.jpeg
├── audio/
│   ├── gypsy/              16 fixed Gypsy lines (entry, transitions, 8 closings, whisper)
│   └── parables/           28 parable scenes, one per virtue pairing
└── scripts/
    ├── gen_cards.sh        parallel xAI Grok render of the deck from seed/cards.tsv
    ├── gen_scene.sh        one-off scene image
    ├── gen_voice.sh        ElevenLabs render of every line in seed/script.json
    ├── gen_parables.sh     ElevenLabs render of every scene in seed/parables.json
    └── deploy.sh           Cloudflare Pages deploy (stages dist/, then wrangler)
```

## Stack

- **Front-end:** vanilla HTML / CSS / JS, single self-contained file
- **Hosting:** Cloudflare Pages (free tier)
- **Art:** xAI Grok image generation (~$0.10/card, $0.80 for a full deck)
- **Voice:** ElevenLabs — voice ID set via `ELEVENLABS_VOICE_GYPSY` in `.env`
- **Future:** D1 for permalink/session storage and live LLM parables

## Run locally

```sh
cp .env.example .env       # fill in your own keys
python3 -m http.server 8765
open http://localhost:8765
```

`file://` doesn't work for the audio (browser security); use any local
server. The `/cards/` subpath is only set up by the deploy step — locally,
hit `/` and use the on-screen skip link or invoke `openCardBrowser(0)` from
the console to test the deck view.

## Regenerate the art

```sh
./scripts/gen_cards.sh v3                # full deck → cards/v3/
./scripts/gen_cards.sh v3 honor valor    # just those two
./scripts/gen_scene.sh scenes/foo.jpeg "prompt..."
```

If you re-roll into a new versioned folder (`v3`, `v4`…), update the `card:`
paths in `DATA.virtues` inside `index.html` so the browser picks up the new
art. The deploy script copies whichever directories live under `cards/`.

## Regenerate the voice

```sh
./scripts/gen_voice.sh                          # 16 Gypsy lines
./scripts/gen_parables.sh                       # 28 parable scenes
./scripts/gen_voice.sh    <ELEVENLABS_VOICE_ID> # swap voice for the Gypsy
./scripts/gen_parables.sh <ELEVENLABS_VOICE_ID> # match voice for parables
```

Both scripts refuse to clobber existing files; delete or move the target
mp3s before re-rolling. Settings are tuned for ceremonial pacing (low
stability, high similarity, mid style).

## Deploy

```sh
./scripts/deploy.sh
```

Requires `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and
`PAGES_PROJECT` in `.env`. The token needs `Cloudflare Pages → Edit`
permission for the account. The script stages `dist/`, copies
`index.html` to `dist/cards/index.html` (so `/cards/` works alongside the
existing `cards/` image directory), copies `functions/` into `dist/` for
the Discord Pages Function, then runs `wrangler pages deploy`.

## Discord `/cast` slash command

A Pages Function at `/api/discord/interactions` powers a `/cast` slash
command that draws a single virtue from the deck and posts it as a rich
embed (random by default, or `/cast virtue: <name>` for a specific pull).

### One-time setup

1. **Create the app:** <https://discord.com/developers/applications> →
   New Application → name it. Copy the **Application ID** and the
   **Public Key** from the General Information page.
2. **Make a bot:** Bot tab → **Reset Token** → copy the bot token.
3. **Fill `.env`:** set `DISCORD_APPLICATION_ID`, `DISCORD_PUBLIC_KEY`,
   `DISCORD_BOT_TOKEN`.
4. **Set the public key as a Pages secret** (the Function reads it at
   runtime):
   ```sh
   wrangler pages secret put DISCORD_PUBLIC_KEY --project-name ultimaiv
   ```
5. **Register the slash command:**
   ```sh
   node scripts/register-discord-commands.mjs
   ```
6. **Deploy:** `./scripts/deploy.sh`
7. **Wire the endpoint:** back in the Discord dev portal → General
   Information → set **Interactions Endpoint URL** to
   `https://ultimaiv.pages.dev/api/discord/interactions` and save. Discord
   sends a PING; the Function PONGs and the URL is accepted.
8. **Install:** Installation tab → enable both *Guild Install* and *User
   Install* → copy the install URL and visit it. Add to a server, or
   install as a user app so `/cast` works in any DM.

### Try it

```
/cast                           # random virtue
/cast virtue: humility          # specific pull
```

The embed renders the card thumbnail, mantra, town/class/companion line,
the prose description, and two cultivation suggestions in the virtue's
stone color.

## Canonical Britannian bundle

| Virtue | Principles | Class | Mantra | Stone | Town | Companion |
|---|---|---|---|---|---|---|
| Honesty | Truth | Mage | AHM | sapphire | Moonglow | Mariah |
| Compassion | Love | Bard | MU | yellow | Britain | Iolo |
| Valor | Courage | Fighter | RA | red | Jhelom | Geoffrey |
| Justice | Truth + Love | Druid | BEH | emerald | Yew | Jaana |
| Sacrifice | Love + Courage | Tinker | CAH | amber | Minoc | Julia |
| Honor | Courage + Truth | Paladin | SUMM | amethyst | Trinsic | Dupre |
| Spirituality | all three | Ranger | OM | white diamond | Skara Brae | Shamino |
| Humility | Void (absence of Pride) | Shepherd | LUM | black | New Magincia | Katrina |

Each card in the deck browser also carries an original prose description
and four short suggestions for cultivating that virtue, in the same
archaic register as the Gypsy's voice.

## License

Original art, voice, prose, and code in this repository are mine. The
*Ultima* setting, virtues, mantras, town names, and Britannian iconography
belong to their respective rights holders; this work is a fan tribute, not
affiliated with or endorsed by anyone associated with the *Ultima* series.
