# Brainrot Bazaar

An entry for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01): a 3D tycoon where you
buy absurd brainrots off a conveyor, carry them home, and defend them from thieves.

Play link: https://www.roblox.com/games/83347875698823 (see `PLAY.json`).

## The game

- **Buy or catch.** The Brainrot-O-Matic drops brainrots onto a moving conveyor. Walk up and press E to buy one;
  free common strays also hop around the plaza and can be caught.
- **Carry it home.** The brainrot rides above your head and a beam points to your base. Step inside and it lands
  on a free pad, where it earns cash every second.
- **Climb.** 13 original brainrots across Common, Rare, Epic, Legendary and Mythic, plus Golden, Radioactive and
  Rainbow mutations. Spend cash on more pads and on levelling brainrots up; sell the ones you outgrow.
- **Defend.** A wave clock counts down to "THIEF WAVE INCOMING". Thieves run from the hideout, grab your
  highest-earning brainrot and leg it. Touch a thief to bonk it, or dash home and hit LOCK BASE (key F) to zap them.
- **Rob the rivals.** The other bases belong to NPC rivals. Steal from them for free loot, and expect a revenge raid.
- **Rebirth.** Trade your cash and brainrots for a permanent income multiplier.

## Layout

| Path | Job |
| --- | --- |
| `src/shared/BrainrotCatalog.luau` | Every brainrot, rarity, mutation, price and formula, shared by server and client |
| `src/server/init.server.luau` | Entry script: builds the world, wires the modules, handles the two client requests |
| `src/server/BazaarWorld.luau` | Builds the 3D map from parts |
| `src/server/BrainrotBuilder.luau` | Builds a creature model and its floating label from a catalog entry |
| `src/server/Economy.luau` | The only keeper of cash, income and rebirths |
| `src/server/BaseManager.luau` | Plots, pads, carrying, placing, upgrades, selling, the base lock |
| `src/server/ConveyorSpawner.luau` | The conveyor, the rarity roll, buying, wandering strays |
| `src/server/ThiefAI.luau` | Thief waves, stealing, bonking, revenge raids |
| `src/client/Hud.client.luau`, `HudKit.luau` | The HUD |
| `src/client/WorldFx.client.luau` | Belt chevrons, cash pops, the carry-home beam |

## Build and hand in

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`
and writes `dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
