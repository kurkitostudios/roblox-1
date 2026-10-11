-- Mondo 0 idempotente. Se BuildId coincide non ricostruisce le parti.
-- Lobby e Arena 1 sono la build visiva. Le arene 2–15 restano giocabili, non rifinite.

local Lighting = game:GetService("Lighting")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local ArenaConfig = shared("ArenaConfig")
local WorldLayout = shared("WorldLayout")
local PetConfig = shared("PetConfig")
local Strings = shared("Strings")
local WorldTextConfig = shared("WorldTextConfig")
local PropKit = shared("PropKit")
local TribalKit = shared("TribalKit")
local EggService = require(script.Parent.EggService)

local WorldBuilder = {}

local EARTH = Color3.fromRGB(116, 86, 54)
local GRASS = Color3.fromRGB(86, 112, 62)
local WOOD = Color3.fromRGB(92, 64, 40)
local BONE = Color3.fromRGB(214, 196, 164)
local RED = Color3.fromRGB(138, 42, 36)

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
	Lighting.ClockTime = 17.35
	Lighting.Brightness = 2.15
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(110, 86, 68)
	Lighting.OutdoorAmbient = Color3.fromRGB(186, 140, 102)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.ShadowSoftness = 0.35

	local atmosphere = ensureEffect("Atmosphere", "KurkitoAtmosphere", Lighting)
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.18
	atmosphere.Color = Color3.fromRGB(255, 196, 150)
	atmosphere.Decay = Color3.fromRGB(120, 78, 52)
	atmosphere.Glare = 0.18
	atmosphere.Haze = 1.1

	local bloom = ensureEffect("BloomEffect", "KurkitoBloom", Lighting)
	bloom.Intensity = 0.28
	bloom.Size = 16
	bloom.Threshold = 1.9

	local correction = ensureEffect("ColorCorrectionEffect", "KurkitoColor", Lighting)
	correction.Brightness = 0.02
	correction.Contrast = 0.08
	correction.Saturation = 0.12
	correction.TintColor = Color3.fromRGB(255, 232, 210)

	local sun = ensureEffect("SunRaysEffect", "KurkitoSun", Lighting)
	sun.Intensity = 0.08
	sun.Spread = 0.55
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
	if decor == "graveyard" then
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
	elseif decor ~= "gravewilds" then
		PropKit.Crystal(root, "VoidA", spots[1], accent, 1.5)
		PropKit.Crystal(root, "VoidB", spots[2], Color3.fromRGB(90, 40, 160), 1.2)
		PropKit.Pillar(root, "AbyssA", spots[3], 9, Color3.fromRGB(30, 24, 44), Enum.Material.Basalt)
		PropKit.Torch(root, "AbyssFlame", spots[5], accent, false)
	end
end

local function buildBoxedArena(root, paths, arena, center)
	local size = WorldLayout.ArenaSize
	local half = size / 2
	local height = WorldLayout.WallHeight
	local floorTop = 1
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
	decorateArena(root, arena, center)
	return zSouth, gap
end

