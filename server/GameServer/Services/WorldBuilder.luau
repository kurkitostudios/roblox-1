-- Mappa prototipo idempotente. Se BuildId coincide non ricostruisce le parti.
-- Geometrie, colori e luci sono provvisori, non asset definitivi.

local Lighting = game:GetService("Lighting")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local ArenaConfig = shared("ArenaConfig")
local WorldLayout = shared("WorldLayout")
local PetConfig = shared("PetConfig")
local EggService = require(script.Parent.EggService)

local WorldBuilder = {}

local function part(parent, name, size, cframe, color, material, collide)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Anchored = true
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color or Color3.fromRGB(90, 90, 96)
	piece.Material = material or Enum.Material.SmoothPlastic
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.CanCollide = collide ~= false
	piece.Parent = parent
	return piece
end

local function folder(parent, name)
	local created = Instance.new("Folder")
	created.Name = name
	created.Parent = parent
	return created
end

local function billboard(adornee, text, color, size)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = size or UDim2.fromOffset(220, 70)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 280
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = color or Color3.fromRGB(240, 230, 200)
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return gui
end

local function prompt(adornee, actionText, objectText, action, attributes)
	local created = Instance.new("ProximityPrompt")
	created.ActionText = actionText
	created.ObjectText = objectText
	created.HoldDuration = 0.15
	created.MaxActivationDistance = 14
	created.RequiresLineOfSight = false
	created.KeyboardKeyCode = Enum.KeyCode.E
	created:SetAttribute("KurkitoAction", action)
	if attributes then
		for key, value in pairs(attributes) do
			created:SetAttribute(key, value)
		end
	end
	created.Parent = adornee
	return created
end

local function light(adornee, color)
	local lamp = Instance.new("PointLight")
	lamp.Color = color or Color3.fromRGB(255, 214, 160)
	lamp.Range = 18
	lamp.Brightness = 1.3
	lamp.Parent = adornee
end

local function preparePlace()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Position = Vector3.new(0, -50, 0)
		baseplate.CanCollide = false
	end
	local legacySpawn = workspace:FindFirstChild("SpawnLocation")
	if legacySpawn and legacySpawn.Parent == workspace then
		legacySpawn:Destroy()
	end
end

