# Kurkito Studios — Roblox 1

RPG Battle Survival multiplayer per Roblox Studio. La Build 001 resta la base giocabile del Mondo 1. La Build 002 ne migliora aspetto, interfaccia inglese e visibilità dei testi 3D, senza cambiare salvataggi, danni, costi o regole di gioco.

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
- [Stato della Build 002](docs/IMPLEMENTATION_STATUS.md)

I numeri di danno, costi, XP e drop sono **provvisori** e stanno nei moduli di `shared/Shared/`. Le geometrie della mappa e dei personaggi sono generate a runtime in Luau da `WorldBuilder`, `PropKit`, `CreatureKit` e `HeroAppearance`. Non sono mesh importate.

Le uova Robux sono solo vetrine: nessun Product ID e nessun acquisto reale.
