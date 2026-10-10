-- Regole deterministiche, senza servizi Roblox.
-- Servizi e test condividono queste funzioni.

local Rules = {}

function Rules.DeepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, child in pairs(value) do
		out[Rules.DeepCopy(key)] = Rules.DeepCopy(child)
	end
	return out
end

function Rules.IsFinite(n)
	return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end

function Rules.Clamp(n, minValue, maxValue)
	if n < minValue then
		return minValue
	end
	if n > maxValue then
		return maxValue
	end
	return n
end

function Rules.FormatNumber(n)
	local value = math.floor(tonumber(n) or 0)
	local negative = value < 0
	local digits = tostring(math.abs(value))
	local reversed = digits:reverse():gsub("(%d%d%d)", "%1.")
	local formatted = reversed:reverse()
	if formatted:sub(1, 1) == "." then
		formatted = formatted:sub(2)
	end
	if negative then
		return "-" .. formatted
	end
	return formatted
end

function Rules.XpToNext(mastery, curve, maxMastery)
	maxMastery = maxMastery or 50
	if mastery >= maxMastery then
		return nil
	end
	local step = mastery + 1
	return math.max(1, math.floor(curve.base * (step ^ curve.exponent)))
end

function Rules.ApplyXp(hero, baseAmount, rebirthBonusPer, curve, maxMastery)
	maxMastery = maxMastery or 50
	hero.skillPoints = hero.skillPoints or 0
	hero.xp = hero.xp or 0
	hero.mastery = hero.mastery or 0
	hero.rebirths = hero.rebirths or 0
	if hero.mastery >= maxMastery then
		hero.mastery = maxMastery
		hero.xp = 0
		return { applied = 0, levels = 0, capped = true }
	end
	if not Rules.IsFinite(baseAmount) or baseAmount <= 0 then
		return { applied = 0, levels = 0, capped = false }
	end
	local multiplier = 1 + (hero.rebirths or 0) * rebirthBonusPer
	local amount = math.max(0, math.floor(baseAmount * multiplier + 0.5))
	hero.xp += amount
	local levels = 0
	while hero.mastery < maxMastery do
		local need = Rules.XpToNext(hero.mastery, curve, maxMastery)
		if not need or hero.xp < need then
			break
		end
		hero.xp -= need
		hero.mastery += 1
		hero.skillPoints += 1
		levels += 1
	end
	if hero.mastery >= maxMastery then
		hero.mastery = maxMastery
		hero.xp = 0
	end
	return { applied = amount, levels = levels, capped = hero.mastery >= maxMastery }
end

function Rules.RewardCoins(baseAmount, rebirths, bonusPer, maxCoins)
	if not Rules.IsFinite(baseAmount) or baseAmount <= 0 then
		return 0
	end
	local amount = math.floor(baseAmount * (1 + (rebirths or 0) * bonusPer) + 0.5)
	if amount < 0 then
		return 0
	end
	if maxCoins and amount > maxCoins then
		return maxCoins
	end
	return amount
end

function Rules.AddCoins(coins, amount, maxCoins)
	if not Rules.IsFinite(amount) or amount <= 0 then
		return coins
	end
	local sum = math.floor(coins + amount)
	if maxCoins and sum > maxCoins then
		return maxCoins
	end
	return sum
end

function Rules.TrySpend(coins, amount)
	if not Rules.IsFinite(amount) then
		return false, coins, "Invalid amount."
	end
	amount = math.floor(amount)
	if amount < 0 then
		return false, coins, "Invalid amount."
	end
	if amount == 0 then
		return true, coins, nil
	end
	if coins < amount then
		return false, coins, "Not enough coins."
	end
	return true, coins - amount, nil
end

function Rules.StatCost(level, statDef)
	if type(level) ~= "number" or not statDef then
		return nil
	end
	if level >= statDef.maxLevel then
		return nil
	end
	return math.max(1, math.floor(statDef.baseCost * (statDef.growth ^ (level - 1))))
end

function Rules.StatPreview(level, classDef, statId)
	local current = Rules.StatValue(level, classDef, statId)
	local nxt = Rules.StatValue(level + 1, classDef, statId)
	return current, nxt, nxt - current
end

function Rules.StatValue(level, classDef, statId)
	if statId == "HP" then
		return classDef.baseHP + (level - 1) * classDef.hpPerLevel
	elseif statId == "DMG" then
		return classDef.baseDMG + (level - 1) * classDef.dmgPerLevel
	elseif statId == "Speed" then
		return classDef.baseWalkSpeed + (level - 1) * classDef.speedPerLevel
	elseif statId == "Mana" then
		return classDef.baseMana + (level - 1) * classDef.manaPerLevel
	elseif statId == "AttackSpeed" then
		return classDef.baseAttackInterval - (level - 1) * classDef.specialPerRank
	end
	return 0
