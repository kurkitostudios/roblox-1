local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local AbilityConfig = shared("AbilityConfig")
local Rules = shared("Rules")
local Strings = shared("Strings")
local PlayerData = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local HeroService = require(script.Parent.HeroService)
local Notifier = require(script.Parent.Notifier)

local UpgradeService = {}

local function heroOf(player)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return nil, nil, "No active hero."
	end
	return data, data.heroes[data.selectedHero], nil
end

function UpgradeService.UpgradeStat(player, statId)
	if not HeroService.InLobby(player) and not HeroService.Near(player, shared("WorldLayout").Upgrades(), shared("WorldLayout").Radii.Upgrade) then
		return { ok = false, error = "Upgrade in the lobby or at the upgrade post." }
	end
	local data, hero, reason = heroOf(player)
	if not hero then
		return { ok = false, error = reason }
	end
	local classDef = HeroConfig.Classes[data.selectedHero]
	local allowed = false
	for _, candidate in ipairs(classDef.stats) do
		if candidate == statId then
			allowed = true
		end
	end
	if not allowed then
		return { ok = false, error = "That stat is not available for this hero." }
	end
	local statDef = HeroConfig.StatDefs[statId]
	local cost = Rules.StatCost(hero.stats[statId], statDef)
	if not cost then
		return { ok = false, error = "Maximum level." }
	end
	local paid, payError = EconomyService.TrySpend(player, cost)
	if not paid then
		return { ok = false, error = payError }
	end
	local upgraded, upgradeError = Rules.UpgradeStat(hero, statId, statDef.maxLevel)
	if not upgraded then
		data.coins = Rules.AddCoins(data.coins, cost, shared("GameConfig").MaxCoins)
		PlayerData.MarkDirty(player, true)
		return { ok = false, error = upgradeError }
	end
	PlayerData.MarkDirty(player, true)
	HeroService.Refresh(player, false)
	Notifier.Send(player, "info", Strings.StatLevel(statDef.label, hero.stats[statId]))
	return { ok = true }
end

function UpgradeService.SpendPoint(player, kind, id)
	if not HeroService.InLobby(player) then
		return { ok = false, error = "Spend points in the lobby or at the hero post." }
	end
	local data, hero, reason = heroOf(player)
	if not hero then
		return { ok = false, error = reason }
	end
	if type(kind) ~= "string" or type(id) ~= "string" then
		return { ok = false, error = "Invalid request." }
	end
	local maxRank = nil
	local unlocked = true
	if kind == "skill" then
		maxRank = AbilityConfig.MaxRank
		local ability = nil
		for _, candidate in ipairs(AbilityConfig[data.selectedHero]) do
			if candidate.id == id then
				ability = candidate
			end
		end
		if not ability then
			return { ok = false, error = "Unknown ability." }
		end
		unlocked = Rules.AbilityUnlocked(hero.mastery, ability)
	elseif kind == "talent" then
		local talent = nil
		for _, candidate in ipairs(HeroConfig.Talents) do
			if candidate.id == id then
				talent = candidate
			end
		end
		if not talent then
			return { ok = false, error = "Unknown talent." }
		end
		maxRank = talent.maxRank
	else
		return { ok = false, error = "Invalid type." }
	end
	local ok, spendError = Rules.SpendPoint(hero, kind, id, maxRank, unlocked)
	if not ok then
		return { ok = false, error = spendError }
	end
	PlayerData.MarkDirty(player, true)
	HeroService.Refresh(player, false)
	Notifier.Send(player, "info", "Point spent. Skill Points left: " .. tostring(hero.skillPoints))
	return { ok = true }
end

function UpgradeService.Bind(ctx)
	local rates = shared("GameConfig").Rates
	ctx.services.RemotesService.Bind(ctx, "UpgradeStat", rates.UpgradeStat, function(player, payload)
		return UpgradeService.UpgradeStat(player, payload.statId)
	end)
	ctx.services.RemotesService.Bind(ctx, "SpendSkillPoint", rates.SpendSkillPoint, function(player, payload)
		return UpgradeService.SpendPoint(player, payload.kind, payload.id)
	end)
end

return UpgradeService
