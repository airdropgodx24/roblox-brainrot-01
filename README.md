# Brainrot Obby Rush

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/airdropgodx24/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard)
[![reward](https://make.fun/badge/roblox-brainrot-01/airdropgodx24/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A bright neon obstacle course for Roblox. Sprint, jump and balance your
way through 12 stages of glowing platforms, moving hazards and tight
landings, all against the clock.

Play it here: https://www.roblox.com/games/138570078055403

Play code: makefun-goblet-clipper-soda

## How it plays

Each stage ends at a checkpoint pad. Touch it and that stage becomes your
new respawn point, so a fall never sends you all the way back to the
start. Your stage, your timer and your collectible count stay on screen
the whole run in a simple HUD at the top.

Hidden around the course are 10 collectible brainrots. Some sit just off
the main path and a few reward a careful look around before you move on.
You do not need them all to finish, but finding every one is the real
challenge for completionists.

Reach the podium at the end of stage 12 and the confetti fires. Your
finish time and how many brainrots you found are shown on the win banner
in the middle of the screen.

## What is in the course

- 12 neon stages that get quicker and trickier as you climb
- 10 hidden brainrots to collect across the whole course
- Checkpoints on every stage so progress is never lost
- A live HUD with run timer, current stage and brainrot tally
- A confetti podium finish with your final time on a win banner

## Layout

- `src/server/` holds the server side of the game: stage checkpoints,
  brainrot pickups, timing and win handling.
- `src/client/` holds the client HUD script that shows the timer, stage
  and brainrot count and presents the win banner.
- `screenshots/` holds the cover and tour pictures of the place.
- `game.rbxl` is the built place file.
- `PLAY.json` points at the published place and universe.
- `main.ts` prepares and checks the make.fun hand-in.

## Running the hand-in

You need Node 22 or newer. From this folder run:

```sh
node main.ts
```

That checks the place file, `PLAY.json`, the sources and the screenshots,
copies them into the output folder, builds `dossier.json` and confirms
every piece is present before printing a short summary. Set
`MAKEFUN_OUTPUT_DIR` if you want the hand-in written somewhere other
than the default `out` folder.

## License

MIT. See the LICENSE file in this repository.
