-- Props preistorici del Mondo 0. Parti native, niente mesh esterne.
-- Le capanne e le bancarelle non usano il cubo con tetto a triangolo.

local PropKit = require(script.Parent.PropKit)

local TribalKit = {}

local HIDE = Color3.fromRGB(148, 96, 62)
local FUR = Color3.fromRGB(72, 48, 32)
local WOOD = Color3.fromRGB(92, 62, 38)
local DARK = Color3.fromRGB(54, 36, 24)
local BONE = Color3.fromRGB(214, 196, 164)
local RED = Color3.fromRGB(138, 42, 36)
local CREAM = Color3.fromRGB(214, 186, 146)
local STONE = Color3.fromRGB(110, 100, 90)
local EARTH = Color3.fromRGB(118, 84, 52)

local function model(parent, name)
	local created = Instance.new("Model")
	created.Name = name
	created.Parent = parent
	return created
end

local function yawTo(from, toward)
	return math.atan2(toward.X - from.X, toward.Z - from.Z)
end

function TribalKit.Rope(parent, name, a, b, color)
	local delta = b - a
	local length = delta.Magnitude
	if length < 0.25 then
		return nil
	end
	local mid = (a + b) * 0.5
	return PropKit.Part(parent, name, Vector3.new(0.1, 0.1, length), CFrame.lookAt(mid, b), color or Color3.fromRGB(120, 92, 60), Enum.Material.Fabric, false)
end

function TribalKit.Skull(parent, name, cf, scale)
	local s = scale or 1
	local skull = PropKit.Ball(parent, name, Vector3.new(0.9, 0.8, 0.95) * s, cf, BONE, Enum.Material.SmoothPlastic, false)
	PropKit.Part(parent, name .. "Jaw", Vector3.new(0.55, 0.22, 0.4) * s, cf * CFrame.new(0, -0.38 * s, -0.12 * s), BONE:Lerp(DARK, 0.15), Enum.Material.SmoothPlastic, false)
	PropKit.Part(parent, name .. "EyeL", Vector3.new(0.16, 0.16, 0.12) * s, cf * CFrame.new(-0.18 * s, 0.08 * s, -0.4 * s), DARK, Enum.Material.SmoothPlastic, false)
	PropKit.Part(parent, name .. "EyeR", Vector3.new(0.16, 0.16, 0.12) * s, cf * CFrame.new(0.18 * s, 0.08 * s, -0.4 * s), DARK, Enum.Material.SmoothPlastic, false)
	return skull
end

function TribalKit.Tusk(parent, name, cf, length)
	local size = length or 2.4
	return PropKit.Part(parent, name, Vector3.new(0.28, size, 0.28), cf, BONE, Enum.Material.SmoothPlastic, false)
end

function TribalKit.Crate(parent, name, cf)
	local box = PropKit.Part(parent, name, Vector3.new(2.2, 1.5, 1.8), cf, WOOD, Enum.Material.Wood, false, nil, true)
	PropKit.Part(parent, name .. "Band", Vector3.new(2.28, 0.16, 1.88), cf * CFrame.new(0, 0.2, 0), DARK, Enum.Material.Wood, false)
	TribalKit.Rope(parent, name .. "Rope", (cf * CFrame.new(-1.1, 0.4, 0)).Position, (cf * CFrame.new(1.1, 0.4, 0)).Position, Color3.fromRGB(140, 110, 70))
	return box
end

function TribalKit.Basket(parent, name, cf)
	local basket = PropKit.Cylinder(parent, name, Vector3.new(1.1, 1.5, 1.5), cf * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(132, 96, 58), Enum.Material.Wood, false)
	PropKit.Ball(parent, name .. "Fill", Vector3.new(1.1, 0.5, 1.1), cf * CFrame.new(0, 0.45, 0), Color3.fromRGB(160, 120, 70), Enum.Material.Fabric, false)
	return basket
end

