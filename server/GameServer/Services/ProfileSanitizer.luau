-- Valida i dati caricati. In caso di profilo corrotto restituisce nil
-- e il chiamante NON deve sovrascriverlo con un profilo vuoto.
-- Le riparazioni sono solo riferimenti orfani e Skill Point incoerenti
-- quando i ranghi spesi non superano la Maestria.

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local HeroConfig = shared("HeroConfig")
local AbilityConfig = shared("AbilityConfig")
local QuestConfig = shared("QuestConfig")
local PetConfig = shared("PetConfig")
local LootConfig = shared("LootConfig")
local ProfileTemplate = shared("ProfileTemplate")

local ProfileSanitizer = {}

local function fail(reason)
	return nil, reason
end

local function isInteger(value, minValue, maxValue)
	if type(value) ~= "number" then
		return false
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return false
	end
	if value ~= math.floor(value) then
		return false
	end
	if value < minValue or value > maxValue then
		return false
	end
	return true
end

local function isSequential(list)
	if type(list) ~= "table" then
		return false
	end
	local count = 0
	local maxIndex = 0
	for key in pairs(list) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false
		end
		count += 1
		if key > maxIndex then
			maxIndex = key
		end
	end
	return maxIndex == count
end

local function isId(value, maxLen)
	if type(value) ~= "string" then
		return false
	end
	if #value < 1 or #value > (maxLen or 64) then
		return false
	end
	return string.match(value, "^[%w_%-]+$") ~= nil
end

local function copyHero(classId, raw)
	if type(raw) ~= "table" then
		return fail("Eroe mancante: " .. classId)
	end
	local classDef = HeroConfig.Classes[classId]
	if not isInteger(raw.mastery, 0, GameConfig.MaxMastery) then
		return fail("Maestria non valida.")
	end
	if not isInteger(raw.xp, 0, 100000000) then
		return fail("XP non valida.")
	end
	if raw.mastery >= GameConfig.MaxMastery and raw.xp ~= 0 then
		return fail("XP oltre il limite di Maestria.")
	end
	if not isInteger(raw.rebirths, 0, 100000) then
		return fail("Rebirth non valido.")
	end
	if not isInteger(raw.skillPoints, 0, GameConfig.MaxMastery) then
		return fail("Skill Point non validi.")
	end

	local stats = {}
	if type(raw.stats) ~= "table" then
		return fail("Statistiche mancanti.")
	end
	for _, statId in ipairs(classDef.stats) do
		local maxLevel = HeroConfig.StatDefs[statId].maxLevel
		if not isInteger(raw.stats[statId], 1, maxLevel) then
			return fail("Statistica non valida: " .. statId)
		end
		stats[statId] = raw.stats[statId]
	end

	local skillRanks = {}
	local spent = 0
	if type(raw.skillRanks) ~= "table" then
		return fail("Abilità mancanti.")
	end
	for _, ability in ipairs(AbilityConfig[classId]) do
		local rank = raw.skillRanks[ability.id]
		if not isInteger(rank, 0, AbilityConfig.MaxRank) then
			return fail("Rango abilità non valido.")
		end
		skillRanks[ability.id] = rank
		spent += rank
	end

	local talents = {}
	if type(raw.talents) ~= "table" then
		return fail("Talenti mancanti.")
	end
	for _, talent in ipairs(HeroConfig.Talents) do
		local rank = raw.talents[talent.id]
		if not isInteger(rank, 0, talent.maxRank) then
			return fail("Talento non valido.")
		end
		talents[talent.id] = rank
		spent += rank
	end
	if spent > raw.mastery then
		return fail("Skill Point superiori alla Maestria.")
	end

	local unlockedArenas = { ["1"] = true }
	if type(raw.unlockedArenas) ~= "table" then
		return fail("Arene mancanti.")
	end
	for key, value in pairs(raw.unlockedArenas) do
		local index = tonumber(key)
		if value == true and index and index >= 1 and index <= 15 and index == math.floor(index) then
			unlockedArenas[tostring(index)] = true
		elseif value ~= false and value ~= true then
			return fail("Sblocco arena non valido.")
		end
	end

	local gear = { weapon = "", armor = "", charm = "" }
	if type(raw.equippedGear) ~= "table" then
		return fail("Equipaggiamento eroe non valido.")
	end
	for _, slot in ipairs({ "weapon", "armor", "charm" }) do
		local uid = raw.equippedGear[slot]
		if uid == nil or uid == "" then
			gear[slot] = ""
		elseif isId(uid, 64) then
			gear[slot] = uid
		else
			return fail("Slot equipaggiamento non valido.")
		end
	end

	return {
		mastery = raw.mastery,
		xp = raw.xp,
		skillPoints = raw.mastery - spent,
		rebirths = raw.rebirths,
		stats = stats,
		skillRanks = skillRanks,
		talents = talents,
		unlockedArenas = unlockedArenas,
		equippedGear = gear,
	}
