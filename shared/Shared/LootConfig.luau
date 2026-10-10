-- Drop table PROVVISORIE. Gli oggetti di classe sono vincolati all'eroe che li ottiene.
-- I charm non hanno boundHero: restano dopo il Rebirth. Vedi RebirthService.

local PotionConfig = require(script.Parent.PotionConfig)

local LootConfig = {
	MaxDropChance = 0.85,
	Items = {},
}

local function item(def)
	LootConfig.Items[def.id] = def
end

for arena = 1, 15 do
	item({
		id = "mat_arena_" .. arena,
		name = "Frammento Arena " .. arena,
		category = "materials",
		rarity = "Common",
		description = "Materiale provvisorio. La forgia non è in questa build.",
	})
	item({
		id = "relic_arena_" .. arena,
		name = "Reliquia Arena " .. arena,
		category = "collectibles",
		rarity = "Rare",
		description = "Collezionabile del Mondo 1.",
	})
end

local function gear(id, name, slot, classId, rarity, bonuses)
	item({
		id = id,
		name = name,
		category = "equipment",
		slot = slot,
		classId = classId,
		rarity = rarity,
		bonuses = bonuses,
		description = "Equipaggiamento prototipo.",
	})
end

gear("warrior_blade_1", "Lama del Recluta", "weapon", "Warrior", "Common", { dmg = 3 })
gear("warrior_blade_2", "Spada del Veterano", "weapon", "Warrior", "Rare", { dmg = 8 })
gear("warrior_blade_3", "Spadone del Campione", "weapon", "Warrior", "Epic", { dmg = 16 })
gear("warrior_armor_1", "Cotta Semplice", "armor", "Warrior", "Common", { hp = 12 })
gear("warrior_armor_2", "Armatura di Ferro", "armor", "Warrior", "Rare", { hp = 30 })
gear("warrior_armor_3", "Corazza del Campione", "armor", "Warrior", "Epic", { hp = 60 })

gear("mage_staff_1", "Ramo Arcano", "weapon", "Mage", "Common", { dmg = 3 })
gear("mage_staff_2", "Bastone delle Braci", "weapon", "Mage", "Rare", { dmg = 9 })
gear("mage_staff_3", "Bastone Astrale", "weapon", "Mage", "Epic", { dmg = 18 })
gear("mage_robe_1", "Veste del Novizio", "armor", "Mage", "Common", { hp = 8 })
gear("mage_robe_2", "Veste Runica", "armor", "Mage", "Rare", { hp = 22 })
gear("mage_robe_3", "Veste del Magister", "armor", "Mage", "Epic", { hp = 45 })

gear("archer_bow_1", "Arco Corto", "weapon", "Archer", "Common", { dmg = 3 })
gear("archer_bow_2", "Arco Lungo", "weapon", "Archer", "Rare", { dmg = 8 })
gear("archer_bow_3", "Arco del Falco", "weapon", "Archer", "Epic", { dmg = 15 })
gear("archer_armor_1", "Giaco di Cuoio", "armor", "Archer", "Common", { hp = 10 })
gear("archer_armor_2", "Corpetto da Cacciatore", "armor", "Archer", "Rare", { hp = 24 })
gear("archer_armor_3", "Manto della Selva", "armor", "Archer", "Epic", { hp = 48 })

gear("charm_minor", "Amuleto Minore", "charm", nil, "Uncommon", { fortune = 0.04 })
gear("charm_major", "Amuleto Maggiore", "charm", nil, "Epic", { fortune = 0.08, hp = 10 })

for potionId, potion in PotionConfig.Potions do
	item({
		id = potionId,
		name = potion.name,
		category = "potions",
		rarity = potion.rarity,
		family = potion.family,
		description = "Consumabile. Stessa famiglia: sostituzione, non stack.",
	})
end

function LootConfig.GetItem(id)
	return LootConfig.Items[id]
end

local function add(list, entry)
	table.insert(list, entry)
end

-- Tabella per arena. Il filtro di classe avviene al momento del drop.
function LootConfig.DropsFor(enemy)
	local arena = enemy.arena
	local list = {}
	add(list, { itemId = "mat_arena_" .. arena, category = "materials", chance = 0.45, min = 1, max = 3 })
	add(list, { itemId = "relic_arena_" .. arena, category = "collectibles", chance = 0.035, min = 1, max = 1, cap = 0.2 })
	add(list, { itemId = "health_common", category = "potions", chance = 0.08, min = 1, max = 1 })
	if arena >= 4 then
		add(list, { itemId = "health_rare", category = "potions", chance = 0.035, min = 1, max = 1 })
		add(list, { itemId = "damage_common", category = "potions", chance = 0.04, min = 1, max = 1 })
	end
	if arena >= 8 then
		add(list, { itemId = "fortune_common", category = "potions", chance = 0.04, min = 1, max = 1 })
		add(list, { itemId = "damage_rare", category = "potions", chance = 0.025, min = 1, max = 1 })
	end
	if arena >= 12 then
		add(list, { itemId = "health_epic", category = "potions", chance = 0.02, min = 1, max = 1 })
		add(list, { itemId = "fortune_rare", category = "potions", chance = 0.02, min = 1, max = 1 })
	end
	if enemy.rarity == "Boss" then
		add(list, { itemId = "health_legendary", category = "potions", chance = 0.08, min = 1, max = 1, cap = 0.35 })
		add(list, { itemId = "damage_epic", category = "potions", chance = 0.06, min = 1, max = 1, cap = 0.3 })
		add(list, { itemId = "charm_major", category = "equipment", chance = 0.05, min = 1, max = 1, cap = 0.25 })
	elseif enemy.rarity == "Elite" or enemy.rarity == "Rare" then
		add(list, { itemId = "charm_minor", category = "equipment", chance = 0.04, min = 1, max = 1, cap = 0.25 })
	end

	local tier = arena >= 12 and 3 or (arena >= 6 and 2 or 1)
	local suffix = "_" .. tostring(tier)
	local chance = enemy.rarity == "Boss" and 0.12 or 0.035
	for _, classId in { "Warrior", "Mage", "Archer" } do
		local prefix = string.lower(classId)
		local weapon = prefix .. (classId == "Warrior" and "_blade" or (classId == "Mage" and "_staff" or "_bow")) .. suffix
		local armor = prefix .. (classId == "Mage" and "_robe" or "_armor") .. suffix
		add(list, { itemId = weapon, category = "equipment", chance = chance, min = 1, max = 1, cap = 0.4, classId = classId })
		add(list, { itemId = armor, category = "equipment", chance = chance * 0.9, min = 1, max = 1, cap = 0.4, classId = classId })
	end
	return list
end

return LootConfig