function TribalKit.LogBench(parent, name, cf)
	local log = PropKit.Cylinder(parent, name, Vector3.new(4.4, 0.9, 0.9), cf * CFrame.Angles(0, math.rad(90), math.rad(90)), WOOD, Enum.Material.Wood, true, nil)
	PropKit.Part(parent, name .. "StubA", Vector3.new(0.45, 0.7, 0.45), cf * CFrame.new(-1.6, -0.55, 0), DARK, Enum.Material.Wood, true)
	PropKit.Part(parent, name .. "StubB", Vector3.new(0.45, 0.7, 0.45), cf * CFrame.new(1.6, -0.55, 0), DARK, Enum.Material.Wood, true)
	return log
end

function TribalKit.Campfire(parent, name, position, withLight)
	local root = model(parent, name)
	local base = Vector3.new(position.X, 1, position.Z)
	for index = 1, 7 do
		local angle = (index / 7) * math.pi * 2
		local spot = base + Vector3.new(math.cos(angle) * 1.7, 0.25, math.sin(angle) * 1.7)
		PropKit.Ball(root, "Stone" .. index, Vector3.new(0.8, 0.55, 0.7), CFrame.new(spot), STONE:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Slate, false)
	end
	PropKit.Cylinder(root, "LogA", Vector3.new(2.4, 0.38, 0.38), CFrame.new(base + Vector3.new(0, 0.45, 0)) * CFrame.Angles(0, 0.4, math.rad(78)), DARK, Enum.Material.Wood, false)
	PropKit.Cylinder(root, "LogB", Vector3.new(2.2, 0.34, 0.34), CFrame.new(base + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0.5, 1.2, math.rad(80)), WOOD, Enum.Material.Wood, false)
	local flame = PropKit.Ball(root, "Flame", Vector3.new(0.9, 1.3, 0.9), CFrame.new(base + Vector3.new(0, 1.15, 0)), Color3.fromRGB(255, 140, 50), Enum.Material.Neon, false, 0.15)
	PropKit.Ball(root, "Core", Vector3.new(0.4, 0.7, 0.4), flame.CFrame * CFrame.new(0, 0.15, 0), Color3.fromRGB(255, 220, 140), Enum.Material.Neon, false, 0.05)
	PropKit.Spark(flame, Color3.fromRGB(255, 170, 70), 4)
	local smoke = PropKit.Ball(root, "Smoke", Vector3.new(0.8, 1.4, 0.8), CFrame.new(base + Vector3.new(0, 2.5, 0)), Color3.fromRGB(80, 76, 72), Enum.Material.SmoothPlastic, false, 0.55)
	if withLight ~= false then
		PropKit.Light(flame, Color3.fromRGB(255, 160, 80), 16, 0.85)
	end
	smoke.CanCollide = false
	return root
end

function TribalKit.Totem(parent, name, position, yaw, tint)
	local root = model(parent, name)
	local cf = CFrame.new(position.X, 1, position.Z) * CFrame.Angles(0, yaw or 0, 0)
	PropKit.Part(root, "Base", Vector3.new(2.2, 0.6, 2.2), cf * CFrame.new(0, 0.3, 0), STONE, Enum.Material.Slate, true, nil, true)
	local colors = {
		tint or RED,
		BONE,
		DARK,
		HIDE,
	}
	local y = 0.8
	for index, color in ipairs(colors) do
		local height = index == 1 and 1.8 or 1.45
		local width = 1.35 - index * 0.08
		PropKit.Part(root, "Stack" .. index, Vector3.new(width, height, width), cf * CFrame.new(0, y + height * 0.5, 0), color, index % 2 == 0 and Enum.Material.Wood or Enum.Material.Wood, false, nil, true)
		y += height
	end
	TribalKit.Skull(root, "Crown", cf * CFrame.new(0, y + 0.45, 0), 1.15)
	TribalKit.Tusk(root, "HornL", cf * CFrame.new(-0.55, y + 0.2, 0) * CFrame.Angles(0, 0, math.rad(28)), 1.6)
	TribalKit.Tusk(root, "HornR", cf * CFrame.new(0.55, y + 0.2, 0) * CFrame.Angles(0, 0, math.rad(-28)), 1.6)
	PropKit.Part(root, "Cloth", Vector3.new(0.12, 1.8, 1.1), cf * CFrame.new(0.7, 2.4, 0), RED, Enum.Material.Fabric, false)
	return root
