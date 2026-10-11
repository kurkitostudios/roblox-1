local shared = require(script.Parent.SharedLoader)
local QuestConfig = shared("QuestConfig")
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
					Rules.GrantEarnedCoins(data, quest.coins, shared("GameConfig").MaxCoins)
				end
				local message = "Quest complete: " .. quest.name
				if quest.coins and quest.coins > 0 then
					message ..= ". +" .. tostring(quest.coins) .. " Coins"
				end
				Notifier.Send(player, "quest", message)
			end
		end
	end
	PlayerData.MarkDirty(player, false)
end

return QuestService
