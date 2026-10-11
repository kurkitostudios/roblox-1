#!/usr/bin/env python3
"""Build 003.2: il costume del Warrior è procedurale, sul giocatore, senza toccare il mondo."""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors = []


def read(rel: str) -> str:
    return (ROOT / rel).read_text()


def must(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


builder = read("server/GameServer/Services/WarriorVisualBuilder.luau")
palette = read("server/GameServer/Services/WarriorPalette.luau")
preview = read("server/GameServer/Services/WarriorPreview.luau")
appearance = read("server/GameServer/Services/HeroAppearance.luau")
hero_service = read("server/GameServer/Services/HeroService.luau")
commands = read("server/GameServer/Services/StudioCommands.luau")
main = read("server/GameServer/Main.server.luau")
game = read("shared/Shared/GameConfig.luau")
motion = read("client/GameClient/Motion.luau")

must('BuildVersion = "003.1"' in game, "BuildVersion è stato cambiato")
must('WorldBuildId = "world0-build003-1"' in game, "WorldBuildId è stato cambiato")
must("Build 003.1 started" in main, "Il bootstrap 003.1 è stato rimosso")
must("WarriorPreview.Build()" not in main, "L'anteprima parte da sola nel server")
must("DestroyIfPublished" in main and "DestroyIfPublished" in preview, "Manca la rimozione dell'anteprima pubblicata")
must('FOLDER_NAME = "KurkitoWarriorPreview"' in preview or 'KurkitoWarriorPreview' in preview, "Nome anteprima assente")

must("WarriorVisualBuilder.Apply" in appearance, "Il giocatore non usa il builder")
must('heroId == "Warrior"' in appearance and '"Club"' in appearance, "Il contratto della clava è sparito da HeroAppearance")
must('motor.Name = "WeaponMotor"' in builder, "Manca WeaponMotor")
must('motor:SetAttribute("Animate", true)' in builder, "La clava non è animabile dal rig esistente")
must('shaft.Name = "Club"' in builder, "Il pezzo impugnato non si chiama Club")
must("SkullCranium" in builder and "RightShoulderSpike" in builder, "Manca il cranio asimmetrico")
must("-(halfX" in builder, "Il cranio non è sulla spalla sinistra")
must("HairLock" in builder and "FaceBrow" in builder and "FacePaint" in builder, "Mancano volto o capelli")
must("BoneFang" in builder and "FurFlap" in builder and "BeltBand" in builder, "Mancano collana, pelliccia o cintura")
must("SkirtPanel" in builder and "WristCuff" in builder and "BootSole" in builder, "Mancano gonna, polsi o stivali")
must("ClubStone" in builder and "ClubWrapRed" in builder and "ClubSpike" in builder, "La clava non ha pietra, rosso o punte")
must("PaintMark" in builder and "ChestStrap" in builder, "Mancano pittura o tracolla")
must("KurkitoVisuals" in builder and "KurkitoVisualGen" in builder, "Manca la pulizia idempotente")
must("Massless = true" in builder and "CanCollide = false" in builder and "CanQuery = false" in builder, "I pezzi cosmetici possono collidere")
must("LoadCharacterAppearance = false" in hero_service, "L'avatar del giocatore può ancora coprire il costume")
must("CharacterAppearanceLoaded" in hero_service, "Il costume non aspetta il caricamento dell'aspetto")
must("HasForeignCosmetics" in hero_service and "HasForeignCosmetics" in builder, "Manca il controllo sui vestiti residui")
must('KurkitoWarriorVisual") ~= "003.2"' in hero_service or 'KurkitoWarriorVisual") ~= "003.2"' in hero_service, "Il respawn non verifica la versione visiva")
must("warriorpreview" in commands and "warriorquality" in commands, "Mancano i comandi Studio dell'anteprima")
must("WarriorVisualBuilder.Apply" in preview, "L'anteprima non usa il builder del giocatore")
must("AimCamera" in preview and "front" in preview and "club" in preview, "Mancano le inquadrature dell'anteprima")
must("if not RunService:IsStudio()" in preview, "L'anteprima può essere creata fuori da Studio")

for label, text in (
    ("builder", builder),
    ("palette", palette),
    ("preview", preview),
    ("appearance", appearance),
):
    lowered = text.lower()
    if "rbxassetid" in lowered or "rbxasset://" in lowered:
        errors.append(f"Asset esterno in {label}")
    if "sword" in lowered or "blade" in lowered:
        errors.append(f"Arma medievale nominata in {label}")

must("stepWarrior" in motion and "WeaponMotor" in motion, "Le animazioni esistenti non leggono più WeaponMotor")
must("WarriorVisualBuilder" not in motion, "Motion è stato accoppiato al costume")
must("function Rules.VisualTier" in read("shared/Shared/Rules.luau"), "I tier grafici degli upgrade sono spariti")
must("VisualTier" in builder, "HP, DMG e Speed non cambiano più il costume")

if errors:
    print("WARRIOR_VISUAL_FAIL")
    for error in errors:
        print(" -", error)
    sys.exit(1)

print("WARRIOR_VISUAL_OK")