local function buildGraveWilds(root, arena, center)
	local size = WorldLayout.ArenaSize
	local half = size / 2
	local floor = PropKit.Part(root, "Floor", Vector3.new(size, 2, size), CFrame.new(center), arena.floor, Enum.Material.Ground, true, nil, true)
	PropKit.Part(root, "MudA", Vector3.new(36, 0.08, 22), CFrame.new(center + Vector3.new(-18, 1.05, 8)), Color3.fromRGB(72, 58, 40), Enum.Material.Mud, false)
	PropKit.Part(root, "MudB", Vector3.new(28, 0.08, 18), CFrame.new(center + Vector3.new(22, 1.05, -6)), Color3.fromRGB(84, 64, 42), Enum.Material.Mud, false)
	PropKit.Part(root, "Ash", Vector3.new(16, 0.08, 16), CFrame.new(center + Vector3.new(8, 1.06, 24)), Color3.fromRGB(58, 52, 48), Enum.Material.Slate, false, 0.1)
	PropKit.Light(floor, Color3.fromRGB(255, 120, 60), 18, 0.25)

	local zSouth = center.Z - half
	local gap = 18
	local colors = {
		Color3.fromRGB(92, 78, 64),
		Color3.fromRGB(74, 64, 54),
		Color3.fromRGB(110, 96, 80),
	}
	local function cliffRun(name, alongZ, fixed, from, to, gapCenter)
		local length = math.abs(to - from)
		local count = math.max(3, math.floor(length / 14))
		for index = 0, count do
			local alpha = index / count
			local coord = from + (to - from) * alpha
			if gapCenter and math.abs(coord - gapCenter) < gap * 0.55 then
				continue
			end
			local height = 12 + (index % 3) * 2.4
			local depth = 7 + (index % 2) * 2
			local cf
			if alongZ then
				cf = CFrame.new(fixed, 1 + height / 2, coord) * CFrame.Angles(0, 0.08 * (index % 2 == 0 and 1 or -1), 0)
				TribalKit.Cliff(root, name .. index, cf, Vector3.new(depth, height, 13), colors[(index % #colors) + 1])
			else
				cf = CFrame.new(coord, 1 + height / 2, fixed) * CFrame.Angles(0, 0.1, 0)
				TribalKit.Cliff(root, name .. index, cf, Vector3.new(13, height, depth), colors[(index % #colors) + 1])
			end
		end
	end
	cliffRun("North", false, center.Z + half - 3, center.X - half + 6, center.X + half - 6, nil)
	cliffRun("South", false, zSouth + 3, center.X - half + 6, center.X + half - 6, center.X)
	cliffRun("West", true, center.X - half + 3, center.Z - half + 8, center.Z + half - 8, nil)
	cliffRun("East", true, center.X + half - 3, center.Z - half + 8, center.Z + half - 8, nil)

	PropKit.Part(root, "GateSeal", Vector3.new(gap - 1, 12, 2.2), CFrame.new(center.X, 7, zSouth + 2), Color3.fromRGB(62, 48, 40), Enum.Material.Wood, true, nil, true)
	TribalKit.BoneArch(root, "GateArch", Vector3.new(center.X, 1, zSouth - 2), 0)
	TribalKit.Skull(root, "GateSkull", CFrame.new(center.X, 6.2, zSouth + 1.2), 1.1)

	local edge = half - 18
	PropKit.Tree(root, "DeadA", Vector3.new(center.X - edge, 1, center.Z - edge + 6), "dead")
	PropKit.Tree(root, "DeadB", Vector3.new(center.X + edge, 1, center.Z + edge - 8), "dead")
	PropKit.Tree(root, "DeadC", Vector3.new(center.X - edge + 4, 1, center.Z + edge - 10), "dead")
	TribalKit.Campfire(root, "ColdCamp", Vector3.new(center.X + edge - 4, 1, center.Z - 8), true)
	TribalKit.Totem(root, "RuinTotem", Vector3.new(center.X - edge + 2, 1, center.Z + 4), 0.6, RED)
	TribalKit.Skull(root, "BonePileA", CFrame.new(center.X + edge - 8, 1.6, center.Z + edge - 12), 1.3)
	TribalKit.Skull(root, "BonePileB", CFrame.new(center.X - edge + 10, 1.5, center.Z - edge + 14), 1)
	PropKit.Rock(root, "BoulderA", Vector3.new(center.X - edge + 8, 1, center.Z - 4), 1.6, Color3.fromRGB(90, 80, 70))
	PropKit.Rock(root, "BoulderB", Vector3.new(center.X + edge - 6, 1, center.Z + 16), 1.3, Color3.fromRGB(80, 70, 60))
	TribalKit.Tuft(root, "ScrubA", Vector3.new(center.X - 50, 1, center.Z + 40), 1.2)
	TribalKit.Tuft(root, "ScrubB", Vector3.new(center.X + 52, 1, center.Z - 36), 1)
	PropKit.Part(root, "Ribs", Vector3.new(2.2, 0.3, 1.4), CFrame.new(center.X + edge - 2, 1.3, center.Z - edge + 12) * CFrame.Angles(0, 0.5, 0), BONE, Enum.Material.SmoothPlastic, false)
	TribalKit.Banner(root, "RuinBanner", Vector3.new(center.X - edge + 6, 1, center.Z - edge + 8), 0.4, RED)
	PropKit.Part(root, "FallenPost", Vector3.new(6, 0.45, 0.45), CFrame.new(center.X + edge - 10, 1.4, center.Z + 8) * CFrame.Angles(0, 0.6, math.rad(80)), WOOD, Enum.Material.Wood, false)
	TribalKit.Skull(root, "RuinSkull", CFrame.new(center.X - edge + 12, 1.8, center.Z + edge - 16), 1.2)
	return zSouth
end

local function buildArena(arenas, paths, arena)
	local center = WorldLayout.ArenaCenter(arena.index)
	local root = PropKit.Folder(arenas, string.format("Arena_%02d", arena.index))
	local zSouth
	if arena.index == 1 then
		zSouth = buildGraveWilds(root, arena, center)
	else
		zSouth = buildBoxedArena(root, paths, arena, center)
	end

	PropKit.Part(root, "SafePad", Vector3.new(16, 1, 16), CFrame.new(center.X, 1.5, center.Z - 58), Color3.fromRGB(196, 154, 96), Enum.Material.Wood, true, 0.2, false)
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

	local sign = PropKit.Part(root, "Sign", Vector3.new(1.2, 5.5, 0.4), CFrame.new(center.X - 16, 3.6, zSouth - 8), WOOD, Enum.Material.Wood, true, nil, true)
	PropKit.Part(root, "SignPost", Vector3.new(0.4, 5.5, 0.4), sign.CFrame * CFrame.new(0, 0, 0.3), Color3.fromRGB(70, 52, 36), Enum.Material.Wood, true)
	PropKit.Billboard(sign, Strings.ArenaSign(arena.index, arena.name, arena.mastery, arena.cost), "ArenaName", UDim2.fromOffset(220, 86), Vector3.new(0, 4.2, 0), Color3.new(1, 1, 1))
	PropKit.Prompt(sign, arena.index == 1 and "Enter" or "Arena", arena.name, "Arena", { ArenaIndex = arena.index }, WorldTextConfig.Prompt("Arena"))

	local back = PropKit.Part(root, "ReturnPad", Vector3.new(10, 1, 10), CFrame.new(center.X, 1.6, center.Z - 48), BONE:Lerp(EARTH, 0.4), Enum.Material.Wood, true, nil, true)
	PropKit.Prompt(back, "Return", "Lobby", "Lobby", {}, WorldTextConfig.Prompt("Default"))

	if arena.index > 1 and arena.index < 15 then
		local nextCenter = WorldLayout.ArenaCenter(arena.index + 1)
		local fromZ = center.Z + WorldLayout.ArenaHalf()
		local toZ = nextCenter.Z - WorldLayout.ArenaHalf()
		local mid = (fromZ + toZ) / 2
		local length = math.abs(toZ - fromZ)
		PropKit.Part(paths, "Bridge_" .. arena.index, Vector3.new(28, 2, length), CFrame.new(0, 0, mid), EARTH, Enum.Material.Ground, true, nil, true)
		PropKit.FenceRun(paths, "RailL_" .. arena.index, Vector3.new(-14, 1, fromZ), Vector3.new(-14, 1, toZ), WOOD)
		PropKit.FenceRun(paths, "RailR_" .. arena.index, Vector3.new(14, 1, fromZ), Vector3.new(14, 1, toZ), WOOD)
	end
end

local function serviceShrine(parent, name, position, color, text, action, category)
	local cf = CFrame.new(position.X, 1, position.Z)
	local pad = PropKit.Cylinder(parent, name, Vector3.new(0.8, 14, 14), cf * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)), EARTH, Enum.Material.Ground, true)
	TribalKit.Totem(parent, name .. "Totem", Vector3.new(position.X, 1, position.Z), 0, color)
	local post = PropKit.Part(parent, name .. "Post", Vector3.new(0.4, 5, 0.4), cf * CFrame.new(0, 8.2, -2.2), WOOD, Enum.Material.Wood, true)
	PropKit.Billboard(post, text, category, UDim2.fromOffset(200, 72), Vector3.new(0, 1.6, 0), Color3.fromRGB(255, 236, 214))
	local promptName = string.match(text, "^[^\n]+") or text
	PropKit.Prompt(post, "Interact", promptName, action, nil, WorldTextConfig.Prompt("Service"))
	return pad
end

local function buildVillage(lobby)
	local camp = Vector3.new(-206, 1, -96)
	local huts = {
		Vector3.new(-262, 1, -150),
		Vector3.new(-214, 1, -168),
		Vector3.new(-158, 1, -146),
		Vector3.new(-268, 1, -78),
		Vector3.new(-176, 1, -58),
		Vector3.new(-230, 1, -40),
	}
	for index, spot in ipairs(huts) do
		local yaw = TribalKit.FacingYaw(spot, camp)
		TribalKit.Hut(lobby, "Hut" .. index, spot, yaw, index % 3 == 0 and 1.05 or 0.92)
	end
	TribalKit.Campfire(lobby, "VillageFire", camp, true)
	TribalKit.Campfire(lobby, "VillageFireB", Vector3.new(-250, 1, -112), true)
	TribalKit.LogBench(lobby, "LogA", CFrame.new(-190, 1.6, -88) * CFrame.Angles(0, 0.4, 0))
	TribalKit.LogBench(lobby, "LogB", CFrame.new(-224, 1.6, -78) * CFrame.Angles(0, 1.1, 0))
	TribalKit.Totem(lobby, "VillageTotemA", Vector3.new(-150, 1, -96), 1.2, RED)
	TribalKit.Totem(lobby, "VillageTotemB", Vector3.new(-248, 1, -24), 0.4, Color3.fromRGB(90, 48, 36))
	TribalKit.Banner(lobby, "FlagA", Vector3.new(-132, 1, -70), 1.1, RED)
	TribalKit.Banner(lobby, "FlagB", Vector3.new(-132, 1, -120), 0.8, Color3.fromRGB(92, 42, 36))
	PropKit.FenceRun(lobby, "FenceWest", Vector3.new(-300, 1, -200), Vector3.new(-300, 1, 10), WOOD)
	PropKit.FenceRun(lobby, "FenceSouth", Vector3.new(-300, 1, -200), Vector3.new(-120, 1, -200), WOOD)
	PropKit.Tree(lobby, "ShadeA", Vector3.new(-290, 1, -40), "oak")
	PropKit.Tree(lobby, "ShadeB", Vector3.new(-120, 1, -170), "oak")
	PropKit.Tree(lobby, "DeadEdge", Vector3.new(-300, 1, -160), "dead")
	PropKit.Rock(lobby, "VillageRockA", Vector3.new(-140, 1, -40), 1.2, Color3.fromRGB(100, 92, 82))
	PropKit.Rock(lobby, "VillageRockB", Vector3.new(-280, 1, -130), 1.5, Color3.fromRGB(88, 80, 72))
	for index = 1, 8 do
		TribalKit.Tuft(lobby, "Grass" .. index, Vector3.new(-150 - (index * 17) % 120, 1, -30 - (index * 23) % 140), 0.8 + (index % 3) * 0.25)
	end
	TribalKit.Crate(lobby, "StoreCrate", CFrame.new(-188, 1.8, -60))
	TribalKit.Basket(lobby, "StoreBasket", CFrame.new(-198, 1.7, -124))
	TribalKit.Skull(lobby, "RackSkull", CFrame.new(-170, 2.2, -70), 0.9)
	TribalKit.LogBench(lobby, "LogC", CFrame.new(-240, 1.6, -130) * CFrame.Angles(0, 0.8, 0))
	PropKit.Rock(lobby, "VillageRockC", Vector3.new(-160, 1, -160), 1.1, Color3.fromRGB(96, 88, 78))
end

local function buildMerchant(lobby)
	local spot = WorldLayout.Merchant()
	local stall, promptPart = TribalKit.Stall(lobby, "MerchantStall", Vector3.new(spot.X, 1, spot.Z), math.rad(-90))
	PropKit.Prompt(promptPart, "Talk to Merchant", "Chief", "Merchant", nil, WorldTextConfig.Prompt("Merchant"))
	return stall
end

local function buildFeaturedEggs(lobby)
	local eggRoot = PropKit.Folder(lobby, "EggZone")
	local coinEgg = PetConfig.GetWorldEgg("coin")
	local advancedEgg = PetConfig.GetWorldEgg("advanced")
	local premium = PetConfig.GetWorldEgg("premium")
	local specs = {
		{
			name = "CoinEgg",
			position = WorldLayout.CoinEgg(),
			color = Color3.fromRGB(196, 150, 96),
			kind = "coin",
			text = Strings.CoinEggSign(coinEgg.cost, EggService.OddsText(coinEgg.pool)),
			category = "EggPrice",
			action = "Open",
			object = "Coin Egg",
			remote = "OpenWorldEgg",
			attributes = { WorldEgg = "coin" },
		},
		{
			name = "AdvancedEgg",
			position = WorldLayout.AdvancedEgg(),
			color = Color3.fromRGB(150, 78, 46),
			kind = "advanced",
			text = Strings.AdvancedEggSign(advancedEgg.cost),
			category = "EggPrice",
			action = "Open",
			object = "Advanced Coin Egg",
			remote = "OpenWorldEgg",
			attributes = { WorldEgg = "advanced" },
		},
		{
			name = "PremiumEgg",
			position = WorldLayout.PremiumEgg(),
			color = Color3.fromRGB(236, 206, 150),
			kind = "premium",
			text = Strings.PremiumEggSign(EggService.OddsText(premium.pool)),
			category = "EggPetInfo",
			action = "Inspect",
			object = "Premium Egg",
			remote = "RobuxEgg",
			attributes = { SpecialIndex = 1 },
		},
	}
	for _, spec in ipairs(specs) do
		local _, column = TribalKit.EggShrine(eggRoot, spec.name, Vector3.new(spec.position.X, 1, spec.position.Z), spec.color, spec.kind)
		PropKit.Billboard(column, spec.text, spec.category, UDim2.fromOffset(220, 120), Vector3.new(0, 4.2, 0), Color3.fromRGB(255, 236, 210))
		PropKit.Prompt(column, spec.action, spec.object, spec.remote, spec.attributes, WorldTextConfig.Prompt("Egg"))
	end
	TribalKit.Campfire(eggRoot, "EggFire", Vector3.new(0, 1, -132), true)
	PropKit.Part(eggRoot, "EggPath", Vector3.new(16, 0.08, 70), CFrame.new(0, 1.08, -120), EARTH, Enum.Material.Ground, false)
end

local function buildBoards(lobby)
	local root = PropKit.Folder(lobby, "Leaderboards")
	local origin = WorldLayout.LeaderboardOrigin()
	PropKit.Part(root, "Avenue", Vector3.new(120, 0.12, 360), CFrame.new(origin.X - 10, 1.08, origin.Z), Color3.fromRGB(102, 78, 52), Enum.Material.Ground, false)
	local entry = PropKit.Part(root, "AvenueSign", Vector3.new(0.4, 4, 8), CFrame.new(origin.X - 48, 3.2, origin.Z - 150), WOOD, Enum.Material.Wood, true)
	PropKit.Billboard(entry, "HALL OF THE TRIBE", "InfoSign", UDim2.fromOffset(200, 40), Vector3.new(0, 2.6, 0), BONE)
	local metals = {
		{ color = Color3.fromRGB(196, 154, 78), material = Enum.Material.Wood },
		{ color = Color3.fromRGB(168, 164, 156), material = Enum.Material.Slate },
		{ color = Color3.fromRGB(150, 96, 62), material = Enum.Material.Wood },
	}
	for boardIndex, board in ipairs(WorldLayout.LeaderboardBoards()) do
		local anchor = WorldLayout.BoardAnchor(boardIndex)
		local wall = PropKit.Part(root, "Board_" .. board.id, Vector3.new(16, 11, 0.8), CFrame.lookAt(Vector3.new(anchor.X, 6.5, anchor.Z), Vector3.new(anchor.X - 10, 6.5, anchor.Z)), Color3.fromRGB(48, 32, 24), Enum.Material.Wood, true, nil, true)
		PropKit.Part(root, "BoardTrim_" .. board.id, Vector3.new(16.4, 0.35, 0.9), wall.CFrame * CFrame.new(0, 5.3, 0), BONE, Enum.Material.Slate, false)
		TribalKit.Skull(root, "BoardSkull_" .. board.id, wall.CFrame * CFrame.new(0, 4.6, -0.6), 0.8)
		PropKit.Billboard(wall, board.title, "Podium", UDim2.fromOffset(200, 36), Vector3.new(0, 6.4, 0), Color3.fromRGB(255, 220, 160))
		local gui = Instance.new("SurfaceGui")
		gui.Name = "BoardGui"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(400, 280)
		gui.Parent = wall
		WorldTextConfig.Mark(gui, "Podium")
		local label = Instance.new("TextLabel")
		label.Name = "Rankings"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextWrapped = true
		label.TextColor3 = Color3.fromRGB(255, 236, 214)
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.Text = "—"
		label.Parent = gui
		for place = 1, 3 do
			local center, size = WorldLayout.PodiumSpec(boardIndex, place)
			local metal = metals[place]
			local look = CFrame.lookAt(center, Vector3.new(center.X - 10, center.Y, center.Z))
			local podium = PropKit.Part(root, WorldLayout.PodiumName(board.id, place), size, look, metal.color, metal.material, true, nil, true)
			podium:SetAttribute("PodiumBoard", board.id)
			podium:SetAttribute("PodiumPlace", place)
			local face = Instance.new("SurfaceGui")
			face.Name = "PodiumGui"
			face.Face = Enum.NormalId.Front
			face.CanvasSize = Vector2.new(200, 120)
			face.Parent = podium
			WorldTextConfig.Mark(face, "Podium")
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			nameLabel.BackgroundTransparency = 1
			nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextScaled = true
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.Text = "—"
			nameLabel.Parent = face
			local value = Instance.new("TextLabel")
			value.Name = "ValueLabel"
			value.BackgroundTransparency = 1
			value.Position = UDim2.new(0, 0, 0.5, 0)
			value.Size = UDim2.new(1, 0, 0.45, 0)
			value.Font = Enum.Font.Gotham
			value.TextScaled = true
			value.TextColor3 = Color3.fromRGB(255, 220, 160)
			value.Text = ""
			value.Parent = face
		end
		TribalKit.Banner(root, "AvenueFlag" .. boardIndex, Vector3.new(anchor.X + 6, 1, anchor.Z), math.rad(90), boardIndex % 2 == 0 and RED or Color3.fromRGB(92, 48, 32))
	end
	PropKit.Folder(root, "PodiumFigures")
end

local function buildServices(lobby)
	local root = PropKit.Folder(lobby, "Services")
	serviceShrine(root, "HeroPad", WorldLayout.HeroSwitch(), Color3.fromRGB(168, 104, 58), "Warrior\nWorld 0 hero", "Hero", "Interaction")
	serviceShrine(root, "UpgradePad", WorldLayout.Upgrades(), Color3.fromRGB(92, 122, 86), "Upgrades\nSpend coins", "UpgradeInfo", "UpgradeStation")
	serviceShrine(root, "FusionPad", WorldLayout.Fusion(), Color3.fromRGB(120, 96, 64), "Pet Fusion\n5 identical = 1 evolved", "FusionInfo", "Interaction")
	serviceShrine(root, "RebirthPad", WorldLayout.Rebirth(), Color3.fromRGB(140, 64, 48), "Rebirth Altar\nMastery 50", "Rebirth", "RebirthInfo")

	local portalPos = WorldLayout.Portal()
	TribalKit.BoneArch(root, "World2Arch", Vector3.new(portalPos.X, 1, portalPos.Z), math.rad(180))
	local lockBar = PropKit.Part(root, "World2Lock", Vector3.new(1.1, 6, 1.1), CFrame.new(portalPos.X, 4, portalPos.Z), Color3.fromRGB(48, 36, 28), Enum.Material.Wood, true)
	PropKit.Billboard(lockBar, "World 2\nPortal inactive", "InfoSign", UDim2.fromOffset(180, 64), Vector3.new(0, 4, 0), Color3.fromRGB(220, 210, 196))
	PropKit.Prompt(lockBar, "Info", "World 2", "Portal", nil, WorldTextConfig.Prompt("Portal"))
end

local function buildLobby(paths, world)
	local lobby = PropKit.Folder(world, "Lobby")
	local center = WorldLayout.Lobby.center
	local size = WorldLayout.Lobby.size
	PropKit.Part(lobby, "Floor", Vector3.new(size.X, 2, size.Z), CFrame.new(center), GRASS, Enum.Material.Grass, true, nil, true)
	local halfX = size.X * 0.5
	local halfZ = size.Z * 0.5
	local north = center.Z + halfZ
	local south = center.Z - halfZ
	local west = center.X - halfX
	local east = center.X + halfX
	PropKit.Part(lobby, "CurbSouth", Vector3.new(size.X, 5, 3), CFrame.new(center.X, 3.2, south), Color3.fromRGB(84, 72, 60), Enum.Material.Slate, true, nil, true)
	PropKit.Part(lobby, "CurbWest", Vector3.new(3, 6, size.Z), CFrame.new(west, 3.6, center.Z), Color3.fromRGB(78, 68, 58), Enum.Material.Slate, true, nil, true)
	PropKit.Part(lobby, "CurbEast", Vector3.new(3, 6, size.Z), CFrame.new(east, 3.6, center.Z), Color3.fromRGB(78, 68, 58), Enum.Material.Slate, true, nil, true)
	local northSpan = (size.X - 28) / 2
	PropKit.Part(lobby, "CurbNorthL", Vector3.new(northSpan, 5, 3), CFrame.new(center.X - (14 + northSpan / 2), 3.2, north), Color3.fromRGB(84, 72, 60), Enum.Material.Slate, true, nil, true)
	PropKit.Part(lobby, "CurbNorthR", Vector3.new(northSpan, 5, 3), CFrame.new(center.X + (14 + northSpan / 2), 3.2, north), Color3.fromRGB(84, 72, 60), Enum.Material.Slate, true, nil, true)

	for index = 1, 5 do
		local height = 18 + index * 4
		PropKit.Part(lobby, "Ridge" .. index, Vector3.new(16, height, 22), CFrame.new(west - 8, height * 0.35, south + 40 + index * 55) * CFrame.Angles(0, 0.2, 0), Color3.fromRGB(92, 86, 78), Enum.Material.Rock, false, nil, true)
	end

	PropKit.Part(lobby, "PathVillage", Vector3.new(70, 0.08, 14), CFrame.new(-70, 1.08, 10) * CFrame.Angles(0, math.rad(18), 0), EARTH, Enum.Material.Ground, false)
	PropKit.Part(lobby, "PathEggs", Vector3.new(14, 0.08, 80), CFrame.new(0, 1.08, -70), EARTH, Enum.Material.Ground, false)
	PropKit.Part(lobby, "PathBoards", Vector3.new(80, 0.08, 16), CFrame.new(90, 1.08, 8), EARTH, Enum.Material.Ground, false)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 2, 46)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = lobby

	local titlePost = PropKit.Part(lobby, "TitlePost", Vector3.new(0.5, 8, 0.5), CFrame.new(0, 5, 78), WOOD, Enum.Material.Wood, true, nil, true)
	PropKit.Billboard(titlePost, "KURKITO\nWorld 0\nBattle Survival", "LobbyTitle", UDim2.fromOffset(220, 78), Vector3.new(0, 3.2, 0), Color3.fromRGB(255, 228, 190))
	TribalKit.BoneArch(lobby, "NorthGate", Vector3.new(0, 1, 188), 0)
	local arenaSign = PropKit.Part(lobby, "ArenaPointer", Vector3.new(0.4, 3.2, 4), CFrame.new(-8, 3, 176), WOOD, Enum.Material.Wood, true)
	PropKit.Billboard(arenaSign, "Grave Wilds\nArena 1", "ArenaName", UDim2.fromOffset(180, 52), Vector3.new(0, 2.4, 0), Color3.fromRGB(255, 220, 180))

	buildVillage(lobby)
	buildMerchant(lobby)
	buildFeaturedEggs(lobby)
	buildBoards(lobby)
	buildServices(lobby)

	local first = WorldLayout.ArenaCenter(1)
	local fromZ = north - 4
	local toZ = first.Z - WorldLayout.ArenaHalf()
	local length = math.abs(toZ - fromZ)
	local mid = (fromZ + toZ) / 2
	PropKit.Part(paths, "PathArenas", Vector3.new(26, 2, length), CFrame.new(0, 0, mid), EARTH, Enum.Material.Ground, true, nil, true)
	PropKit.FenceRun(paths, "HuntRailL", Vector3.new(-13, 1, fromZ), Vector3.new(-13, 1, toZ), WOOD)
	PropKit.FenceRun(paths, "HuntRailR", Vector3.new(13, 1, fromZ), Vector3.new(13, 1, toZ), WOOD)
	TribalKit.Banner(paths, "HuntFlagL", Vector3.new(-13, 1, fromZ + 18), 0, RED)
	TribalKit.Banner(paths, "HuntFlagR", Vector3.new(13, 1, fromZ + 18), math.pi, RED)
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
		if arena.index == 1 then
			buildArena(arenas, paths, arena)
		end
	end
	print("[Kurkito] World 0 built (" .. GameConfig.WorldBuildId .. ").")
	return world
end

return WorldBuilder
