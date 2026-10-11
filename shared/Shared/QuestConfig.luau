-- Missioni. Almeno la prima è completabile subito nell'Arena 1.
-- Gli eroi sbloccati restano sbloccati anche dopo il Rebirth.

local QuestConfig = {
	{
		id = "prova_del_ferro",
		name = "First Hunt",
		description = "Defeat 10 enemies in the Grave Wilds.",
		metric = "kills",
		goal = 10,
		coins = 150,
		unlockNextHero = false,
	},
	{
		id = "cacciatore",
		name = "Hunter",
		description = "Defeat 30 enemies.",
		metric = "kills",
		goal = 30,
		coins = 400,
		unlockNextHero = false,
	},
}

local byId = {}
for _, quest in QuestConfig do
	byId[quest.id] = quest
end

function QuestConfig.Get(id)
	return byId[id]
end

return QuestConfig
