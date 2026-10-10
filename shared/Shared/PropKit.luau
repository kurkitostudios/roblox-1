-- Geometrie procedurali native. Nessun asset esterno e nessun id inventato.
-- Le decorazioni non collidono, così i percorsi di gioco restano aperti.

local WorldTextConfig = require(script.Parent.WorldTextConfig)

local PropKit = {}

local function finish(piece, parent, collide, transparency, shadow)
	piece.Anchored = true
	piece.CanCollide = collide == true
	piece.CanQuery = collide == true
	piece.CanTouch = false
	piece.CastShadow = shadow == true
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	if transparency then
		piece.Transparency = transparency
	end
	piece.Parent = parent
	return piece
end

function PropKit.Part(parent, name, size, cframe, color, material, collide, transparency, shadow)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color or Color3.fromRGB(90, 90, 96)
	piece.Material = material or Enum.Material.SmoothPlastic
	return finish(piece, parent, collide, transparency, shadow)
end

function PropKit.Ball(parent, name, size, cframe, color, material, collide, transparency)
	local piece = PropKit.Part(parent, name, size, cframe, color, material, collide, transparency, false)
	piece.Shape = Enum.PartType.Ball
	return piece
end

function PropKit.Cylinder(parent, name, size, cframe, color, material, collide, transparency)
	local piece = PropKit.Part(parent, name, size, cframe, color, material, collide, transparency, collide == true)
	piece.Shape = Enum.PartType.Cylinder
	return piece
end

function PropKit.Wedge(parent, name, size, cframe, color, material, collide, transparency)
	local piece = Instance.new("WedgePart")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = color or Color3.fromRGB(90, 90, 96)
	piece.Material = material or Enum.Material.SmoothPlastic
	return finish(piece, parent, collide, transparency, false)
end

function PropKit.SphereMesh(part, scale)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = scale or Vector3.new(1, 1, 1)
	mesh.Parent = part
	return mesh
end

function PropKit.Folder(parent, name)
	local created = Instance.new("Folder")
	created.Name = name
	created.Parent = parent
	return created
end

