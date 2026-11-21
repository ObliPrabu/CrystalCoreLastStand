# Crystal Core: Last Stand

A wave-defense survival game for Roblox. Protect the glowing Crystal Core from zombies, runners, tanks and a boss
every 5th wave. Earn coins for kills, buy turrets, guns and melee weapons, upgrade them, and survive to win.

## What is in this repo

This repo is a **snapshot of the game's scripts**. The game itself (the map, parts, UI objects, remote events,
lighting) lives in the Roblox place and is edited in Roblox Studio. Studio is the source of truth; this folder
makes the code easy to read, search, review and keep history for.

The folder layout mirrors the Studio hierarchy:

| File ending | Studio object |
|---|---|
| `.server.luau` | `Script` |
| `.client.luau` | `LocalScript` |
| `.luau` | `ModuleScript` |

```
src/
  ServerScriptService/        WaveManager, ShopManager, WeaponManager, AmmoPickups, MagicCarpet
  StarterPlayer/StarterPlayerScripts/
                              DifficultyMenu, ShopUI, ArmoryUI, CarpetClient
  ReplicatedStorage/          WeaponData (one list of every weapon and its numbers)
  ServerStorage/WeaponScripts/ GunServer, GunClient, MeleeServer (cloned onto every weapon)
assets/product-icons/         icons used for the Robux products and the game pass
```

## Not in this repo (create these in Studio)

These objects are not scripts, so they are not exported. The scripts expect them to exist:

- `ReplicatedStorage`: RemoteEvents `DifficultyEvent`, `ShopEvent`, `CarpetEvent`, `WeaponEvent`
- `ServerStorage`: BindableEvents `SkipRequest`, `AdminCommand`, `WeaponReset`; a Folder `WeaponScripts`
  (holding the three weapon scripts above); an R15 rig named `Enemy`
- `Workspace`: `Core`, `ArenaFloor` (700x700), `SpawnPoint` to `SpawnPoint4`, `PlayerSpawn`, `Decor`

The game also has an owner-only admin panel for testing. It is deliberately not part of this repo.
(`WaveManager` still listens on the `AdminCommand` BindableEvent for it, so keep that object.)

See `CLAUDE.md` for how the pieces fit together.

## Monetization

Developer Products (skips) and a game pass (Magic Carpet) are created in the owner's Roblox account. Their ids are
in `ShopManager` and `MagicCarpet`. While `OWNER_TESTS_FREE = true`, the game owner and Studio get them free.

## Syncing

After changing scripts in Studio, re-export them into `src/` (same paths) and commit. There is no build step and
no automated tests; scripts are tested by playing in Studio.
