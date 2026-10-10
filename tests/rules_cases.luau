local function expect(condition, message)
	if not condition then
		error(message or "asserzione fallita", 2)
	end
end

local curve = { base = 40, exponent = 1.45 }

local function newHero()
	return {
		mastery = 0,
		xp = 0,
		skillPoints = 0,
		rebirths = 0,
		stats = { HP = 4, DMG = 3, Speed = 2 },
		skillRanks = { spinning_slash = 0, steel_skin = 0, fury = 0 },
		talents = { vitality = 0, power = 0, class_mastery = 0 },
		unlockedArenas = { ["1"] = true, ["4"] = true },
		equippedGear = { weapon = "sword", armor = "", charm = "charm" },
	}
end

do
	local hero = newHero()
	local levels = 0
	while hero.mastery < 50 do
		local need = Rules.XpToNext(hero.mastery, curve, 50)
		local result = Rules.ApplyXp(hero, need, 0.1, curve, 50)
		levels += result.levels
	end
	expect(hero.mastery == 50, "maestria non arriva a 50")
	expect(hero.skillPoints == 50, "i punti non sono 50")
	expect(hero.xp == 0, "xp residua al cap")
	expect(levels == 50, "livelli guadagnati diversi da 50")
	local extra = Rules.ApplyXp(hero, 5000, 0.1, curve, 50)
	expect(extra.applied == 0 and hero.skillPoints == 50 and hero.mastery == 50, "xp oltre il cap")
end

do
	local hero = newHero()
	hero.rebirths = 1
	local result = Rules.ApplyXp(hero, 40, 0.1, curve, 50)
	expect(result.applied == 44, "bonus rebirth xp 10%")
	expect(hero.mastery == 1, "primo livello")
	expect(hero.xp == 4, "xp residua dopo il bonus")
	expect(Rules.RewardCoins(100, 5, 0.1, 10 ^ 12) == 150, "bonus monete 5 rebirth")
	expect(Rules.RewardCoins(7, 0, 0.1, 10 ^ 12) == 7, "monete senza rebirth")
end

do
	local coins = 100
	local ok, left = Rules.TrySpend(coins, 40)
	expect(ok and left == 60, "spesa valida")
	local fail, same = Rules.TrySpend(left, 61)
	expect(fail == false and same == 60, "saldo negativo impedito")
	local bad = Rules.TrySpend(left, -5)
	expect(bad == false, "importo negativo rifiutato")
end

