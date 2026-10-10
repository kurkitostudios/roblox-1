-- Missioni. Almeno la prima è completabile subito nell'Arena 1.
-- Gli eroi sbloccati restano sbloccati anche dopo il Rebirth.

local QuestConfig = {
	{
		id = "prova_del_ferro",
		name = "Trial of Iron",
		description = "Defeat 10 enemies. Unlocks the next hero.",
		metric = "kills",
		goal = 10,
		coins = 150,
		unlockNextHero = true,
	},
	{
		id = "cacciatore",
		name = "Hunter",
		description = "Defeat 30 enemies. Unlocks the next hero that is still locked.",
		metric = "kills",
		goal = 30,
		coins = 400,
		unlockNextHero = true,
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
