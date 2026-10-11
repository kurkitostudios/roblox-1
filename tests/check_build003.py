#!/usr/bin/env python3
"""Controlli statici della Build 003.1: Warrior unico, uova fisse, mercante spento."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors = []

def read(rel: str) -> str:
    return (ROOT / rel).read_text()

def must(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

game = read("shared/Shared/GameConfig.luau")
must('BuildVersion = "003.1"' in game, "BuildVersion non è 003.1")
must('WorldBuildId = "world0-build003-1"' in game, "WorldBuildId non è world0-build003-1")
must('ProductionStoreName = "Kurkito_Player_v1"' in game, "DataStore giocatore di produzione cambiato")
must('StudioStoreName = "Kurkito_Studio_Player_v1"' in game, "DataStore Studio cambiato")
must('Rebirth = "Kurkito_LB_Rebirth_v1"' in game, "Board Rebirth cambiata")
must('Time = "Kurkito_LB_Time_v1"' in game, "Board Time cambiata")
must('Kills = "Kurkito_LB_Kills_v1"' in game, "Board Kills cambiata")
must('Coins = "Kurkito_LB_Coins_v1"' in game, "Manca la board Coins di produzione")
must('Coins = "Kurkito_Studio_LB_Coins_v1"' in game, "Manca la board Coins di Studio")

profile = read("shared/Shared/ProfileTemplate.luau")
must("SchemaVersion = 1" in profile, "schemaVersion non è 1")

enemies = read("shared/Shared/EnemyConfig.luau")
must('id = "zombie", name = "Scavenger Zombie"' in enemies and "hp = 48" in enemies and "coins = 7" in enemies and 'behavior = "scavenger"' in enemies, "Scavenger Zombie alterato")
must('id = "zombie_corrotto", name = "Bonewalker Zombie"' in enemies and "hp = 78" in enemies and "coins = 11" in enemies and "range = 5" in enemies and 'behavior = "bonewalker"' in enemies, "Bonewalker alterato")
must('id = "rotfang", name = "Rotfang Zombie"' in enemies and 'behavior = "rotfang"' in enemies, "Manca Rotfang")
must('id = "grave_chieftain", name = "Grave Chieftain"' in enemies and 'rarity = "Boss"' in enemies and 'behavior = "chieftain"' in enemies, "Manca Grave Chieftain")
must("MaxActive = 3" in enemies and "PerCast = 2" in enemies, "Il tetto dei minion non è 3/2")
risen_at = enemies.find('id = "risen_dead"')
spawn_at = enemies.find("function EnemyConfig.SpawnPlan")
must(risen_at > spawn_at > 0, "Risen Dead entra nello spawn plan o nel pool pet")

layout = read("shared/Shared/WorldLayout.luau")
for title in ("MOST KILLS", "MOST REBIRTHS", "MOST TIME PLAYED", "MOST COINS"):
    must(title in layout, f"Manca la classifica {title}")
must("ArenaSize = 150" in layout and "FirstArenaZ = 430" in layout and "ArenaSpacing = 210" in layout, "Geometria arene spostata")

strings = read("shared/Shared/Strings.luau")
for phrase in (
    'MerchantTitle = "Tribal Merchant"',
    'MerchantSell = "Sell Loot"',
    'SellOne = "Sell 1"',
):
    must(phrase in strings, f"Manca la stringa {phrase}")
must("Talk to Merchant" in read("server/GameServer/Services/WorldBuilder.luau"), "Manca il prompt Talk to Merchant")

world_body = read("server/GameServer/Services/WorldBuilder.luau")
must("buildGraveWilds" in world_body and "buildVillage" in world_body and "buildMerchant" in world_body and "buildFeaturedEggs" in world_body and "buildBoards" in world_body, "Il world builder non ricostruisce lobby e Arena 1")
must('existing:GetAttribute("BuildId")' in world_body and "existing:Destroy()" in world_body, "Il world builder non è idempotente")

enemy_service = read("server/GameServer/Services/EnemyService.luau")
for move in ("swipe", "leap", "bash", "smash", "claw", "recover", "roar", "slam", "summon", "charge"):
    must(f'"{move}"' in enemy_service, f"Mossa nemico assente: {move}")

hero = read("server/GameServer/Services/HeroAppearance.luau")
must('heroId == "Warrior"' in hero and '"Club"' in hero, "Il guerriero non usa la clava")
for path in ROOT.rglob("*.luau"):
    for line in path.read_text().splitlines():
        code = line.split("--", 1)[0]
        if "MarketplaceService" in code:
            errors.append(f"MarketplaceService usato in {path.relative_to(ROOT)}")

remote = read("shared/Shared/RemoteNames.luau")
must('"SellLoot"' in remote and '"OpenMerchant"' in remote, "Remote del mercante assenti")

text = read("shared/Shared/WorldTextConfig.luau")
must("Merchant = 22" in text and "EnemyName = 36" in text and "Podium = 26" in text, "Distanze testi 3D incomplete")

rules = read("shared/Shared/Rules.luau")
must('return false, "World 0 has one hero: the Warrior."' in rules, "SwitchHero può ancora cambiare classe")
must("function Rules.ReconcileWorld0" in rules and "function Rules.WarriorRebirths" in rules and "function Rules.GrantEarnedCoins" in rules and "function Rules.SummonRoom" in rules, "Mancano le regole della correzione")

profile_full = read("shared/Shared/ProfileTemplate.luau")
must("lifetimeCoinsEarned = 0" in profile_full and 'selectedHero = "Warrior"' in profile_full and "firstHeroChosen = true" in profile_full, "Il profilo nuovo non nasce Warrior")

pets = read("shared/Shared/PetConfig.luau")
must('id = "world0_coin"' in pets and "cost = 250" in pets and 'id = "world0_advanced"' in pets and "cost = 900" in pets, "Le uova del Mondo 0 non sono fisse")
must("productId = nil" in pets and "enabled = false" in pets, "Il Premium Egg è acquistabile")

merchant = read("shared/Shared/MerchantConfig.luau")
must("TradingEnabled = false" in merchant and "Rates = {}" in merchant and "MaxPerSale = 0" in merchant, "La vendita del mercante è attiva")

sanitizer = read("server/GameServer/Services/ProfileSanitizer.luau")
must("Rules.ReconcileWorld0(profile)" in sanitizer, "Il sanitizer non riconcilia il Warrior")

eggs = read("server/GameServer/Services/EggService.luau")
must("function EggService.OpenArena" in eggs and "WorldEggOnly" in eggs and 'key ~= "coin" and key ~= "advanced"' in eggs, "Le uova di arena si aprono ancora")

merchant_service = read("server/GameServer/Services/MerchantService.luau")
must("TradingEnabled ~= true" in merchant_service and "TradingSoon" in merchant_service, "SellLoot può pagare a catalogo spento")

leaderboard = read("server/GameServer/Services/LeaderboardService.luau")
must("WarriorRebirths" in leaderboard and "lifetimeCoinsEarned" in leaderboard, "Le classifiche non usano Warrior e monete vita")

enemy_service = read("server/GameServer/Services/EnemyService.luau")
must("noReward" in enemy_service and "SummonDead" in enemy_service and "DismissSummons" in enemy_service, "Il summon del boss non è reale")
must("for arenaIndex = 1, 1" in enemy_service, "Gli spawn delle arene 2–15 sono attivi")

world = read("server/GameServer/Services/WorldBuilder.luau")
must("if arena.index == 1 then" in world, "Il builder costruisce le arene 2–15")

hero_service = read("server/GameServer/Services/HeroService.luau")
must('heroId ~= "Warrior"' in hero_service, "SelectHero accetta altre classi")

main = read("server/GameServer/Main.server.luau")
must("MerchantService" in main and "Build 003.1 started" in main, "Bootstrap Build 003.1 incompleto")

client = read("client/GameClient/ClientBootstrap.local.luau")
must("Merchant.Open" in client and "OpenMerchant" in client, "Il client non apre il mercante")

italian = re.compile(r'"(?:[^"\\\n]|\\.)*(?:Scegli|Apri |Chiudi|Monete|Uccisioni|Rinascita|Maestria|Benvenuto|Avvicinati|Nessun |Vendita |Uovo )')
for path in list((ROOT / "shared").rglob("*.luau")) + list((ROOT / "client").rglob("*.luau")) + list((ROOT / "server").rglob("*.luau")):
    for match in italian.finditer(path.read_text()):
        errors.append(f"Testo italiano visibile in {path.relative_to(ROOT)}: {match.group(0)[:80]}")

if errors:
    print("BUILD003_FAIL")
    for error in errors:
        print(" -", error)
    sys.exit(1)

print("BUILD003_OK")
