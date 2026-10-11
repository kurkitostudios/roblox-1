-- Distanze massime dei testi 3D. Modifica solo questa tabella.
-- La UI permanente (HP, XP, Coins, menu) non usa queste distanze.

local WorldTextConfig = {
	MaxDistance = {
		EnemyName = 36,
		EnemyHealth = 32,
		EnemyRarity = 28,
		ArenaName = 40,
		InfoSign = 26,
		EggPrice = 22,
		EggPetInfo = 22,
		Interaction = 16,
		UpgradeStation = 22,
		RebirthInfo = 24,
		Podium = 26,
		LobbyTitle = 34,
		DamageNumber = 42,
		Merchant = 22,
	},
	PromptDistance = {
		Default = 12,
		Arena = 14,
		Egg = 12,
		Service = 12,
		Portal = 12,
		Merchant = 12,
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
