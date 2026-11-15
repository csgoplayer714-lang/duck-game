# DUCK RNG – The Ultimate Duck Hunt

A Roblox game where you sneak through themed ponds, pounce on rubber ducks with a net, fight the rare ones in your net, and escape the pond before Mom duck catches you. Ducks fill your collection, your battle team and your coop, where they make Feathers for cosmetics.

The game is built and played in **Roblox Studio** (place "catch a duck"). This repository mirrors every script in the place, in the standard [Rojo](https://rojo.space) layout, plus the Blender model exports and UI images. Each change made in Studio is committed here.

## Layout

```
src/
  ServerScriptService/
    Main.server.luau          server bootstrap, wires the services together
    Services/                 server-authoritative game systems
  ReplicatedStorage/
    Shared/                   data + maths used by both server and client
    Client/                   UI, rendering and input (required by ClientMain)
  StarterPlayer/StarterPlayerScripts/
    ClientMain.client.luau    client bootstrap
  ServerStorage/Templates/
    MapBuilder.luau           edit-time generator for all 8 worlds + the Coop Field
assets/
  models/                     Blender .glb exports (imported into ReplicatedStorage.Assets.Meshes)
  images/                     icon sheets and UI textures
docs/previews/                renders of the Blender models
default.project.json          Rojo project
```

## Systems

| Area | Server | Shared | Client |
|---|---|---|---|
| Netting ducks (Hunt & Pounce) | `FishingService` – shared ponds per world, duck awareness/panic, pounce validation, net fights, personal Mom chase | `PoolSim` – pond outlines, deterministic duck paths, awareness and fight tuning | `Fishing` – duck rendering, sneak, pounce, fight dial, Mom, escape UI |
| Data | `DataService` – load/save, validation, client sync | `Config`, `Stats` | `State` |
| Ducks | `InventoryService` – team, training, evolving, releasing | `DuckData`, `Rarity`, `DuckModelBuilder`, `ModelKit` | `PanelDucks`, `RigAnimator`, `Followers` |
| Nets | `ShopService` (also world travel) | `RodModelBuilder` | `PanelMisc`, `FirstPerson` |
| Battles | `BattleEngine`, `BossService`, `PvPService` | `BossModelBuilder` | `BattleView` |
| Coop + Feathers | `CoopService` | `CoopData` | `PanelCoop`, `CoopFx` |
| Cosmetics | `CosmeticService` | `Cosmetics` | `PanelCoop` (Style shop), `CoopFx` (animations) |
| Progress | `ProgressService`, `LeaderboardService`, `AnnounceService`, `LuckEventService` | | `HUD`, `Effects`, `Panels`, `UIKit` |
| Networking | `Net` – one validated, rate-limited remote for every request | | |
| World | | `WorldData` | `WorldFx` |

## Rebuilding the maps

`MapBuilder` runs in Edit mode, not at runtime: it builds `workspace.Map.World_1..8` and `workspace.Map.CoopField`, including the smooth-terrain hills, from the meshes in `ReplicatedStorage.Assets.Meshes`.