end

function ProfileSanitizer.Sanitize(raw)
	if type(raw) ~= "table" then
		return fail("Profilo non è una tabella.")
	end
	if raw.schemaVersion ~= ProfileTemplate.SchemaVersion then
		return fail("Versione schema non supportata.")
	end
	if not isInteger(raw.coins, 0, GameConfig.MaxCoins) then
		return fail("Monete non valide.")
	end
	if type(raw.firstHeroChosen) ~= "boolean" then
		return fail("Scelta eroe non valida.")
	end
	if type(raw.unlockedHeroes) ~= "table" then
		return fail("Eroi sbloccati mancanti.")
	end

	local unlocked = {}
	for _, heroId in ipairs(HeroConfig.Order) do
		if type(raw.unlockedHeroes[heroId]) ~= "boolean" then
			return fail("Stato eroe non valido.")
		end
		unlocked[heroId] = raw.unlockedHeroes[heroId]
	end

	local selected = raw.selectedHero
	if selected == nil then
		selected = ""
	end
	if selected ~= "" and not HeroConfig.Classes[selected] then
		return fail("Eroe selezionato sconosciuto.")
	end
	if raw.firstHeroChosen then
		if selected == "" or unlocked[selected] ~= true then
			return fail("Eroe attivo non sbloccato.")
		end
	elseif selected ~= "" then
		return fail("Eroe selezionato prima della scelta iniziale.")
	end

	if not isInteger(raw.playTimeSeconds, 0, 2000000000) then
		return fail("Tempo di gioco non valido.")
	end
	if not isInteger(raw.totalKills, 0, 2000000000) then
		return fail("Uccisioni non valide.")
	end

	local heroes = {}
	if type(raw.heroes) ~= "table" then
		return fail("Dati eroi mancanti.")
	end
	for _, heroId in ipairs(HeroConfig.Order) do
		local hero, reason = copyHero(heroId, raw.heroes[heroId])
		if not hero then
			return fail(reason)
		end
		heroes[heroId] = hero
	end

	local quests = {}
	if type(raw.quests) ~= "table" then
		return fail("Missioni mancanti.")
	end
	for _, quest in ipairs(QuestConfig) do
		local state = raw.quests[quest.id]
		if type(state) ~= "table" then
			quests[quest.id] = { progress = 0, completed = false }
		else
			if not isInteger(state.progress, 0, quest.goal) then
				return fail("Progresso missione non valido.")
			end
			if type(state.completed) ~= "boolean" then
				return fail("Stato missione non valido.")
			end
			local completed = state.completed
			if state.progress >= quest.goal then
				completed = true
			elseif completed and state.progress < quest.goal then
				return fail("Missione completata senza progresso.")
			end
			quests[quest.id] = { progress = state.progress, completed = completed }
		end
	end

	if type(raw.inventory) ~= "table" then
		return fail("Inventario mancante.")
	end
	local inventory = {
		equipment = {},
		materials = {},
		potions = {},
		collectibles = {},
	}
	local seenUid = {}
	if not isSequential(raw.inventory.equipment) then
		return fail("Equipaggiamenti mancanti o non validi.")
	end
	local equipCount = 0
	for _, entry in ipairs(raw.inventory.equipment) do
		equipCount += 1
		if equipCount > GameConfig.Inventory.MaxEquipment then
			return fail("Troppi equipaggiamenti.")
		end
		if type(entry) ~= "table" or not isId(entry.uid, 64) or not isId(entry.itemId, 64) then
			return fail("Equipaggiamento non valido.")
		end
		if seenUid[entry.uid] then
			return fail("UID equipaggiamento duplicato.")
		end
		local def = LootConfig.GetItem(entry.itemId)
		if not def or def.category ~= "equipment" then
			return fail("Oggetto equipaggiamento sconosciuto.")
		end
		local bound = entry.boundHero
		if bound == nil then
			if def.classId ~= nil then
				return fail("Equipaggiamento di classe senza eroe.")
			end
		else
			if not HeroConfig.Classes[bound] or def.classId ~= bound then
				return fail("Vincolo equipaggiamento non valido.")
			end
		end
		seenUid[entry.uid] = true
		table.insert(inventory.equipment, {
			uid = entry.uid,
			itemId = entry.itemId,
			boundHero = bound,
		})
	end

	local function copyStack(source, target, category)
		if type(source) ~= "table" then
			return fail("Categoria inventario mancante: " .. category)
		end
		for itemId, count in pairs(source) do
			if not isId(itemId, 64) or not isInteger(count, 1, GameConfig.Inventory.MaxStack) then
				return fail("Stack non valido.")
			end
			local def = LootConfig.GetItem(itemId)
			if not def or def.category ~= category then
				return fail("Oggetto stack sconosciuto.")
			end
			target[itemId] = count
		end
		return true
	end

	local okMats, matErr = copyStack(raw.inventory.materials, inventory.materials, "materials")
	if not okMats then
		return fail(matErr)
	end
	local okPot, potErr = copyStack(raw.inventory.potions, inventory.potions, "potions")
	if not okPot then
		return fail(potErr)
	end
	local okCol, colErr = copyStack(raw.inventory.collectibles, inventory.collectibles, "collectibles")
	if not okCol then
		return fail(colErr)
	end

	if not isSequential(raw.pets) then
		return fail("Pet mancanti o non validi.")
	end
	local pets = {}
	local petUids = {}
	for _, pet in ipairs(raw.pets) do
		if #pets >= GameConfig.Inventory.MaxPets then
			return fail("Troppi Pet.")
		end
		if type(pet) ~= "table" or not isId(pet.uid, 64) or not isId(pet.petId, 64) then
			return fail("Pet non valido.")
		end
		if petUids[pet.uid] or seenUid[pet.uid] then
			return fail("UID Pet duplicato.")
		end
		if not PetConfig.Get(pet.petId) then
			return fail("Specie Pet sconosciuta.")
		end
		if not PetConfig.EvolutionMult[pet.evolution] then
			return fail("Evoluzione Pet non valida.")
		end
		petUids[pet.uid] = true
		table.insert(pets, {
			uid = pet.uid,
			petId = pet.petId,
			evolution = pet.evolution,
		})
	end

	if not isSequential(raw.equippedPets) then
		return fail("Pet equipaggiati mancanti o non validi.")
	end
	local equippedPets = { "", "", "" }
	local usedPet = {}
	for slot = 1, PetConfig.MaxEquipped do
		local uid = raw.equippedPets[slot]
		if uid == nil or uid == "" then
			equippedPets[slot] = ""
		elseif isId(uid, 64) and petUids[uid] and not usedPet[uid] then
			equippedPets[slot] = uid
			usedPet[uid] = true
		elseif uid == "" or uid == nil then
			equippedPets[slot] = ""
		else
			equippedPets[slot] = ""
		end
	end

	for _, hero in pairs(heroes) do
		for slot, uid in pairs(hero.equippedGear) do
			if uid ~= "" and not seenUid[uid] then
				hero.equippedGear[slot] = ""
			elseif uid ~= "" then
				local found = nil
				for _, entry in ipairs(inventory.equipment) do
					if entry.uid == uid then
						found = entry
						break
					end
				end
				local def = found and LootConfig.GetItem(found.itemId)
				if not def or def.slot ~= slot then
					hero.equippedGear[slot] = ""
				end
			end
		end
	end

	return {
		schemaVersion = ProfileTemplate.SchemaVersion,
		coins = raw.coins,
		selectedHero = selected,
		firstHeroChosen = raw.firstHeroChosen,
		unlockedHeroes = unlocked,
		playTimeSeconds = raw.playTimeSeconds,
		totalKills = raw.totalKills,
		quests = quests,
		pets = pets,
		equippedPets = equippedPets,
		inventory = inventory,
		heroes = heroes,
	}
end

return ProfileSanitizer
