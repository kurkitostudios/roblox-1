-- Pet, uova e fusioni. Coefficienti PROVVISORI.
-- La rarità del Pet è indipendente dal livello di evoluzione.
-- I Pet delle uova normali sono i mostri dell'arena corrispondente.

local EnemyConfig = require(script.Parent.EnemyConfig)
local ArenaConfig = require(script.Parent.ArenaConfig)

local PetConfig = {
	MaxEquipped = 3,
	EvolutionOrder = { "Normal", "Gold", "Diamond", "Platinum", "Stellar", "Void" },
	-- PROVVISORIO. Ogni passo è molto più forte del precedente.
	EvolutionMult = {
		Normal = 1,
		Gold = 1.6,
		Diamond = 2.5,
		Platinum = 4,
		Stellar = 6,
		Void = 9,
	},
	BaseBonus = {
		Common = { hp = 0.03, dmg = 0.03, speed = 0.2, fortune = 0.02 },
		Uncommon = { hp = 0.05, dmg = 0.05, speed = 0.3, fortune = 0.035 },
		Rare = { hp = 0.07, dmg = 0.08, speed = 0.4, fortune = 0.05 },
		Elite = { hp = 0.1, dmg = 0.11, speed = 0.55, fortune = 0.07 },
		Boss = { hp = 0.14, dmg = 0.15, speed = 0.7, fortune = 0.09 },
	},
	EvolutionColor = {
		Normal = Color3.fromRGB(200, 200, 200),
		Gold = Color3.fromRGB(220, 180, 70),
		Diamond = Color3.fromRGB(120, 210, 230),
		Platinum = Color3.fromRGB(210, 220, 235),
		Stellar = Color3.fromRGB(255, 220, 120),
		Void = Color3.fromRGB(150, 80, 220),
	},
}

local pets = {}
for _, enemy in EnemyConfig.List do
	pets[enemy.id] = {
		id = enemy.id,
		name = enemy.name,
		arena = enemy.arena,
		rarity = enemy.rarity,
		sourceEnemyId = enemy.id,
	}
end
PetConfig.Pets = pets

function PetConfig.Get(id)
	return pets[id]
end

function PetConfig.NextEvolution(evolution)
	for index, name in PetConfig.EvolutionOrder do
		if name == evolution then
			return PetConfig.EvolutionOrder[index + 1]
		end
	end
	return nil
end

local function weightsFor(enemies)
	local hasBoss = false
	for _, enemy in enemies do
		if enemy.rarity == "Boss" then
			hasBoss = true
		end
	end
	local rarityWeight = { Common = 70, Uncommon = 22, Rare = 10, Elite = 12, Boss = 5 }
	local raw = {}
	local total = 0
	for _, enemy in enemies do
		local weight = rarityWeight[enemy.rarity] or 10
		if hasBoss and enemy.rarity == "Boss" then
			weight = 5
		elseif hasBoss then
			weight = rarityWeight[enemy.rarity] or 10
		end
		raw[enemy.id] = weight
		total += weight
	end
	if hasBoss then
		local bossTotal = 0
		local otherTotal = 0
		for _, enemy in enemies do
			if enemy.rarity == "Boss" then
				bossTotal += raw[enemy.id]
			else
				otherTotal += raw[enemy.id]
			end
		end
		for _, enemy in enemies do
			if enemy.rarity == "Boss" then
				raw[enemy.id] = (raw[enemy.id] / math.max(1, bossTotal)) * 5
			else
				raw[enemy.id] = (raw[enemy.id] / math.max(1, otherTotal)) * 95
			end
		end
		total = 100
	end
	local entries = {}
	for _, enemy in enemies do
		table.insert(entries, {
			petId = enemy.id,
			weight = raw[enemy.id],
			chance = raw[enemy.id] / total,
		})
	end
	return entries
end

local eggs = {}
for _, arena in ipairs(ArenaConfig) do
	local enemies = EnemyConfig.GetByArena(arena.index)
	eggs[arena.index] = {
		id = "egg_arena_" .. arena.index,
		kind = "coins",
		arena = arena.index,
		name = arena.name .. " Egg",
		cost = math.floor(120 * (1.48 ^ (arena.index - 1)) + 0.5),
		productId = nil,
		enabled = true,
		pool = weightsFor(enemies),
		color = arena.color,
	}
