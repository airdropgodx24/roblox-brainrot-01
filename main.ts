// Brainrot Obby Rush - make.fun hand-in program.
// Checks the entry is complete, copies the playable pieces into the
// output directory, builds the dossier the scorer expects, and verifies
// everything landed before printing a one-line summary.

import { cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { buildDossier } from './vendor/makefun-roblox.ts';

const GAME = {
  title: 'Brainrot Obby Rush',
  version: 1,
  stageCount: 12,
  brainrotCount: 10,
};

const here = dirname(fileURLToPath(import.meta.url));

function fail(message) {
  throw new Error(`${GAME.title}: ${message}`);
}

function requirePresent(name) {
  const target = join(here, name);
  if (!existsSync(target)) {
    fail(`missing ${name} beside main.ts - the hand-in is incomplete`);
  }
  return target;
}

function checkPlayFile(playPath) {
  let play;
  try {
    play = JSON.parse(readFileSync(playPath, 'utf8'));
  } catch (err) {
    fail(`PLAY.json does not parse: ${err.message}`);
  }
  if (typeof play.place_id !== 'number') {
    fail('PLAY.json needs a numeric place_id');
  }
  if (typeof play.universe_id !== 'number') {
    fail('PLAY.json needs a numeric universe_id');
  }
  if (typeof play.url !== 'string' || play.url.length === 0) {
    fail('PLAY.json needs a non-empty string url');
  }
  if (!play.url.endsWith(String(play.place_id))) {
    fail(`PLAY.json url should end with its place_id (${play.place_id}), got ${play.url}`);
  }
  return play;
}

// ---- Preflight ----------------------------------------------------------
const placeFile = requirePresent('game.rbxl');
const playFile = requirePresent('PLAY.json');
const srcDir = requirePresent('src');
const shotsDir = requirePresent('screenshots');
checkPlayFile(playFile);

// ---- Hand-in ------------------------------------------------------------
const out = process.env.MAKEFUN_OUTPUT_DIR || join(here, 'out');
mkdirSync(out, { recursive: true });

const skipDotfiles = (source) => !source.split(/[\\/]/).some((part) => part.startsWith('.') && part.length > 1);

cpSync(placeFile, join(out, 'game.rbxl'));
cpSync(playFile, join(out, 'PLAY.json'));
cpSync(srcDir, join(out, 'src'), { recursive: true, filter: skipDotfiles });
cpSync(shotsDir, join(out, 'screenshots'), { recursive: true, filter: skipDotfiles });

const dossier = buildDossier(out, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(out, 'dossier.json'), dossier);

// ---- Verify -------------------------------------------------------------
for (const piece of ['game.rbxl', 'PLAY.json', 'src', 'screenshots', 'dossier.json']) {
  if (!existsSync(join(out, piece))) {
    fail(`hand-in verification failed: ${piece} is not in the output directory`);
  }
}
try {
  JSON.parse(readFileSync(join(out, 'dossier.json'), 'utf8'));
} catch (err) {
  fail(`dossier.json does not parse back: ${err.message}`);
}

console.log(
  `${GAME.title} v${GAME.version}: ${GAME.stageCount} stages, ${GAME.brainrotCount} brainrots, handed in at ${out}`,
);