do
	local profile = {
		firstHeroChosen = false,
		selectedHero = "",
		unlockedHeroes = { Warrior = false, Mage = false, Archer = false },
		coins = 250,
		pets = {
			{ uid = "p1", petId = "zombie", evolution = "Normal" },
		},
		equippedPets = { "", "", "" },
		inventory = {
			equipment = {
				{ uid = "sword", itemId = "warrior_blade_1", boundHero = "Warrior" },
				{ uid = "charm", itemId = "charm_minor", boundHero = nil },
				{ uid = "robe", itemId = "mage_robe_1", boundHero = "Mage" },
			},
			materials = { mat_arena_1 = 3 },
			potions = { health_common = 2 },
			collectibles = { relic_arena_1 = 1 },
		},
		heroes = {
			Warrior = newHero(),
			Mage = newHero(),
			Archer = newHero(),
		},
	}
	profile.heroes.Warrior.mastery = 50
	profile.heroes.Mage.mastery = 12
	profile.heroes.Mage.skillPoints = 12
	local ok, err = Rules.SelectFirstHero(profile, "Warrior", { Warrior = true, Mage = true, Archer = true })
	expect(ok, err)
	local again = Rules.SelectFirstHero(profile, "Mage", { Warrior = true, Mage = true, Archer = true })
	expect(again == false, "seconda scelta gratuita")
	local switched = Rules.SwitchHero(profile, "Mage")
	expect(switched == false, "mago ancora bloccato")
	profile.unlockedHeroes.Mage = true
	expect(Rules.SwitchHero(profile, "Mage") == true, "cambio verso mago sbloccato")
	expect(profile.heroes.Warrior.mastery == 50, "il cambio non sposta la maestria")
	expect(profile.heroes.Mage.mastery == 12, "il mago conserva la propria maestria")
	profile.selectedHero = "Warrior"
	local removed
	local applied
	applied, err, removed = Rules.ApplyRebirth(profile, "Warrior", { "HP", "DMG", "Speed" }, { "spinning_slash", "steel_skin", "fury" }, { "vitality", "power", "class_mastery" })
	expect(applied, err)
	expect(profile.heroes.Warrior.mastery == 0, "maestria azzerata")
	expect(profile.heroes.Warrior.xp == 0, "xp azzerata")
	expect(profile.heroes.Warrior.skillPoints == 0, "punti azzerati")
	expect(profile.heroes.Warrior.stats.HP == 1, "hp azzerati")
	expect(profile.heroes.Warrior.rebirths == 1, "rebirth incrementato")
	expect(profile.heroes.Warrior.unlockedArenas["1"] == true, "arena 1 resta")
	expect(profile.heroes.Warrior.unlockedArenas["4"] == nil, "arene riacquistate")
	expect(profile.coins == 250, "monete conservate")
	expect(#profile.pets == 1, "pet conservati")
	expect(profile.inventory.materials.mat_arena_1 == 3, "materiali conservati")
	expect(profile.inventory.potions.health_common == 2, "pozioni conservate")
	expect(profile.inventory.collectibles.relic_arena_1 == 1, "collezionabili conservati")
	expect(profile.unlockedHeroes.Warrior == true and profile.unlockedHeroes.Mage == true, "eroi sbloccati conservati")
	expect(profile.heroes.Mage.mastery == 12, "altro eroe intatto")
	expect(removed == 1, "solo l'equip del guerriero")
	local keptCharm, keptRobe, keptSword = false, false, false
	for _, item in ipairs(profile.inventory.equipment) do
		if item.uid == "charm" then
			keptCharm = true
		elseif item.uid == "robe" then
			keptRobe = true
		elseif item.uid == "sword" then
			keptSword = true
		end
	end
	expect(keptCharm and keptRobe and not keptSword, "regola boundHero")
	expect(profile.heroes.Warrior.equippedGear.weapon == "", "slot arma pulito")
	expect(Rules.TotalRebirths(profile) == 1, "somma rebirth")
end

do
	local pets = {}
	for index = 1, 5 do
		table.insert(pets, { uid = "n" .. index, petId = "zombie", evolution = "Normal" })
	end
	table.insert(pets, { uid = "other", petId = "slime", evolution = "Normal" })
	local ok, result = Rules.ApplyFuse(pets, { n1 = true }, { "n1", "n2", "n3", "n4", "n5" }, 5, function(evolution)
		if evolution == "Normal" then
			return "Gold"
		end
		return nil
	end, "gold1")
	expect(ok == false, "pet equipaggiato rifiutato")
	ok, result = Rules.ApplyFuse(pets, {}, { "n1", "n1", "n2", "n3", "n4" }, 5, function()
		return "Gold"
	end, "gold1")
	expect(ok == false, "uid duplicato rifiutato")
	ok, result = Rules.ApplyFuse(pets, {}, { "n1", "n2", "n3", "n4", "other" }, 5, function()
		return "Gold"
	end, "gold1")
	expect(ok == false, "pet diversi rifiutati")
	ok, result = Rules.ApplyFuse(pets, {}, { "n1", "n2", "n3", "n4", "n5" }, 5, function(evolution)
		expect(evolution == "Normal", "evoluzione base")
		return "Gold"
	end, "gold1")
	expect(ok == true, "fusione 5 a 1")
	expect(#result == 2, "restano il pet estraneo e quello evoluto")
	expect(result[#result].evolution == "Gold" and result[#result].petId == "zombie", "risultato oro")
	local chain = result[#result].evolution
	local order = { Normal = "Gold", Gold = "Diamond", Diamond = "Platinum", Platinum = "Stellar", Stellar = "Void", Void = nil }
	expect(order[chain] == "Diamond", "catena successiva")
	local voidPet = { { uid = "v", petId = "zombie", evolution = "Void" } }
	local cannot = Rules.CanFuse(voidPet, {}, { "v" }, 1, function(evolution)
		return order[evolution]
	end)
	expect(cannot == false, "void non evolve, ma il test del rapporto usa 5")
end

do
	local entries = {
		{ itemId = "rare", category = "collectibles", chance = 0.5, min = 1, max = 1, cap = 0.85 },
		{ itemId = "warrior_blade_1", category = "equipment", chance = 1, classId = "Warrior" },
		{ itemId = "mage_staff_1", category = "equipment", chance = 1, classId = "Mage" },
	}
	local blocked = Rules.RollDrops(entries, 100, function()
		return 0.9
	end, "Warrior")
	expect(#blocked == 1 and blocked[1].itemId == "warrior_blade_1", "il cap impedisce il raro e filtra la classe")
	local allowed = Rules.RollDrops(entries, 100, function()
		return 0.2
	end, "Mage")
	expect(#allowed == 2, "mago riceve raro e oggetto di classe")
end

do
	local active = {}
	Rules.ApplyPotion(active, { id = "health_common", family = "HealthRegen", duration = 30, healthPerSecond = 4 }, 100)
	Rules.ApplyPotion(active, { id = "health_rare", family = "HealthRegen", duration = 120, healthPerSecond = 8 }, 110)
	local families = 0
	for _ in pairs(active) do
		families += 1
	end
	expect(families == 1, "niente stack di famiglia")
	expect(active.HealthRegen.potionId == "health_rare", "la nuova pozione sostituisce")
	expect(active.HealthRegen.expiresAt == 230, "la durata non si somma")
	expect(active.HealthRegen.healthPerSecond == 8, "la potenza non si moltiplica")
end

do
	local credit = Rules.PickKillCredit({ [10] = 20, [11] = 20 }, 11, "HighestDamage")
	expect(credit == 11, "parità all'ultimo colpo")
	credit = Rules.PickKillCredit({ [10] = 5, [11] = 9 }, 10, "HighestDamage")
	expect(credit == 11, "vince il danno maggiore")
	credit = Rules.PickKillCredit({ [10] = 5, [11] = 9 }, 10, "LastHit")
	expect(credit == 10, "modalità ultimo colpo")
end

do
	local profile = {
		unlockedHeroes = { Warrior = true, Mage = false, Archer = false },
	}
	expect(Rules.UnlockNextHero(profile, { "Warrior", "Mage", "Archer" }) == "Mage", "sblocca il successivo")
	expect(profile.unlockedHeroes.Mage == true, "sblocco permanente nel profilo")
end

expect(Rules.FormatNumber(0) == "0", "format 0")
expect(Rules.FormatNumber(1234) == "1.234", "format migliaia")
expect(Rules.FormatNumber(1234567) == "1.234.567", "format milioni")

local arena = { index = 2, mastery = 5, cost = 180 }
local hero = newHero()
hero.mastery = 4
local ok = Rules.CanPurchaseArena(hero, arena, 9999)
expect(ok == false, "maestria insufficiente")
hero.mastery = 5
ok = Rules.CanPurchaseArena(hero, arena, 10)
expect(ok == false, "monete insufficienti")
ok = Rules.CanPurchaseArena(hero, arena, 180)
expect(ok == true, "acquisto consentito")

print("RULES_OK")
