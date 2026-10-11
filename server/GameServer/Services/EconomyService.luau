local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)

local EconomyService = {}

function EconomyService.GrantBase(player, baseAmount)
	local data = PlayerData.Get(player)
	local hero = data and data.heroes and data.heroes.Warrior
	if not data or type(hero) ~= "table" then
		return 0
	end
	local amount = Rules.RewardCoins(baseAmount, hero.rebirths, HeroConfig.RebirthCoinBonus, GameConfig.MaxCoins)
	if amount <= 0 then
		return 0
	end
	local gained = Rules.GrantEarnedCoins(data, amount, GameConfig.MaxCoins)
	PlayerData.MarkDirty(player, false)
	return gained
end

function EconomyService.TrySpend(player, amount)
	local data = PlayerData.Get(player)
	if not data then
		return false, "Data is not loaded."
	end
	local ok, newCoins, reason = Rules.TrySpend(data.coins, amount)
	if not ok then
		return false, reason
	end
	data.coins = newCoins
	PlayerData.MarkDirty(player, true)
	return true, nil
end

return EconomyService