function PropKit.Billboard(adornee, text, category, size, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = size or UDim2.fromOffset(200, 64)
	gui.StudsOffset = offset or Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 40
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Caption"
	label.BackgroundTransparency = 0.28
	label.BackgroundColor3 = Color3.fromRGB(16, 14, 22)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = color or Color3.fromRGB(244, 236, 214)
	label.TextStrokeTransparency = 0.65
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(196, 164, 92)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.35
	stroke.Parent = label
	WorldTextConfig.Mark(gui, category or "InfoSign")
	return gui
end

function PropKit.Prompt(adornee, actionText, objectText, action, attributes, distance)
	local created = Instance.new("ProximityPrompt")
	created.ActionText = actionText
	created.ObjectText = objectText
	created.HoldDuration = 0.15
	created.MaxActivationDistance = distance or WorldTextConfig.Prompt("Default")
	created.RequiresLineOfSight = false
	created.KeyboardKeyCode = Enum.KeyCode.E
	created.Style = Enum.ProximityPromptStyle.Default
	created:SetAttribute("KurkitoAction", action)
	if attributes then
		for key, value in pairs(attributes) do
			created:SetAttribute(key, value)
		end
	end
	created.Parent = adornee
	return created
end

function PropKit.Light(adornee, color, range, brightness)
	local lamp = Instance.new("PointLight")
	lamp.Color = color or Color3.fromRGB(255, 214, 160)
	lamp.Range = range or 14
	lamp.Brightness = brightness or 0.7
	lamp.Shadows = false
	lamp.Parent = adornee
	return lamp
end

function PropKit.Spark(part, color, rate)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Spark"
	emitter.Rate = rate or 3
	emitter.Lifetime = NumberRange.new(0.45, 0.9)
	emitter.Speed = NumberRange.new(0.3, 1.1)
	emitter.Rotation = NumberRange.new(0, 180)
	emitter.RotSpeed = NumberRange.new(-20, 20)
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.LightEmission = 0.45
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(color or Color3.fromRGB(255, 210, 140))
	emitter:SetAttribute("KurkitoBaseRate", emitter.Rate)
	emitter.Parent = part
	return emitter
end

function PropKit.Torch(parent, name, position, flameColor, withLight)
	local root = PropKit.Part(parent, name, Vector3.new(0.45, 4.2, 0.45), CFrame.new(position + Vector3.new(0, 2.1, 0)), Color3.fromRGB(92, 64, 40), Enum.Material.Wood, false, nil, false)
	local cup = PropKit.Part(parent, name .. "Cup", Vector3.new(0.7, 0.35, 0.7), root.CFrame * CFrame.new(0, 2.15, 0), Color3.fromRGB(70, 62, 54), Enum.Material.Metal, false)
	local flame = PropKit.Ball(parent, name .. "Flame", Vector3.new(0.55, 0.7, 0.55), cup.CFrame * CFrame.new(0, 0.45, 0), flameColor or Color3.fromRGB(255, 150, 60), Enum.Material.Neon, false)
	PropKit.Spark(flame, flameColor or Color3.fromRGB(255, 170, 80), 2)
	if withLight then
		PropKit.Light(flame, flameColor or Color3.fromRGB(255, 180, 110), 12, 0.55)
	end
	return root
end

function PropKit.Lantern(parent, name, position, color, withLight)
	local post = PropKit.Part(parent, name, Vector3.new(0.55, 7.5, 0.55), CFrame.new(position + Vector3.new(0, 3.75, 0)), Color3.fromRGB(54, 58, 70), Enum.Material.Metal, false, nil, false)
	local arm = PropKit.Part(parent, name .. "Arm", Vector3.new(1.6, 0.22, 0.22), post.CFrame * CFrame.new(0.7, 3.2, 0), Color3.fromRGB(54, 58, 70), Enum.Material.Metal, false)
	local lamp = PropKit.Part(parent, name .. "Lamp", Vector3.new(0.9, 1.1, 0.9), arm.CFrame * CFrame.new(0.8, -0.7, 0), color or Color3.fromRGB(255, 196, 120), Enum.Material.Neon, false, 0.15)
	if withLight then
		PropKit.Light(lamp, color, 16, 0.8)
	end
	return post
end

function PropKit.Tree(parent, name, position, kind)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local trunkColor = Color3.fromRGB(92, 66, 42)
	local leaf = Color3.fromRGB(58, 120, 64)
	local height = 8
	if kind == "pine" then
		height = 12
		leaf = Color3.fromRGB(36, 92, 62)
	elseif kind == "dead" then
		height = 9
		leaf = Color3.fromRGB(70, 64, 58)
	elseif kind == "swamp" then
		height = 8
		trunkColor = Color3.fromRGB(62, 70, 48)
		leaf = Color3.fromRGB(70, 110, 62)
	elseif kind == "snow" then
		leaf = Color3.fromRGB(220, 230, 236)
		trunkColor = Color3.fromRGB(110, 90, 74)
	end
	local trunk = PropKit.Cylinder(model, "Trunk", Vector3.new(height, 1.3, 1.3), CFrame.new(position + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), trunkColor, Enum.Material.Wood, false)
	if kind == "pine" or kind == "snow" then
		for layer = 1, 3 do
			local width = 5.2 - layer * 1.05
			local y = height * 0.45 + layer * 1.7
			PropKit.Part(model, "Tier" .. layer, Vector3.new(width, 1.6, width), CFrame.new(position + Vector3.new(0, y, 0)), leaf, Enum.Material.Grass, false)
		end
	elseif kind == "dead" then
		PropKit.Part(model, "BranchA", Vector3.new(0.35, 3.2, 0.35), trunk.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(50)), trunkColor, Enum.Material.Wood, false)
		PropKit.Part(model, "BranchB", Vector3.new(0.3, 2.6, 0.3), trunk.CFrame * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0.4, math.rad(-60)), trunkColor, Enum.Material.Wood, false)
	else
		local crown = PropKit.Ball(model, "Crown", Vector3.new(6.2, 5.2, 6.2), CFrame.new(position + Vector3.new(0, height + 1.2, 0)), leaf, Enum.Material.Grass, false)
		PropKit.Ball(model, "CrownB", Vector3.new(3.4, 3.2, 3.4), crown.CFrame * CFrame.new(1.8, 0.4, 0.6), leaf:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Grass, false)
	end
	return model
