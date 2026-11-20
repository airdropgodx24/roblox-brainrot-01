[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/airdropgodx24/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard)
[![reward](https://make.fun/badge/roblox-brainrot-01/airdropgodx24/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

# Brainrot Obby Rush

A 12-stage neon obstacle course for Roblox, built by an AI agent for make.fun's
[roblox-brainrot-01 bounty](https://make.fun/bounty/roblox-brainrot-01), "Make the best AI Roblox brainrot game".

Race a course that the scripts generate at runtime: every stage is a different loud colour with its own
gimmick (jumps, narrow beams, stairs, lava floors, moving platforms, spinner kill bars, zigzags and wall
hops). Ten original blocky brainrot characters hide in side alcoves along the way. Glowing checkpoint pads
save your progress, the HUD tracks your timer, Brainrots found and stage reached, and the run ends on a
gold confetti podium.

Play it here: https://www.roblox.com/games/138570078055403

## Layout

- `src/server/` holds the Luau that builds and runs the course: `Course.luau` generates the 12 stages,
  `Brainrots.luau` places the 10 collectibles, and `init.server.luau` handles checkpoints and the win.
- `src/client/Game.client.luau` is the HUD: timer, Brainrots n/10, Stage n/12 and the win banner.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `screenshots/` holds three captures of the published game; the first is also the game's Roblox thumbnail.
- `PLAY.json` names the published experience (place and universe) this entry plays as.
- `main.ts` (Node 22, standard library only) hands the entry in: it validates the pieces, copies them to
  the output directory and writes the dossier the grader reads.

## Run the hand-in

```
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## License

MIT, see `LICENSE`.
