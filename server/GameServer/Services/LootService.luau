local shared = require(script.Parent.SharedLoader)
local LootConfig = shared("LootConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local StatsService = require(script.Parent.StatsService)
local InventoryService = require(script.Parent.InventoryService)
local Notifier = require(script.Parent.Notifier)

local LootService = {}

function LootService.GrantEnemyDrops(player, enemyDef)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return
	end
	local stats = StatsService.Compute(player)
	local fortune = stats and stats.fortune or 1
	local rng = Random.new()
	local grants = Rules.RollDrops(LootConfig.DropsFor(enemyDef), fortune, function()
		return rng:NextNumber()
	end, "Warrior")
	local accepted = InventoryService.Grant(player, grants, "Warrior")
	for _, drop in ipairs(accepted) do
		local suffix = drop.count > 1 and (" x" .. tostring(drop.count)) or ""
		Notifier.Send(player, "drop", drop.name .. suffix)
	end
end

return LootService
