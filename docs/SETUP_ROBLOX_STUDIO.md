# Setup in Roblox Studio — Build 003

Questo progetto si sincronizza con **Roblox Studio Script Sync**. Non usare Rojo, non installare Wally e non aggiungere un file di progetto Rojo.

Script Sync copia solo `Script`, `LocalScript`, `ModuleScript` e `Folder`. Le parti della mappa non stanno nel repository: le crea a runtime `WorldBuilder`.

## 1. Cartelle già sincronizzate

È già collegata:

| Nel repository | In Roblox Studio |
| --- | --- |
| `server/GameServer/` | `ServerScriptService/GameServer` |

Dentro c'è ancora `TestSync.legacy.luau`. Non eliminarlo e non staccare questo collegamento.

## 2. Cartelle da creare a mano in Studio

Crearle prima di avviare Play. I nomi devono essere esatti.

1. In `ReplicatedStorage`, crea un `Folder` chiamato `Shared`.
2. In `StarterPlayer/StarterPlayerScripts`, crea un `Folder` chiamato `GameClient`.

Non creare gli script a mano uno per uno. Script Sync li genera dai file.

## 3. Percorsi Script Sync

Per ogni cartella nuova:

1. Selezionala nell'Explorer.
2. Tasto destro → **Sync to…**
3. Scegli la cartella del clone Git, poi conferma.

| Istanza in Studio | Cartella sul disco |
| --- | --- |
| `ReplicatedStorage/Shared` | `<clone>/shared/Shared` |
| `StarterPlayer/StarterPlayerScripts/GameClient` | `<clone>/client/GameClient` |
| `ServerScriptService/GameServer` | `<clone>/server/GameServer` (già fatto) |

`<clone>` è la cartella locale del repository `kurkitostudios/roblox-1`, la stessa aperta in GitHub Desktop.

Estensioni usate da Script Sync:

| File | Istanza |
| --- | --- |
| `Nome.luau` | ModuleScript |
| `Nome.server.luau` | Script con RunContext Server |
| `Nome.local.luau` | LocalScript |
| `Nome.legacy.luau` | Script con RunContext Legacy |
| cartella | Folder |

Non aggiungere `init.luau` nelle tre radici sincronizzate: trasformerebbe la cartella in uno script.

Se Studio mostra un conflitto tra disco e place, leggi l'elenco. Per ricevere questa build scegli la versione **su disco** solo dopo aver verificato che non stai buttando via script scritti soltanto in Studio. `TestSync` deve restare.

`ReplicatedStorage.KurkitoRemotes` non va creato a mano: lo crea il server all'avvio.

## 4. Aggiornare da GitHub Desktop

1. Apri il repository in GitHub Desktop.
2. Controlla di essere su `main`.
3. **Fetch origin**, poi **Pull origin**.
4. Se ci sono modifiche locali non committate, non scartarle alla cieca: risolvi il conflitto prima del pull.
5. Torna in Studio con il place aperto. Se Script Sync era fermo, tasto destro sulla cartella → **Script Sync** e riprendi. Se compare il dialogo di conflitto all'apertura, applica la scelta del punto 3.
6. Controlla che nell'Explorer esistano `Main` sotto `GameServer`, `ClientBootstrap` sotto `GameClient` e i ModuleScript in `Shared`.

## 5. Avviare Play

1. Salva il place.
2. Premi **Play**.
3. La mappa viene costruita da sola. Lo spawn neutrale è la lobby.
4. La prima schermata chiede l'eroe gratuito. La scelta non si può rifare.
5. Arena 1 è a nord ed è gratuita. Il cerchio rosso è l'aggro: entrando, il combattimento parte da solo.
6. I menu in basso (Eroi, Potenziamenti, Inventario, Pet, Fusione, Pozioni, Rebirth, Arene, Missioni, Uova) eseguono azioni reali. Il portale del Mondo 2 e le uova Robux spiegano di essere non attivi.

In Studio, con le API DataStore spente, la partita resta in memoria e un avviso lo dice. Per provare il salvataggio segui il punto 6.

Comandi disponibili **solo** in Studio, nella chat:

- `/coins 1000`
- `/mastery 50`
- `/xp 100`
- `/pet zombie`
- `/potion health_common`
- `/kills 10`

## 6. Salvataggi, senza toccare la produzione

I nomi sono diversi di proposito. Studio usa `RunService:IsStudio()`.

| Dato | Studio | Pubblicato |
| --- | --- | --- |
| Profilo | `Kurkito_Studio_Player_v1` | `Kurkito_Player_v1` |
| Rebirth | `Kurkito_Studio_LB_Rebirth_v1` | `Kurkito_LB_Rebirth_v1` |
| Tempo | `Kurkito_Studio_LB_Time_v1` | `Kurkito_LB_Time_v1` |
| Uccisioni | `Kurkito_Studio_LB_Kills_v1` | `Kurkito_LB_Kills_v1` |
| Monete | `Kurkito_Studio_LB_Coins_v1` | `Kurkito_LB_Coins_v1` |
| Aspetto podio | `Kurkito_Studio_Public_v1` | `Kurkito_Public_v1` |

Per provare il salvataggio in Studio:

1. Home → **Game Settings** → **Security** → abilita **Enable Studio Access to API Services**.
2. Premi Play, cambia qualcosa (monete, eroe, un upgrade).
3. Ferma e riavvia Play con lo stesso utente di Studio.
4. Se il dato c'è ancora, il DataStore di Studio ha funzionato.

Questo non scrive `Kurkito_Player_v1`. Non pubblicare il place su un'esperienza già usata dai giocatori solo per “provare”: fuori da Studio il gioco usa gli store di produzione.

Se il caricamento fallisce in un server pubblicato, il gioco **non** sostituisce il profilo con uno vuoto. Il giocatore vede l'errore e non progredisce.

Un profilo nuovo in Studio parte con 500 monete di test. In produzione parte da 0.

## 7. Errori nell'Output

1. In Studio apri **View → Output**.
2. Cerca le righe `[Kurkito]`.
3. Errori attesi se manca un collegamento:
   - `Manca ReplicatedStorage.Shared`
   - `Remote non creati` sul client
4. Un traceback con `Shared` o `attempt to index nil` subito dopo Play di solito significa che `Shared` o `GameClient` non sono sincronizzati, oppure che uno script ha il tipo sbagliato (per esempio un ModuleScript invece di un LocalScript). Controlla le estensioni della tabella sopra.
5. `DataStore` / `StudioAccessToApisNotAllowed` senza API Services è previsto: la sessione di Studio continua in memoria.
6. `TestSync` stampa ancora `Cursor Cloud e Roblox Studio collegati!`. Quella riga non indica che il gioco sia pronto: indica solo che il vecchio collegamento server funziona.
