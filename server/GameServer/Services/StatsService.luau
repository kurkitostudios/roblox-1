local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local Loadout = shared("Loadout")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local RuntimeState = require(script.Parent.RuntimeState)

local StatsService = {}

function StatsService.Compute(player)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return nil
	end
	local heroId = "Warrior"
	local classDef = HeroConfig.Classes[heroId]
	local hero = data.heroes[heroId]
	if type(hero) ~= "table" then
		return nil
	end
	local runtime = RuntimeState.Get(player)
	local now = os.clock()
	local buffs = runtime.buffs
	local doubleDamage = false
	local doubleFortune = false
	local damageEffect = runtime.effects.DoubleDamage
	local fortuneEffect = runtime.effects.DoubleFortune
	if damageEffect and damageEffect.expiresAt > now then
		doubleDamage = true
	end
	if fortuneEffect and fortuneEffect.expiresAt > now then
		doubleFortune = true
	end
	local fury = 0
	local hawk = 0
	local hawkRange = 0
	local reduction = 0
	if buffs.furyUntil > now then
		fury = buffs.furyBonus
	end
	if buffs.hawkUntil > now then
		hawk = buffs.hawkBonus
		hawkRange = buffs.hawkRange
	end
	if buffs.defenseUntil > now then
		reduction = buffs.defenseReduction
	end
	local talentHp, talentDmg = Loadout.TalentRates()
	return Rules.ComputeStats({
		classId = heroId,
		classDef = classDef,
		hero = hero,
		gearBonus = Loadout.GearBonus(data, heroId),
		petBonus = Loadout.PetBonus(data),
		talentHpPct = talentHp,
		talentDmgPct = talentDmg,
		doubleDamage = doubleDamage,
		doubleFortune = doubleFortune,
		furyBonus = fury,
		hawkBonus = hawk,
		hawkRange = hawkRange,
		damageReduction = reduction,
	})
end

return StatsService
