#!/usr/bin/env node
// Register the /cast slash command with Discord — one-off, idempotent.
//
// usage:  node scripts/register-discord-commands.mjs
//
// Reads .env for DISCORD_APPLICATION_ID and DISCORD_BOT_TOKEN, then PUTs
// the command set to https://discord.com/api/v10/applications/<id>/commands.
// Run again any time you change the command shape (description, options,
// integration_types, contexts). Re-registration is idempotent.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const envPath = resolve(here, '..', '.env');

const env = {};
try {
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
    if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
} catch (e) {
  console.error(`could not read ${envPath}:`, e.message);
  process.exit(1);
}

const APP_ID = env.DISCORD_APPLICATION_ID;
const TOKEN  = env.DISCORD_BOT_TOKEN;
if (!APP_ID || !TOKEN) {
  console.error('DISCORD_APPLICATION_ID and DISCORD_BOT_TOKEN must be set in .env');
  process.exit(1);
}

const commands = [
  {
    name: 'cast',
    type: 1, // CHAT_INPUT
    description: 'Draw a single virtue from the deck of Britannia.',
    // Available in guilds (0) and as a user-installable app (1):
    integration_types: [0, 1],
    // Usable in guild channels (0), bot DMs (1), and group DMs / private channels (2):
    contexts: [0, 1, 2],
    options: [
      {
        name: 'virtue',
        description: 'Name a specific virtue, or omit for a random draw.',
        type: 3, // STRING
        required: false,
        choices: [
          { name: 'Honesty',      value: 'honesty' },
          { name: 'Compassion',   value: 'compassion' },
          { name: 'Valor',        value: 'valor' },
          { name: 'Justice',      value: 'justice' },
          { name: 'Sacrifice',    value: 'sacrifice' },
          { name: 'Honor',        value: 'honor' },
          { name: 'Spirituality', value: 'spirituality' },
          { name: 'Humility',     value: 'humility' },
        ],
      },
    ],
  },
];

const url = `https://discord.com/api/v10/applications/${APP_ID}/commands`;
const r = await fetch(url, {
  method: 'PUT',
  headers: {
    Authorization: `Bot ${TOKEN}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(commands),
});
const txt = await r.text();
console.log(`HTTP ${r.status}`);
console.log(txt);
process.exit(r.ok ? 0 : 1);