end

function Rules.VisualTier(level)
	if level >= 40 then
		return 5
	elseif level >= 25 then
		return 4
	elseif level >= 15 then
		return 3
	elseif level >= 8 then
		return 2
	elseif level >= 3 then
		return 1
	end
	return 0
end

function Rules.ComputeStats(input)
	local classDef = input.classDef
	local hero = input.hero
	local hpLevel = hero.stats.HP or 1
	local dmgLevel = hero.stats.DMG or 1
	local maxHp = classDef.baseHP + (hpLevel - 1) * classDef.hpPerLevel
	local damage = classDef.baseDMG + (dmgLevel - 1) * classDef.dmgPerLevel

	local vitality = (hero.talents and hero.talents.vitality) or 0
	local power = (hero.talents and hero.talents.power) or 0
	local special = (hero.talents and hero.talents.class_mastery) or 0
	local hpPct = input.talentHpPct or 0.03
	local dmgPct = input.talentDmgPct or 0.03

	maxHp *= (1 + vitality * hpPct)
	damage *= (1 + power * dmgPct)

	local gear = input.gearBonus or {}
	local pet = input.petBonus or {}
	maxHp += gear.hp or 0
	damage += gear.dmg or 0
	maxHp *= (1 + (pet.hp or 0))
	damage *= (1 + (pet.dmg or 0))

	local fury = input.furyBonus or 0
	local hawk = input.hawkBonus or 0
	damage *= (1 + fury + hawk)
	if input.doubleDamage then
		damage *= 2
	end

	local walkSpeed = classDef.baseWalkSpeed
	if input.classId == "Warrior" then
		local speedLevel = hero.stats.Speed or 1
		walkSpeed = classDef.baseWalkSpeed + (speedLevel - 1) * classDef.speedPerLevel
		walkSpeed += special * (classDef.specialPerRank or 0)
	end
	walkSpeed += pet.speed or 0

	local attackInterval = classDef.baseAttackInterval
	if input.classId == "Archer" then
		local attackLevel = hero.stats.AttackSpeed or 1
		attackInterval = classDef.baseAttackInterval - (attackLevel - 1) * classDef.specialPerRank
		attackInterval -= special * (classDef.specialPerRank or 0)
	end
	attackInterval = math.max(classDef.minAttackInterval, attackInterval)

	local maxMana = 0
	local manaRegen = 0
	if input.classId == "Mage" then
		local manaLevel = hero.stats.Mana or 1
		maxMana = classDef.baseMana + (manaLevel - 1) * classDef.manaPerLevel
		maxMana *= (1 + special * (classDef.specialManaPct or 0))
		manaRegen = classDef.baseManaRegen + (manaLevel - 1) * classDef.manaRegenPerLevel
	end

	local fortune = 1 + (pet.fortune or 0) + (gear.fortune or 0)
	if fortune < 0 then
		fortune = 0
	end
	if input.doubleFortune then
		fortune *= 2
	end

	local range = classDef.attackRange + (hawk > 0 and (input.hawkRange or 0) or 0)
	return {
		maxHp = math.max(1, maxHp),
		damage = math.max(1, damage),
		walkSpeed = math.clamp(walkSpeed, 8, 40),
		attackInterval = attackInterval,
		attackRange = range,
		maxMana = maxMana,
		manaRegen = manaRegen,
		fortune = fortune,
		damageReduction = math.clamp(input.damageReduction or 0, 0, 0.75),
	}
end

function Rules.SumBonuses(parts)
	local total = { hp = 0, dmg = 0, speed = 0, fortune = 0, hpFlat = 0 }
	for _, part in parts do
		total.hp += part.hp or 0
		total.dmg += part.dmg or 0
		total.speed += part.speed or 0
		total.fortune += part.fortune or 0
	end
	return total
end

function Rules.CanPurchaseArena(hero, arenaDef, coins)
	if not arenaDef then
		return false, "Arena does not exist."
	end
	local key = tostring(arenaDef.index)
	if hero.unlockedArenas[key] then
		return false, "Arena already unlocked."
	end
	if (hero.mastery or 0) < arenaDef.mastery then
		return false, "Mastery is too low."
	end
	if (coins or 0) < arenaDef.cost then
		return false, "Not enough coins."
	end
	return true, nil
end

function Rules.SelectFirstHero(profile, heroId, valid)
	if profile.firstHeroChosen then
		return false, "The first hero has already been chosen."
	end
	if not valid[heroId] then
		return false, "Invalid hero."
	end
	profile.firstHeroChosen = true
	profile.selectedHero = heroId
	profile.unlockedHeroes[heroId] = true
	return true, nil
end

