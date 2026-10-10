# Test — Build 001

Questa macchina non ha Roblox Studio. I controlli sotto sono statici o eseguono solo la logica pura. Non sono un playtest.

## Controlli eseguiti qui

1. **Sintassi Luau.** Ogni file `.luau` del repository è stato compilato ed eseguito con il CLI Luau. Nessun errore di sintassi. I moduli che usano `game`, `script`, `Color3` o `Vector3` si fermano a runtime su quei globali, come previsto fuori da Studio.
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
3. **Caricamento dei moduli condivisi.** I 14 moduli di `shared/Shared/` sono stati caricati in un ambiente finto (`Color3`, `Vector3`, `require`). Atteso: `SHARED_OK`. Controlla 15 arene, Arena 15 a Maestria 48, 30 nemici, 15 uova monete, 3 uova Robux disattivate e senza Product ID, il pool dell'uovo 8, 15 pozioni, il profilo iniziale e le posizioni della lobby.
4. **Struttura Script Sync.** `python3 tests/check_structure.py` deve stampare `STRUCTURE_OK`.
   - Nessun `init.luau` nelle radici sincronizzate.
   - `TestSync.legacy.luau` invariato.
   - I `require` di fratello e i nomi dei Remote usati da `Bind` esistono in `RemoteNames`.

Per ripetere i punti 2 e 4 servono il binario `luau` e Python 3. Il punto 2 si ottiene togliendo l'ultima riga `return Rules` da `Rules.luau` e appendendo `tests/rules_cases.luau`.

## Non eseguito

- Play in Roblox Studio.
- DataStore reali, OrderedDataStore, avatar dei podi.
- Combattimento, pathfinding, UI su PC o telefono.
- Acquisti Robux. Non vanno provati: non ci sono Product ID.

## Verifica manuale in Studio

Dopo i passi di [SETUP_ROBLOX_STUDIO.md](SETUP_ROBLOX_STUDIO.md):

1. Output: `[Kurkito] Build 001 avviata` e `TestSync` che stampa ancora la riga di collegamento.
2. La mappa compare una sola volta. Un secondo Play nello stesso server non duplica `KurkitoWorld` se il `BuildId` coincide.
3. Scegli un eroe. La schermata non si ripresenta. Gli altri due restano bloccati.
4. Entra nell'Arena 1. Entra nel cerchio rosso: il nemico insegue e l'eroe attacca da solo. Allontanandolo oltre il guinzaglio, dopo 5 secondi torna allo spawn e non si fa trascinare.
5. XP, monete e Maestria salgono. Le monete sono le stesse se cambi eroe. La Maestria no.
6. Uccidi 10 nemici: la missione sblocca il secondo eroe. Il cambio funziona dalla lobby.
7. Arena 2 rifiuta l'ingresso senza Maestria 5 e senza le monete. Dopo l'acquisto l'altro eroe non ce l'ha.
8. A Maestria 50, all'altare, Prepara e poi Conferma il Rebirth. Si azzerano Maestria, statistiche, punti, arene e l'equipaggiamento di quell'eroe. Restano monete, Pet, materiali, pozioni, collezionabili e gli altri eroi.
9. Apri un uovo dell'arena sbloccata. Fondi 5 Pet identici non equipaggiati. Una seconda pozione della stessa famiglia sostituisce la prima.
10. Le uova Robux e il portale del Mondo 2 dicono di non essere attivi e non aprono acquisti.
11. Con le API DataStore spente la sessione resta in memoria. Con le API accese, il salvataggio usa solo i nomi `Kurkito_Studio_*`.
