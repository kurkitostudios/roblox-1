-- Stato di combattimento non persistente. Non viene salvato nel DataStore.

local RuntimeState = {}

local byPlayer = {}

local function blank()
	return {
		cooldowns = {},
		effects = {},
		shield = 0,
		shieldUntil = 0,
		lastAttack = 0,
		engaged = {},
		mana = 0,
		heroId = "",
		rebirthArmedUntil = 0,
		busy = {},
		playtimeBuffer = 0,
		buffs = {
			furyUntil = 0,
			furyBonus = 0,
			defenseUntil = 0,
			defenseReduction = 0,
			hawkUntil = 0,
			hawkBonus = 0,
			hawkRange = 0,
		},
	}
end

function RuntimeState.Get(player)
	local runtime = byPlayer[player]
	if not runtime then
		runtime = blank()
		byPlayer[player] = runtime
	end
	return runtime
end

function RuntimeState.Clear(player)
	byPlayer[player] = nil
end

function RuntimeState.TryLock(player, key)
	local runtime = RuntimeState.Get(player)
	if runtime.busy[key] then
		return false
	end
	runtime.busy[key] = true
	return true
end

function RuntimeState.Unlock(player, key)
	local runtime = byPlayer[player]
	if runtime then
		runtime.busy[key] = nil
	end
end

return RuntimeState
