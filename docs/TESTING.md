# Test — Build 003

Questa macchina non ha Roblox Studio. I controlli sotto sono statici o eseguono solo la logica pura. Non sono un playtest.

## Controlli eseguiti qui

1. **Sintassi Luau.** Ogni file `.luau` di `server/`, `client/`, `shared/` e `tests/` è stato compilato con `luau-compile` 0.742. Nessun errore di sintassi. I moduli non sono stati eseguiti fuori da Studio, perché usano `game`, `script` e le API Roblox.
2. **Regole di gioco.** `shared/Shared/Rules.luau` è stato concatenato con `tests/rules_cases.luau` ed eseguito. Atteso: `RULES_OK`.
   - 50 livelli di Maestria danno esattamente 50 Skill Point e l'XP oltre 50 non sale.
   - Il bonus Rebirth è +10% XP per Rebirth e +10% monete, solo sull'eroe che riceve la ricompensa.
   - La spesa di monete non va in negativo.
   - La scelta del primo eroe è una sola. Il cambio eroe non sposta la Maestria.
   - Il Rebirth azzera solo quell'eroe, tiene monete, Pet, materiali, pozioni, collezionabili, eroi sbloccati e gli oggetti senza `boundHero`, e cancella l'equipaggiamento vincolato.
   - La fusione è 5:1, rifiuta Pet equipaggiati, uid duplicati e Pet diversi.
   - Il tetto di drop (0,85) blocca un raro anche con fortuna enorme. Un drop con probabilità base 1 resta garantito. Il filtro di classe scarta gli oggetti delle altre classi.
   - Una pozione della stessa famiglia sostituisce durata e potenza, non le somma.
   - Il credito dell'uccisione segue danno maggiore, con parità all'ultimo colpo.
3. **Struttura Script Sync.** `python3 tests/check_structure.py` deve stampare `STRUCTURE_OK`.
   - Nessun `init.luau` nelle radici sincronizzate.
   - `TestSync.legacy.luau` invariato.
   - I `require` di fratello e i nomi dei Remote usati da `Bind` esistono in `RemoteNames`.
4. **Build 003.** `python3 tests/check_build003.py` deve stampare `BUILD003_OK`.
   - `WorldBuildId` è `world0-build003` e lo schema resta 1.
   - I DataStore del profilo e delle tre classifiche vecchie non cambiano nome. La board monete è aggiunta.
   - `zombie` resta Scavenger con 48 HP e 7 monete. `zombie_corrotto` resta Bonewalker. Rotfang e Grave Chieftain esistono, con mosse distinte.
   - Quattro titoli di classifica, prompt “Talk to Merchant”, pannello Tribal Merchant, niente `MarketplaceService`.
   - Nessuna stringa italiana nei testi tra virgolette dei moduli di gioco.

Per ripetere i punti 2 e 3 servono il binario `luau` e Python 3. Il punto 2 si ottiene togliendo l'ultima riga `return Rules` da `Rules.luau` e appendendo `tests/rules_cases.luau`.

## Non eseguito

- Play in Roblox Studio.
- DataStore reali, OrderedDataStore, avatar dei podi.
- Combattimento, pathfinding, UI su PC o telefono.
- Movimento reale dei nemici, collisione delle capanne, distanza visiva dei cartelli in camera.
- Acquisti Robux. Non vanno provati: non ci sono Product ID.

## Verifica manuale in Studio

Dopo i passi di [SETUP_ROBLOX_STUDIO.md](SETUP_ROBLOX_STUDIO.md):

1. Output: `[Kurkito] Build 003 started. World 0 lobby, Arena 1, automatic combat.` e `[Kurkito] World 0 built (world0-build003).` `TestSync` stampa ancora la riga di collegamento.
2. Il mondo compare una sola volta. Un secondo Play nello stesso server non duplica `KurkitoWorld` se il `BuildId` coincide.
3. Il lobby non è la piazza della Build 002: villaggio a sinistra, tre uova al centro-sud, mercante, viale delle classifiche a destra, arco verso l'Arena 1.
4. I cartelli lontani non si leggono. Avvicinandosi, nomi, prezzi, classifiche e prompt compaiono entro le distanze di `WorldTextConfig`.
5. HUD, menu, mercante, uova e notifiche sono in inglese.
6. “Talk to Merchant” apre Tribal Merchant / Sell Loot. Senza materiali o reliquie il pannello è vuoto. Equip, pozioni e Pet non compaiono in vendita.
7. Coin Egg apre solo l'uovo dell'Arena 1, da vicino. Advanced Coin Egg apre l'arena sbloccata più alta tra 2 e 15, oppure dice di sbloccarne un'altra. Premium Egg non compra nulla.
8. Scegli il Warrior. L'aspetto è tribale, con clava, non con spada. Gli altri due eroi restano sbloccabili dalle missioni.
9. Entra nell'Arena 1. I quattro tipi (tre zombie e il boss) sono presenti. Il cerchio di aggro è sottile. I comportamenti non sono identici: salto, colpo pesante, raffica, e mosse del boss.
10. XP, monete, Mastery, Rebirth, Pet e salvataggio seguono ancora le regole della Build 001. Un Pet `zombie` già salvato resta valido.
