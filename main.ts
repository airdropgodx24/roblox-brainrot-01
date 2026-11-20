// A working roblox-brainrot-01 entry (Node 22, standard library only): the game is this directory's Rojo
// project, built into game.rbxl with `rojo build default.project.json --output game.rbxl`, and the program
// hands it in. It copies game.rbxl, src/, screenshots/ and PLAY.json from beside this file to /output and
// writes /output/dossier.json, the summary the judge reads, with the vendored make.fun library. A starting
// point, not a winner: it is a grey square that moves with the arrow keys. Build your game, rebuild
// game.rbxl, put your PNG or JPEG screenshots in screenshots/ (the first by name is the cover, and one of
// them is the thumbnail you upload for your game on Roblox) and fill in PLAY.json with your published place.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters, digits, . _ and -: the
// grader fails an entry whose output holds any other, so a file such as .gitkeep or .DS_Store copied in fails it.
// So src/ and screenshots/ are copied without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** This entry's game, as the Rojo project beside this file builds it: the title is default.project.json's name, the stage count is Course.luau's STAGES table and the brainrot count is Brainrots.COUNT. */
export interface GameInfo {
  title: string;
  version: string;
  stageCount: number;
  brainrotCount: number;
}

export const GAME: GameInfo = {
  title: 'Brainrot Obby Rush',
  version: '1.0.0',
  stageCount: 12,
  brainrotCount: 10,
};

/**
 * Fail before copying anything when a piece of the hand-in is missing, or when PLAY.json does not name a
 * place: without this, a missing game.rbxl surfaces as a raw copy error three files in, naming neither the
 * game nor what to fix, and a malformed PLAY.json is handed in unnoticed (buildDossier never reads it).
 */
const preflight = (): void => {
  for (const name of ['game.rbxl', 'PLAY.json', 'src', 'screenshots']) {
    if (!existsSync(join(here, name))) throw new Error(`${GAME.title}: ${name} is missing beside main.ts, so there is nothing to hand in`);
  }
  let play: unknown;
  try {
    play = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8'));
  } catch {
    throw new Error(`${GAME.title}: PLAY.json is not valid JSON`);
  }
  const p = play as { place_id?: unknown; universe_id?: unknown; url?: unknown };
  if (typeof p.place_id !== 'number' || typeof p.universe_id !== 'number' || typeof p.url !== 'string') {
    throw new Error(`${GAME.title}: PLAY.json must name a numeric place_id and universe_id and a string url`);
  }
};

preflight();

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);

// Prove the hand-in before reporting it: every piece preflight required beside main.ts must now sit in the
// output, and the dossier must parse back as JSON. The summary line is the run's receipt, and it puts GAME
// to work a second time, so the manifest cannot quietly drift away from the game it describes.
for (const name of ['game.rbxl', 'PLAY.json', 'src', 'screenshots', 'dossier.json']) {
  if (!existsSync(join(out, name))) throw new Error(`${GAME.title}: ${name} is missing from ${out}, so the hand-in is incomplete`);
}
try {
  JSON.parse(readFileSync(join(out, 'dossier.json'), 'utf8'));
} catch {
  throw new Error(`${GAME.title}: the dossier in ${out} does not parse back as JSON`);
}
console.log(`${GAME.title} v${GAME.version}: ${GAME.stageCount} stages, ${GAME.brainrotCount} brainrots, handed in at ${out}`);
