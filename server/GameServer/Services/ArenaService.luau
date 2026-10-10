local shared = require(script.Parent.SharedLoader)
local ArenaConfig = shared("ArenaConfig")
local Rules = shared("Rules")
local WorldLayout = shared("WorldLayout")
local PlayerData = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local HeroService = require(script.Parent.HeroService)
local RuntimeState = require(script.Parent.RuntimeState)
local Notifier = require(script.Parent.Notifier)

local ArenaService = {}

local function heroOf(player)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return nil, nil, "Seleziona un eroe."
	end
	return data, data.heroes[data.selectedHero], nil
end

local function arenaFromPayload(payload)
	local index = payload.arenaIndex
	if type(index) ~= "number" or index ~= math.floor(index) then
		return nil
	end
	return ArenaConfig.Get(index)
end

function ArenaService.CanTravel(player)
	if HeroService.InLobby(player) then
		return true
	end
	local position = HeroService.Position(player)
	if not position then
		return false
	end
	for index = 1, 15 do
		if WorldLayout.Near(position, WorldLayout.ArenaGate(index), WorldLayout.Radii.ArenaPad + 8) then
			return true
		end
		if WorldLayout.InsideArena(position, index) then
			return true
		end
	end
	return false
end

local function spawnFor(index)
	local world = workspace:FindFirstChild("KurkitoWorld")
	if not world then
		return nil
	end
	return world:FindFirstChild("ArenaSpawn_" .. tostring(index), true)
end

local function lobbySpawn()
	local world = workspace:FindFirstChild("KurkitoWorld")
	if not world then
		return nil
	end
	return world:FindFirstChild("LobbySpawn", true)
end

local function teleport(player, position, spawnLocation)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = CFrame.new(position)
	RuntimeState.Get(player).safeCFrame = CFrame.new(position)
	if spawnLocation and spawnLocation:IsA("SpawnLocation") then
		player.RespawnLocation = spawnLocation
	end
	return true
end

function ArenaService.Unlock(player, arenaIndex)
	local arena = ArenaConfig.Get(arenaIndex)
	if not arena then
		return { ok = false, error = "Arena inesistente." }
	end
	local position = HeroService.Position(player)
	local nearGate = position and WorldLayout.Near(position, WorldLayout.ArenaGate(arena.index), WorldLayout.Radii.ArenaPad + 8)
	if not nearGate and not HeroService.InLobby(player) then
		return { ok = false, error = "Sblocca l'arena dal cancello o dalla lobby." }
	end
	local data, hero, reason = heroOf(player)
	if not hero then
		return { ok = false, error = reason }
	end
	local allowed, why = Rules.CanPurchaseArena(hero, arena, data.coins)
	if not allowed then
		return { ok = false, error = why }
	end
	if arena.cost > 0 then
		local paid, payError = EconomyService.TrySpend(player, arena.cost)
		if not paid then
			return { ok = false, error = payError }
		end
	end
	hero.unlockedArenas[tostring(arena.index)] = true
	PlayerData.MarkDirty(player, true)
	PlayerData.Save(player, false)
	Notifier.Send(player, "info", "Arena sbloccata: " .. arena.name)
	return { ok = true }
end

function ArenaService.TeleportToArena(player, arenaIndex)
	if not ArenaService.CanTravel(player) then
		return { ok = false, error = "Teletrasporto disponibile da lobby, cancelli o arene." }
	end
	local arena = ArenaConfig.Get(arenaIndex)
	if not arena then
		return { ok = false, error = "Arena inesistente." }
	end
	local _, hero, reason = heroOf(player)
	if not hero then
		return { ok = false, error = reason }
	end
	if not hero.unlockedArenas[tostring(arena.index)] then
		return { ok = false, error = "Arena bloccata per questo eroe." }
	end
	local spawn = spawnFor(arena.index)
	local ok = teleport(player, WorldLayout.ArenaEntry(arena.index), spawn)
	if not ok then
		return { ok = false, error = "Personaggio non pronto." }
	end
	return { ok = true }
end

function ArenaService.TeleportLobby(player)
	if not ArenaService.CanTravel(player) and not HeroService.InLobby(player) then
		return { ok = false, error = "Non puoi tornare in lobby da qui." }
	end
	if not PlayerData.IsLoaded(player) then
		return { ok = false, error = "Dati non caricati." }
	end
	local ok = teleport(player, WorldLayout.LobbySpawn(), lobbySpawn())
	if not ok then
		return { ok = false, error = "Personaggio non pronto." }
	end
	return { ok = true }
end

function ArenaService.Enforce(player)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return
	end
	local position = HeroService.Position(player)
	if not position then
		return
	end
	if position.Y < -20 then
		teleport(player, WorldLayout.LobbySpawn(), lobbySpawn())
		return
	end
	local index = WorldLayout.ArenaIndexAt(position)
	if not index then
		return
	end
	local hero = data.heroes[data.selectedHero]
	if hero.unlockedArenas[tostring(index)] then
		return
	end
	teleport(player, WorldLayout.ArenaGate(index) + Vector3.new(0, 4, -6), lobbySpawn())
	Notifier.Send(player, "error", "Questa arena non è sbloccata per l'eroe attivo.")
end

function ArenaService.EnforceAll()
	local Players = game:GetService("Players")
	for _, player in ipairs(Players:GetPlayers()) do
		ArenaService.Enforce(player)
	end
end

function ArenaService.Bind(ctx)
	local rates = shared("GameConfig").Rates
	ctx.services.RemotesService.Bind(ctx, "UnlockArena", rates.UnlockArena, function(player, payload)
		local arena = arenaFromPayload(payload)
		if not arena then
			return { ok = false, error = "Arena non valida." }
		end
		return ArenaService.Unlock(player, arena.index)
	end)
	ctx.services.RemotesService.Bind(ctx, "Teleport", rates.Teleport, function(player, payload)
		if payload.destination == "lobby" then
			return ArenaService.TeleportLobby(player)
		end
		local arena = arenaFromPayload(payload)
		if not arena then
			return { ok = false, error = "Destinazione non valida." }
		end
		return ArenaService.TeleportToArena(player, arena.index)
	end)
end

return ArenaService
