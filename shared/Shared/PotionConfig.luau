-- Pozioni. Durate e potenze PROVVISORIE.
-- Anti-stack: una sola pozione attiva per famiglia.
-- Usarne un'altra della stessa famiglia SOSTITUISCE durata e potenza.
-- Non moltiplica l'effetto e non crea stack infiniti.

local PotionConfig = {
	Families = { "HealthRegen", "DoubleDamage", "DoubleFortune" },
	RarityDuration = {
		Common = 30,
		Rare = 120,
		Epic = 300,
		Legendary = 600,
		Mythic = 1200,
	},
	RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" },
	RarityColor = {
		Common = Color3.fromRGB(180, 180, 180),
		Rare = Color3.fromRGB(80, 140, 220),
		Epic = Color3.fromRGB(160, 80, 210),
		Legendary = Color3.fromRGB(220, 170, 60),
		Mythic = Color3.fromRGB(220, 80, 120),
	},
	-- Scala visiva dell'ampolla. Non è un asset definitivo.
	RarityScale = {
		Common = 1,
		Rare = 1.15,
		Epic = 1.3,
		Legendary = 1.5,
		Mythic = 1.75,
	},
	-- HP rigenerati ogni secondo. PROVVISORIO.
	HealthPerSecond = {
		Common = 4,
		Rare = 8,
		Epic = 14,
		Legendary = 22,
		Mythic = 34,
	},
}

local potions = {}

local function addFamily(family, prefix, label, tint)
	for _, rarity in PotionConfig.RarityOrder do
		local id = prefix .. "_" .. string.lower(rarity)
		potions[id] = {
			id = id,
			name = label .. " " .. rarity,
			description = family == "HealthRegen" and "Restores health over time. A new potion of the same family replaces this one."
				or family == "DoubleDamage" and "Doubles damage. A new potion of the same family replaces this one."
				or "Doubles fortune. A new potion of the same family replaces this one.",
			family = family,
			rarity = rarity,
			duration = PotionConfig.RarityDuration[rarity],
			healthPerSecond = family == "HealthRegen" and PotionConfig.HealthPerSecond[rarity] or 0,
			damageMultiplier = family == "DoubleDamage" and 2 or 1,
			fortuneMultiplier = family == "DoubleFortune" and 2 or 1,
			color = tint:Lerp(PotionConfig.RarityColor[rarity], 0.35),
			scale = PotionConfig.RarityScale[rarity],
		}
	end
end

addFamily("HealthRegen", "health", "Health Potion", Color3.fromRGB(220, 70, 80))
addFamily("DoubleDamage", "damage", "Damage Potion", Color3.fromRGB(230, 120, 40))
addFamily("DoubleFortune", "fortune", "Fortune Potion", Color3.fromRGB(80, 200, 140))

PotionConfig.Potions = potions

function PotionConfig.Get(id)
	return potions[id]
end

return PotionConfig