end

function TribalKit.Banner(parent, name, position, yaw, color)
	local cf = CFrame.new(position + Vector3.new(0, 0, 0)) * CFrame.Angles(0, yaw or 0, 0)
	local pole = PropKit.Part(parent, name .. "Pole", Vector3.new(0.28, 7.2, 0.28), cf * CFrame.new(0, 4.4, 0), WOOD, Enum.Material.Wood, false, nil, true)
	local cloth = PropKit.Part(parent, name .. "Cloth", Vector3.new(2.6, 3.4, 0.1), pole.CFrame * CFrame.new(1.4, 1.2, 0), color or RED, Enum.Material.Fabric, false)
	PropKit.Part(parent, name .. "Mark", Vector3.new(0.7, 0.9, 0.08), cloth.CFrame * CFrame.new(0, 0.2, -0.08), CREAM, Enum.Material.Fabric, false)
	TribalKit.Skull(parent, name .. "Skull", pole.CFrame * CFrame.new(0, 3.5, 0), 0.7)
	return pole
end

function TribalKit.Tuft(parent, name, position, scale)
	local s = scale or 1
	local cf = CFrame.new(position.X, 1.15, position.Z)
	PropKit.Part(parent, name, Vector3.new(0.2, 1.1 * s, 0.5), cf * CFrame.Angles(0, 0.4, math.rad(12)), Color3.fromRGB(70, 110, 52), Enum.Material.Grass, false)
	PropKit.Part(parent, name .. "B", Vector3.new(0.18, 0.9 * s, 0.4), cf * CFrame.new(0.25, 0, 0.1) * CFrame.Angles(0, 0.8, math.rad(-16)), Color3.fromRGB(86, 120, 48), Enum.Material.Grass, false)
end

function TribalKit.Hut(parent, name, position, yaw, scale)
	local s = scale or 1
	local root = model(parent, name)
	local cf = CFrame.new(position.X, 1, position.Z) * CFrame.Angles(0, yaw or 0, 0)
	local radius = 4.4 * s
	PropKit.Cylinder(root, "Floor", Vector3.new(0.45, radius * 2.15, radius * 2.15), cf * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), EARTH, Enum.Material.Ground, true)
	local posts = 7
	local door = 4
	for index = 1, posts do
		local angle = ((index - 1) / posts) * math.pi * 2
		if index ~= door then
			local localPos = Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius)
			local height = 4.2 * s + (index % 2) * 0.35
			local post = PropKit.Cylinder(root, "Post" .. index, Vector3.new(height, 0.42 * s, 0.42 * s), cf * CFrame.new(localPos + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), index % 2 == 0 and WOOD or DARK, Enum.Material.Wood, true)
			local nextAngle = (index / posts) * math.pi * 2
			if index ~= posts then
				local hide = PropKit.Part(root, "Hide" .. index, Vector3.new(radius * 0.85, 2.5 * s, 0.12), cf * CFrame.new(math.sin((angle + nextAngle) * 0.5) * (radius - 0.2), 1.7 * s, math.cos((angle + nextAngle) * 0.5) * (radius - 0.2)) * CFrame.Angles(0, -(angle + nextAngle) * 0.5, 0), index % 3 == 0 and RED:Lerp(HIDE, 0.45) or HIDE, Enum.Material.Fabric, false)
				hide.Name = "Hide" .. index
			end
			if index % 2 == 0 then
				TribalKit.Rope(root, "Tie" .. index, post.Position + Vector3.new(0, 0.8, 0), (cf * CFrame.new(0, 3.2 * s, 0)).Position, Color3.fromRGB(130, 100, 64))
			end
		end
	end
	local apex = cf * CFrame.new(0, 7.1 * s, 0)
	for index = 1, posts do
		local angle = ((index - 1) / posts) * math.pi * 2
		local foot = (cf * CFrame.new(math.sin(angle) * radius, 4.1 * s, math.cos(angle) * radius)).Position
		TribalKit.Rope(root, "Rafter" .. index, foot, apex.Position, WOOD)
		local rafter = PropKit.Part(root, "Pole" .. index, Vector3.new(0.22, 0.22, (apex.Position - foot).Magnitude), CFrame.lookAt((foot + apex.Position) * 0.5, apex.Position), WOOD, Enum.Material.Wood, false)
		rafter.Color = index % 2 == 0 and DARK or WOOD
	end
	for layer = 1, 3 do
		local width = (6.2 - layer * 1.15) * s
		local y = 4.3 * s + layer * 0.85 * s
		local thatch = PropKit.Ball(root, "Thatch" .. layer, Vector3.new(width, 1.15 * s, width), cf * CFrame.new(0, y, 0), Color3.fromRGB(138, 112, 62):Lerp(Color3.fromRGB(90, 70, 36), layer * 0.12), Enum.Material.Grass, false)
		PropKit.SphereMesh(thatch, Vector3.new(1, 0.55, 1))
	end
	PropKit.Part(root, "Lintel", Vector3.new(2.2 * s, 0.28, 0.35), cf * CFrame.new(0, 3.1 * s, -radius + 0.2), DARK, Enum.Material.Wood, false, nil, true)
	TribalKit.Skull(root, "DoorSkull", cf * CFrame.new(0, 3.5 * s, -radius + 0.15), 0.65 * s)
	local smoke = PropKit.Ball(root, "Smoke", Vector3.new(0.9, 1.3, 0.9) * s, apex * CFrame.new(0, 0.8, 0), Color3.fromRGB(90, 86, 80), Enum.Material.SmoothPlastic, false, 0.6)
	smoke.CanCollide = false
	return root
