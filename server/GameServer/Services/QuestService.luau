local shared = require(script.Parent.SharedLoader)
local QuestConfig = shared("QuestConfig")
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Notifier)

local QuestService = {}

function QuestService.OnKill(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	for _, quest in ipairs(QuestConfig) do
		if quest.metric == "kills" then
			local completedNow = Rules.ProgressQuest(data, quest, 1)
			if completedNow then
				if quest.coins and quest.coins > 0 then
					-- Ricompensa fissa di missione: non applica il bonus Rebirth.
					data.coins = Rules.AddCoins(data.coins, quest.coins, shared("GameConfig").MaxCoins)
				end
				local unlocked = nil
				if quest.unlockNextHero then
					unlocked = Rules.UnlockNextHero(data, HeroConfig.Order)
				end
				local message = "Missione completata: " .. quest.name
				if unlocked then
					message ..= ". Eroe sbloccato: " .. HeroConfig.Classes[unlocked].displayName
				end
				if quest.coins and quest.coins > 0 then
					message ..= ". +" .. tostring(quest.coins) .. " monete"
				end
				Notifier.Send(player, "quest", message)
			end
		end
	end
	PlayerData.MarkDirty(player, false)
end

return QuestService