end

local function specialPool(fromArena, toArena)
	local picked = {}
	for arena = fromArena, toArena do
		for _, enemy in EnemyConfig.GetByArena(arena) do
			if enemy.rarity == "Boss" or enemy.rarity == "Rare" or enemy.rarity == "Elite" then
				table.insert(picked, enemy)
			end
		end
	end
	if #picked == 0 then
		picked = EnemyConfig.GetByArena(fromArena)
	end
	return weightsFor(picked)
end

local specials = {
	{
		id = "egg_robux_1",
		kind = "robux",
		name = "Premium Egg",
		terrace = 1,
		arenas = "1–5",
		cost = nil,
		productId = nil,
		enabled = false,
		pool = specialPool(1, 5),
		color = Color3.fromRGB(212, 175, 90),
	},
	{
		id = "egg_robux_2",
		kind = "robux",
		name = "Royal Egg II",
		terrace = 2,
		arenas = "6–10",
		cost = nil,
		productId = nil,
		enabled = false,
		pool = specialPool(6, 10),
		color = Color3.fromRGB(230, 140, 70),
	},
	{
		id = "egg_robux_3",
		kind = "robux",
		name = "Royal Egg III",
		terrace = 3,
		arenas = "11–15",
		cost = nil,
		productId = nil,
		enabled = false,
		pool = specialPool(11, 15),
		color = Color3.fromRGB(180, 80, 200),
	},
}

local function explicitPool(entries)
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry.weight
	end
	local pool = {}
	for _, entry in ipairs(entries) do
		table.insert(pool, {
			petId = entry.petId,
			weight = entry.weight,
			chance = entry.weight / total,
		})
	end
	return pool
end

-- Uova fisse del Mondo 0. I prezzi sono PROVVISORI.
-- Non seguono l'arena sbloccata. Le uova delle arene restano in PetConfig.Eggs per il futuro.
local worldEggs = {
	coin = {
		id = "world0_coin",
		kind = "coins",
		name = "Coin Egg",
		cost = 250,
		provisional = true,
		productId = nil,
		enabled = true,
		pool = explicitPool({
			{ petId = "zombie", weight = 70 },
			{ petId = "zombie_corrotto", weight = 22 },
			{ petId = "rotfang", weight = 8 },
		}),
	},
	advanced = {
		id = "world0_advanced",
		kind = "coins",
		name = "Advanced Coin Egg",
		cost = 900,
		provisional = true,
		productId = nil,
		enabled = true,
		pool = explicitPool({
			{ petId = "zombie_corrotto", weight = 45 },
			{ petId = "rotfang", weight = 40 },
			{ petId = "grave_chieftain", weight = 15 },
		}),
	},
	premium = {
		id = "egg_robux_1",
		kind = "robux",
		name = "Premium Egg",
		cost = nil,
		provisional = true,
		productId = nil,
		enabled = false,
		pool = explicitPool({
			{ petId = "rotfang", weight = 55 },
			{ petId = "grave_chieftain", weight = 45 },
		}),
	},
}

PetConfig.Eggs = eggs
PetConfig.SpecialEggs = specials
PetConfig.WorldEggs = worldEggs

function PetConfig.GetEgg(arenaIndex)
	return eggs[arenaIndex]
end

function PetConfig.GetWorldEgg(key)
	return worldEggs[key]
end

function PetConfig.BonusFor(petId, evolution)
	local pet = pets[petId]
	if not pet then
		return { hp = 0, dmg = 0, speed = 0, fortune = 0 }
	end
	local base = PetConfig.BaseBonus[pet.rarity] or PetConfig.BaseBonus.Common
	local mult = PetConfig.EvolutionMult[evolution] or 1
	return {
		hp = base.hp * mult,
		dmg = base.dmg * mult,
		speed = base.speed * mult,
		fortune = base.fortune * mult,
	}
end

return PetConfig
