// Brainrot Obby Rush - make.fun hand-in program.
//
// Run with Node 22 (no install, no build step):
//
//   node main.ts
//
// The program checks that every piece of the entry is present beside
// it, copies the place, the sources and the screenshots into the
// output folder, and asks the vendored make.fun library to describe
// that folder in a dossier.json. The output folder is taken from the
// MAKEFUN_OUTPUT_DIR environment variable and defaults to "out".

import { cpSync, existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { buildDossier } from './vendor/makefun-roblox.ts';

// The facts about this game that the hand-in is built around.
const GAME = {
  title: 'Brainrot Obby Rush',
  version: 1,
  stageCount: 12,
  brainrotCount: 10,
} as const;

// Everything is resolved relative to this file, never the caller's
// working directory, so the program behaves the same from anywhere.
const here = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(process.env.MAKEFUN_OUTPUT_DIR ?? join(here, 'out'));

// Stop early, naming the game, when the entry cannot be handed in.
function fail(reason: string): never {
  throw new Error(`${GAME.title}: ${reason}`);
}

// --- Preflight -------------------------------------------------------------

// The four pieces a hand-in is made of, each beside this file.
const required: { name: string; kind: 'file' | 'directory' }[] = [
  { name: 'game.rbxl', kind: 'file' },
  { name: 'PLAY.json', kind: 'file' },
  { name: 'src', kind: 'directory' },
  { name: 'screenshots', kind: 'directory' },
];

for (const piece of required) {
  const path = join(here, piece.name);
  if (!existsSync(path)) {
    fail(`cannot hand in: ${piece.name} is missing from ${here}`);
  }
  const isDirectory = statSync(path).isDirectory();
  if (piece.kind === 'directory' && !isDirectory) {
    fail(`cannot hand in: ${piece.name} should be a folder, not a file`);
  }
  if (piece.kind === 'file' && isDirectory) {
    fail(`cannot hand in: ${piece.name} should be a file, not a folder`);
  }
}

// PLAY.json must parse and point at the published place: both ids are
// numbers and the page address is a string.
let play: unknown;
try {
  play = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8'));
} catch {
  fail('cannot hand in: PLAY.json is not valid JSON');
}
if (typeof play !== 'object' || play === null) {
  fail('cannot hand in: PLAY.json must hold a JSON object');
}
const record = play as Record<string, unknown>;
if (typeof record.place_id !== 'number' || !Number.isFinite(record.place_id)) {
  fail('cannot hand in: PLAY.json needs a numeric place_id');
}
if (typeof record.universe_id !== 'number' || !Number.isFinite(record.universe_id)) {
  fail('cannot hand in: PLAY.json needs a numeric universe_id');
}
if (typeof record.url !== 'string' || record.url.length === 0) {
  fail('cannot hand in: PLAY.json needs a string url');
}

// --- Copy the entry into the output folder ---------------------------------

// Hidden files (names starting with a dot) are working files, not part
// of the game, so the copy leaves them behind at every depth.
const keepPublic = (source: string): boolean => {
  const base = source.split(/[\\/]/).pop() ?? '';
  return !base.startsWith('.');
};

mkdirSync(outDir, { recursive: true });

for (const name of ['game.rbxl', 'PLAY.json']) {
  cpSync(join(here, name), join(outDir, name));
}
for (const name of ['src', 'screenshots']) {
  cpSync(join(here, name), join(outDir, name), { recursive: true, filter: keepPublic });
}

// --- Describe the output folder --------------------------------------------

// The caps are the bounty's own: they bound the dossier text, the
// screenshots it may carry and the size of place it may read.
const dossier = buildDossier(outDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(outDir, 'dossier.json'), dossier);

// --- Verify the hand-in ------------------------------------------------------

// Every piece copied above must have landed, and the dossier must be
// readable JSON, before this program calls the hand-in done.
for (const name of ['game.rbxl', 'PLAY.json', 'src', 'screenshots', 'dossier.json']) {
  if (!existsSync(join(outDir, name))) {
    fail(`hand-in incomplete: ${name} did not reach ${outDir}`);
  }
}
try {
  JSON.parse(readFileSync(join(outDir, 'dossier.json'), 'utf8'));
} catch {
  fail('hand-in incomplete: dossier.json is not valid JSON');
}

// The copied PLAY.json must still point at the same place the preflight
// approved; a copy that changed the ids would hand in the wrong game.
const copied = JSON.parse(readFileSync(join(outDir, 'PLAY.json'), 'utf8')) as Record<string, unknown>;
if (copied.place_id !== record.place_id || copied.universe_id !== record.universe_id) {
  fail('hand-in incomplete: the copied PLAY.json names a different place');
}

console.log(
  `${GAME.title} v${GAME.version}: ${GAME.stageCount} stages, ${GAME.brainrotCount} brainrots, handed in at ${outDir}`,
);
