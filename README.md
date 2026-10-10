# Kurkito Studios — Roblox 1

RPG Battle Survival multiplayer per Roblox Studio. Build 001 è la prima base giocabile del Mondo 1: lobby, 15 arene, combattimento automatico, eroi, Maestria, economia, Rebirth, inventario, pozioni, Pet, uova, fusioni e classifiche.

Il codice è Luau e si sincronizza con **Roblox Studio Script Sync**. Non usare Rojo.

## Layout

| Repository | Roblox Studio |
| --- | --- |
| `server/GameServer/` | `ServerScriptService/GameServer` (già collegato) |
| `client/GameClient/` | `StarterPlayer/StarterPlayerScripts/GameClient` (da collegare) |
| `shared/Shared/` | `ReplicatedStorage/Shared` (da collegare) |

`server/GameServer/TestSync.legacy.luau` resta dov'è.

## Documentazione

- [Setup in Roblox Studio](docs/SETUP_ROBLOX_STUDIO.md)
- [Test](docs/TESTING.md)
- [Stato della Build 001](docs/IMPLEMENTATION_STATUS.md)

I numeri di danno, costi, XP e drop sono **provvisori** e stanno nei moduli di `shared/Shared/`. Le geometrie della mappa sono prototipi creati a runtime da `WorldBuilder`, non asset definitivi.

Le uova Robux sono solo vetrine: nessun Product ID e nessun acquisto reale.
