-- Rebirth in due passi: preparazione e conferma.
-- Un solo eroe viene azzerato. Monete, Pet, materiali, pozioni,
-- collezionabili, eroi sbloccati e gli altri eroi restano.
-- Gli equipaggiamenti con boundHero uguale all'eroe rinato vengono eliminati.
-- Gli oggetti senza boundHero (charm) restano nell'inventario condiviso
-- e vengono solo rimossi dallo slot di quell'eroe.

local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local AbilityConfig = shared("AbilityConfig")
local Rules = shared("Rules")
local WorldLayout = shared("WorldLayout")
local GameConfig = shared("GameConfig")
local PlayerData = require(script.Parent.PlayerDataService)
local HeroService = require(script.Parent.HeroService)
local RuntimeState = require(script.Parent.RuntimeState)
local Notifier = require(script.Parent.Notifier)

local RebirthService = {}

local function ready(player)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return nil, nil, "Seleziona un eroe."
	end
	if not HeroService.Near(player, WorldLayout.Rebirth(), WorldLayout.Radii.Rebirth) then
		return nil, nil, "Avvicinati all'altare del Rebirth."
	end
	local hero = data.heroes[data.selectedHero]
	local ok, reason = Rules.CanRebirth(hero, GameConfig.MaxMastery)
	if not ok then
		return nil, nil, reason
	end
	return data, hero, nil
end

function RebirthService.Preview(player)
	local data, _, reason = ready(player)
	if not data then
		return { ok = false, error = reason }
	end
	local runtime = RuntimeState.Get(player)
	runtime.rebirthArmedUntil = os.clock() + 30
	local heroId = data.selectedHero
	Notifier.Send(player, "info", "Rebirth pronto per " .. HeroConfig.Classes[heroId].displayName .. ". Conferma entro 30 secondi.")
	return {
		ok = true,
		heroId = heroId,
		rebirths = data.heroes[heroId].rebirths,
	}
end

function RebirthService.Confirm(player)
	if not RuntimeState.TryLock(player, "rebirth") then
		return { ok = false, error = "Rebirth già in corso." }
	end
	local function finish(result)
		RuntimeState.Unlock(player, "rebirth")
		return result
	end
	local data, _, reason = ready(player)
	if not data then
		return finish({ ok = false, error = reason })
	end
	local runtime = RuntimeState.Get(player)
	if os.clock() > (runtime.rebirthArmedUntil or 0) then
		return finish({ ok = false, error = "Conferma scaduta. Prepara di nuovo il Rebirth." })
	end
	local heroId = data.selectedHero
	local classDef = HeroConfig.Classes[heroId]
	local skillIds = {}
	for _, ability in ipairs(AbilityConfig[heroId]) do
		table.insert(skillIds, ability.id)
	end
	local talentIds = {}
	for _, talent in ipairs(HeroConfig.Talents) do
		table.insert(talentIds, talent.id)
	end
	local applied, applyError = Rules.ApplyRebirth(data, heroId, classDef.stats, skillIds, talentIds)
	if not applied then
		return finish({ ok = false, error = applyError })
	end
	runtime.rebirthArmedUntil = 0
	runtime.cooldowns = {}
	runtime.shield = 0
	runtime.shieldUntil = 0
	runtime.engaged = {}
	runtime.buffs.furyUntil = 0
	runtime.buffs.furyBonus = 0
	runtime.buffs.defenseUntil = 0
	runtime.buffs.defenseReduction = 0
	runtime.buffs.hawkUntil = 0
	runtime.buffs.hawkBonus = 0
	runtime.buffs.hawkRange = 0
	runtime.heroId = ""
	runtime.manaInitialized = false
	PlayerData.MarkDirty(player, true)
	HeroService.Refresh(player, true)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(WorldLayout.LobbySpawn())
		root.AssemblyLinearVelocity = Vector3.zero
	end
	PlayerData.Save(player, false)
	Notifier.Send(player, "quest", HeroConfig.Classes[heroId].displayName .. " ha completato un Rebirth. Bonus permanente: +" .. tostring(math.floor(data.heroes[heroId].rebirths * 10)) .. "% XP e monete.")
	return finish({ ok = true, rebirths = data.heroes[heroId].rebirths })
end

function RebirthService.Bind(ctx)
	ctx.services.RemotesService.Bind(ctx, "Rebirth", shared("GameConfig").Rates.Rebirth, function(player, payload)
		if payload.step == "confirm" then
			return RebirthService.Confirm(player)
		end
		return RebirthService.Preview(player)
	end)
end

return RebirthService
