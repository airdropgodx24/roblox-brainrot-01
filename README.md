# Brainrot Obby Rush

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/airdropgodx24/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard)
[![reward](https://make.fun/badge/roblox-brainrot-01/airdropgodx24/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A neon obstacle course for Roblox: twelve stages of glowing jumps,
spinners and narrow beams, with ten collectible brainrots hidden along
the way for anyone who explores instead of just racing ahead.

**Play it here:** https://www.roblox.com/games/138570078055403

**Play code:** makefun-goblet-clipper-soda

## How it plays

You spawn at the foot of the course and run it from stage 1 to stage
12. Every stage ends at a checkpoint pad; step on it and that stage
becomes your respawn point, so a fall costs you seconds rather than
the whole run. Lava and kill bricks send you back to your last
checkpoint, and the higher stages mix in tighter jumps and moving
hazards under the same neon lights.

Ten brainrots are tucked around the course, some just off the main
line and a few in plain sight above jumps you would otherwise hurry
past. Walking into one banks it for the run. None of them are required
to finish, but the podium at the top keeps count of how many you
found.

Touch the podium at the end of stage 12 and the run is won: confetti
rains over the podium, your finish time is recorded, and the win
banner shows your time next to your brainrot tally.

## The HUD

A slim bar at the top of the screen follows the whole run:

- a stopwatch that starts with the run and stops at the podium,
- a brainrot counter (found out of 10) that flashes on every pickup,
- a stage tracker (current stage out of 12).

The server owns the run state and mirrors it onto the player as the
attributes `Stage`, `Collected`, `Won` and `StartTime`, with the final
time also published in leaderstats. Two RemoteEvents, `BrainrotCollect`
and `BrainrotWin`, sit directly in ReplicatedStorage and drive the
counter flash and the win banner on the client.

## Repository layout

- `game.rbxl` - the built Roblox place.
- `src/server/` - the server scripts: checkpoints, brainrot pickups,
  the podium and the run state.
- `src/client/` - the client scripts: the HUD in `Game.client.luau`.
- `screenshots/` - the tour screenshots, start, mid-run and podium.
- `PLAY.json` - the published place and universe ids and the play link.
- `TOUR.json` - the screenshot tour steps.
- `default.project.json` - the Rojo project for the place.
- `vendor/makefun-roblox.ts` - the vendored make.fun place library.
- `main.ts` - the hand-in program described below.

## Running the hand-in

The hand-in program needs Node 22 and nothing else; it uses only the
standard library. From this folder:

```sh
node main.ts
```

It checks that `game.rbxl`, `PLAY.json`, `src/` and `screenshots/` are
all present and that `PLAY.json` parses, copies the entry into the
output folder (`out/` by default, or the folder named by the
`MAKEFUN_OUTPUT_DIR` environment variable), and writes a
`dossier.json` there with the vendored `buildDossier`. It then
verifies every piece arrived and that the dossier parses before
printing the hand-in summary.

## License

MIT. See `LICENSE`.
