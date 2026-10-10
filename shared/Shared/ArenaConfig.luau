-- 15 arene del Mondo 1. Requisiti PROVVISORI.
-- L'Arena 15 richiede Maestria 48, quindi è raggiungibile prima del Rebirth.
-- L'accesso è individuale per eroe. L'Arena 1 è sempre gratuita.

local ArenaConfig = {
	{
		index = 1,
		name = "Cripta Iniziale",
		mastery = 0,
		cost = 0,
		color = Color3.fromRGB(96, 140, 96),
	},
	{
		index = 2,
		name = "Ossario",
		mastery = 5,
		cost = 180,
		color = Color3.fromRGB(150, 150, 158),
	},
	{
		index = 3,
		name = "Accampamento Goblin",
		mastery = 8,
		cost = 256,
		color = Color3.fromRGB(92, 148, 72),
	},
	{
		index = 4,
		name = "Radura dei Lupi",
		mastery = 12,
		cost = 363,
		color = Color3.fromRGB(110, 124, 86),
	},
	{
		index = 5,
		name = "Fortezza dei Banditi",
		mastery = 15,
		cost = 515,
		color = Color3.fromRGB(150, 112, 72),
	},
	{
		index = 6,
		name = "Palude",
		mastery = 18,
		cost = 732,
		color = Color3.fromRGB(70, 130, 110),
	},
	{
		index = 7,
		name = "Nido dei Ragni",
		mastery = 22,
		cost = 1039,
		color = Color3.fromRGB(120, 70, 90),
	},
	{
		index = 8,
		name = "Cappella del Culto",
		mastery = 25,
		cost = 1476,
		color = Color3.fromRGB(110, 70, 140),
	},
	{
		index = 9,
		name = "Gola degli Orchi",
		mastery = 28,
		cost = 2096,
		color = Color3.fromRGB(130, 90, 60),
	},
	{
		index = 10,
		name = "Rocca del Warlord",
		mastery = 32,
		cost = 2976,
		color = Color3.fromRGB(150, 64, 48),
	},
	{
		index = 11,
		name = "Velario Spettrale",
		mastery = 35,
		cost = 4225,
		color = Color3.fromRGB(90, 110, 150),
	},
	{
		index = 12,
		name = "Sala dei Golem",
		mastery = 38,
		cost = 6000,
		color = Color3.fromRGB(100, 110, 120),
	},
	{
		index = 13,
		name = "Fenditura Demoniaca",
		mastery = 42,
		cost = 8520,
		color = Color3.fromRGB(160, 50, 50),
	},
	{
		index = 14,
		name = "Cortile dei Cavalieri",
		mastery = 46,
		cost = 12099,
		color = Color3.fromRGB(70, 78, 110),
	},
	{
		index = 15,
		name = "Trono dell'Abisso",
		mastery = 48,
		cost = 17180,
		color = Color3.fromRGB(70, 40, 110),
	},
}

local byIndex = {}
for _, arena in ArenaConfig do
	byIndex[arena.index] = arena
end

function ArenaConfig.Get(index)
	return byIndex[index]
end

return ArenaConfig
