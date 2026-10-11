local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local HeroConfig = shared("HeroConfig")
local AbilityConfig = shared("AbilityConfig")
local Rules = shared("Rules")
local Strings = shared("Strings")
local PlayerData = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Notifier)

local MasteryService = {}

function MasteryService.AddBaseXp(player, baseAmount)
	local data = PlayerData.Get(player)
	local hero = data and data.heroes and data.heroes.Warrior
	if not data or type(hero) ~= "table" then
		return { applied = 0, levels = 0, capped = false }
	end
	local previous = hero.mastery or 0
	local result = Rules.ApplyXp(hero, baseAmount, HeroConfig.RebirthXpBonus, GameConfig.MasteryCurve, GameConfig.MaxMastery)
	if result.applied > 0 or result.levels > 0 then
		PlayerData.MarkDirty(player, false)
	end
	if result.levels > 0 then
		Notifier.Send(player, "mastery", Strings.MasteryUp(hero.mastery, result.levels))
		for _, ability in ipairs(AbilityConfig.Warrior) do
			local required = ability.masteryRequired or 0
			if required > previous and required <= hero.mastery then
				Notifier.Send(player, "skill", Strings.SkillUnlocked(ability.name))
			end
		end
	end
	return result
end

return MasteryService
