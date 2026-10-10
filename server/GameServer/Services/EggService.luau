-- Le uova Robux non chiamano MarketplaceService: non esistono Product ID verificati.

local shared = require(script.Parent.SharedLoader)
local PetConfig = shared("PetConfig")
local Rules = shared("Rules")
local Strings = shared("Strings")
local WorldLayout = shared("WorldLayout")
local PlayerData = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local HeroService = require(script.Parent.HeroService)
local PetService = require(script.Parent.PetService)
local Notifier = require(script.Parent.Notifier)

local EggService = {}

local function oddsText(pool)
	local lines = {}
	for _, entry in ipairs(pool) do
		local pet = PetConfig.Get(entry.petId)
		local percent = math.floor((entry.chance * 1000) + 0.5) / 10
		table.insert(lines, (pet and pet.name or entry.petId) .. " (" .. (pet and pet.rarity or "?") .. ") " .. tostring(percent) .. "%")
	end
	return table.concat(lines, "\n")
end

function EggService.OddsText(pool)
	return oddsText(pool)
end

function EggService.OpenArena(player, arenaIndex)
	if type(arenaIndex) ~= "number" or arenaIndex ~= math.floor(arenaIndex) then
		return { ok = false, error = "Invalid egg." }
	end
	local egg = PetConfig.GetEgg(arenaIndex)
	if not egg or egg.enabled ~= true or egg.kind ~= "coins" then
		return { ok = false, error = "That egg is not available." }
	end
	local position = WorldLayout.FindArenaEgg(arenaIndex)
	if not position or not HeroService.Near(player, position, WorldLayout.Radii.Egg) then
		return { ok = false, error = "Move closer to the egg." }
	end
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return { ok = false, error = "Select a hero." }
	end
	local hero = data.heroes[data.selectedHero]
	if not hero.unlockedArenas[tostring(arenaIndex)] then
		return { ok = false, error = "Unlock the matching arena with your active hero." }
	end
	local paid, payError = EconomyService.TrySpend(player, egg.cost)
	if not paid then
		return { ok = false, error = payError }
	end
	local rng = Random.new()
	local rolled = Rules.RollWeighted(egg.pool, function()
		return rng:NextNumber()
	end)
	if not rolled then
		data.coins = Rules.AddCoins(data.coins, egg.cost, shared("GameConfig").MaxCoins)
		PlayerData.MarkDirty(player, true)
		return { ok = false, error = "Egg table is empty. Coins refunded." }
	end
	local pet, grantError = PetService.Grant(player, rolled.petId, "Normal")
	if not pet then
		data.coins = Rules.AddCoins(data.coins, egg.cost, shared("GameConfig").MaxCoins)
		PlayerData.MarkDirty(player, true)
		return { ok = false, error = (grantError or "Pet was not granted.") .. " Coins refunded." }
	end
	PlayerData.Save(player, false)
	local def = PetConfig.Get(rolled.petId)
	Notifier.Send(player, "pet", Strings.PetHatched(def and def.name or rolled.petId, def and def.rarity or ""))
	return { ok = true, petId = rolled.petId, name = def and def.name or rolled.petId }
end

function EggService.InspectRobux(player, specialIndex)
	if type(specialIndex) ~= "number" then
		return { ok = false, error = "Invalid showcase." }
	end
	local egg = PetConfig.SpecialEggs[specialIndex]
	if not egg then
		return { ok = false, error = "Invalid showcase." }
	end
	local position = WorldLayout.FindSpecialEgg(specialIndex)
	if position and not HeroService.Near(player, position, WorldLayout.Radii.Egg) and not HeroService.InLobby(player) then
		return { ok = false, error = "Move closer to the showcase." }
	end
	Notifier.Send(player, "info", egg.name .. " cannot be purchased. No Product ID is configured. Odds are on the sign.")
	return {
		ok = false,
		error = "Robux purchases are disabled in this build.",
		odds = oddsText(egg.pool),
	}
end

function EggService.Bind(ctx)
	ctx.services.RemotesService.Bind(ctx, "OpenEgg", shared("GameConfig").Rates.OpenEgg, function(player, payload)
		if payload.kind == "robux" then
			return EggService.InspectRobux(player, payload.specialIndex)
		end
		return EggService.OpenArena(player, payload.arenaIndex)
	end)
end

return EggService
