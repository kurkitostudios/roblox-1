-- Vendita provvisoria di materiali e collezionabili. Non tocca Pet, equip o pozioni.

local shared = require(script.Parent.SharedLoader)
local MerchantConfig = shared("MerchantConfig")
local LootConfig = shared("LootConfig")
local Rules = shared("Rules")
local Strings = shared("Strings")
local WorldLayout = shared("WorldLayout")
local GameConfig = shared("GameConfig")
local PlayerData = require(script.Parent.PlayerDataService)
local HeroService = require(script.Parent.HeroService)
local Notifier = require(script.Parent.Notifier)

local MerchantService = {}

local function inRange(player)
	return HeroService.Near(player, WorldLayout.Merchant(), WorldLayout.Radii.Merchant)
end

function MerchantService.Open(player)
	if not inRange(player) then
		return { ok = false, error = Strings.Error.MoveCloserMerchant }
	end
	local remote = nil
	-- Il remote è letto dal contesto solo dopo Bind. Open è chiamato dal PromptRouter.
	if MerchantService.Remote then
		remote = MerchantService.Remote
	end
	if remote then
		remote:FireClient(player)
	end
	return { ok = true }
end

function MerchantService.Sell(player, itemId, count)
	if not inRange(player) then
		return { ok = false, error = Strings.Error.MoveCloserMerchant }
	end
	if type(itemId) ~= "string" then
		return { ok = false, error = Strings.Error.InvalidItem }
	end
	local amount = count
	if amount == nil then
		amount = 1
	end
	if type(amount) ~= "number" or amount ~= math.floor(amount) or amount < 1 or amount > MerchantConfig.MaxPerSale then
		return { ok = false, error = Strings.Error.InvalidRequest }
	end
	local def = LootConfig.GetItem(itemId)
	if not def then
		return { ok = false, error = Strings.Error.InvalidItem }
	end
	local rate = MerchantConfig.Rates[def.category]
	if not rate then
		return { ok = false, error = Strings.Error.MerchantNoBuy }
	end
	local data = PlayerData.Get(player)
	if not data then
		return { ok = false, error = Strings.Error.DataNotLoaded }
	end
	local bucket = data.inventory[def.category]
	local owned = bucket and bucket[itemId] or 0
	if owned < amount then
		return { ok = false, error = Strings.Error.NothingToSell }
	end
	local ok = Rules.AddStack(bucket, itemId, -amount, shared("GameConfig").Inventory.MaxStack)
	if not ok then
		return { ok = false, error = Strings.Error.NothingToSell }
	end
	local payout = rate * amount
	data.coins = Rules.AddCoins(data.coins, payout, GameConfig.MaxCoins)
	PlayerData.MarkDirty(player, true)
	PlayerData.Save(player, false)
	Notifier.Send(player, "reward", Strings.SoldLoot(def.name, amount, payout))
	return { ok = true, coins = payout, itemId = itemId, count = amount }
end

function MerchantService.Bind(ctx)
	MerchantService.Remote = ctx.remotes.OpenMerchant
	ctx.services.RemotesService.Bind(ctx, "SellLoot", GameConfig.Rates.SellLoot, function(player, payload)
		return MerchantService.Sell(player, payload.itemId, payload.count)
	end)
end

return MerchantService