function Rules.SwitchHero(profile, heroId)
	if profile.selectedHero == "" or profile.firstHeroChosen ~= true then
		return false, "Choose your first hero first."
	end
	if not profile.unlockedHeroes[heroId] then
		return false, "Hero is locked."
	end
	if profile.selectedHero == heroId then
		return false, "That hero is already active."
	end
	profile.selectedHero = heroId
	return true, nil
end

function Rules.AbilityUnlocked(mastery, ability)
	return (mastery or 0) >= ability.masteryRequired
end

function Rules.SpendPoint(hero, kind, id, maxRank, unlocked)
	if (hero.skillPoints or 0) < 1 then
		return false, "No Skill Points."
	end
	local bucket = kind == "skill" and hero.skillRanks or hero.talents
	if kind ~= "skill" and kind ~= "talent" then
		return false, "Invalid type."
	end
	if kind == "skill" and not unlocked then
		return false, "Ability is still locked."
	end
	if bucket[id] == nil then
		return false, "Unknown entry."
	end
	if bucket[id] >= maxRank then
		return false, "Maximum rank."
	end
	bucket[id] += 1
	hero.skillPoints -= 1
	return true, nil
end

function Rules.UpgradeStat(hero, statId, maxLevel)
	local level = hero.stats[statId]
	if level == nil then
		return false, "That stat is not available for this hero."
	end
	if level >= maxLevel then
		return false, "Maximum level."
	end
	hero.stats[statId] = level + 1
	return true, nil
end

function Rules.CanRebirth(hero, maxMastery)
	if not hero then
		return false, "Invalid hero."
	end
	if (hero.mastery or 0) < maxMastery then
		return false, "Requires Mastery " .. tostring(maxMastery) .. "."
	end
	return true, nil
end

-- Reset dell'eroe. Non tocca Coins, pet, materiali, pozioni, collezionabili,
-- eroi sbloccati o gli altri eroi. Gli oggetti con boundHero uguale all'eroe
-- vengono rimossi. Gli oggetti senza boundHero restano nell'inventario.
function Rules.ApplyRebirth(profile, heroId, statNames, skillIds, talentIds)
	local hero = profile.heroes[heroId]
	local allowed, reason = Rules.CanRebirth(hero, 50)
	if not allowed then
		return false, reason
	end
	hero.rebirths = (hero.rebirths or 0) + 1
	hero.mastery = 0
	hero.xp = 0
	hero.skillPoints = 0
	hero.stats = hero.stats or {}
	for _, statId in statNames do
		hero.stats[statId] = 1
	end
	hero.skillRanks = hero.skillRanks or {}
	for _, skillId in skillIds do
		hero.skillRanks[skillId] = 0
	end
	hero.talents = hero.talents or {}
	for _, talentId in talentIds do
		hero.talents[talentId] = 0
	end
	hero.unlockedArenas = { ["1"] = true }
	hero.equippedGear = { weapon = "", armor = "", charm = "" }

	local kept = {}
	local removed = 0
	for _, entry in profile.inventory.equipment do
		if entry.boundHero == heroId then
			removed += 1
		else
			table.insert(kept, entry)
		end
	end
	profile.inventory.equipment = kept

	local valid = {}
	for _, entry in kept do
		valid[entry.uid] = true
	end
	for _, other in pairs(profile.heroes) do
		if type(other.equippedGear) == "table" then
			for slot, uid in pairs(other.equippedGear) do
				if type(uid) == "string" and uid ~= "" and not valid[uid] then
					other.equippedGear[slot] = ""
				end
			end
		end
	end
	return true, nil, removed
end

function Rules.TotalRebirths(profile)
	local total = 0
	for _, hero in pairs(profile.heroes) do
		total += hero.rebirths or 0
	end
	return total
end

function Rules.PickKillCredit(damageByUserId, lastHitUserId, rule)
	if rule == "LastHit" then
		return lastHitUserId
	end
	local bestId = nil
	local bestDamage = -1
	for userId, damage in pairs(damageByUserId) do
		if damage > bestDamage or (damage == bestDamage and userId == lastHitUserId) then
			bestDamage = damage
			bestId = userId
		end
	end
	return bestId
end

function Rules.RollDrops(entries, fortuneMultiplier, rng, classId)
	local grants = {}
	for _, entry in entries do
		if entry.classId == nil or entry.classId == classId then
			local cap = entry.cap or 0.85
			local baseChance = entry.chance or 0
			-- Un drop con probabilità base 1 resta garantito. Il tetto limita solo i bonus fortuna.
			local chance = baseChance
			if baseChance < 1 then
				chance = math.clamp(baseChance * fortuneMultiplier, 0, cap)
			end
			if rng() < chance then
				local minCount = entry.min or 1
				local maxCount = entry.max or minCount
				if maxCount < minCount then
					maxCount = minCount
				end
				local count = minCount
				if maxCount > minCount then
					count = minCount + math.floor(rng() * ((maxCount - minCount) + 1))
				end
				table.insert(grants, {
					itemId = entry.itemId,
					category = entry.category,
					count = count,
					classId = entry.classId,
				})
			end
		end
	end
	return grants
