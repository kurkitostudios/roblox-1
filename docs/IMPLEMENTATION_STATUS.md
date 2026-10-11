# Stato — Build 003.1

Correzione del Mondo 0 sulla Build 003. Non è un gioco nuovo e non rifinisce le arene 2–15.

Valori di danno, costi, curva XP, drop e bonus Pet sono **provvisori** e centralizzati in `shared/Shared/`. Le mesh sono parti Roblox generate da `WorldBuilder`, `TribalKit`, `PropKit`, `CreatureKit` e `HeroAppearance`. Non sono asset importati.

Nessun playtest in Roblox Studio è stato eseguito. “Staticamente validato” significa compilazione Luau, regole pure e controlli di struttura. Non significa fedeltà visiva, FPS o correttezza di runtime.

`WorldBuildId` è `world0-build003-1`. Un server che ha ancora il mondo `world0-build003` lo distrugge e lo ricostruisce. Lo schema del profilo resta versione 1. I nomi dei DataStore non cambiano.

## Completo nel codice

- Un solo eroe giocabile: **Warrior**. `SelectHero` rifiuta ogni altro id. `SwitchHero` restituisce sempre un errore. Mastery, XP, statistiche, Skill Point, Rebirth, loot, equip, uova e combattimento usano il Warrior.
- I nuovi profili nascono Warrior, Mastery 0, `firstHeroChosen = true`. Non c'è una schermata di scelta classe. Può comparire una scheda introduttiva del Warrior, senza pulsanti Mage o Archer.
- `Rules.ReconcileWorld0` gira a ogni caricamento. Se l'eroe attivo archiviato è Mage o Archer, il puntatore passa a Warrior. La Maestria, gli upgrade e i Rebirth archiviati restano nelle loro tabelle e non vengono copiati. Portafoglio, Pet, collezionabili, materiali e missioni non si cancellano. Se `lifetimeCoinsEarned` manca, diventa 0: non si inventa lo storico dal saldo.
- Mage e Archer restano nello schema (`HeroConfig.Order`) solo per leggere i salvataggi vecchi. Non hanno menu, modelli visibili, animazioni attive né abilità invocabili.
- Le missioni `prova_del_ferro` e `cacciatore` non sbloccano altri eroi. I nomi visibili restano First Hunt e Hunter.
- Guerriero procedurale: pelle, pelliccia, osso, pittura, spalle, cintura, fasce, calzari e clava di legno con testa di pietra. Niente spada sul modello attivo. HP, DMG e Speed cambiano ossa, clava e fasce di movimento secondo `Rules.VisualTier`.
- Animazioni procedurali del rig (`Motor6D.Transform`): idle, walk, run, combat-ready, attack 1, attack 2, smash, heavy sweep, hide guard, primal fury, danno, stun, vittoria, morte, spawn. Il server non muove il personaggio con queste pose.
- Arena 1: Scavenger, Bonewalker, Rotfang e Grave Chieftain, con mosse, intervalli, portate e danni diversi. Il server decide il colpo. Gli id `zombie` e `zombie_corrotto` tengono HP, danno, XP e monete precedenti.
- Summon Dead crea fino a 2 Risen Dead per cast e 3 vivi. Non sono nel piano di spawn né nei Pet. XP e monete 0, e `Kill` non chiama `GrantRewards`. Si distruggono se il boss muore o torna al guinzaglio.
- Tre uova fisse del Mondo 0. Coin Egg 250 monete (provvisorio): zombie 70, zombie_corrotto 22, rotfang 8. Advanced Coin Egg 900 monete (provvisorio): zombie_corrotto 45, rotfang 40, grave_chieftain 15. Non segue l'arena sbloccata. Premium Egg (`egg_robux_1`) ha `productId = nil` e `enabled = false`. Le uova delle arene future restano in config e `OpenArena` le rifiuta.
- Mercante: skin, bancarella, prompt “Talk to Merchant”, pannello “Tribal Merchant”. `TradingEnabled = false`, tariffe vuote, massimo 0. `SellLoot` risponde “Trading will be available soon.” e non toglie oggetti né dà monete.
- Quattro classifiche: uccisioni, Rebirth del Warrior, tempo, monete vita (`lifetimeCoinsEarned`). La spesa e i rimborsi non riducono il totale vita. Il saldo iniziale di Studio (500) e `/coins` usano `AddCoins`, non il totale vita. I combattimenti e le missioni usano `GrantEarnedCoins`.
- La board Rebirth resta `Kurkito_LB_Rebirth_v1`. Il prossimo `SetAsync` di un giocatore sostituisce la vecchia somma delle tre classi con i Rebirth del Warrior. Chi non rientra tiene il valore vecchio finché non viene riscritto. Non si rinomina lo store e non si inventano punteggi.
- Lobby: villaggio a ovest, uova a sud, quattro muri e dodici podi a est, strada verso l'Arena 1 a nord. Il builder è idempotente sul `BuildId`.
- Le arene 2–15 restano in config e nei salvataggi. Non vengono costruite né popolate. Sblocco e teletrasporto verso di loro rispondono che non sono disponibili, senza cancellare `unlockedArenas`. Il portale del Mondo 2 resta spento.
- Testi giocatore in inglese. I cartelli 3D usano `WorldTextConfig` e si aggiornano circa ogni 0,3 secondi.

## Parziale

- **Aspetto.** Geometria procedurale ispirata ai fogli approvati. Non è una mesh esterna e non è stata vista in Studio.
- **Animazioni.** Pose locali sul rig. Non sono clip importate. Il peso del movimento e l'assenza di glitch di rotazione vanno visti in Play.
- **Mercante.** La logica di catalogo resta dietro `TradingEnabled`. Spento, il pannello non ha pulsanti di vendita.
- **Podi.** L'avatar reale dipende da `GetHumanoidDescriptionFromUserId`. Altrimenti resta il manichino.
- **Classifiche.** Senza API o senza giocatori restano vuote.
- **Bilanciamento.** Prezzi uova, Rotfang, boss e Risen Dead sono provvisori. I due zombie già presenti no.
- **Arene 2–15.** Configurazione compatibile, stanze non costruite.

## Non implementato

- Mondo 2 giocabile.
- Acquisti Robux e Product ID.
- Catalogo finale del mercante e prezzi approvati.
- Rifinitura visiva delle arene 2–15.
- Verifica runtime in Roblox Studio.

## Migrazioni

- `ReconcileWorld0` è idempotente. Non assegna Rebirth e non copia upgrade tra classi.
- `lifetimeCoinsEarned` assente diventa 0. Non si ricostruisce dal portafoglio.
- La board Rebirth viene sovrascritta al prossimo push con i soli Rebirth del Warrior.
- La board monete è `Kurkito_LB_Coins_v1` / `Kurkito_Studio_LB_Coins_v1` e riceve il totale vita, non il saldo.

## Regole da non perdere

- Monete, Pet, materiali, pozioni e collezionabili sono dell'account. Maestria, statistiche, Skill Point, arene e Rebirth attivi sono del Warrior.
- I dati Mage e Archer restano nel profilo e non sono giocabili.
- Il bonus Rebirth sulle ricompense usa i Rebirth del Warrior.
- `boundHero == nil` non viene cancellato al Rebirth. `boundHero == "Warrior"` sì, solo per il Warrior.
- Un drop con probabilità base 1 non viene abbassato dal tetto fortuna.
- Gli id `zombie` e `zombie_corrotto` restano validi nei salvataggi e nei Pet.
