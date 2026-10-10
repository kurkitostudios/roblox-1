# Stato — Build 001

Valori di danno, costi, curva XP, drop e bonus Pet sono **provvisori** e centralizzati in `shared/Shared/`. Le mesh sono parti Roblox generate da `WorldBuilder`, non asset artistici definitivi.

Nessun playtest in Roblox Studio è stato eseguito in questa consegna. Lo stato “funzionante” qui significa: implementato, con regole coperte dai test statici dove indicato in [TESTING.md](TESTING.md).

## Completo nel codice

- Bootstrap server (`Main.server.luau`) e client (`ClientBootstrap.local.luau`). `TestSync.legacy.luau` è conservato.
- Configurazioni condivise: gioco, eroi, abilità, arene, nemici, loot, pozioni, Pet, missioni, remoti, layout del mondo.
- Regole pure in `Rules.luau`: XP, monete, statistiche, eroi, Rebirth, drop, pozioni, fusione, missioni.
- Dati giocatore: schema versione 1, default, sanitizer, session lock, retry, autosave, salvataggio in uscita e alla chiusura, niente sovrascrittura se il caricamento fallisce. In Studio, store separati; se le API sono spente, sessione solo in memoria.
- Tre classi (Guerriero, Mago, Arciere) con statistiche, Maestria 0–50, +1 Skill Point per livello, scelta iniziale unica, cambio dalla lobby, progressi indipendenti, monete condivise.
- Due missioni di uccisioni che sbloccano gli eroi successivi. Lo sblocco resta dopo il Rebirth.
- Potenziamenti statistiche e spesa Skill Point su talenti e abilità, con costi progressivi.
- Mondo 1 idempotente: lobby, 15 arene chiuse con pad sicuro, percorso, zona uova a tre terrazze, tre classifiche con 9 podi, zone eroi / upgrade / fusione / Rebirth, portale Mondo 2 spento.
- Nemici stilizzati, stati Idle / Aggro / Chasing / Attacking / Returning / Dead / Respawning, cerchio di aggro, guinzaglio di 5 secondi, respawn con modello nuovo.
- Combattimento automatico server-side, abilità a cooldown, mana del Mago, credito uccisione configurabile senza doppia ricompensa. L'aggro richiede l'arena sbloccata dall'eroe attivo.
- Sblocco arene per eroe (Maestria + monete). Teleport verificato dal server. Il Rebirth riblocca solo le arene di quell'eroe.
- Economia atomica sul server.
- Rebirth in due passi (prepara, conferma), un'operazione alla volta, solo all'altare, +10% XP e +10% monete cumulativi per quell'eroe.
- Inventario condiviso: equipaggiamenti (con classe e `boundHero`), materiali, pozioni, collezionabili, Pet. I charm senza `boundHero` restano al Rebirth.
- Pozioni: rigenerazione, danno ×2, fortuna ×2, durate 30/120/300/600/1200. Stessa famiglia: la nuova sostituisce la precedente.
- Pet: massimo 3 equipaggiati, 15 uova monete (pool = mostri di quell'arena, arena sbloccata), fusione 5:1 fino a Void.
- Vetrine uova Robux con probabilità visibili, `productId = nil`, `enabled = false`. Nessun `MarketplaceService`.
- Classifiche OrderedDataStore (somma Rebirth, tempo, uccisioni) con aggiornamento periodico e pupazzi di fallback sui podi.
- UI generata da LocalScript: HUD, scelta eroe, menu eroi, upgrade, inventario, Pet, fusione, pozioni, Rebirth, arene, missioni, uova, notifiche.
- Rate limit, validazione payload, prossimità, lock su Rebirth e fusione.

## Parziale

- **Aspetto eroi.** Spada, armatura, cappello, arco e scie cambiano con i livelli, ma sono parti prototipo. I nemici non si voltano verso il bersaglio: restano in piedi con `AlignOrientation`.
- **Podi.** Etichette e modelli ci sono. L'avatar reale dipende da `GetHumanoidDescriptionFromUserId`; se fallisce resta un blocco. Lo snapshot estetico è un DataStore separato.
- **Classifiche.** Il codice c'è. Senza API Studio o senza giocatori restano vuote. Non vanno interrogate a ogni frame.
- **Movimento nemici.** `Humanoid:MoveTo` in campo aperto. Non c'è pathfinding intorno ai muri. L'ingresso alle arene è un teletrasporto, non un varco camminabile.
- **Bilanciamento.** Tutti i numeri sono provvisori.
- **Materiali.** Si accumulano. Non esiste una forgia.
- **UI.** Pensata per mouse e touch (`Activated`, altezza minima 44). Non è stata verificata su un dispositivo.

## Non implementato

- Mondo 2 giocabile. Il portale avvisa che è spento.
- Acquisti Robux e Product ID.
- Forgia, crafting, animazioni custom, asset 3D definitivi.
- Verifica runtime in Roblox Studio.

## Regole da non perdere

- Monete, Pet, materiali, pozioni e collezionabili sono dell'account. Maestria, statistiche, Skill Point, arene e Rebirth sono dell'eroe.
- Il bonus Rebirth si applica solo alle ricompense dell'eroe attivo. Le monete delle missioni sono fisse.
- `boundHero == nil` non viene cancellato al Rebirth. `boundHero == classe` sì, solo per l'eroe rinato.
- L'accesso alle uova normali deriva dalle arene sbloccate, non da un flag separato.
- Un drop con probabilità base 1 non viene abbassato dal tetto fortuna. Il tetto limita solo le probabilità inferiori a 1.
