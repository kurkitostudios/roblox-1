-- Mondo 1 idempotente. Se BuildId coincide non ricostruisce le parti.
-- Le posizioni di gameplay restano in WorldLayout. Le decorazioni non collidono.

local Lighting = game:GetService("Lighting")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local ArenaConfig = shared("ArenaConfig")
local WorldLayout = shared("WorldLayout")
local PetConfig = shared("PetConfig")
local Strings = shared("Strings")
local WorldTextConfig = shared("WorldTextConfig")
local PropKit = shared("PropKit")
local EggService = require(script.Parent.EggService)

local WorldBuilder = {}

local function ensureEffect(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = parent
	return created
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
	Lighting.ClockTime = 16.1
	Lighting.Brightness = 2.35
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(92, 90, 104)
	Lighting.OutdoorAmbient = Color3.fromRGB(156, 154, 166)
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.25
	Lighting.ShadowSoftness = 0.3

	local atmosphere = ensureEffect("Atmosphere", "KurkitoAtmosphere", Lighting)
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(198, 204, 220)
	atmosphere.Decay = Color3.fromRGB(110, 104, 130)
	atmosphere.Glare = 0.12
	atmosphere.Haze = 0.8

	local bloom = ensureEffect("BloomEffect", "KurkitoBloom", Lighting)
	bloom.Intensity = 0.35
	bloom.Size = 18
	bloom.Threshold = 1.85

	local correction = ensureEffect("ColorCorrectionEffect", "KurkitoColor", Lighting)
	correction.Brightness = 0.02
	correction.Contrast = 0.06
	correction.Saturation = 0.08
	correction.TintColor = Color3.fromRGB(255, 248, 240)

	local sun = ensureEffect("SunRaysEffect", "KurkitoSun", Lighting)
	sun.Intensity = 0.06
	sun.Spread = 0.4
end

local function decorateArena(root, arena, center)
	local decor = arena.decor
	local accent = arena.accent
	local half = WorldLayout.ArenaHalf() - 16
	local y = 1
	local spots = {
		Vector3.new(center.X - half, y, center.Z - half + 8),
		Vector3.new(center.X + half, y, center.Z - half + 8),
		Vector3.new(center.X - half, y, center.Z + half - 10),
		Vector3.new(center.X + half, y, center.Z + half - 10),
		Vector3.new(center.X - half + 6, y, center.Z),
		Vector3.new(center.X + half - 6, y, center.Z),
	}
	if decor == "crypt" then
		PropKit.Pillar(root, "PillarA", spots[1], 7, arena.wall, Enum.Material.Slate)
		PropKit.Pillar(root, "PillarB", spots[2], 7, arena.wall, Enum.Material.Slate)
		PropKit.Coffin(root, "CoffinA", spots[3], 0.4)
		PropKit.Torch(root, "TorchA", spots[5], accent, false)
		PropKit.Torch(root, "TorchB", spots[6], accent, false)
	elseif decor == "graveyard" then
		PropKit.Grave(root, "GraveA", spots[1])
		PropKit.Grave(root, "GraveB", spots[2])
		PropKit.Tree(root, "DeadTree", spots[3], "dead")
		PropKit.Rock(root, "BoneRock", spots[4], 1.1, Color3.fromRGB(180, 176, 160))
	elseif decor == "forest" then
		PropKit.Tree(root, "TreeA", spots[1], "oak")
		PropKit.Tree(root, "TreeB", spots[2], "pine")
		PropKit.Rock(root, "RockA", spots[5], 1.2, Color3.fromRGB(110, 108, 96))
		PropKit.Rock(root, "RockB", spots[6], 0.8, Color3.fromRGB(96, 100, 86))
	elseif decor == "fortress" then
		PropKit.Banner(root, "BannerA", spots[1], accent, 0.2)
		PropKit.Banner(root, "BannerB", spots[2], arena.color, -0.2)
		PropKit.Pillar(root, "KeepA", spots[3], 8, arena.wall, Enum.Material.Brick)
		PropKit.Torch(root, "BrazierA", spots[5], accent, false)
		PropKit.Torch(root, "BrazierB", spots[6], accent, false)
	elseif decor == "swamp" then
		PropKit.Tree(root, "BogTree", spots[1], "swamp")
		PropKit.Tree(root, "BogTreeB", spots[2], "dead")
		PropKit.Rock(root, "Moss", spots[5], 1.3, Color3.fromRGB(70, 90, 64))
		PropKit.Crystal(root, "Spore", spots[6] + Vector3.new(0, 0, 2), accent, 0.8)
	elseif decor == "nest" then
		PropKit.Web(root, "WebA", spots[1] + Vector3.new(0, 3, 0))
		PropKit.Web(root, "WebB", spots[2] + Vector3.new(0, 3.4, 0))
		PropKit.Egg(root, "Sac", spots[3] + Vector3.new(0, 1.6, 0), accent, false)
		PropKit.Rock(root, "NestRock", spots[4], 1, Color3.fromRGB(70, 60, 66))
	elseif decor == "chapel" then
		PropKit.Pillar(root, "ChapelA", spots[1], 9, Color3.fromRGB(70, 64, 84), Enum.Material.Marble)
		PropKit.Pillar(root, "ChapelB", spots[2], 9, Color3.fromRGB(70, 64, 84), Enum.Material.Marble)
		PropKit.Torch(root, "CandleA", spots[5], accent, false)
		PropKit.Banner(root, "ChapelBanner", spots[3], accent, 0)
	elseif decor == "gorge" then
		PropKit.Rock(root, "GorgeA", spots[1], 1.8, Color3.fromRGB(150, 110, 70))
		PropKit.Rock(root, "GorgeB", spots[2], 1.4, Color3.fromRGB(130, 96, 60))
		PropKit.Rock(root, "GorgeC", spots[5], 1, Color3.fromRGB(120, 90, 58))
		PropKit.Banner(root, "Hide", spots[6], accent, 0.6)
	elseif decor == "frozen" then
		PropKit.Tree(root, "IceTree", spots[1], "snow")
		PropKit.Crystal(root, "IceA", spots[2], accent, 1.3)
		PropKit.Crystal(root, "IceB", spots[5], Color3.fromRGB(210, 230, 255), 0.9)
		PropKit.Rock(root, "SnowRock", spots[6], 1.1, Color3.fromRGB(200, 210, 216))
	elseif decor == "temple" then
		PropKit.Pillar(root, "TempleA", spots[1], 10, Color3.fromRGB(196, 176, 130), Enum.Material.Sandstone)
		PropKit.Pillar(root, "TempleB", spots[2], 10, Color3.fromRGB(196, 176, 130), Enum.Material.Sandstone)
		PropKit.Crystal(root, "RuneStone", spots[5], accent, 1)
		PropKit.Statue(root, "Guardian", spots[6], Color3.fromRGB(210, 200, 180))
	elseif decor == "volcano" then
		PropKit.Rock(root, "MagmaA", spots[1], 1.6, Color3.fromRGB(60, 40, 38))
		PropKit.Rock(root, "MagmaB", spots[2], 1.3, Color3.fromRGB(70, 42, 36))
		PropKit.LavaCrack(root, "LavaA", spots[5], 0.4)
		PropKit.Torch(root, "Vent", spots[6], accent, false)
	elseif decor == "kingdom" then
		PropKit.Banner(root, "RoyalA", spots[1], accent, 0)
		PropKit.Banner(root, "RoyalB", spots[2], Color3.fromRGB(40, 48, 90), 0)
		PropKit.Statue(root, "KnightStatue", spots[3], Color3.fromRGB(180, 186, 198))
		PropKit.Pillar(root, "Court", spots[6], 8, Color3.fromRGB(90, 94, 110), Enum.Material.Marble)
	else
		PropKit.Crystal(root, "VoidA", spots[1], accent, 1.5)
		PropKit.Crystal(root, "VoidB", spots[2], Color3.fromRGB(90, 40, 160), 1.2)
		PropKit.Pillar(root, "AbyssA", spots[3], 9, Color3.fromRGB(30, 24, 44), Enum.Material.Basalt)
		PropKit.Torch(root, "AbyssFlame", spots[5], accent, false)
	end
end

local function buildArena(arenas, paths, arena)
	local center = WorldLayout.ArenaCenter(arena.index)
	local size = WorldLayout.ArenaSize
	local half = size / 2
	local height = WorldLayout.WallHeight
	local floorTop = 1
	local root = PropKit.Folder(arenas, string.format("Arena_%02d", arena.index))
	local floorPiece = PropKit.Part(root, "Floor", Vector3.new(size, 2, size), CFrame.new(center), arena.floor or arena.color, arena.floorMaterial or Enum.Material.Slate, true, nil, true)
	PropKit.Light(floorPiece, arena.accent or arena.color, 22, 0.45)
	PropKit.Part(root, "Inlay", Vector3.new(size - 18, 0.08, size - 18), CFrame.new(center + Vector3.new(0, 1.02, 0)), arena.color, Enum.Material.Slate, false, 0.15)

	local wallY = floorTop + height / 2
	local thickness = 4
	local gap = 18
	local side = (size - gap) / 2
	local zSouth = center.Z - half
	local xShift = gap / 2 + side / 2
	local wallColor = arena.wall or Color3.fromRGB(58, 56, 68)
	PropKit.Part(root, "WallSouthL", Vector3.new(side, height, thickness), CFrame.new(center.X - xShift, wallY, zSouth), wallColor, Enum.Material.Concrete, true, nil, true)
	PropKit.Part(root, "WallSouthR", Vector3.new(side, height, thickness), CFrame.new(center.X + xShift, wallY, zSouth), wallColor, Enum.Material.Concrete, true, nil, true)
	PropKit.Part(root, "WallNorth", Vector3.new(size, height, thickness), CFrame.new(center.X, wallY, center.Z + half), wallColor, Enum.Material.Concrete, true, nil, true)
	PropKit.Part(root, "WallEast", Vector3.new(thickness, height, size), CFrame.new(center.X + half, wallY, center.Z), wallColor, Enum.Material.Concrete, true, nil, true)
	PropKit.Part(root, "WallWest", Vector3.new(thickness, height, size), CFrame.new(center.X - half, wallY, center.Z), wallColor, Enum.Material.Concrete, true, nil, true)

	local gate = PropKit.Part(root, "Gate", Vector3.new(gap - 1, height, 2), CFrame.new(center.X, wallY, zSouth), arena.color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.ForceField, true, 0.35, false)
	PropKit.Part(root, "GateFrameL", Vector3.new(1.4, height + 1, 1.6), CFrame.new(center.X - gap / 2, wallY, zSouth - 1.2), arena.accent, Enum.Material.Metal, false)
	PropKit.Part(root, "GateFrameR", Vector3.new(1.4, height + 1, 1.6), CFrame.new(center.X + gap / 2, wallY, zSouth - 1.2), arena.accent, Enum.Material.Metal, false)
	PropKit.Part(root, "GateLintel", Vector3.new(gap + 1, 1.2, 1.6), CFrame.new(center.X, floorTop + height + 0.4, zSouth - 1.2), arena.accent, Enum.Material.Metal, false)

	local pad = PropKit.Part(root, "SafePad", Vector3.new(16, 1, 16), CFrame.new(center.X, 1.5, center.Z - 58), Color3.fromRGB(230, 210, 140), Enum.Material.Neon, true, 0.45, false)
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

	local sign = PropKit.Part(root, "Sign", Vector3.new(1.2, 5.5, 0.4), CFrame.new(center.X - 16, 3.6, zSouth - 8), Color3.fromRGB(48, 40, 34), Enum.Material.Wood, true, nil, true)
	PropKit.Part(root, "SignPost", Vector3.new(0.4, 5.5, 0.4), sign.CFrame * CFrame.new(0, 0, 0.3), Color3.fromRGB(70, 52, 36), Enum.Material.Wood, true)
	PropKit.Billboard(sign, Strings.ArenaSign(arena.index, arena.name, arena.mastery, arena.cost), "ArenaName", UDim2.fromOffset(220, 86), Vector3.new(0, 4.2, 0), Color3.new(1, 1, 1))
	PropKit.Prompt(sign, "Arena", arena.name, "Arena", { ArenaIndex = arena.index }, WorldTextConfig.Prompt("Arena"))

	local back = PropKit.Part(root, "ReturnPad", Vector3.new(10, 1, 10), CFrame.new(center.X, 1.6, center.Z - 48), Color3.fromRGB(186, 186, 196), Enum.Material.Marble, true, nil, true)
	PropKit.Prompt(back, "Lobby", "Return", "Lobby", {}, WorldTextConfig.Prompt("Default"))

	decorateArena(root, arena, center)

	if arena.index < 15 then
		local nextCenter = WorldLayout.ArenaCenter(arena.index + 1)
		local fromZ = center.Z + half
		local toZ = nextCenter.Z - half
		local mid = (fromZ + toZ) / 2
		local length = math.abs(toZ - fromZ)
		PropKit.Part(paths, "Bridge_" .. arena.index, Vector3.new(28, 2, length), CFrame.new(0, 0, mid), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true, nil, true)
		PropKit.FenceRun(paths, "RailL_" .. arena.index, Vector3.new(-14, 1, fromZ), Vector3.new(-14, 1, toZ), Color3.fromRGB(96, 74, 48))
		PropKit.FenceRun(paths, "RailR_" .. arena.index, Vector3.new(14, 1, fromZ), Vector3.new(14, 1, toZ), Color3.fromRGB(96, 74, 48))
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
		PropKit.Part(parent, name .. "_" .. step, Vector3.new(28, 2, depth), CFrame.new(0, top - 1, centerZ), Color3.fromRGB(150, 136, 108), Enum.Material.Cobblestone, true, nil, true)
	end
	PropKit.Part(parent, name .. "WallL", Vector3.new(2.2, math.abs(toTop - fromTop) + 4, length), CFrame.new(-18, (fromTop + toTop) * 0.5, (fromZ + toZ) * 0.5), Color3.fromRGB(120, 100, 74), Enum.Material.Slate, true, nil, true)
	PropKit.Part(parent, name .. "WallR", Vector3.new(2.2, math.abs(toTop - fromTop) + 4, length), CFrame.new(18, (fromTop + toTop) * 0.5, (fromZ + toZ) * 0.5), Color3.fromRGB(120, 100, 74), Enum.Material.Slate, true, nil, true)
end

local function buildEggs(paths, world)
	local eggRoot = PropKit.Folder(world, "EggZone")
	local terraces = WorldLayout.EggTerraces()
	PropKit.Part(paths, "PathEggs", Vector3.new(28, 2, 150), CFrame.new(0, 0, -185), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true, nil, true)
	PropKit.Part(eggRoot, "Hillside", Vector3.new(280, 18, 460), CFrame.new(0, -6, -500), Color3.fromRGB(96, 118, 72), Enum.Material.Grass, false, nil, true)
	for index, terrace in ipairs(terraces) do
		local center = terrace.position
		local slab = PropKit.Part(eggRoot, "Terrace_" .. index, Vector3.new(230, 2, 100), CFrame.new(center), Color3.fromRGB(214, 186, 132), Enum.Material.Sandstone, true, nil, true)
		if index == 1 then
			PropKit.Light(slab, Color3.fromRGB(255, 214, 150), 18, 0.4)
		end
		PropKit.Part(eggRoot, "RailL_" .. index, Vector3.new(3, 4.5, 100), CFrame.new(center + Vector3.new(-113, 3, 0)), Color3.fromRGB(122, 96, 68), Enum.Material.Slate, true, nil, true)
		PropKit.Part(eggRoot, "RailR_" .. index, Vector3.new(3, 4.5, 100), CFrame.new(center + Vector3.new(113, 3, 0)), Color3.fromRGB(122, 96, 68), Enum.Material.Slate, true, nil, true)
		local sign = PropKit.Part(eggRoot, "TerraceSign_" .. index, Vector3.new(0.4, 4.2, 6), CFrame.new(center + Vector3.new(0, 3.2, -42)), Color3.fromRGB(70, 52, 36), Enum.Material.Wood, true)
		PropKit.Billboard(sign, "Egg Terrace " .. index, "InfoSign", UDim2.fromOffset(200, 48), Vector3.new(0, 3.2, 0), Color3.fromRGB(255, 236, 200))
		PropKit.Tree(eggRoot, "TerraceTreeL_" .. index, center + Vector3.new(-96, 1, 30), index == 3 and "pine" or "oak")
		PropKit.Rock(eggRoot, "TerraceRock_" .. index, center + Vector3.new(96, 1, 28), 1, Color3.fromRGB(130, 118, 96))
		for slot, arenaIndex in ipairs(terrace.arenas) do
			local eggPos = WorldLayout.EggPosition(terrace, slot)
			local eggDef = PetConfig.GetEgg(arenaIndex)
			local column = PropKit.Pedestal(eggRoot, "Pedestal_" .. arenaIndex, eggPos - Vector3.new(0, 3.4, 0), eggDef.color:Lerp(Color3.fromRGB(40, 32, 24), 0.45))
			PropKit.Egg(eggRoot, "Egg_" .. arenaIndex, eggPos, eggDef.color, false)
			local odds = EggService.OddsText(eggDef.pool)
			PropKit.Billboard(column, Strings.EggSign(arenaIndex, eggDef.cost, odds), "EggPrice", UDim2.fromOffset(230, 140), Vector3.new(0, 5.2, 0), Color3.new(1, 1, 1))
			PropKit.Prompt(column, "Open", eggDef.cost .. " Coins", "OpenEgg", { ArenaIndex = arenaIndex }, WorldTextConfig.Prompt("Egg"))
		end
		local special = PetConfig.SpecialEggs[terrace.special]
		local specialPos = WorldLayout.EggPosition(terrace, 6)
		local specialPad = PropKit.Pedestal(eggRoot, "RobuxPad_" .. index, specialPos - Vector3.new(0, 3.2, 0), Color3.fromRGB(48, 40, 32))
		PropKit.Egg(eggRoot, "RobuxEgg_" .. index, specialPos + Vector3.new(0, 0.3, 0), special.color, true)
		PropKit.Billboard(specialPad, Strings.RobuxEggSign(special.name, EggService.OddsText(special.pool)), "EggPetInfo", UDim2.fromOffset(240, 160), Vector3.new(0, 5.6, 0), Color3.fromRGB(255, 220, 140))
		PropKit.Prompt(specialPad, "Info", "Not for sale", "RobuxEgg", { SpecialIndex = terrace.special }, WorldTextConfig.Prompt("Egg"))
	end
	local first = terraces[1].position
	local second = terraces[2].position
	local third = terraces[3].position
	buildStairs(eggRoot, "Stairs12", first.Z - 50, second.Z + 50, 1, 17)
	buildStairs(eggRoot, "Stairs23", second.Z - 50, third.Z + 50, 17, 33)
end

local function buildBoards(paths, world)
	local root = PropKit.Folder(world, "Leaderboards")
	local origin = WorldLayout.LeaderboardOrigin()
	PropKit.Part(root, "Plaza", Vector3.new(180, 2, 90), CFrame.new(origin), Color3.fromRGB(214, 210, 204), Enum.Material.Marble, true, nil, true)
	PropKit.Part(paths, "PathBoards", Vector3.new(80, 2, 24), CFrame.new(-160, 0, 0), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true, nil, true)
	local titles = {
		{ id = "Rebirth", title = "MOST REBIRTH" },
		{ id = "Time", title = "MOST TIME PLAYED" },
		{ id = "Kills", title = "MOST KILLS" },
	}
	local metals = {
		{ color = Color3.fromRGB(212, 170, 64), material = Enum.Material.Metal },
		{ color = Color3.fromRGB(186, 192, 200), material = Enum.Material.Metal },
		{ color = Color3.fromRGB(168, 112, 64), material = Enum.Material.Metal },
	}
	for boardIndex, board in ipairs(titles) do
		local headerPos = origin + Vector3.new((boardIndex - 2) * 52, 8, -28)
		local header = PropKit.Part(root, "Header_" .. board.id, Vector3.new(28, 5, 0.6), CFrame.new(headerPos), Color3.fromRGB(28, 26, 40), Enum.Material.SmoothPlastic, true)
		PropKit.Part(root, "HeaderTrim_" .. board.id, Vector3.new(28, 0.25, 0.7), header.CFrame * CFrame.new(0, -2.4, 0), Color3.fromRGB(212, 176, 90), Enum.Material.Metal, false)
		PropKit.Billboard(header, board.title, "Podium", UDim2.fromOffset(240, 42), Vector3.new(0, 3.4, 0), Color3.fromRGB(240, 210, 120))
		for place = 1, 3 do
			local center, size = WorldLayout.PodiumSpec(boardIndex, place)
			local metal = metals[place]
			local podium = PropKit.Part(root, WorldLayout.PodiumName(board.id, place), size, CFrame.new(center), metal.color, metal.material, true, nil, true)
			PropKit.Part(root, "PodiumBase_" .. board.id .. place, Vector3.new(size.X + 1.4, 0.4, size.Z + 1.4), CFrame.new(center - Vector3.new(0, size.Y / 2, 0)), metal.color:Lerp(Color3.new(0, 0, 0), 0.35), Enum.Material.Slate, true)
			podium:SetAttribute("PodiumBoard", board.id)
			podium:SetAttribute("PodiumPlace", place)
			if place == 1 then
				PropKit.Light(podium, metal.color, 10, 0.35)
			end
			local gui = Instance.new("SurfaceGui")
			gui.Name = "PodiumGui"
			gui.Face = Enum.NormalId.Front
			gui.CanvasSize = Vector2.new(200, 120)
			gui.Parent = podium
			WorldTextConfig.Mark(gui, "Podium")
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
	PropKit.Folder(root, "PodiumFigures")
end

local function servicePad(parent, name, position, color, text, action, category)
	local pad = PropKit.Part(parent, name, Vector3.new(16, 1.2, 16), CFrame.new(position.X, 0.6, position.Z), color, Enum.Material.Marble, true, nil, true)
	local post = PropKit.Part(parent, name .. "Post", Vector3.new(1.2, 7, 1.2), CFrame.new(position.X, 4.2, position.Z), color:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Metal, true)
	local crystal = PropKit.Part(parent, name .. "Crystal", Vector3.new(1.3, 1.3, 1.3), post.CFrame * CFrame.new(0, 3.6, 0), color, Enum.Material.Neon, false, 0.1)
	crystal.Shape = Enum.PartType.Ball
	PropKit.Light(crystal, color, 12, 0.45)
	PropKit.Billboard(post, text, category, UDim2.fromOffset(200, 72), Vector3.new(0, 5.2, 0), Color3.new(1, 1, 1))
	PropKit.Prompt(post, "Interact", text, action, nil, WorldTextConfig.Prompt("Service"))
	PropKit.Arch(parent, name .. "Arch", Vector3.new(position.X, 1, position.Z - 10), color, 0)
	return pad
end

local function buildServices(paths, world)
	local root = PropKit.Folder(world, "Services")
	PropKit.Part(root, "EastFloor", Vector3.new(280, 2, 240), CFrame.new(300, 0, 40), Color3.fromRGB(74, 68, 92), Enum.Material.Slate, true, nil, true)
	PropKit.Part(paths, "PathEast", Vector3.new(70, 2, 28), CFrame.new(150, 0, 20), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true, nil, true)
	servicePad(root, "HeroPad", WorldLayout.HeroSwitch(), Color3.fromRGB(176, 72, 58), "Heroes\nChange character", "Hero", "Interaction")
	servicePad(root, "UpgradePad", WorldLayout.Upgrades(), Color3.fromRGB(80, 140, 200), "Upgrades\nOpen the menu", "UpgradeInfo", "UpgradeStation")
	servicePad(root, "FusionPad", WorldLayout.Fusion(), Color3.fromRGB(90, 190, 210), "Pet Fusion\n5 identical = 1 evolved", "FusionInfo", "Interaction")
	servicePad(root, "RebirthPad", WorldLayout.Rebirth(), Color3.fromRGB(140, 80, 190), "Rebirth Altar\nMastery 50", "Rebirth", "RebirthInfo")
	PropKit.Banner(root, "HeroFlag", WorldLayout.HeroSwitch() + Vector3.new(10, 0, -8), Color3.fromRGB(176, 72, 58), 0.8)
	PropKit.Banner(root, "RebirthFlag", WorldLayout.Rebirth() + Vector3.new(-12, 0, 8), Color3.fromRGB(150, 80, 200), -0.4)

	local portalPos = WorldLayout.Portal()
	PropKit.Part(root, "PortalPlatform", Vector3.new(40, 2, 40), CFrame.new(portalPos.X, 0, portalPos.Z), Color3.fromRGB(58, 58, 68), Enum.Material.Basalt, true, nil, true)
	PropKit.Part(paths, "PathPortal", Vector3.new(20, 2, 80), CFrame.new(400, 0, 160), Color3.fromRGB(90, 90, 96), Enum.Material.Basalt, true, nil, true)
	local ring = PropKit.Part(root, "World2Ring", Vector3.new(16, 16, 2), CFrame.new(portalPos), Color3.fromRGB(70, 74, 96), Enum.Material.Metal, true)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(portalPos) * CFrame.Angles(0, 0, math.rad(90))
	local lockBar = PropKit.Part(root, "World2Lock", Vector3.new(1.2, 11, 1.2), CFrame.new(portalPos), Color3.fromRGB(36, 36, 44), Enum.Material.DiamondPlate, true)
	PropKit.Billboard(lockBar, "World 2\nPortal inactive", "InfoSign", UDim2.fromOffset(180, 64), Vector3.new(0, 4, 0), Color3.fromRGB(200, 200, 210))
	PropKit.Prompt(lockBar, "Info", "World 2", "Portal", nil, WorldTextConfig.Prompt("Portal"))
end

local function buildLobby(paths, world)
	local lobby = PropKit.Folder(world, "Lobby")
	PropKit.Part(lobby, "Floor", Vector3.new(WorldLayout.LobbySize, 2, WorldLayout.LobbySize), CFrame.new(0, 0, 0), Color3.fromRGB(62, 60, 74), Enum.Material.Slate, true, nil, true)
	PropKit.Part(lobby, "PlazaRing", Vector3.new(54, 0.15, 54), CFrame.new(0, 1.08, 0), Color3.fromRGB(186, 164, 112), Enum.Material.Marble, false)
	PropKit.Fountain(lobby, "Fountain", Vector3.new(0, 1, 0))
	local monument = PropKit.Part(lobby, "Obelisk", Vector3.new(3.2, 16, 3.2), CFrame.new(0, 10, -16), Color3.fromRGB(226, 210, 160), Enum.Material.Marble, true, nil, true)
	PropKit.Part(lobby, "ObeliskCap", Vector3.new(1.2, 2.4, 1.2), monument.CFrame * CFrame.new(0, 9, 0), Color3.fromRGB(255, 214, 120), Enum.Material.Neon, false, 0.1)
	PropKit.Billboard(monument, "KURKITO\nBattle Survival\nWorld 1", "LobbyTitle", UDim2.fromOffset(240, 88), Vector3.new(0, 10, 0), Color3.fromRGB(255, 236, 190))
	PropKit.Light(monument, Color3.fromRGB(255, 220, 170), 16, 0.55)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 1.6, 36)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 0.35
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(240, 214, 150)
	spawn.Parent = lobby

	PropKit.Tree(lobby, "TreeNW", Vector3.new(-78, 1, -70), "oak")
	PropKit.Tree(lobby, "TreeNE", Vector3.new(78, 1, -70), "pine")
	PropKit.Tree(lobby, "TreeSW", Vector3.new(-78, 1, 70), "oak")
	PropKit.Tree(lobby, "TreeSE", Vector3.new(78, 1, 70), "pine")
	PropKit.Rock(lobby, "RockW", Vector3.new(-60, 1, 20), 1.1, Color3.fromRGB(120, 116, 110))
	PropKit.Rock(lobby, "RockE", Vector3.new(60, 1, -24), 0.9, Color3.fromRGB(110, 108, 102))
	PropKit.Bench(lobby, "BenchW", CFrame.new(-28, 1.7, 18))
	PropKit.Bench(lobby, "BenchE", CFrame.new(28, 1.7, 18) * CFrame.Angles(0, math.rad(180), 0))
	PropKit.Lantern(lobby, "LampNW", Vector3.new(-36, 1, -36), Color3.fromRGB(255, 196, 130), true)
	PropKit.Lantern(lobby, "LampNE", Vector3.new(36, 1, -36), Color3.fromRGB(255, 196, 130), true)
	PropKit.Lantern(lobby, "LampSW", Vector3.new(-36, 1, 48), Color3.fromRGB(255, 196, 130), false)
	PropKit.Lantern(lobby, "LampSE", Vector3.new(36, 1, 48), Color3.fromRGB(255, 196, 130), false)
	PropKit.Torch(lobby, "TorchN", Vector3.new(-12, 1, 78), Color3.fromRGB(255, 150, 70), false)
	PropKit.Torch(lobby, "TorchS", Vector3.new(12, 1, -78), Color3.fromRGB(255, 150, 70), false)
	PropKit.Banner(lobby, "FlagW", Vector3.new(-48, 1, 0), Color3.fromRGB(150, 42, 48), 1.57)
	PropKit.Banner(lobby, "FlagE", Vector3.new(48, 1, 0), Color3.fromRGB(48, 72, 140), -1.57)
	PropKit.Statue(lobby, "HeroStatue", Vector3.new(0, 1, 62), Color3.fromRGB(214, 206, 188))

	local function pointer(name, position, text)
		local post = PropKit.Part(lobby, name, Vector3.new(1.1, 5.5, 1.1), CFrame.new(position), Color3.fromRGB(64, 56, 48), Enum.Material.Wood, true)
		PropKit.Billboard(post, text, "InfoSign", UDim2.fromOffset(200, 56), Vector3.new(0, 3.6, 0), Color3.fromRGB(240, 230, 210))
	end
	pointer("SignArenas", Vector3.new(0, 3.5, 90), "Arenas → north")
	pointer("SignEggs", Vector3.new(0, 3.5, -90), "Eggs → south")
	pointer("SignBoards", Vector3.new(-90, 3.5, 0), "Leaderboards → west")
	pointer("SignHeroes", Vector3.new(90, 3.5, 0), "Heroes and Rebirth → east")

	local first = WorldLayout.ArenaCenter(1)
	local pathLength = (first.Z - WorldLayout.ArenaHalf()) - 110
	local pathCenter = 110 + pathLength / 2
	PropKit.Part(paths, "PathArenas", Vector3.new(28, 2, pathLength), CFrame.new(0, 0, pathCenter), Color3.fromRGB(118, 112, 100), Enum.Material.Cobblestone, true, nil, true)
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
	local world = PropKit.Folder(workspace, "KurkitoWorld")
	world:SetAttribute("BuildId", GameConfig.WorldBuildId)
	local paths = PropKit.Folder(world, "Paths")
	local arenas = PropKit.Folder(world, "Arenas")
	PropKit.Folder(world, "Enemies")
	PropKit.Folder(world, "Effects")
	buildLobby(paths, world)
	for _, arena in ipairs(ArenaConfig) do
		buildArena(arenas, paths, arena)
	end
	buildEggs(paths, world)
	buildBoards(paths, world)
	buildServices(paths, world)
	print("[Kurkito] World 1 built (" .. GameConfig.WorldBuildId .. ").")
	return world
end

return WorldBuilder