local function buildLighting()
	Lighting.ClockTime = 15.4
	Lighting.Brightness = 2.1
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(70, 68, 84)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 146)
	local atmosphere = Lighting:FindFirstChild("KurkitoAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "KurkitoAtmosphere"
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(190, 196, 214)
	atmosphere.Decay = Color3.fromRGB(92, 96, 120)
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.1
end

local function buildArena(arenas, paths, arena)
	local center = WorldLayout.ArenaCenter(arena.index)
	local size = WorldLayout.ArenaSize
	local half = size / 2
	local height = WorldLayout.WallHeight
	local floorTop = 1
	local root = folder(arenas, string.format("Arena_%02d", arena.index))
	local floorPiece = part(root, "Floor", Vector3.new(size, 2, size), CFrame.new(center), arena.color, Enum.Material.Slate, true)
	light(floorPiece, arena.color)

	local wallY = floorTop + height / 2
	local thickness = 4
	local gap = 18
	local side = (size - gap) / 2
	local zSouth = center.Z - half
	local xShift = gap / 2 + side / 2
	part(root, "WallSouthL", Vector3.new(side, height, thickness), CFrame.new(center.X - xShift, wallY, zSouth), Color3.fromRGB(58, 56, 68), Enum.Material.Concrete, true)
	part(root, "WallSouthR", Vector3.new(side, height, thickness), CFrame.new(center.X + xShift, wallY, zSouth), Color3.fromRGB(58, 56, 68), Enum.Material.Concrete, true)
	part(root, "WallNorth", Vector3.new(size, height, thickness), CFrame.new(center.X, wallY, center.Z + half), Color3.fromRGB(58, 56, 68), Enum.Material.Concrete, true)
	part(root, "WallEast", Vector3.new(thickness, height, size), CFrame.new(center.X + half, wallY, center.Z), Color3.fromRGB(58, 56, 68), Enum.Material.Concrete, true)
	part(root, "WallWest", Vector3.new(thickness, height, size), CFrame.new(center.X - half, wallY, center.Z), Color3.fromRGB(58, 56, 68), Enum.Material.Concrete, true)
	-- Cancello fisico: l'ingresso reale è il teletrasporto, così lo sblocco resta per-giocatore.
	local gate = part(root, "Gate", Vector3.new(gap - 1, height, 2), CFrame.new(center.X, wallY, zSouth), arena.color:Lerp(Color3.new(0, 0, 0), 0.35), Enum.Material.Metal, true)
	gate.Transparency = 0.25

	local pad = part(root, "SafePad", Vector3.new(16, 1, 16), CFrame.new(center.X, 1.5, center.Z - 58), Color3.fromRGB(230, 210, 140), Enum.Material.Neon, true)
	pad.Transparency = 0.45
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ArenaSpawn_" .. tostring(arena.index)
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(center.X, 2, center.Z - 58)
	spawn.Neutral = false
	spawn.Enabled = false
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = root

	local sign = part(root, "Sign", Vector3.new(2, 6, 10), CFrame.new(center.X - 16, 4, zSouth - 8), Color3.fromRGB(40, 36, 48), Enum.Material.Wood, true)
	local costText = arena.cost > 0 and (tostring(arena.cost) .. " monete") or "Gratuita"
	billboard(sign, string.format("Arena %d\n%s\nMaestria %d · %s", arena.index, arena.name, arena.mastery, costText), Color3.new(1, 1, 1), UDim2.fromOffset(240, 96))
	prompt(sign, "Arena", arena.name, "Arena", { ArenaIndex = arena.index })

	local back = part(root, "ReturnPad", Vector3.new(10, 1, 10), CFrame.new(center.X, 1.6, center.Z - 48), Color3.fromRGB(180, 180, 190), Enum.Material.SmoothPlastic, true)
	prompt(back, "Lobby", "Ritorna", "Lobby", {})

	if arena.index < 15 then
		local nextCenter = WorldLayout.ArenaCenter(arena.index + 1)
		local fromZ = center.Z + half
		local toZ = nextCenter.Z - half
		local mid = (fromZ + toZ) / 2
		local length = math.abs(toZ - fromZ)
		part(paths, "Bridge_" .. arena.index, Vector3.new(28, 2, length), CFrame.new(0, 0, mid), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true)
	end
end

local function buildStairs(parent, name, fromZ, toZ, fromTop, toTop)
	local steps = 8
	local length = math.abs(toZ - fromZ)
	local depth = length / steps
	local direction = toZ > fromZ and 1 or -1
	local rise = (toTop - fromTop) / steps
	for step = 1, steps do
		local top = fromTop + rise * step
		local centerZ = fromZ + direction * (depth * (step - 0.5))
		part(parent, name .. "_" .. step, Vector3.new(28, 2, depth), CFrame.new(0, top - 1, centerZ), Color3.fromRGB(150, 140, 120), Enum.Material.Cobblestone, true)
	end
end

local function buildEggs(paths)
	local eggRoot = folder(workspace:FindFirstChild("KurkitoWorld"), "EggZone")
	local terraces = WorldLayout.EggTerraces()
	part(paths, "PathEggs", Vector3.new(28, 2, 150), CFrame.new(0, 0, -185), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true)
	for index, terrace in ipairs(terraces) do
		local center = terrace.position
		local slab = part(eggRoot, "Terrace_" .. index, Vector3.new(230, 2, 100), CFrame.new(center), Color3.fromRGB(214, 196, 150), Enum.Material.Sandstone, true)
		light(slab, Color3.fromRGB(255, 220, 160))
		part(eggRoot, "RailL_" .. index, Vector3.new(4, 5, 100), CFrame.new(center + Vector3.new(-113, 3, 0)), Color3.fromRGB(120, 100, 80), Enum.Material.Wood, true)
		part(eggRoot, "RailR_" .. index, Vector3.new(4, 5, 100), CFrame.new(center + Vector3.new(113, 3, 0)), Color3.fromRGB(120, 100, 80), Enum.Material.Wood, true)
		local sign = part(eggRoot, "TerraceSign_" .. index, Vector3.new(2, 5, 8), CFrame.new(center + Vector3.new(0, 4, -42)), Color3.fromRGB(70, 54, 36), Enum.Material.Wood, true)
		billboard(sign, "Terrazza uova " .. index, Color3.fromRGB(255, 236, 200))
		for slot, arenaIndex in ipairs(terrace.arenas) do
			local eggPos = WorldLayout.EggPosition(terrace, slot)
			local eggDef = PetConfig.GetEgg(arenaIndex)
			local pedestal = part(eggRoot, "Pedestal_" .. arenaIndex, Vector3.new(6, 3, 6), CFrame.new(eggPos - Vector3.new(0, 2.2, 0)), Color3.fromRGB(90, 78, 64), Enum.Material.Slate, true)
			local egg = part(eggRoot, "Egg_" .. arenaIndex, Vector3.new(3.2, 4.2, 3.2), CFrame.new(eggPos), eggDef.color, Enum.Material.SmoothPlastic, false)
			egg.Shape = Enum.PartType.Ball
			local odds = EggService.OddsText(eggDef.pool)
			billboard(pedestal, string.format("Uovo Arena %d\n%d monete\n%s", arenaIndex, eggDef.cost, odds), Color3.new(1, 1, 1), UDim2.fromOffset(260, 150))
			prompt(pedestal, "Apri", eggDef.cost .. " monete", "OpenEgg", { ArenaIndex = arenaIndex })
		end
		local special = PetConfig.SpecialEggs[terrace.special]
		local specialPos = WorldLayout.EggPosition(terrace, 6)
		local specialPad = part(eggRoot, "RobuxPad_" .. index, Vector3.new(8, 3, 8), CFrame.new(specialPos - Vector3.new(0, 2.2, 0)), Color3.fromRGB(40, 36, 32), Enum.Material.Marble, true)
		local shell = part(eggRoot, "RobuxEgg_" .. index, Vector3.new(4.4, 5.6, 4.4), CFrame.new(specialPos + Vector3.new(0, 0.4, 0)), special.color, Enum.Material.Neon, false)
		shell.Shape = Enum.PartType.Ball
		shell.Transparency = 0.15
		billboard(specialPad, special.name .. "\nNON ACQUISTABILE\nProduct ID assente\n" .. EggService.OddsText(special.pool), Color3.fromRGB(255, 220, 140), UDim2.fromOffset(280, 180))
		prompt(specialPad, "Info", "Robux non attivo", "RobuxEgg", { SpecialIndex = terrace.special })
	end
	local first = terraces[1].position
	local second = terraces[2].position
	local third = terraces[3].position
	buildStairs(eggRoot, "Stairs12", first.Z - 50, second.Z + 50, 1, 17)
	buildStairs(eggRoot, "Stairs23", second.Z - 50, third.Z + 50, 17, 33)
end

local function buildBoards(paths)
	local root = folder(workspace:FindFirstChild("KurkitoWorld"), "Leaderboards")
	local origin = WorldLayout.LeaderboardOrigin()
	part(root, "Plaza", Vector3.new(180, 2, 90), CFrame.new(origin), Color3.fromRGB(226, 226, 232), Enum.Material.Marble, true)
	part(paths, "PathBoards", Vector3.new(80, 2, 24), CFrame.new(-160, 0, 0), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true)
	local titles = {
		{ id = "Rebirth", title = "MOST REBIRTH" },
		{ id = "Time", title = "MOST TIME PLAYED" },
		{ id = "Kills", title = "MOST KILLS" },
	}
	for boardIndex, board in ipairs(titles) do
		local headerPos = origin + Vector3.new((boardIndex - 2) * 52, 8, -28)
		local header = part(root, "Header_" .. board.id, Vector3.new(30, 6, 1), CFrame.new(headerPos), Color3.fromRGB(28, 26, 40), Enum.Material.SmoothPlastic, true)
		billboard(header, board.title, Color3.fromRGB(240, 210, 120), UDim2.fromOffset(260, 50))
		for place = 1, 3 do
			local center, size = WorldLayout.PodiumSpec(boardIndex, place)
			local podium = part(root, WorldLayout.PodiumName(board.id, place), size, CFrame.new(center), Color3.fromRGB(210 - place * 25, 180 - place * 20, 90), Enum.Material.Metal, true)
			podium:SetAttribute("PodiumBoard", board.id)
			podium:SetAttribute("PodiumPlace", place)
			local gui = Instance.new("SurfaceGui")
			gui.Name = "PodiumGui"
			gui.Face = Enum.NormalId.Front
			gui.CanvasSize = Vector2.new(200, 120)
			gui.Parent = podium
			local label = Instance.new("TextLabel")
			label.Name = "NameLabel"
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, 0, 0.55, 0)
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Text = "—"
			label.Parent = gui
			local value = Instance.new("TextLabel")
			value.Name = "ValueLabel"
			value.BackgroundTransparency = 1
			value.Position = UDim2.new(0, 0, 0.5, 0)
			value.Size = UDim2.new(1, 0, 0.45, 0)
			value.Font = Enum.Font.Gotham
			value.TextScaled = true
			value.TextColor3 = Color3.fromRGB(255, 220, 140)
			value.Text = ""
			value.Parent = gui
		end
	end
	local figures = folder(root, "PodiumFigures")
	figures.Name = "PodiumFigures"