end

function PropKit.Rock(parent, name, position, scale, color)
	local size = 2.4 * (scale or 1)
	local rock = PropKit.Ball(parent, name, Vector3.new(size * 1.4, size, size * 1.15), CFrame.new(position + Vector3.new(0, size * 0.35, 0)) * CFrame.Angles(0.1, 0.4, 0.2), color or Color3.fromRGB(110, 108, 104), Enum.Material.Slate, false)
	PropKit.SphereMesh(rock, Vector3.new(1.15, 0.72, 1))
	return rock
end

function PropKit.Banner(parent, name, position, color, yaw)
	local angle = yaw or 0
	local cf = CFrame.new(position + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, angle, 0)
	local pole = PropKit.Part(parent, name, Vector3.new(0.35, 8.4, 0.35), cf, Color3.fromRGB(72, 64, 54), Enum.Material.Wood, false, nil, false)
	local cloth = PropKit.Part(parent, name .. "Cloth", Vector3.new(2.4, 3.2, 0.12), pole.CFrame * CFrame.new(1.35, 1.6, 0), color or Color3.fromRGB(150, 48, 48), Enum.Material.Fabric, false)
	PropKit.Part(parent, name .. "Trim", Vector3.new(2.4, 0.18, 0.14), cloth.CFrame * CFrame.new(0, -1.5, 0), Color3.fromRGB(230, 200, 120), Enum.Material.Fabric, false)
	return pole
end

function PropKit.Bench(parent, name, cframe)
	local seat = PropKit.Part(parent, name, Vector3.new(4.2, 0.35, 1.4), cframe, Color3.fromRGB(110, 78, 48), Enum.Material.Wood, true, nil, true)
	PropKit.Part(parent, name .. "Back", Vector3.new(4.2, 1.5, 0.25), seat.CFrame * CFrame.new(0, 0.9, -0.6), Color3.fromRGB(92, 64, 40), Enum.Material.Wood, true, nil, true)
	PropKit.Part(parent, name .. "LegL", Vector3.new(0.3, 1.1, 1.2), seat.CFrame * CFrame.new(-1.7, -0.6, 0), Color3.fromRGB(70, 50, 36), Enum.Material.Wood, true)
	PropKit.Part(parent, name .. "LegR", Vector3.new(0.3, 1.1, 1.2), seat.CFrame * CFrame.new(1.7, -0.6, 0), Color3.fromRGB(70, 50, 36), Enum.Material.Wood, true)
	return seat
end

