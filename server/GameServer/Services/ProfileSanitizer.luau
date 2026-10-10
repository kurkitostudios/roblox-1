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
		return fail("Missing hero: " .. classId)
	end
	local classDef = HeroConfig.Classes[classId]
	if not isInteger(raw.mastery, 0, GameConfig.MaxMastery) then
		return fail("Invalid mastery.")
	end
	if not isInteger(raw.xp, 0, 100000000) then
		return fail("Invalid XP.")
	end
	if raw.mastery >= GameConfig.MaxMastery and raw.xp ~= 0 then
		return fail("XP is above the Mastery cap.")
	end
	if not isInteger(raw.rebirths, 0, 100000) then
		return fail("Invalid rebirth count.")
	end
	if not isInteger(raw.skillPoints, 0, GameConfig.MaxMastery) then
		return fail("Invalid Skill Points.")
	end

	local stats = {}
	if type(raw.stats) ~= "table" then
		return fail("Missing stats.")
	end
	for _, statId in ipairs(classDef.stats) do
		local maxLevel = HeroConfig.StatDefs[statId].maxLevel
		if not isInteger(raw.stats[statId], 1, maxLevel) then
			return fail("Invalid stat: " .. statId)
		end
		stats[statId] = raw.stats[statId]
	end

	local skillRanks = {}
	local spent = 0
	if type(raw.skillRanks) ~= "table" then
		return fail("Missing abilities.")
	end
	for _, ability in ipairs(AbilityConfig[classId]) do
		local rank = raw.skillRanks[ability.id]
		if not isInteger(rank, 0, AbilityConfig.MaxRank) then
			return fail("Invalid ability rank.")
		end
		skillRanks[ability.id] = rank
		spent += rank
	end

	local talents = {}
	if type(raw.talents) ~= "table" then
		return fail("Missing talents.")
	end
	for _, talent in ipairs(HeroConfig.Talents) do
		local rank = raw.talents[talent.id]
		if not isInteger(rank, 0, talent.maxRank) then
			return fail("Invalid talent.")
		end
		talents[talent.id] = rank
		spent += rank
	end
	if spent > raw.mastery then
		return fail("Skill Points exceed Mastery.")
	end

	local unlockedArenas = { ["1"] = true }
	if type(raw.unlockedArenas) ~= "table" then
		return fail("Missing arenas.")
	end
	for key, value in pairs(raw.unlockedArenas) do
		local index = tonumber(key)
		if value == true and index and index >= 1 and index <= 15 and index == math.floor(index) then
			unlockedArenas[tostring(index)] = true
		elseif value ~= false and value ~= true then
			return fail("Invalid arena unlock.")
		end
	end

	local gear = { weapon = "", armor = "", charm = "" }
	if type(raw.equippedGear) ~= "table" then
		return fail("Invalid hero equipment.")
	end
	for _, slot in ipairs({ "weapon", "armor", "charm" }) do
		local uid = raw.equippedGear[slot]
		if uid == nil or uid == "" then
			gear[slot] = ""
		elseif isId(uid, 64) then
			gear[slot] = uid
		else
			return fail("Invalid equipment slot.")
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
		return fail("Profile is not a table.")
	end
	if raw.schemaVersion ~= ProfileTemplate.SchemaVersion then
		return fail("Unsupported schema version.")
	end
	if not isInteger(raw.coins, 0, GameConfig.MaxCoins) then
		return fail("Invalid coins.")
	end
	if type(raw.firstHeroChosen) ~= "boolean" then
		return fail("Invalid hero choice.")
	end
	if type(raw.unlockedHeroes) ~= "table" then
		return fail("Missing unlocked heroes.")
	end

	local unlocked = {}
	for _, heroId in ipairs(HeroConfig.Order) do
		if type(raw.unlockedHeroes[heroId]) ~= "boolean" then
			return fail("Invalid hero state.")
		end
		unlocked[heroId] = raw.unlockedHeroes[heroId]
	end

	local selected = raw.selectedHero
	if selected == nil then
		selected = ""
	end
	if selected ~= "" and not HeroConfig.Classes[selected] then
		return fail("Unknown selected hero.")
	end
	if raw.firstHeroChosen then
		if selected == "" or unlocked[selected] ~= true then
			return fail("Active hero is not unlocked.")
		end
	elseif selected ~= "" then
		return fail("A hero is selected before the first choice.")
	end

	if not isInteger(raw.playTimeSeconds, 0, 2000000000) then
		return fail("Invalid play time.")
	end
	if not isInteger(raw.totalKills, 0, 2000000000) then
		return fail("Invalid kills.")
	end

	local heroes = {}
	if type(raw.heroes) ~= "table" then
		return fail("Missing hero data.")
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
				return fail("Invalid quest progress.")
			end
			if type(state.completed) ~= "boolean" then
				return fail("Invalid quest state.")
			end
			local completed = state.completed
			if state.progress >= quest.goal then
				completed = true
			elseif completed and state.progress < quest.goal then
				return fail("Quest is complete without progress.")
			end
			quests[quest.id] = { progress = state.progress, completed = completed }
		end
	end

	if type(raw.inventory) ~= "table" then
		return fail("Missing inventory.")
	end
	local inventory = {
		equipment = {},
		materials = {},
		potions = {},
		collectibles = {},
	}
	local seenUid = {}
	if not isSequential(raw.inventory.equipment) then
		return fail("Equipment list is missing or invalid.")
	end
	local equipCount = 0
	for _, entry in ipairs(raw.inventory.equipment) do
		equipCount += 1
		if equipCount > GameConfig.Inventory.MaxEquipment then
			return fail("Too much equipment.")
		end
		if type(entry) ~= "table" or not isId(entry.uid, 64) or not isId(entry.itemId, 64) then
			return fail("Invalid equipment.")
		end
		if seenUid[entry.uid] then
			return fail("Duplicate equipment uid.")
		end
		local def = LootConfig.GetItem(entry.itemId)
		if not def or def.category ~= "equipment" then
			return fail("Unknown equipment item.")
		end
		local bound = entry.boundHero
		if bound == nil then
			if def.classId ~= nil then
				return fail("Class equipment is missing a hero.")
			end
		else
			if not HeroConfig.Classes[bound] or def.classId ~= bound then
				return fail("Invalid equipment binding.")
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
			return fail("Missing inventory category: " .. category)
		end
		for itemId, count in pairs(source) do
			if not isId(itemId, 64) or not isInteger(count, 1, GameConfig.Inventory.MaxStack) then
				return fail("Invalid stack.")
			end
			local def = LootConfig.GetItem(itemId)
			if not def or def.category ~= category then
				return fail("Unknown stacked item.")
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
		return fail("Pets are missing or invalid.")
	end
	local pets = {}
	local petUids = {}
	for _, pet in ipairs(raw.pets) do
		if #pets >= GameConfig.Inventory.MaxPets then
			return fail("Too many pets.")
		end
		if type(pet) ~= "table" or not isId(pet.uid, 64) or not isId(pet.petId, 64) then
			return fail("Invalid pet.")
		end
		if petUids[pet.uid] or seenUid[pet.uid] then
			return fail("Duplicate pet uid.")
		end
		if not PetConfig.Get(pet.petId) then
			return fail("Unknown pet species.")
		end
		if not PetConfig.EvolutionMult[pet.evolution] then
			return fail("Invalid pet evolution.")
		end
		petUids[pet.uid] = true
		table.insert(pets, {
			uid = pet.uid,
			petId = pet.petId,
			evolution = pet.evolution,
		})
	end

	if not isSequential(raw.equippedPets) then
		return fail("Equipped pets are missing or invalid.")
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