end

function TribalKit.Chief(parent, name, cf)
	local root = model(parent, name)
	local skin = Color3.fromRGB(186, 132, 92)
	local torso = PropKit.Part(root, "Torso", Vector3.new(2.3, 2.2, 1.25), cf * CFrame.new(0, 3.5, 0), FUR, Enum.Material.Fabric, false, nil, true)
	PropKit.Part(root, "Sash", Vector3.new(2.4, 0.7, 1.3), torso.CFrame * CFrame.new(0, -0.3, -0.05), RED, Enum.Material.Fabric, false)
	PropKit.Part(root, "HideSkirt", Vector3.new(2.15, 1.3, 1.2), torso.CFrame * CFrame.new(0, -1.5, 0), HIDE, Enum.Material.Fabric, false)
	local head = PropKit.Ball(root, "Head", Vector3.new(1.25, 1.25, 1.25), torso.CFrame * CFrame.new(0, 1.7, 0), skin, Enum.Material.SmoothPlastic, false, nil)
	PropKit.Part(root, "Hair", Vector3.new(1.35, 0.7, 1.3), head.CFrame * CFrame.new(0, 0.35, 0.08), Color3.fromRGB(24, 16, 12), Enum.Material.Fabric, false)
	PropKit.Part(root, "Beard", Vector3.new(0.7, 0.45, 0.4), head.CFrame * CFrame.new(0, -0.45, -0.35), Color3.fromRGB(28, 18, 14), Enum.Material.Fabric, false)
	local crown = PropKit.Part(root, "Crown", Vector3.new(1.5, 0.35, 1.5), head.CFrame * CFrame.new(0, 0.7, 0), BONE, Enum.Material.SmoothPlastic, false, nil, true)
	TribalKit.Tusk(root, "AntlerL", crown.CFrame * CFrame.new(-0.55, 0.7, 0) * CFrame.Angles(0, 0, math.rad(24)), 2.1)
	TribalKit.Tusk(root, "AntlerR", crown.CFrame * CFrame.new(0.55, 0.7, 0) * CFrame.Angles(0, 0, math.rad(-24)), 2.1)
	PropKit.Part(root, "RedBand", Vector3.new(1.55, 0.18, 1.55), crown.CFrame * CFrame.new(0, -0.05, 0), RED, Enum.Material.Fabric, false)
	for index = 1, 4 do
		PropKit.Ball(root, "Tooth" .. index, Vector3.new(0.16, 0.22, 0.12), torso.CFrame * CFrame.new(-0.45 + index * 0.22, 0.85, -0.68), BONE, Enum.Material.SmoothPlastic, false)
	end
	local armL = PropKit.Part(root, "ArmL", Vector3.new(0.48, 1.7, 0.48), torso.CFrame * CFrame.new(-1.35, 0.15, 0) * CFrame.Angles(0, 0, math.rad(18)), skin, Enum.Material.SmoothPlastic, false)
	local armR = PropKit.Part(root, "ArmR", Vector3.new(0.48, 1.7, 0.48), torso.CFrame * CFrame.new(1.15, 0.05, -0.35) * CFrame.Angles(math.rad(-70), math.rad(20), math.rad(-10)), skin, Enum.Material.SmoothPlastic, false)
	PropKit.Part(root, "WrapL", Vector3.new(0.52, 0.35, 0.52), armL.CFrame * CFrame.new(0, -0.5, 0), HIDE, Enum.Material.Fabric, false)
	PropKit.Ball(root, "HandR", Vector3.new(0.42, 0.36, 0.42), armR.CFrame * CFrame.new(0, -0.95, 0), skin, Enum.Material.SmoothPlastic, false)
	PropKit.Part(root, "LegL", Vector3.new(0.55, 1.5, 0.55), cf * CFrame.new(-0.42, 1.15, 0), skin:Lerp(DARK, 0.15), Enum.Material.SmoothPlastic, false)
	PropKit.Part(root, "LegR", Vector3.new(0.55, 1.5, 0.55), cf * CFrame.new(0.42, 1.15, 0), skin:Lerp(DARK, 0.15), Enum.Material.SmoothPlastic, false)
	root.PrimaryPart = torso
	return root, torso
