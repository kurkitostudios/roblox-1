-- Mostri del Mondo 1. Valori PROVVISORI.
-- La rarità dei mostri è distinta dalla rarità degli oggetti e dei Pet.

local RAW = {
	{ id = "zombie", name = "Scavenger Zombie", arena = 1, rarity = "Common", hp = 48, dmg = 6, speed = 11, aggro = 20, leash = 58, range = 5, interval = 1.45, xp = 12, coins = 7, respawn = 6, scale = 1, behavior = "scavenger" },
	{ id = "zombie_corrotto", name = "Bonewalker Zombie", arena = 1, rarity = "Uncommon", hp = 78, dmg = 8, speed = 12, aggro = 22, leash = 58, range = 5, interval = 1.4, xp = 20, coins = 11, respawn = 8, scale = 1.08, behavior = "bonewalker" },
	{ id = "rotfang", name = "Rotfang Zombie", arena = 1, rarity = "Rare", hp = 118, dmg = 11, speed = 15, aggro = 24, leash = 60, range = 5.2, interval = 1.05, xp = 32, coins = 16, respawn = 9, scale = 1.12, behavior = "rotfang" },
	{ id = "grave_chieftain", name = "Grave Chieftain", arena = 1, rarity = "Boss", hp = 640, dmg = 18, speed = 10, aggro = 28, leash = 70, range = 8, interval = 1.65, xp = 160, coins = 80, respawn = 30, scale = 1.7, behavior = "chieftain" },
	{ id = "scheletro", name = "Skeleton", arena = 2, rarity = "Common", hp = 64, dmg = 7, speed = 12, aggro = 20, leash = 60, range = 5, interval = 1.4, xp = 16, coins = 9, respawn = 6, scale = 1 },
	{ id = "scheletro_arciere", name = "Skeleton Archer", arena = 2, rarity = "Uncommon", hp = 58, dmg = 9, speed = 11, aggro = 24, leash = 62, range = 18, interval = 1.6, xp = 24, coins = 13, respawn = 8, scale = 1 },
	{ id = "goblin", name = "Goblin", arena = 3, rarity = "Common", hp = 86, dmg = 8, speed = 13, aggro = 20, leash = 60, range = 4.5, interval = 1.25, xp = 22, coins = 13, respawn = 6, scale = 0.9 },
	{ id = "goblin_bruto", name = "Brute Goblin", arena = 3, rarity = "Rare", hp = 150, dmg = 12, speed = 11, aggro = 22, leash = 60, range = 6, interval = 1.6, xp = 40, coins = 22, respawn = 10, scale = 1.25 },
	{ id = "lupo", name = "Wolf", arena = 4, rarity = "Common", hp = 115, dmg = 10, speed = 15, aggro = 24, leash = 64, range = 5, interval = 1.15, xp = 30, coins = 17, respawn = 6, scale = 1 },
	{ id = "lupo_alfa", name = "Alpha Wolf", arena = 4, rarity = "Uncommon", hp = 180, dmg = 14, speed = 16, aggro = 26, leash = 64, range = 5.5, interval = 1.2, xp = 48, coins = 26, respawn = 9, scale = 1.2 },
	{ id = "bandito", name = "Bandit", arena = 5, rarity = "Common", hp = 155, dmg = 12, speed = 13, aggro = 22, leash = 62, range = 5, interval = 1.3, xp = 41, coins = 23, respawn = 7, scale = 1 },
	{ id = "capo_banditi", name = "Bandit Chief", arena = 5, rarity = "Boss", hp = 720, dmg = 22, speed = 12, aggro = 28, leash = 70, range = 7, interval = 1.5, xp = 180, coins = 90, respawn = 28, scale = 1.55 },
	{ id = "slime", name = "Slime", arena = 6, rarity = "Common", hp = 207, dmg = 14, speed = 10, aggro = 18, leash = 58, range = 5, interval = 1.5, xp = 56, coins = 30, respawn = 6, scale = 1.05 },
	{ id = "slime_tossico", name = "Toxic Slime", arena = 6, rarity = "Uncommon", hp = 280, dmg = 18, speed = 11, aggro = 20, leash = 58, range = 5, interval = 1.45, xp = 80, coins = 42, respawn = 8, scale = 1.2 },
	{ id = "ragno", name = "Spider", arena = 7, rarity = "Common", hp = 278, dmg = 16, speed = 14, aggro = 22, leash = 62, range = 5, interval = 1.15, xp = 76, coins = 41, respawn = 6, scale = 0.95 },
	{ id = "ragno_madre", name = "Broodmother", arena = 7, rarity = "Rare", hp = 520, dmg = 22, speed = 12, aggro = 24, leash = 64, range = 6, interval = 1.4, xp = 130, coins = 70, respawn = 12, scale = 1.35 },
	{ id = "cultista", name = "Cultist", arena = 8, rarity = "Common", hp = 372, dmg = 19, speed = 12, aggro = 24, leash = 64, range = 16, interval = 1.45, xp = 103, coins = 54, respawn = 7, scale = 1 },
	{ id = "accolito", name = "Acolyte", arena = 8, rarity = "Uncommon", hp = 460, dmg = 24, speed = 12, aggro = 26, leash = 64, range = 18, interval = 1.5, xp = 140, coins = 74, respawn = 9, scale = 1.05 },
	{ id = "orco", name = "Orc", arena = 9, rarity = "Common", hp = 499, dmg = 23, speed = 12, aggro = 22, leash = 64, range = 6, interval = 1.4, xp = 140, coins = 73, respawn = 7, scale = 1.15 },
	{ id = "guardia_orchesca", name = "Orc Guard", arena = 9, rarity = "Rare", hp = 760, dmg = 30, speed = 11, aggro = 24, leash = 66, range = 6, interval = 1.55, xp = 210, coins = 110, respawn = 12, scale = 1.3 },
	{ id = "orco_guerriero", name = "Orc Warrior", arena = 10, rarity = "Elite", hp = 980, dmg = 34, speed = 13, aggro = 24, leash = 68, range = 6, interval = 1.3, xp = 260, coins = 140, respawn = 12, scale = 1.25 },
	{ id = "warlord", name = "Warlord", arena = 10, rarity = "Boss", hp = 2400, dmg = 48, speed = 12, aggro = 30, leash = 74, range = 8, interval = 1.45, xp = 700, coins = 360, respawn = 35, scale = 1.7 },
	{ id = "spettro", name = "Specter", arena = 11, rarity = "Uncommon", hp = 896, dmg = 31, speed = 14, aggro = 24, leash = 66, range = 6, interval = 1.25, xp = 260, coins = 131, respawn = 8, scale = 1.05 },
	{ id = "wraith", name = "Wraith", arena = 11, rarity = "Rare", hp = 1200, dmg = 38, speed = 15, aggro = 26, leash = 68, range = 7, interval = 1.2, xp = 360, coins = 180, respawn = 11, scale = 1.15 },
	{ id = "golem", name = "Golem", arena = 12, rarity = "Rare", hp = 1800, dmg = 42, speed = 9, aggro = 20, leash = 60, range = 7, interval = 1.7, xp = 420, coins = 210, respawn = 12, scale = 1.45 },
	{ id = "golem_runico", name = "Runic Golem", arena = 12, rarity = "Elite", hp = 2300, dmg = 50, speed = 9, aggro = 22, leash = 62, range = 7, interval = 1.75, xp = 560, coins = 280, respawn = 14, scale = 1.6 },
	{ id = "imp", name = "Imp", arena = 13, rarity = "Uncommon", hp = 1400, dmg = 40, speed = 16, aggro = 24, leash = 66, range = 14, interval = 1.15, xp = 400, coins = 200, respawn = 7, scale = 0.85 },
	{ id = "demone", name = "Demon", arena = 13, rarity = "Elite", hp = 2600, dmg = 58, speed = 13, aggro = 26, leash = 70, range = 7, interval = 1.35, xp = 680, coins = 340, respawn = 14, scale = 1.4 },
	{ id = "cavaliere_oscuro", name = "Dark Knight", arena = 14, rarity = "Rare", hp = 2400, dmg = 56, speed = 12, aggro = 24, leash = 68, range = 6, interval = 1.35, xp = 620, coins = 310, respawn = 10, scale = 1.15 },
	{ id = "campione_oscuro", name = "Dark Champion", arena = 14, rarity = "Elite", hp = 3400, dmg = 68, speed = 13, aggro = 26, leash = 70, range = 7, interval = 1.4, xp = 860, coins = 430, respawn = 14, scale = 1.35 },
	{ id = "progenie_abisso", name = "Abyss Spawn", arena = 15, rarity = "Elite", hp = 3600, dmg = 70, speed = 14, aggro = 26, leash = 72, range = 6, interval = 1.25, xp = 900, coins = 460, respawn = 12, scale = 1.2 },
	{ id = "signore_abisso", name = "Abyss Lord", arena = 15, rarity = "Boss", hp = 9000, dmg = 95, speed = 12, aggro = 32, leash = 80, range = 8, interval = 1.4, xp = 2400, coins = 1200, respawn = 45, scale = 1.9 },
}

