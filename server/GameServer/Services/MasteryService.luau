local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Notifier)

local MasteryService = {}

function MasteryService.AddBaseXp(player, baseAmount)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return { applied = 0, levels = 0, capped = false }
	end
	local hero = data.heroes[data.selectedHero]
	local result = Rules.ApplyXp(hero, baseAmount, HeroConfig.RebirthXpBonus, GameConfig.MasteryCurve, GameConfig.MaxMastery)
	if result.applied > 0 or result.levels > 0 then
		PlayerData.MarkDirty(player, false)
	end
	if result.levels > 0 then
		Notifier.Send(player, "xp", "Maestria " .. tostring(hero.mastery) .. " (+" .. tostring(result.levels) .. " Skill Point)")
	end
	return result
end

return MasteryService
