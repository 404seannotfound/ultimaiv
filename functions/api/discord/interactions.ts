// Discord Interactions endpoint for ultimaiv.
//
// Receives signed POSTs from Discord whenever a user invokes a slash command
// registered to this application. Implements:
//   - PING (type 1) → PONG (responder verification)
//   - APPLICATION_COMMAND (type 2) /cast [virtue?] → virtue embed
//
// Signature is verified with Ed25519 against DISCORD_PUBLIC_KEY (Cloudflare
// Pages secret). The virtue catalog is inlined so this Function has no
// runtime dependency on the front-end bundle.

interface Env {
  DISCORD_PUBLIC_KEY: string;
}

type DiscordInteraction = {
  type: number;
  data?: {
    name?: string;
    options?: Array<{ name: string; value: string }>;
  };
};

const SITE = 'https://ultimaiv.pages.dev';

type Virtue = {
  id: string;
  mantra: string;
  class: string;
  principles: string;
  town: string;
  stone: string;
  companion: string;
  color_hex: string;
  card: string;
  description: string;
  cultivate: string[];
};

const VIRTUES: Virtue[] = [
  {
    id: 'honesty', mantra: 'AHM', class: 'Mage', principles: 'Truth',
    town: 'Moonglow', stone: 'sapphire', companion: 'Mariah', color_hex: '#5fa8ff',
    card: '/cards/v2/honesty.jpeg',
    description:
      "The first and clearest of the virtues — the practice of speaking and acting in accord with what one knows. In Britannia, Honesty is taught at the Lycaeum on the island of Moonglow.",
    cultivate: [
      'Say plainly what is so, before deciding what to do about it.',
      'Notice when thou softenest a thing to spare thyself the saying.',
    ],
  },
  {
    id: 'compassion', mantra: 'MU', class: 'Bard', principles: 'Love',
    town: 'Britain', stone: 'yellow', companion: 'Iolo', color_hex: '#f6d65a',
    card: '/cards/v2_fix/compassion.jpeg',
    description:
      "The practice of moving toward another's suffering rather than away. Compassion's town is Britain itself, the seat of Lord British's mercy.",
    cultivate: [
      'Each day, attend to one creature thou wouldst rather pass by.',
      'Listen to a grief without trying to mend it.',
    ],
  },
  {
    id: 'valor', mantra: 'RA', class: 'Fighter', principles: 'Courage',
    town: 'Jhelom', stone: 'red', companion: 'Geoffrey', color_hex: '#e74646',
    card: '/cards/v2/valor.jpeg',
    description:
      "The willingness to act in the face of cost. Valor's home is Jhelom, the warrior isles where children are taught the sword before the alphabet.",
    cultivate: [
      'Do today the small thing thou hast been putting off.',
      'Speak the hard sentence first, before the easy one.',
    ],
  },
  {
    id: 'justice', mantra: 'BEH', class: 'Druid', principles: 'Truth + Love',
    town: 'Yew', stone: 'emerald', companion: 'Jaana', color_hex: '#4dc278',
    card: '/cards/v2/justice.jpeg',
    description:
      "The slow balancing of one good against another. Justice sits in Yew, where the courts of judgment hold beneath ancient evergreens older than the kingdom.",
    cultivate: [
      'Hear all parties before thy judgment forms.',
      'Ask of every ruling: would I make this same call against a friend?',
    ],
  },
  {
    id: 'sacrifice', mantra: 'CAH', class: 'Tinker', principles: 'Love + Courage',
    town: 'Minoc', stone: 'amber', companion: 'Julia', color_hex: '#f2974a',
    card: '/cards/v2/sacrifice.jpeg',
    description:
      "The willingness to give what one has — time, hope, body, name — for another's good. Sacrifice's home is Minoc, the northern craft-town where every offering is forged in fire.",
    cultivate: [
      'Give one thing this week thou wouldst rather keep.',
      'Take the harder watch when the duty is shared.',
    ],
  },
  {
    id: 'honor', mantra: 'SUMM', class: 'Paladin', principles: 'Courage + Truth',
    town: 'Trinsic', stone: 'amethyst', companion: 'Dupre', color_hex: '#a878e6',
    card: '/cards/v2_fix/honor.jpeg',
    description:
      "The keeping of one's word and one's measure even when no one is watching. Honor stands in Trinsic, the walled paladin city whose golden gates open only to those who bow before they enter.",
    cultivate: [
      'Make no promise thou hast not weighed; keep every one thou makest.',
      'Carry thyself the same when watched and when alone.',
    ],
  },
  {
    id: 'spirituality', mantra: 'OM', class: 'Ranger', principles: 'Truth + Love + Courage',
    town: 'Skara Brae', stone: 'white diamond', companion: 'Shamino', color_hex: '#f3ebd0',
    card: '/cards/v2/spirituality.jpeg',
    description:
      "The practice of attention to the larger whole. Spirituality dwells in Skara Brae, the misted isle where the seen and the unseen sit closer than elsewhere. The only virtue that joins all three Principles at once.",
    cultivate: [
      "Sit in silence each day, even for the length of a candle's first inch.",
      'When thou prayest, pray briefly, and listen long.',
    ],
  },
  {
    id: 'humility', mantra: 'LUM', class: 'Shepherd', principles: 'the Void (absence of Pride)',
    town: 'New Magincia', stone: 'black', companion: 'Katrina', color_hex: '#888090',
    card: '/cards/v2/humility.jpeg',
    description:
      "The absence of pride. Of all eight, Humility is the strangest — it derives from the Void. Its town is New Magincia, rebuilt from the ruins of a city that worshipped itself to death.",
    cultivate: [
      "Praise another's work before thou speakest of thine.",
      'Do a good deed and tell no one of it.',
    ],
  },
];