end

function Rules.RollWeighted(pool, rng)
	local total = 0
	for _, entry in pool do
		total += entry.weight or 0
	end
	if total <= 0 then
		return nil
	end
	local roll = rng() * total
	local cursor = 0
	for _, entry in pool do
		cursor += entry.weight or 0
		if roll <= cursor then
			return entry
		end
	end
	return pool[#pool]
end

function Rules.CanFuse(petList, equippedLookup, uids, required, nextEvolution)
	if type(uids) ~= "table" or #uids ~= required then
		return false, "Requires exactly " .. tostring(required) .. " pets."
	end
	local byUid = {}
	for _, pet in petList do
		byUid[pet.uid] = pet
	end
	local seen = {}
	local petId = nil
	local evolution = nil
	for _, uid in uids do
		if type(uid) ~= "string" or uid == "" or seen[uid] then
			return false, "Duplicate or invalid pet."
		end
		seen[uid] = true
		if equippedLookup[uid] then
			return false, "Unequip pets before fusing them."
		end
		local pet = byUid[uid]
		if not pet then
			return false, "You do not own that pet."
		end
		if not petId then
			petId = pet.petId
			evolution = pet.evolution
		elseif pet.petId ~= petId or pet.evolution ~= evolution then
			return false, "Pets must share the same id and evolution."
		end
	end
	local evolved = nextEvolution(evolution)
	if not evolved then
		return false, "This pet cannot evolve further."
	end
	return true, nil, { petId = petId, evolution = evolved }
end

function Rules.ApplyFuse(petList, equippedLookup, uids, required, nextEvolution, newUid)
	local ok, err, result = Rules.CanFuse(petList, equippedLookup, uids, required, nextEvolution)
	if not ok then
		return false, err
	end
	local remove = {}
	for _, uid in uids do
		remove[uid] = true
	end
	local nextList = {}
	local removed = 0
	for _, pet in petList do
		if remove[pet.uid] then
			removed += 1
		else
			table.insert(nextList, pet)
		end
	end
	if removed ~= required then
		return false, "Invalid fusion count."
	end
	table.insert(nextList, {
		uid = newUid,
		petId = result.petId,
		evolution = result.evolution,
	})
	return true, nextList
end

function Rules.ApplyPotion(active, potion, now)
	active[potion.family] = {
		family = potion.family,
		potionId = potion.id,
		rarity = potion.rarity,
		expiresAt = now + potion.duration,
		healthPerSecond = potion.healthPerSecond or 0,
		damageMultiplier = potion.damageMultiplier or 1,
		fortuneMultiplier = potion.fortuneMultiplier or 1,
		nextTick = now + 1,
	}
	return active[potion.family]
end

function Rules.EquippedLookup(heroes)
	local lookup = {}
	for _, hero in pairs(heroes) do
		if type(hero.equippedGear) == "table" then
			for _, uid in pairs(hero.equippedGear) do
				if type(uid) == "string" and uid ~= "" then
					lookup[uid] = true
				end
			end
		end
	end
	return lookup
end

function Rules.EquippedPetLookup(equippedPets)
	local lookup = {}
	for _, uid in equippedPets do
		if type(uid) == "string" and uid ~= "" then
			lookup[uid] = true
		end
	end
	return lookup
end

function Rules.AddStack(map, itemId, count, cap)
	if type(itemId) ~= "string" or not Rules.IsFinite(count) or count == 0 then
		return false, "Invalid item."
	end
	count = math.floor(count)
	local current = map[itemId] or 0
	local nextCount = current + count
	if nextCount > cap then
		return false, "Capacity reached."
	end
	if nextCount < 0 then
		return false, "Not enough items."
	end
	if nextCount == 0 then
		map[itemId] = nil
	else
		map[itemId] = nextCount
	end
	return true, nil
end

function Rules.UnlockNextHero(profile, order)
	for _, heroId in order do
		if not profile.unlockedHeroes[heroId] then
			profile.unlockedHeroes[heroId] = true
			return heroId
		end
	end
	return nil
end

function Rules.ProgressQuest(profile, quest, amount)
	local state = profile.quests[quest.id]
	if not state or state.completed then
		return false
	end
	state.progress += amount
	if state.progress > quest.goal then
		state.progress = quest.goal
	end
	if state.progress >= quest.goal then
		state.completed = true
		return true
	end
	return false
end

return Rules
