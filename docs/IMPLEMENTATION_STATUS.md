# Stato — Build 003

Valori di danno, costi, curva XP, drop e bonus Pet sono **provvisori** e centralizzati in `shared/Shared/`. Le mesh sono parti Roblox generate da `WorldBuilder`, `TribalKit`, `PropKit`, `CreatureKit` e `HeroAppearance`. Non sono asset importati.

Nessun playtest in Roblox Studio è stato eseguito in questa consegna. Lo stato “funzionante” qui significa: implementato, con regole coperte dai test statici dove indicato in [TESTING.md](TESTING.md).

`WorldBuildId` è `world0-build003`. Se un server ha ancora il mondo della Build 002, il builder lo distrugge e lo ricostruisce. Lo schema del profilo resta versione 1. I DataStore del profilo e delle classifiche esistenti non cambiano nome. La classifica monete è uno store nuovo: `Kurkito_LB_Coins_v1` in produzione e `Kurkito_Studio_LB_Coins_v1` in Studio.

## Completo nel codice

- Bootstrap server (`Main.server.luau`) e client (`ClientBootstrap.local.luau`). `TestSync.legacy.luau` è conservato.
- Configurazioni condivise: gioco, eroi, abilità, arene, nemici, loot, pozioni, Pet, missioni, remoti, layout del mondo, mercante.
- Regole pure in `Rules.luau`: XP, monete, statistiche, eroi, Rebirth, drop, pozioni, fusione, missioni.
- Dati giocatore: schema versione 1, default, sanitizer, session lock, retry, autosave, salvataggio in uscita e alla chiusura, niente sovrascrittura se il caricamento fallisce. In Studio, store separati; se le API sono spente, sessione solo in memoria.
- Tre classi restano nel codice (`Warrior`, `Mage`, `Archer`) per compatibilità. Il Mondo 0 presenta il Warrior preistorico con clava. La scelta iniziale resta unica. La Maestria non si sposta tra eroi. Le monete restano dell'account.
- Due missioni di uccisioni che sbloccano gli eroi successivi. Lo sblocco resta dopo il Rebirth. Il nome visibile della prima missione è “First Hunt”; l'id resta `prova_del_ferro`.
- Potenziamenti statistiche e spesa Skill Point su talenti e abilità, con costi progressivi. Gli id delle abilità del Warrior non cambiano. I nomi visibili sono Heavy Sweep, Hide Guard e Primal Fury.
- Mondo 0 idempotente. Il lobby è un rettangolo lungo: villaggio a ovest, tre uova a sud, mercante davanti al villaggio, viale di quattro classifiche a est, percorso verso l'Arena 1 a nord. Le arene 2–15 restano sul percorso e usano ancora le stanze chiuse della build precedente.
- Arena 1, “Grave Wilds”: terreno, rocce, scogliere, resti, ossa, alberi morti. Il centro resta libero per i nemici. L'ingresso di gioco resta il teletrasporto.
- Quattro nemici dell'Arena 1 con comportamenti diversi: Scavenger (`zombie`), Bonewalker (`zombie_corrotto`), Rotfang (`rotfang`), Grave Chieftain (`grave_chieftain`). HP, danno, XP e monete dei due id vecchi non cambiano. I Pet nascono ancora dagli id dei mostri.
- Combattimento automatico server-side. Le mosse dei nemici dell'Arena 1 sono scelte dal server. Le arene 2–15 senza `behavior` restano sul colpo singolo. Abilità, credito uccisione e guinzaglio restano quelli della Build 001.
- Sblocco arene per eroe. Teleport verificato dal server. Il Rebirth riblocca solo le arene di quell'eroe.
- Economia atomica sul server. Il mercante vende solo materiali e collezionabili, con tariffe provvisorie in `MerchantConfig`. Non tocca Pet, equipaggiamento o pozioni. Nessun `MarketplaceService`.
- Rebirth in due passi, solo all'altare.
- Inventario condiviso invariato nelle categorie.
- Pet: massimo 3 equipaggiati, uova monete, fusione 5:1, Pet persistenti dopo il Rebirth. Tre piedistalli fisici: Coin Egg (arena 1), Advanced Coin Egg (arena sbloccata più alta tra 2 e 15), Premium Egg (vetrina, `productId = nil`, `enabled = false`).
- Quattro classifiche OrderedDataStore (uccisioni, Rebirth, tempo, monete), ognuna con podio da tre figure. Se l'avatar reale non arriva, resta un manichino tribale.
- UI inglese generata da LocalScript, più il pannello Tribal Merchant / Sell Loot aperto dal prompt.
- Testi 3D solo da vicino, tramite `WorldTextConfig`.
- Rate limit, validazione payload, prossimità.

## Parziale

- **Aspetto.** Guerriero, zombie dell'Arena 1, villaggio, mercante, uova e viale sono geometria procedurale ispirata ai fogli approvati. Non sono mesh esterne. Le arene 2–15 non sono state ridisegnate.
- **Animazioni.** Procedurali sul client (`Motor6D.Transform`). Il server pubblica `GetServerTimeNow()` su colpo, danno e vittoria. Non ci sono animazioni importate.
- **Mercante.** Struttura e vendita provvisoria. Non è l'economia finale.
- **Summon del boss.** È solo un effetto visivo. Non crea nemici extra.
- **Podi.** L'avatar reale dipende da `GetHumanoidDescriptionFromUserId`.
- **Classifiche.** Senza API Studio o senza giocatori restano vuote, con i manichini.
- **Bilanciamento.** I numeri nuovi di Rotfang e del boss sono provvisori. I numeri dei due zombie già presenti no.
- **UI.** Pensata per mouse e touch. Non è stata verificata su un dispositivo.

## Non implementato

- Mondo 2 giocabile. Il portale avvisa che è spento.
- Acquisti Robux e Product ID.
- Forgia, crafting, mesh esterne, rifinitura visiva delle arene 2–15.
- Verifica runtime in Roblox Studio.

## Regole da non perdere

- Monete, Pet, materiali, pozioni e collezionabili sono dell'account. Maestria, statistiche, Skill Point, arene e Rebirth sono dell'eroe.
- Il bonus Rebirth si applica solo alle ricompense dell'eroe attivo. La vendita al mercante non applica quel bonus.
- `boundHero == nil` non viene cancellato al Rebirth. `boundHero == classe` sì, solo per l'eroe rinato.
- L'accesso alle uova normali deriva dalle arene sbloccate, non da un flag separato.
- Un drop con probabilità base 1 non viene abbassato dal tetto fortuna. Il tetto limita solo le probabilità inferiori a 1.
- Gli id `zombie` e `zombie_corrotto` restano validi nei salvataggi e nei Pet.
