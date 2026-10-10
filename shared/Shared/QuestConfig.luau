-- Missioni. Almeno la prima è completabile subito nell'Arena 1.
-- Gli eroi sbloccati restano sbloccati anche dopo il Rebirth.

local QuestConfig = {
	{
		id = "prova_del_ferro",
		name = "Prova del Ferro",
		description = "Sconfiggi 10 nemici. Sblocca il prossimo eroe.",
		metric = "kills",
		goal = 10,
		coins = 150,
		unlockNextHero = true,
	},
	{
		id = "cacciatore",
		name = "Cacciatore",
		description = "Sconfiggi 30 nemici. Sblocca il prossimo eroe ancora bloccato.",
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