local EnemyConfig = {
	Rarities = { "Common", "Uncommon", "Rare", "Elite", "Boss" },
	RarityColor = {
		Common = Color3.fromRGB(190, 190, 190),
		Uncommon = Color3.fromRGB(90, 180, 90),
		Rare = Color3.fromRGB(80, 140, 220),
		Elite = Color3.fromRGB(170, 90, 220),
		Boss = Color3.fromRGB(220, 140, 50),
	},
	BodyColor = {
		Common = Color3.fromRGB(86, 140, 86),
		Uncommon = Color3.fromRGB(70, 120, 70),
		Rare = Color3.fromRGB(70, 90, 150),
		Elite = Color3.fromRGB(110, 60, 130),
		Boss = Color3.fromRGB(140, 50, 48),
	},
	List = RAW,
}

local byId = {}
local byArena = {}
for _, enemy in RAW do
	byId[enemy.id] = enemy
	if not byArena[enemy.arena] then
		byArena[enemy.arena] = {}
	end
	table.insert(byArena[enemy.arena], enemy)
end

function EnemyConfig.Get(id)
	return byId[id]
end

function EnemyConfig.GetByArena(arenaIndex)
	return byArena[arenaIndex] or {}
end

-- Quattro nemici regolari per arena, più il boss se presente.
function EnemyConfig.SpawnPlan(arenaIndex)
	local defs = EnemyConfig.GetByArena(arenaIndex)
	local regular = {}
	local boss = nil
	for _, def in defs do
		if def.rarity == "Boss" then
			boss = def
		else
			table.insert(regular, def)
		end
	end
	local plan = {}
	for slot = 1, 4 do
		local def = regular[((slot - 1) % math.max(1, #regular)) + 1]
		if def then
			table.insert(plan, { def = def, slot = slot, boss = false })
		end
	end
	if boss then
		table.insert(plan, { def = boss, slot = 5, boss = true })
	end
	return plan
end

function EnemyConfig.SpawnOffset(slot, boss)
	if boss then
		return Vector3.new(0, 5, 18)
	end
	local offsets = {
		Vector3.new(-42, 5, 8),
		Vector3.new(42, 5, 8),
		Vector3.new(-28, 5, 42),
		Vector3.new(28, 5, 42),
	}
	return offsets[slot] or Vector3.new(0, 5, 20)
end

return EnemyConfig
