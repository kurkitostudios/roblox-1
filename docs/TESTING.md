# Test — Build 003.1

Questa macchina non ha Roblox Studio. I controlli sotto sono statici o eseguono solo la logica pura. Non sono un playtest. Non provano fedeltà visiva, FPS o il comportamento di `Humanoid`.

## Controlli eseguiti qui

1. **Sintassi Luau.** Ogni file `.luau` di `server/`, `client/`, `shared/` e `tests/` è compilato con `luau-compile` 0.742 (`--only-parse` e compilazione). I moduli di gioco non girano fuori da Studio, perché usano `game` e `script`.
2. **Regole di gioco.** `shared/Shared/Rules.luau` senza `return Rules`, più `tests/rules_cases.luau`, eseguito con `luau`. Atteso: `RULES_OK`.
   - 50 livelli di Maestria danno 50 Skill Point. L'XP oltre il tetto non sale.
   - Il bonus Rebirth è +10% XP e +10% monete sull'eroe che riceve la ricompensa.
   - La spesa non va in negativo.
   - La prima scelta accetta solo Warrior. Una seconda scelta Mage fallisce. `SwitchHero` verso Mage fallisce anche se Mage è sbloccato, e `selectedHero` resta Warrior.
   - `ReconcileWorld0` passa l'eroe attivo a Warrior, tiene la Maestria e i Rebirth del Warrior, non copia quelli del Mage, tiene il portafoglio ed è idempotente.
   - `WarriorRebirths` ignora i Rebirth archiviati. `TotalRebirths` li somma ancora, ma non è la classifica.
   - `GrantEarnedCoins` alza portafoglio e totale vita. `AddCoins` (rimborso) non alza il totale vita.
   - `SummonRoom` rispetta il tetto dei minion.
   - Il Rebirth azzera solo il Warrior, tiene monete, Pet, materiali, pozioni, collezionabili e gli oggetti senza `boundHero`.
   - La fusione è 5:1 fino a Void.
3. **Struttura Script Sync.** `python3 tests/check_structure.py` deve stampare `STRUCTURE_OK`.
4. **Build 003.1.** `python3 tests/check_build003.py` deve stampare `BUILD003_OK`.
   - `BuildVersion` è `003.1` e `WorldBuildId` è `world0-build003-1`. Lo schema resta 1.
   - I DataStore del profilo e delle classifiche non cambiano nome.
   - `SwitchHero` è rifiutato. Il profilo nuovo nasce Warrior. Il sanitizer chiama `ReconcileWorld0`.
   - Le uova del Mondo 0 sono fisse (250 e 900, prezzi provvisori). Il Premium Egg non ha Product ID.
   - `TradingEnabled` è false. `SellLoot` esce prima di mutare l'inventario.
   - Risen Dead non è nello spawn plan. Il tetto è 3 vivi e 2 per cast. Solo l'arena 1 viene popolata e costruita.
   - Le classifiche usano `WarriorRebirths` e `lifetimeCoinsEarned`.
   - Nessun `MarketplaceService` nel codice. Nessuna stringa italiana nei testi tra virgolette dei moduli di gioco.

Per ripetere il punto 2 servono il binario `luau` e Python 3. Si toglie l'ultima riga `return Rules` da `Rules.luau` e si appende `tests/rules_cases.luau`.

## Non eseguito

- Play in Roblox Studio.
- DataStore reali, OrderedDataStore, avatar dei podi.
- Combattimento, pathfinding, UI su PC o telefono.
- Movimento reale dei nemici, collisione delle capanne, distanza visiva dei cartelli.
- Acquisti Robux. Non vanno provati: non ci sono Product ID.
- Fedeltà visiva rispetto ai fogli approvati. FPS e assenza di glitch di animazione.

## Verifica manuale in Studio

Dopo i passi di [SETUP_ROBLOX_STUDIO.md](SETUP_ROBLOX_STUDIO.md):

1. Output: `[Kurkito] Build 003.1 started. World 0 Warrior, lobby, Arena 1, automatic combat.` e `[Kurkito] World 0 built (world0-build003-1).` Il client stampa `[Kurkito] Client Build 003.1 ready.`
2. Il mondo compare una sola volta. Un secondo avvio con lo stesso `BuildId` non duplica `KurkitoWorld`.
3. Un profilo nuovo entra come Warrior, senza scelta Mage o Archer. Un profilo vecchio con Mage o Archer attivo entra come Warrior e tiene portafoglio, Pet e i dati archiviati.
4. Il lobby ha villaggio a ovest, tre uova a sud, mercante, quattro classifiche e dodici podi a est, strada verso l'Arena 1. Le arene 2–15 non sono stanze percorribili. Il portale del Mondo 2 avvisa che è spento.
5. I cartelli lontani non coprono lo schermo. HUD, menu, mercante, uova e notifiche sono in inglese.
6. “Talk to Merchant” apre Tribal Merchant e il testo “Trading will be available soon.” Non vende e non cancella oggetti.
7. Coin Egg e Advanced Coin Egg spendono monete solo da vicino e pescano i pool fissi. Premium Egg non compra nulla.
8. Il Warrior ha clava, pelliccia e osso. Gli upgrade di HP, DMG e Speed si vedono sul modello. Le pose muovono braccia, busto e gambe, non solo l'arma.
9. In Arena 1 i quattro tipi sono distinti. L'anello di aggro è sottile. Il boss mostra le zone di pericolo e Summon Dead crea al massimo tre minion, senza XP né monete.
10. Uccidere un nemico aumenta le monete vita. Spenderle non le riduce. La classifica Rebirth mostra i Rebirth del Warrior.