end

function TribalKit.Stall(parent, name, position, yaw)
	local root = model(parent, name)
	local cf = CFrame.new(position.X, 1, position.Z) * CFrame.Angles(0, yaw or 0, 0)
	local deck = PropKit.Part(root, "Deck", Vector3.new(14, 1.1, 8), cf * CFrame.new(0, 0.55, 0.4), EARTH:Lerp(WOOD, 0.35), Enum.Material.Wood, true, nil, true)
	for index, x in ipairs({ -6, -2, 2, 6 }) do
		PropKit.Cylinder(root, "Post" .. index, Vector3.new(6.4, 0.4, 0.4), cf * CFrame.new(x, 4.2, -3.2) * CFrame.Angles(0, 0, math.rad(90)), WOOD, Enum.Material.Wood, false, nil)
	end
	local canopy = PropKit.Part(root, "Canopy", Vector3.new(15, 0.18, 7.5), cf * CFrame.new(0, 7.2, -0.4) * CFrame.Angles(math.rad(8), 0, 0), CREAM, Enum.Material.Fabric, false, nil, true)
	PropKit.Part(root, "CanopyRed", Vector3.new(15, 0.16, 1.4), canopy.CFrame * CFrame.new(0, -0.05, -2.6), RED, Enum.Material.Fabric, false)
	local banner = PropKit.Part(root, "Banner", Vector3.new(6.2, 2.2, 0.12), cf * CFrame.new(0, 5.6, -3.35), RED, Enum.Material.Fabric, false, nil, true)
	PropKit.Part(root, "Hand", Vector3.new(1.3, 1.5, 0.08), banner.CFrame * CFrame.new(-1.5, 0, -0.08), CREAM, Enum.Material.Fabric, false)
	PropKit.Billboard(banner, "TRIBAL MERCHANT", "Merchant", UDim2.fromOffset(180, 36), Vector3.new(0, 1.8, 0), CREAM)
	for index, x in ipairs({ -6.2, 6.2 }) do
		TribalKit.Tusk(root, "Tusk" .. index, cf * CFrame.new(x, 5.4, -3.2) * CFrame.Angles(0, 0, x > 0 and math.rad(-18) or math.rad(18)), 2.8)
		TribalKit.Skull(root, "Hang" .. index, cf * CFrame.new(x * 0.7, 4.3, -3.15), 0.7)
	end
	TribalKit.Rope(root, "Swag", (cf * CFrame.new(-6, 6.4, -3.2)).Position, (cf * CFrame.new(6, 6.4, -3.2)).Position, Color3.fromRGB(120, 86, 52))
	local counter = PropKit.Part(root, "Counter", Vector3.new(10, 0.35, 2.2), cf * CFrame.new(0, 2.15, -1.2), WOOD, Enum.Material.Wood, true, nil, true)
	TribalKit.Crate(root, "CrateL", cf * CFrame.new(-4.6, 1.7, 1.4))
	TribalKit.Crate(root, "CrateR", cf * CFrame.new(4.4, 1.7, 1.6) * CFrame.Angles(0, 0.4, 0))
	TribalKit.Basket(root, "Basket", cf * CFrame.new(2.2, 2.5, -1.1))
	TribalKit.Skull(root, "CounterSkull", cf * CFrame.new(-2.4, 2.7, -1.2), 0.8)
	PropKit.Part(root, "ClothPile", Vector3.new(1.6, 0.35, 1.2), cf * CFrame.new(0.2, 2.45, -1.15), RED:Lerp(CREAM, 0.4), Enum.Material.Fabric, false)
	PropKit.Part(root, "SideHide", Vector3.new(0.12, 3.2, 3.4), cf * CFrame.new(-7.1, 3.2, 0.2), HIDE, Enum.Material.Fabric, false)
	local chiefCf = cf * CFrame.new(0, 0, 1.5)
	local chief, promptPart = TribalKit.Chief(root, "Chief", chiefCf)
	chief.Name = "ChiefMerchant"
	local lamp = PropKit.Part(root, "Lamp", Vector3.new(0.4, 0.4, 0.4), cf * CFrame.new(0, 6.4, -1), Color3.fromRGB(255, 170, 80), Enum.Material.Neon, false)
	PropKit.Light(lamp, Color3.fromRGB(255, 160, 80), 14, 0.7)
	return root, promptPart