end

local function servicePad(parent, name, position, color, text, action, attributes)
	local pad = part(parent, name, Vector3.new(16, 2, 16), CFrame.new(position.X, 1, position.Z), color, Enum.Material.Marble, true)
	local post = part(parent, name .. "Post", Vector3.new(2, 8, 2), CFrame.new(position.X, 5, position.Z), color:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Neon, true)
	light(post, color)
	billboard(post, text, Color3.new(1, 1, 1), UDim2.fromOffset(220, 80))
	prompt(post, "Interagisci", text, action, attributes)
	return pad
end

local function buildServices(paths)
	local root = folder(workspace:FindFirstChild("KurkitoWorld"), "Services")
	part(root, "EastFloor", Vector3.new(280, 2, 240), CFrame.new(300, 0, 40), Color3.fromRGB(86, 78, 104), Enum.Material.Slate, true)
	part(paths, "PathEast", Vector3.new(70, 2, 28), CFrame.new(150, 0, 20), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true)
	servicePad(root, "HeroPad", WorldLayout.HeroSwitch(), Color3.fromRGB(176, 72, 58), "Eroi\nCambia personaggio", "Hero")
	servicePad(root, "UpgradePad", WorldLayout.Upgrades(), Color3.fromRGB(80, 140, 200), "Potenziamenti\nApri il menu", "UpgradeInfo")
	servicePad(root, "FusionPad", WorldLayout.Fusion(), Color3.fromRGB(120, 210, 230), "Fusione Pet\n5 identici = 1 evoluto", "FusionInfo")
	servicePad(root, "RebirthPad", WorldLayout.Rebirth(), Color3.fromRGB(150, 80, 200), "Altare Rebirth\nMaestria 50", "Rebirth")

	local portalPos = WorldLayout.Portal()
	part(root, "PortalPlatform", Vector3.new(40, 2, 40), CFrame.new(portalPos.X, 0, portalPos.Z), Color3.fromRGB(70, 70, 78), Enum.Material.Basalt, true)
	part(paths, "PathPortal", Vector3.new(20, 2, 80), CFrame.new(400, 0, 160), Color3.fromRGB(90, 90, 96), Enum.Material.Basalt, true)
	local ring = part(root, "World2Ring", Vector3.new(16, 16, 2), CFrame.new(portalPos), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, true)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(portalPos) * CFrame.Angles(0, 0, math.rad(90))
	local lockBar = part(root, "World2Lock", Vector3.new(2, 12, 2), CFrame.new(portalPos), Color3.fromRGB(40, 40, 46), Enum.Material.DiamondPlate, true)
	billboard(lockBar, "Mondo 2\nPortale non attivo", Color3.fromRGB(200, 200, 210), UDim2.fromOffset(200, 70))
	prompt(lockBar, "Info", "Mondo 2", "Portal")
