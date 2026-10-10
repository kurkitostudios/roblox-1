-- Bonus di equipaggiamento e Pet, condivisi da server e client.

local LootConfig = require(script.Parent.LootConfig)
local PetConfig = require(script.Parent.PetConfig)
local Rules = require(script.Parent.Rules)

local Loadout = {}

function Loadout.GearBonus(data, heroId)
	local total = { hp = 0, dmg = 0, fortune = 0 }
	local hero = data.heroes and data.heroes[heroId]
	if not hero or type(hero.equippedGear) ~= "table" then
		return total
	end
	for _, uid in pairs(hero.equippedGear) do
		if type(uid) == "string" and uid ~= "" then
			for _, entry in ipairs(data.inventory.equipment) do
				if entry.uid == uid then
					local def = LootConfig.GetItem(entry.itemId)
					if def and def.bonuses then
						total.hp += def.bonuses.hp or 0
						total.dmg += def.bonuses.dmg or 0
						total.fortune += def.bonuses.fortune or 0
					end
				end
			end
		end
	end
	return total
end

function Loadout.PetBonus(data)
	local parts = {}
	for _, uid in ipairs(data.equippedPets or {}) do
		if uid ~= "" then
			for _, pet in ipairs(data.pets or {}) do
				if pet.uid == uid then
					table.insert(parts, PetConfig.BonusFor(pet.petId, pet.evolution))
				end
			end
		end
	end
	return Rules.SumBonuses(parts)
end

function Loadout.TalentRates()
	local hpPct = 0.03
	local dmgPct = 0.03
	local HeroConfig = require(script.Parent.HeroConfig)
	for _, talent in ipairs(HeroConfig.Talents) do
		if talent.id == "vitality" and talent.hpPct then
			hpPct = talent.hpPct
		elseif talent.id == "power" and talent.dmgPct then
			dmgPct = talent.dmgPct
		end
	end
	return hpPct, dmgPct
end

return Loadout