// --- crypto helpers (Ed25519 via WebCrypto in the Workers runtime) ---

function hexToBytes(hex: string): Uint8Array {
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return out;
}

async function verifySignature(
  publicKeyHex: string,
  signatureHex: string,
  timestamp: string,
  body: string,
): Promise<boolean> {
  try {
    const key = await crypto.subtle.importKey(
      'raw',
      hexToBytes(publicKeyHex),
      { name: 'Ed25519' } as unknown as AlgorithmIdentifier,
      false,
      ['verify'],
    );
    const msg = new TextEncoder().encode(timestamp + body);
    return await crypto.subtle.verify(
      'Ed25519',
      key,
      hexToBytes(signatureHex),
      msg,
    );
  } catch (e) {
    return false;
  }
}

// --- /cast response builder ---

function cap(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function virtueEmbed(v: Virtue) {
  return {
    title: `${v.mantra} — ${cap(v.id)}`,
    url: `${SITE}/cards/`,
    description: v.description,
    color: parseInt(v.color_hex.replace('#', ''), 16),
    thumbnail: { url: `${SITE}${v.card}` },
    fields: [
      { name: 'class',     value: v.class,      inline: true },
      { name: 'principle', value: v.principles, inline: true },
      { name: 'town',      value: v.town,       inline: true },
      { name: 'stone',     value: v.stone,      inline: true },
      { name: 'companion', value: v.companion,  inline: true },
      { name: 'cultivate', value: v.cultivate.map(s => `· ${s}`).join('\n'), inline: false },
    ],
    footer: { text: 'ultimaiv · the casting' },
  };
}

function handleCast(payload: DiscordInteraction) {
  const named = payload.data?.options?.find(o => o.name === 'virtue')?.value;
  let v: Virtue | undefined;
  if (named) {
    v = VIRTUES.find(x => x.id === named.toLowerCase());
    if (!v) {
      return {
        type: 4,
        data: {
          content: `Unknown virtue: \`${named}\`. The eight are honesty, compassion, valor, justice, sacrifice, honor, spirituality, humility.`,
          flags: 64, // ephemeral
        },
      };
    }
  } else {
    v = VIRTUES[Math.floor(Math.random() * VIRTUES.length)];
  }
  return {
    type: 4,
    data: { embeds: [virtueEmbed(v!)] },
  };
}

// --- entry point ---

export const onRequestPost: PagesFunction<Env> = async ({ request, env }) => {
  const signature = request.headers.get('x-signature-ed25519');
  const timestamp = request.headers.get('x-signature-timestamp');
  const body = await request.text();

  if (!env.DISCORD_PUBLIC_KEY) {
    return new Response('server missing DISCORD_PUBLIC_KEY', { status: 500 });
  }
  if (!signature || !timestamp) {
    return new Response('missing signature headers', { status: 401 });
  }
  const ok = await verifySignature(env.DISCORD_PUBLIC_KEY, signature, timestamp, body);
  if (!ok) {
    return new Response('invalid signature', { status: 401 });
  }

  let payload: DiscordInteraction;
  try { payload = JSON.parse(body); } catch {
    return new Response('bad json', { status: 400 });
  }

  // PING → PONG
  if (payload.type === 1) {
    return Response.json({ type: 1 });
  }

  // APPLICATION_COMMAND
  if (payload.type === 2) {
    if (payload.data?.name === 'cast') {
      return Response.json(handleCast(payload));
    }
    return Response.json({
      type: 4,
      data: { content: `Unknown command: ${payload.data?.name}`, flags: 64 },
    });
  }

  return Response.json({ type: 4, data: { content: 'Unhandled interaction type', flags: 64 } });
};

// Friendly GET for health checks.
export const onRequestGet: PagesFunction<Env> = async () =>
  new Response('ultimaiv discord interactions endpoint — POST only', { status: 200 });