end

local function buildLobby(paths)
	local lobby = folder(workspace:FindFirstChild("KurkitoWorld"), "Lobby")
	local floorPiece = part(lobby, "Floor", Vector3.new(WorldLayout.LobbySize, 2, WorldLayout.LobbySize), CFrame.new(0, 0, 0), Color3.fromRGB(52, 50, 64), Enum.Material.Slate, true)
	light(floorPiece, Color3.fromRGB(255, 220, 170))
	local obelisk = part(lobby, "Obelisk", Vector3.new(8, 22, 8), CFrame.new(0, 12, 0), Color3.fromRGB(230, 206, 140), Enum.Material.Marble, true)
	billboard(obelisk, "KURKITO\nBattle Survival\nMondo 1", Color3.fromRGB(255, 236, 190), UDim2.fromOffset(260, 100))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 1.6, 36)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 0.4
	spawn.Color = Color3.fromRGB(240, 220, 160)
	spawn.Parent = lobby

	local function pointer(name, position, text)
		local post = part(lobby, name, Vector3.new(3, 7, 3), CFrame.new(position), Color3.fromRGB(70, 64, 84), Enum.Material.Wood, true)
		billboard(post, text, Color3.fromRGB(240, 230, 210))
	end
	pointer("SignArenas", Vector3.new(0, 4, 90), "Arene → nord")
	pointer("SignEggs", Vector3.new(0, 4, -90), "Uova → sud")
	pointer("SignBoards", Vector3.new(-90, 4, 0), "Classifiche → ovest")
	pointer("SignHeroes", Vector3.new(90, 4, 0), "Eroi e Rebirth → est")

	local first = WorldLayout.ArenaCenter(1)
	local pathLength = (first.Z - WorldLayout.ArenaHalf()) - 110
	local pathCenter = 110 + pathLength / 2
	part(paths, "PathArenas", Vector3.new(28, 2, pathLength), CFrame.new(0, 0, pathCenter), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true)
end

function WorldBuilder.Build()
	preparePlace()
	buildLighting()
	local existing = workspace:FindFirstChild("KurkitoWorld")
	if existing and existing:GetAttribute("BuildId") == GameConfig.WorldBuildId then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local world = folder(workspace, "KurkitoWorld")
	world:SetAttribute("BuildId", GameConfig.WorldBuildId)
	local paths = folder(world, "Paths")
	local arenas = folder(world, "Arenas")
	folder(world, "Enemies")
	folder(world, "Effects")
	buildLobby(paths)
	for _, arena in ipairs(ArenaConfig) do
		buildArena(arenas, paths, arena)
	end
	buildEggs(paths)
	buildBoards(paths)
	buildServices(paths)
	print("[Kurkito] Mondo 1 costruito (" .. GameConfig.WorldBuildId .. ").")
	return world
end

return WorldBuilder
