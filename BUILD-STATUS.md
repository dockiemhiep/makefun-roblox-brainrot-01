# BUILD-STATUS — Brainrot Bazaar (roblox-brainrot-01)

Status: **built, play-tested, saved to Roblox, committed and pushed.** Session #2, written 2026-11-18 ~13:30 ICT.
Two things need the owner before the 20/11 steps; they are listed first.

## Needs the owner

1. **`.mcp.json` was not rewritten.** The harness refused the write ("sensitive file"), so the file still has its
   start-of-recording content and no line of it was written in this session. I did not write it another way,
   because that would be going around the refusal. If the transcript gate counts `.mcp.json`, it fails
   `transcripts_witnessed`. Fix: allow the edit and have a recorded session write the same bytes back, or remove the
   file from the entry commit if the MCP wiring is no longer needed there.
2. **The live place may still be the old version.** `save_place` returned `Saved to Roblox, version 12` for place
   83347875698823. The tool's contract says it saves and never publishes, and the MCP toolset has no publish call
   (Open Cloud upload refuses `.rbxl`). I could not confirm which version players get. In Studio:
   **File > Publish to Roblox** (Alt+P) on the open "Brainrot Bazaar" place, once.

## Verified ids

Read from the open Studio place through MCP (`execute_luau`, Edit datamodel) before anything was built:
`game.PlaceId = 83347875698823`, `game.GameId = 10777470989`. `PLAY.json` was written from those values and has not
changed since. Open Cloud reports the place as `root: true` (start place), server size 50.

## What was built

A 3D tycoon in the Steal-a-Brainrot genre with its own cast and world. All script text is under `src/` (11 files),
written in this session; `game.rbxl` is the Rojo build of them.

- **World** (`BazaarWorld`): plaza, moving conveyor between the Brainrot-O-Matic and the Recycler, eight walled base
  plots with pads, gates, awnings and shields, a thief hideout, welcome arch, tents, lamps, palms, hills, clouds.
- **Cast** (`BrainrotCatalog`, `BrainrotBuilder`): 13 original brainrots built from parts with faces and floating
  name / rarity / $-per-second labels. Common 3, Rare 3, Epic 3, Legendary 2, Mythic 2; Golden, Radioactive and
  Rainbow mutations; rarity beams from Epic up.
- **Loop** (`ConveyorSpawner`, `BaseManager`, `Economy`): buy off the conveyor (E) or catch a free stray, carry it
  home, it lands on a pad and pays every second. More pads, five upgrade levels, selling, rebirth for a permanent
  income multiplier.
- **Threat** (`ThiefAI`): a wave clock, then thieves run from the hideout, take the best brainrot and run back.
  Touching a thief returns the loot and pays a bounty; LOCK BASE (F, only from inside the base, 30 s cooldown) zaps
  them. Other plots are NPC rival bases that can be robbed, which triggers a revenge raid.
- **HUD** (`Hud`, `HudKit`, `WorldFx`): cash and income top-centre, pads / found / multiplier chips, wave clock that
  becomes a centre banner, rarity ladder, Lock Base and Rebirth buttons, rarity-coloured popups, belt chevrons,
  cash pops, carry-home beam.

Not built: saving progress between sessions (no DataStore), sounds, player-versus-player stealing.

## Screenshots

Captures of the running Studio play test, cropped to the 16:9 frame the HUD keeps to, scaled to 1280x720.

| File | Size | Shows |
| --- | --- | --- |
| `screenshots/1-cover.jpg` | 254,090 B | Carrying a brainrot home to a stocked base, full HUD |
| `screenshots/2-bazaar.jpg` | 248,712 B | Conveyor with a Legendary for sale, the machine and arch |
| `screenshots/3-thief.jpg` | 257,038 B | Wave-one thief leaving the gate, raid banner, THIEF ALERT popup |

- They are `.jpg`, not the `.png` names in the brief: a 1280x720 PNG of this scene does not fit 256 KiB.
- The Studio viewport was 797x693, so the 16:9 crop is 797x448 upscaled; they are a little soft at full size.
- Three, not four: the judge's sheet shows three at 382x238 each and four at 253x158.

## Verify results (commit 55cfe7f tree)

| Gate | Result |
| --- | --- |
| `rojo build default.project.json --output game.rbxl` | exit 0 |
| luau-web 1.5.1 compile of every file in `src/` | exit 0, 11 of 11 |
| `MAKEFUN_OUTPUT_DIR=out node main.ts` | exit 0 |
| Dossier: scripts matched to `src/` | 100% (11 of 11), dossier 1.08 MB |
| `game.rbxl` binary and at most 32 MiB | pass |
| Screenshots: 3, each at most 256 KiB, 1280x720 | pass |
| `PLAY.json` holds the real ids | pass |
| No dot-named files under `src/` or `screenshots/` | pass |
| Studio scripts equal `src/` (length + checksum per file) | 11 of 11 |
| Play test output log | empty after a 50 s run through a thief raid |
| `makefun check` | 4 pass, 1 fail, 16 skipped |

Played through in Studio: buy with E, carry, place, income tick, pad unlock, upgrade, thief steal and loss, bonk,
lock base, rebirth, rob a rival and the revenge raid.

`makefun check` fails `play_link` because the experience is Private. That is expected until the Public flip.
It also lists, as checked only at submission: the GitHub repository must be public, and either its owner is the
account's GitHub login or the commit carries `.makefun/owner.json`. I did not check or change either.

## Remaining owner steps

- Now: the two items under "Needs the owner".
- 20/11: set the experience Public; upload the icon and the thumbnail (thumbnail = `screenshots/1-cover.jpg`, the
  same file); wait until the experience page shows both; then `makefun check` and submit.
- Optional: the place allows 50 players a server and the map has eight bases. A ninth player gets no base (they are
  told so and can still bonk thieves). Setting the server size to 8 avoids that.
- Not run: the kit's submit.