end

function TribalKit.EggShrine(parent, name, ground, color, kind)
	local root = model(parent, name)
	local cf = CFrame.new(ground.X, 1, ground.Z)
	local ringColor = kind == "premium" and Color3.fromRGB(212, 170, 80) or (kind == "advanced" and Color3.fromRGB(140, 64, 40) or BONE)
	PropKit.Cylinder(root, "Ring", Vector3.new(0.45, 7.2, 7.2), cf * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Slate, true)
	for index = 1, 6 do
		local angle = (index / 6) * math.pi * 2
		local spot = cf * CFrame.new(math.cos(angle) * 3.1, 0.45, math.sin(angle) * 3.1)
		PropKit.Ball(root, "Stone" .. index, Vector3.new(0.9, 0.7, 0.8), spot, STONE, Enum.Material.Slate, false)
		if index % 2 == 0 then
			TribalKit.Skull(root, "Mark" .. index, spot * CFrame.new(0, 0.55, 0), 0.45)
		end
	end
	local column = PropKit.Part(root, "Column", Vector3.new(2.2, 2.4, 2.2), cf * CFrame.new(0, 1.6, 0), ringColor:Lerp(DARK, 0.35), Enum.Material.Wood, true, nil, true)
	PropKit.Part(root, "Cap", Vector3.new(3.1, 0.35, 3.1), column.CFrame * CFrame.new(0, 1.35, 0), BONE:Lerp(ringColor, 0.3), Enum.Material.Slate, true)
	local eggY = 4.15
	local shell = PropKit.Part(root, "Shell", Vector3.new(2.8, 3.6, 2.8), cf * CFrame.new(0, eggY, 0), color, kind == "premium" and Enum.Material.Neon or Enum.Material.SmoothPlastic, false, kind == "premium" and 0.08 or 0)
	PropKit.SphereMesh(shell, Vector3.new(0.82, 1.15, 0.82))
	local band = PropKit.Part(root, "Band", Vector3.new(2.3, 0.22, 2.3), cf * CFrame.new(0, eggY - 0.2, 0), ringColor, Enum.Material.Wood, false)
	PropKit.SphereMesh(band, Vector3.new(1.05, 0.4, 1.05))
	if kind == "coin" then
		PropKit.Part(root, "Wrap", Vector3.new(0.16, 2.4, 0.16), shell.CFrame * CFrame.Angles(0, 0, math.rad(90)), WOOD, Enum.Material.Wood, false)
		TribalKit.Tusk(root, "Charm", column.CFrame * CFrame.new(0.8, 0.4, -0.8) * CFrame.Angles(0.4, 0, 0.6), 1.1)
	elseif kind == "advanced" then
		PropKit.Part(root, "Stripe", Vector3.new(0.35, 3.2, 0.2), shell.CFrame * CFrame.new(0.4, 0, -1.1), RED, Enum.Material.Fabric, false)
		PropKit.Part(root, "StripeB", Vector3.new(0.35, 3.2, 0.2), shell.CFrame * CFrame.new(-0.55, 0, -0.9) * CFrame.Angles(0, 0.5, 0), Color3.fromRGB(70, 28, 22), Enum.Material.Fabric, false)
		TribalKit.Skull(root, "EggSkull", column.CFrame * CFrame.new(0, 0.2, -1.35), 0.55)
	else
		PropKit.Part(root, "GoldWrap", Vector3.new(0.18, 3.3, 0.18), shell.CFrame * CFrame.Angles(0, 0.6, math.rad(80)), Color3.fromRGB(230, 190, 90), Enum.Material.SmoothPlastic, false)
		PropKit.Part(root, "Hand", Vector3.new(0.7, 0.9, 0.08), shell.CFrame * CFrame.new(0, 0.2, -1.25), RED, Enum.Material.Neon, false, 0.15)
		PropKit.Spark(shell, Color3.fromRGB(255, 210, 120), 2)
		PropKit.Light(shell, Color3.fromRGB(255, 196, 120), 10, 0.45)
	end
	return root, column
