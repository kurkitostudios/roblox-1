-- Distanze massime dei testi 3D. Modifica solo questa tabella.
-- La UI permanente (HP, XP, Coins, menu) non usa queste distanze.

local WorldTextConfig = {
	MaxDistance = {
		EnemyName = 45,
		EnemyHealth = 45,
		EnemyRarity = 40,
		ArenaName = 65,
		InfoSign = 35,
		EggPrice = 30,
		EggPetInfo = 30,
		Interaction = 20,
		UpgradeStation = 25,
		RebirthInfo = 30,
		Podium = 65,
		LobbyTitle = 65,
		DamageNumber = 48,
	},
	PromptDistance = {
		Default = 12,
		Arena = 14,
		Egg = 12,
		Service = 12,
		Portal = 12,
	},
	-- Il fade inizia a questa frazione della distanza massima.
	FadeStart = 0.68,
	UpdateInterval = 0.3,
	Tag = "KurkitoWorldText",
}

function WorldTextConfig.Distance(category)
	return WorldTextConfig.MaxDistance[category] or WorldTextConfig.MaxDistance.InfoSign
end

function WorldTextConfig.Prompt(category)
	return WorldTextConfig.PromptDistance[category] or WorldTextConfig.PromptDistance.Default
end

function WorldTextConfig.Mark(gui, category)
	if not gui then
		return gui
	end
	local distance = WorldTextConfig.Distance(category)
	gui:SetAttribute("KurkitoText", category)
	gui:SetAttribute("KurkitoMaxDistance", distance)
	if gui:IsA("BillboardGui") then
		gui.MaxDistance = distance
		gui.AlwaysOnTop = category == "DamageNumber"
		gui.LightInfluence = 0
	end
	local ok, collection = pcall(function()
		return game:GetService("CollectionService")
	end)
	if ok and collection then
		collection:AddTag(gui, WorldTextConfig.Tag)
	end
	return gui
end

return WorldTextConfig
