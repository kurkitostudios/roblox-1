local shared = require(script.Parent.SharedLoader)
local ArenaConfig = shared("ArenaConfig")
local Rules = shared("Rules")
local Strings = shared("Strings")
local WorldLayout = shared("WorldLayout")
local PlayerData = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local HeroService = require(script.Parent.HeroService)
local RuntimeState = require(script.Parent.RuntimeState)
local Notifier = require(script.Parent.Notifier)

local ArenaService = {}

local function heroOf(player)
	local data = PlayerData.Get(player)
	local hero = data and data.heroes and data.heroes.Warrior
	if not data or type(hero) ~= "table" then
		return nil, nil, "The Warrior is not ready."
	end
	data.selectedHero = "Warrior"
	return data, hero, nil
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
	if arenaIndex ~= 1 then
		return { ok = false, error = Strings.Error.ArenaUnavailable }
	end
	local arena = ArenaConfig.Get(arenaIndex)
	if not arena then
		return { ok = false, error = "Arena does not exist." }
	end
	local position = HeroService.Position(player)
	local nearGate = position and WorldLayout.Near(position, WorldLayout.ArenaGate(arena.index), WorldLayout.Radii.ArenaPad + 8)
	if not nearGate and not HeroService.InLobby(player) then
		return { ok = false, error = "Unlock the arena at its gate or from the lobby." }
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
	Notifier.Send(player, "arena", Strings.ArenaUnlocked(arena.name))
	return { ok = true }
end

function ArenaService.TeleportToArena(player, arenaIndex)
	if not ArenaService.CanTravel(player) then
		return { ok = false, error = "Travel is available from the lobby, gates, or arenas." }
	end
	if arenaIndex ~= 1 then
		return { ok = false, error = Strings.Error.ArenaUnavailable }
	end
	local arena = ArenaConfig.Get(arenaIndex)
	if not arena then
		return { ok = false, error = "Arena does not exist." }
	end
	local _, hero, reason = heroOf(player)
	if not hero then
		return { ok = false, error = reason }
	end
	if not hero.unlockedArenas[tostring(arena.index)] then
		return { ok = false, error = "Arena locked for this hero." }
	end
	local spawn = spawnFor(arena.index)
	local ok = teleport(player, WorldLayout.ArenaEntry(arena.index), spawn)
	if not ok then
		return { ok = false, error = "Character is not ready." }
	end
	return { ok = true }
end

function ArenaService.TeleportLobby(player)
	if not ArenaService.CanTravel(player) and not HeroService.InLobby(player) then
		return { ok = false, error = "You cannot return to the lobby from here." }
	end
	if not PlayerData.IsLoaded(player) then
		return { ok = false, error = "Data is not loaded." }
	end
	local ok = teleport(player, WorldLayout.LobbySpawn(), lobbySpawn())
	if not ok then
		return { ok = false, error = "Character is not ready." }
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
	Notifier.Send(player, "error", "This arena is not unlocked for your active hero.")
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
			return { ok = false, error = "Invalid arena." }
		end
		return ArenaService.Unlock(player, arena.index)
	end)
	ctx.services.RemotesService.Bind(ctx, "Teleport", rates.Teleport, function(player, payload)
		if payload.destination == "lobby" then
			return ArenaService.TeleportLobby(player)
		end
		local arena = arenaFromPayload(payload)
		if not arena then
			return { ok = false, error = "Invalid destination." }
		end
		return ArenaService.TeleportToArena(player, arena.index)
	end)
end

return ArenaService