end

function TribalKit.Cliff(parent, name, cf, size, color)
	local rock = PropKit.Part(parent, name, size, cf, color or Color3.fromRGB(96, 84, 70), Enum.Material.Slate, true, nil, true)
	PropKit.Ball(parent, name .. "Cap", Vector3.new(size.X * 0.7, size.Y * 0.35, size.Z * 0.8), cf * CFrame.new(0, size.Y * 0.4, 0), (color or STONE):Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.Rock, false)
	return rock
end

function TribalKit.BoneArch(parent, name, position, yaw)
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
	local root = model(parent, name)
	PropKit.Part(root, "PostL", Vector3.new(1.1, 8, 1.1), cf * CFrame.new(-4.2, 4, 0), BONE:Lerp(STONE, 0.35), Enum.Material.Slate, true, nil, true)
	PropKit.Part(root, "PostR", Vector3.new(1.1, 8, 1.1), cf * CFrame.new(4.2, 4, 0), BONE:Lerp(STONE, 0.35), Enum.Material.Slate, true, nil, true)
	PropKit.Part(root, "Lintel", Vector3.new(9.4, 1.1, 1.3), cf * CFrame.new(0, 8.2, 0), DARK, Enum.Material.Wood, true, nil, true)
	TribalKit.Skull(root, "Key", cf * CFrame.new(0, 7.3, -0.4), 1)
	TribalKit.Tusk(root, "HornL", cf * CFrame.new(-3.2, 7.6, 0) * CFrame.Angles(0, 0, math.rad(20)), 1.8)
	TribalKit.Tusk(root, "HornR", cf * CFrame.new(3.2, 7.6, 0) * CFrame.Angles(0, 0, math.rad(-20)), 1.8)
	PropKit.Part(root, "Hide", Vector3.new(3.2, 2.4, 0.1), cf * CFrame.new(0, 6.2, -0.55), RED, Enum.Material.Fabric, false)
	return root
end

function TribalKit.FacingYaw(from, toward)
	return yawTo(from, toward)
end

return TribalKit
