# Test — Build 002

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
3. **Moduli condivisi.** `python3 tests/check_structure.py` stampa anche il numero di moduli in `shared/Shared/`. La Build 002 aggiunge `Strings`, `WorldTextConfig` e `PropKit`. Non esiste più un harness che carichi i moduli in un ambiente finto: quel controllo non è nel repository.
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

1. Output: `[Kurkito] Build 002 started. World 1, 15 arenas, automatic combat.` e `TestSync` che stampa ancora la riga di collegamento.
2. I cartelli di un'arena lontana non si leggono. Avvicinandosi, nomi, prezzi e prompt compaiono entro le distanze di `WorldTextConfig`.
3. HUD, menu e notifiche sono in inglese. La UI permanente resta visibile anche da lontano.
4. La mappa compare una sola volta. Un secondo Play nello stesso server non duplica `KurkitoWorld` se il `BuildId` coincide (`world1-build002`).
5. Scegli un eroe. La schermata non si ripresenta. Gli altri due restano bloccati. L'aspetto cambia con gli upgrade e con il cambio eroe.
6. Entra nell'Arena 1. Entra nel cerchio rosso: il nemico insegue e l'eroe attacca da solo. Allontanandolo oltre il guinzaglio, dopo 5 secondi torna allo spawn e non si fa trascinare.
7. XP, monete e Mastery salgono. Le monete sono le stesse se cambi eroe. La Mastery no.
8. Uccidi 10 nemici: la missione sblocca il secondo eroe. Il cambio funziona dalla lobby.
9. Arena 2 rifiuta l'ingresso senza Mastery 5 e senza le monete. Dopo l'acquisto l'altro eroe non ce l'ha.
10. A Mastery 50, all'altare, Prepara e poi Conferma il Rebirth. Si azzerano Mastery, statistiche, punti, arene e l'equipaggiamento di quell'eroe. Restano monete, Pet, materiali, pozioni, collezionabili e gli altri eroi.
11. Apri un uovo dell'arena sbloccata. Fondi 5 Pet identici non equipaggiati. Una seconda pozione della stessa famiglia sostituisce la prima.
12. Le uova Robux e il portale del Mondo 2 dicono di non essere attivi e non aprono acquisti.
13. Con le API DataStore spente la sessione resta in memoria. Con le API accese, il salvataggio usa solo i nomi `Kurkito_Studio_*`.