function PropKit.Pillar(parent, name, position, height, color, material)
	local h = height or 8
	local shaft = PropKit.Cylinder(parent, name, Vector3.new(h, 1.5, 1.5), CFrame.new(position + Vector3.new(0, h * 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), color or Color3.fromRGB(150, 146, 138), material or Enum.Material.Marble, false, nil)
	PropKit.Part(parent, name .. "Cap", Vector3.new(2.1, 0.4, 2.1), CFrame.new(position + Vector3.new(0, h + 0.2, 0)), color or Color3.fromRGB(170, 164, 150), material or Enum.Material.Marble, false)
	PropKit.Part(parent, name .. "Base", Vector3.new(2.3, 0.45, 2.3), CFrame.new(position + Vector3.new(0, 0.2, 0)), Color3.fromRGB(90, 86, 80), Enum.Material.Slate, false)
	return shaft
end

function PropKit.Crystal(parent, name, position, color, scale)
	local s = scale or 1
	local crystal = PropKit.Part(parent, name, Vector3.new(0.7, 2.4, 0.7) * s, CFrame.new(position + Vector3.new(0, 1.2 * s, 0)) * CFrame.Angles(0, 0.4, 0.15), color or Color3.fromRGB(140, 190, 255), Enum.Material.Neon, false, 0.15)
	PropKit.Part(parent, name .. "Shard", Vector3.new(0.35, 1.4, 0.35) * s, crystal.CFrame * CFrame.new(0.45, -0.2, 0.2), color, Enum.Material.Glass, false, 0.2)
	if s >= 1.2 then
		PropKit.Spark(crystal, color, 2)
	end
	return crystal
end

function PropKit.Grave(parent, name, position)
	local stone = PropKit.Part(parent, name, Vector3.new(2.2, 2.4, 0.35), CFrame.new(position + Vector3.new(0, 1.3, 0)), Color3.fromRGB(130, 132, 136), Enum.Material.Slate, false)
	PropKit.Part(parent, name .. "Base", Vector3.new(2.6, 0.35, 0.8), stone.CFrame * CFrame.new(0, -1.25, 0), Color3.fromRGB(90, 90, 94), Enum.Material.Slate, false)
	return stone
end

function PropKit.Arch(parent, name, position, color, yaw)
	color = color or Color3.fromRGB(120, 110, 98)
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
	local left = PropKit.Part(parent, name .. "L", Vector3.new(1.2, 8, 1.2), cf * CFrame.new(-4.2, 4, 0), color or Color3.fromRGB(120, 110, 98), Enum.Material.Cobblestone, false, nil, false)
	local right = PropKit.Part(parent, name .. "R", Vector3.new(1.2, 8, 1.2), cf * CFrame.new(4.2, 4, 0), color or Color3.fromRGB(120, 110, 98), Enum.Material.Cobblestone, false, nil, false)
	PropKit.Part(parent, name .. "Top", Vector3.new(9.6, 1.1, 1.3), cf * CFrame.new(0, 8.4, 0), color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.Cobblestone, false, nil, false)
	return left
end

function PropKit.Fountain(parent, name, position)
	local base = PropKit.Cylinder(parent, name .. "Basin", Vector3.new(1.2, 14, 14), CFrame.new(position + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(168, 164, 156), Enum.Material.Marble, true, nil)
	local water = PropKit.Cylinder(parent, name .. "Water", Vector3.new(0.45, 11, 11), CFrame.new(position + Vector3.new(0, 1.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(80, 150, 190), Enum.Material.Glass, false, 0.35)
	local pillar = PropKit.Part(parent, name .. "Spout", Vector3.new(1.2, 3.4, 1.2), CFrame.new(position + Vector3.new(0, 2.6, 0)), Color3.fromRGB(210, 198, 160), Enum.Material.Marble, false, nil, true)
	local jet = PropKit.Ball(parent, name .. "Jet", Vector3.new(1.1, 1.1, 1.1), pillar.CFrame * CFrame.new(0, 2, 0), Color3.fromRGB(150, 210, 230), Enum.Material.Neon, false, 0.25)
	PropKit.Spark(jet, Color3.fromRGB(180, 220, 255), 3)
	PropKit.Light(jet, Color3.fromRGB(180, 210, 255), 14, 0.45)
	return base
end

function PropKit.Statue(parent, name, position, color)
	local plinth = PropKit.Part(parent, name .. "Plinth", Vector3.new(3.2, 1.4, 3.2), CFrame.new(position + Vector3.new(0, 0.7, 0)), Color3.fromRGB(90, 86, 80), Enum.Material.Slate, true, nil, true)
	local body = PropKit.Part(parent, name .. "Body", Vector3.new(1.5, 2.6, 1), plinth.CFrame * CFrame.new(0, 2, 0), color or Color3.fromRGB(214, 206, 188), Enum.Material.Marble, false, nil, true)
	PropKit.Ball(parent, name .. "Head", Vector3.new(1.05, 1.05, 1.05), body.CFrame * CFrame.new(0, 1.7, 0), color or Color3.fromRGB(230, 224, 210), Enum.Material.Marble, false)
	PropKit.Part(parent, name .. "Blade", Vector3.new(0.18, 2.4, 0.4), body.CFrame * CFrame.new(0.9, 0.4, -0.2), Color3.fromRGB(190, 196, 204), Enum.Material.Metal, false)
	return plinth
end

function PropKit.Egg(parent, name, position, color, fancy)
	local shell = PropKit.Part(parent, name, Vector3.new(3.1, 3.9, 3.1), CFrame.new(position), color, fancy and Enum.Material.Neon or Enum.Material.SmoothPlastic, false, fancy and 0.08 or 0)
	PropKit.SphereMesh(shell, Vector3.new(0.86, 1.12, 0.86))
	local band = PropKit.Part(parent, name .. "Band", Vector3.new(2.5, 0.28, 2.5), CFrame.new(position), Color3.fromRGB(230, 206, 130), Enum.Material.Metal, false)
	PropKit.SphereMesh(band, Vector3.new(1.05, 0.35, 1.05))
	local cap = PropKit.Part(parent, name .. "Cap", Vector3.new(1.1, 0.45, 1.1), CFrame.new(position + Vector3.new(0, 1.85, 0)), color:Lerp(Color3.new(1, 1, 1), 0.35), Enum.Material.Metal, false)
	if fancy then
		PropKit.Spark(shell, color, 3)
	else
		PropKit.Spark(shell, color:Lerp(Color3.new(1, 1, 1), 0.4), 1)
	end
	return shell
end

function PropKit.Pedestal(parent, name, position, color)
	local foot = PropKit.Part(parent, name, Vector3.new(5.2, 0.6, 5.2), CFrame.new(position + Vector3.new(0, 0.3, 0)), color or Color3.fromRGB(78, 70, 60), Enum.Material.Slate, true, nil, true)
	local column = PropKit.Part(parent, name .. "Column", Vector3.new(2.4, 2.2, 2.4), foot.CFrame * CFrame.new(0, 1.3, 0), (color or Color3.fromRGB(90, 80, 68)):Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Marble, true, nil, true)
	return column
end

function PropKit.FenceRun(parent, name, from, to, color)
	local delta = to - from
	local length = Vector3.new(delta.X, 0, delta.Z).Magnitude
	if length < 1 then
		return nil
	end
	local mid = (from + to) * 0.5
	local yaw = math.atan2(delta.X, delta.Z)
	local rail = PropKit.Part(parent, name, Vector3.new(0.25, 0.25, length), CFrame.new(mid + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, yaw, 0), color or Color3.fromRGB(96, 72, 48), Enum.Material.Wood, false)
	local posts = math.max(2, math.floor(length / 6))
	for index = 0, posts do
		local alpha = index / posts
		local spot = from:Lerp(to, alpha)
		PropKit.Part(parent, name .. "P" .. index, Vector3.new(0.35, 2.6, 0.35), CFrame.new(spot + Vector3.new(0, 1.3, 0)), color or Color3.fromRGB(84, 62, 42), Enum.Material.Wood, false)
	end
	return rail
end

function PropKit.Coffin(parent, name, position, yaw)
	local cf = CFrame.new(position + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, yaw or 0, 0)
	local box = PropKit.Part(parent, name, Vector3.new(2.2, 1.1, 5.2), cf, Color3.fromRGB(72, 56, 44), Enum.Material.Wood, false)
	PropKit.Part(parent, name .. "Lid", Vector3.new(1.8, 0.25, 4.6), box.CFrame * CFrame.new(0, 0.65, 0), Color3.fromRGB(90, 70, 52), Enum.Material.Wood, false)
	return box
end

function PropKit.Web(parent, name, position)
	local web = PropKit.Part(parent, name, Vector3.new(6, 0.08, 6), CFrame.new(position) * CFrame.Angles(0, 0.3, 0), Color3.fromRGB(220, 220, 226), Enum.Material.SmoothPlastic, false, 0.45)
	return web
end

function PropKit.LavaCrack(parent, name, position, yaw)
	local crack = PropKit.Part(parent, name, Vector3.new(1.2, 0.15, 7), CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, yaw or 0, 0), Color3.fromRGB(255, 90, 30), Enum.Material.Neon, false)
	return crack
end

return PropKit
