-- Warrior del Mondo 0. Geometria procedurale nativa, un solo costume.
-- La stessa funzione veste il giocatore e l'anteprima Studio.
--
-- Perché il modello precedente non reggeva i fogli:
-- aggiungeva pochi blocchi sopra l'avatar Roblox, senza togliere vestiti,
-- viso, capelli e accessori. Le spalle erano due sfere speculari, la clava
-- era corta e il busto veniva coperto come una tunica.
--
-- Assi locali del corpo: +X destra del personaggio, +Y su, -Z avanti.
-- Il cranio sta sulla spalla SINISTRA (-X). La clava sta nella mano DESTRA.

local shared = require(script.Parent.SharedLoader)
local Rules = shared("Rules")
local Palette = require(script.Parent.WarriorPalette)

local WarriorVisualBuilder = {}

local VISUAL_VERSION = "003.2"
local FOLDER_NAME = "KurkitoVisuals"

local function firstPart(root, names)
	for _, name in ipairs(names) do
		local found = root:FindFirstChild(name)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	for _, name in ipairs(names) do
		local found = root:FindFirstChild(name, true)
		if found and found:IsA("BasePart") and not found:FindFirstAncestor(FOLDER_NAME) then
			return found
		end
	end
	return nil
end

local function findLimbs(character)
	local upperTorso = firstPart(character, { "UpperTorso", "Torso" })
	local head = firstPart(character, { "Head" })
	local hand = firstPart(character, { "RightHand", "Right Arm" })
	if not upperTorso or not head or not hand then
		return nil
	end
	local lowerTorso = firstPart(character, { "LowerTorso" }) or upperTorso
	local rightUpper = firstPart(character, { "RightUpperArm", "Right Arm" }) or hand
	local rightLower = firstPart(character, { "RightLowerArm", "Right Arm" }) or rightUpper
	local leftUpper = firstPart(character, { "LeftUpperArm", "Left Arm" })
	local leftLower = firstPart(character, { "LeftLowerArm", "Left Arm" }) or leftUpper
	local leftHand = firstPart(character, { "LeftHand", "Left Arm" }) or leftLower
	local rightUpperLeg = firstPart(character, { "RightUpperLeg", "Right Leg" })
	local leftUpperLeg = firstPart(character, { "LeftUpperLeg", "Left Leg" })
	local rightLowerLeg = firstPart(character, { "RightLowerLeg", "Right Leg" }) or rightUpperLeg
	local leftLowerLeg = firstPart(character, { "LeftLowerLeg", "Left Leg" }) or leftUpperLeg
	local rightFoot = firstPart(character, { "RightFoot", "Right Leg" }) or rightLowerLeg
	local leftFoot = firstPart(character, { "LeftFoot", "Left Leg" }) or leftLowerLeg
	return {
		r15 = character:FindFirstChild("UpperTorso") ~= nil,
		head = head,
		upperTorso = upperTorso,
		lowerTorso = lowerTorso,
		rightUpper = rightUpper,
		rightLower = rightLower,
		rightHand = hand,
		leftUpper = leftUpper,
		leftLower = leftLower,
		leftHand = leftHand,
		rightUpperLeg = rightUpperLeg,
		leftUpperLeg = leftUpperLeg,
		rightLowerLeg = rightLowerLeg,
		leftLowerLeg = leftLowerLeg,
		rightFoot = rightFoot,
		leftFoot = leftFoot,
	}
end

function WarriorVisualBuilder.HasForeignCosmetics(character)
	if not character then
		return false
	end
	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("Accessory") or child:IsA("CharacterMesh") or child:IsA("FaceControls") then
			return true
		end
		if (child:IsA("Decal") or child:IsA("Texture")) and child.Parent and child.Parent.Name == "Head" then
			return true
		end
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("MeshPart") and head.Transparency < 0.9 and head.TextureID ~= "" then
		return true
	end
	return false
end

local function stripCosmetics(character)
	local doomed = {}
	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("Accessory") or child:IsA("CharacterMesh") or child:IsA("FaceControls") or child:IsA("SurfaceAppearance") or child:IsA("WrapLayer") or child:IsA("WrapTarget") then
			table.insert(doomed, child)
		elseif (child:IsA("Decal") or child:IsA("Texture")) and child.Parent and child.Parent.Name == "Head" then
			table.insert(doomed, child)
		elseif child.Name == "KurkitoTrailA" or child.Name == "KurkitoTrailB" or child.Name == "ManaSpark" then
			table.insert(doomed, child)
		end
	end
	for _, child in ipairs(doomed) do
		pcall(function()
			child:Destroy()
		end)
	end
end

local function paintBody(character, skin)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
	end
	bodyColors.HeadColor3 = skin
	bodyColors.TorsoColor3 = skin
	bodyColors.LeftArmColor3 = skin
	bodyColors.RightArmColor3 = skin
	bodyColors.LeftLegColor3 = skin
	bodyColors.RightLegColor3 = skin
	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" and not child:FindFirstAncestor(FOLDER_NAME) and not child:FindFirstAncestor("KurkitoPets") then
			child.Color = skin
			child.Material = Enum.Material.SmoothPlastic
			child.Reflectance = 0
			if child:IsA("MeshPart") then
				pcall(function()
					child.TextureID = ""
				end)
			end
			local special = child:FindFirstChildOfClass("SpecialMesh")
			if special then
				pcall(function()
					special.TextureId = ""
				end)
			end
		end
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		head.Transparency = 1
		head.CastShadow = false
	end
end

local function guardCosmetics(character)
	if not character:GetAttribute("KurkitoCosmeticGuard") then
		character:SetAttribute("KurkitoCosmeticGuard", true)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("Accessory") or child:IsA("CharacterMesh") then
				pcall(function()
					child:Destroy()
				end)
			end
		end)
	end
	local head = character:FindFirstChild("Head")
	if head and not head:GetAttribute("KurkitoFaceGuard") then
		head:SetAttribute("KurkitoFaceGuard", true)
		head.ChildAdded:Connect(function(child)
			if child:IsA("Decal") or child:IsA("Texture") or child:IsA("FaceControls") then
				pcall(function()
					child:Destroy()
				end)
			end
		end)
	end
end

local function makeCtx(folder, full)
	local ctx = {
		folder = folder,
		full = full,
		count = 0,
	}

	function ctx.part(name, size, cf, color, material, target, shadow)
		local piece = Instance.new("Part")
		piece.Name = name
		piece.Size = size
		piece.CFrame = cf
		piece.Color = color
		piece.Material = material or Enum.Material.SmoothPlastic
		piece.Anchored = false
		piece.CanCollide = false
		piece.CanQuery = false
		piece.CanTouch = false
		piece.Massless = true
		piece.CastShadow = shadow == true
		piece.Reflectance = 0
		piece.TopSurface = Enum.SurfaceType.Smooth
		piece.BottomSurface = Enum.SurfaceType.Smooth
		piece.Parent = folder
		if target then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = target
			weld.Part1 = piece
			weld.Parent = piece
		end
		ctx.count += 1
		return piece
	end

	function ctx.ball(name, size, cf, color, material, target, shadow)
		local piece = ctx.part(name, size, cf, color, material, target, shadow)
		piece.Shape = Enum.PartType.Ball
		return piece
	end

	function ctx.wedge(name, size, cf, color, material, target, shadow)
		local piece = Instance.new("WedgePart")
		piece.Name = name
		piece.Size = size
		piece.CFrame = cf
		piece.Color = color
		piece.Material = material or Enum.Material.Fabric
		piece.Anchored = false
		piece.CanCollide = false
		piece.CanQuery = false
		piece.CanTouch = false
		piece.Massless = true
		piece.CastShadow = shadow == true
		piece.TopSurface = Enum.SurfaceType.Smooth
		piece.BottomSurface = Enum.SurfaceType.Smooth
		piece.Parent = folder
		if target then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = target
			weld.Part1 = piece
			weld.Parent = piece
		end
		ctx.count += 1
		return piece
	end

	-- Lunghezza sull'asse Y del CFrame dato. Il cilindro nativo è lungo X.
	function ctx.cylinder(name, length, diameter, cf, color, material, target, shadow)
		local piece = ctx.part(name, Vector3.new(length, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), color, material, target, shadow)
		piece.Shape = Enum.PartType.Cylinder
		return piece
	end

	-- Ellisse lunga: la punta cresce lungo +Y a partire da baseCF.
	function ctx.spike(name, baseCF, length, thickness, color, material, target)
		local cf = baseCF * CFrame.new(0, length * 0.5, 0)
		return ctx.ball(name, Vector3.new(thickness, length, thickness * 0.82), cf, color, material or Enum.Material.SmoothPlastic, target, false)
	end

	return ctx
end

local function span(fromPos, toPos)
	local delta = toPos - fromPos
	local length = delta.Magnitude
	if length < 0.05 then
		return CFrame.new(fromPos), 0.05
	end
	local up = Vector3.new(0, 1, 0)
	if math.abs(delta.Unit:Dot(up)) > 0.98 then
		up = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(fromPos, toPos, up), length
end

local function worldPos(part, localPos)
	return (part.CFrame * CFrame.new(localPos)).Position
end

local function tiersOf(heroState)
	local stats = heroState and heroState.stats or {}
	return {
		hp = Rules.VisualTier(stats.HP or 1),
		dmg = Rules.VisualTier(stats.DMG or 1),
		speed = Rules.VisualTier(stats.Speed or 1),
	}
end

local function buildHead(ctx, limbs)
	local head = limbs.head
	local shell = Palette.HeadShell
	ctx.part("HeadShell", shell, head.CFrame, Palette.Skin, Enum.Material.SmoothPlastic, head, true)
	local front = -(shell.Z * 0.5 + 0.03)
	-- Spigoli anteriori ammorbiditi: il volto dei fogli è un cubo arrotondato.
	local edge = shell.X * 0.38
	local rise = shell.Y * 0.32
	ctx.ball("HeadCorner", Vector3.new(0.28, 0.34, 0.22), head.CFrame * CFrame.new(-edge, rise, front + 0.08), Palette.Skin, Enum.Material.SmoothPlastic, head, false)
	ctx.ball("HeadCorner", Vector3.new(0.28, 0.34, 0.22), head.CFrame * CFrame.new(edge, rise, front + 0.08), Palette.Skin, Enum.Material.SmoothPlastic, head, false)
	ctx.ball("HeadCorner", Vector3.new(0.26, 0.28, 0.2), head.CFrame * CFrame.new(-edge, -rise, front + 0.1), Palette.Skin, Enum.Material.SmoothPlastic, head, false)
	ctx.ball("HeadCorner", Vector3.new(0.26, 0.28, 0.2), head.CFrame * CFrame.new(edge, -rise, front + 0.1), Palette.Skin, Enum.Material.SmoothPlastic, head, false)
	ctx.cylinder("Neck", 0.34, 0.52, head.CFrame * CFrame.new(0, -(shell.Y * 0.46), 0.04), Palette.Skin, Enum.Material.SmoothPlastic, head, false)

	local function face(name, size, offset, color, shape)
		local cf = head.CFrame * CFrame.new(offset)
		local piece = ctx.part(name, size, cf, color, Enum.Material.SmoothPlastic, head, false)
		if shape then
			piece.Shape = shape
		end
		return piece
	end

	face("EyeWhite", Vector3.new(0.3, 0.34, 0.1), Vector3.new(-0.28, 0.04, front - 0.02), Palette.EyeWhite, Enum.PartType.Ball)
	face("EyeWhite", Vector3.new(0.3, 0.34, 0.1), Vector3.new(0.28, 0.04, front - 0.02), Palette.EyeWhite, Enum.PartType.Ball)
	face("Iris", Vector3.new(0.2, 0.22, 0.08), Vector3.new(-0.28, 0.03, front - 0.06), Palette.Iris, Enum.PartType.Ball)
	face("Iris", Vector3.new(0.2, 0.22, 0.08), Vector3.new(0.28, 0.03, front - 0.06), Palette.Iris, Enum.PartType.Ball)
	face("Pupil", Vector3.new(0.1, 0.11, 0.06), Vector3.new(-0.28, 0.03, front - 0.09), Palette.Pupil, Enum.PartType.Ball)
	face("Pupil", Vector3.new(0.1, 0.11, 0.06), Vector3.new(0.28, 0.03, front - 0.09), Palette.Pupil, Enum.PartType.Ball)
	face("EyeHighlight", Vector3.new(0.06, 0.06, 0.04), Vector3.new(-0.34, 0.1, front - 0.1), Palette.EyeWhite, Enum.PartType.Ball)
	face("EyeHighlight", Vector3.new(0.06, 0.06, 0.04), Vector3.new(0.22, 0.1, front - 0.1), Palette.EyeWhite, Enum.PartType.Ball)

	local function brow(x, roll)
		local cf = head.CFrame * CFrame.new(x, 0.3, front - 0.04) * CFrame.Angles(0, 0, math.rad(roll))
		ctx.part("FaceBrow", Vector3.new(0.4, 0.13, 0.1), cf, Palette.Brow, Enum.Material.SmoothPlastic, head, false)
	end
	brow(-0.26, -18)
	brow(0.26, 18)

	ctx.part("Mouth", Vector3.new(0.26, 0.045, 0.06), head.CFrame * CFrame.new(0, -0.36, front - 0.03), Palette.Mouth, Enum.Material.SmoothPlastic, head, false)
	ctx.ball("Nose", Vector3.new(0.12, 0.14, 0.1), head.CFrame * CFrame.new(0, -0.08, front - 0.06), Palette.SkinShadow, Enum.Material.SmoothPlastic, head, false)

	-- Pittura bianca sotto gli occhi, due colpi per lato.
	local paints = {
		{ -0.2, -0.2, 0.34, 8 },
		{ -0.34, -0.16, 0.26, 14 },
		{ 0.2, -0.2, 0.36, -6 },
		{ 0.36, -0.15, 0.24, -12 },
	}
	for _, mark in ipairs(paints) do
		local cf = head.CFrame * CFrame.new(mark[1], mark[2], front - 0.04) * CFrame.Angles(0, 0, math.rad(mark[4]))
		ctx.part("FacePaint", Vector3.new(0.07, mark[3], 0.05), cf, Palette.Paint, Enum.Material.SmoothPlastic, head, false)
	end
	return shell
end

local function buildHair(ctx, head)
	-- Ciocche grosse, non un elmo. I valori sono offset locali della testa.
	local locks = {
		{ -0.22, 0.78, -0.36, -24, 12, 16, 0.4, 0.58, 0.42, false },
		{ 0.26, 0.82, -0.32, -18, -14, -12, 0.38, 0.64, 0.4, false },
		{ 0.02, 0.96, -0.12, -12, 4, 8, 0.36, 0.7, 0.4, false },
		{ -0.34, 0.92, 0.08, -8, 20, 22, 0.34, 0.66, 0.38, false },
		{ 0.38, 0.98, 0.12, -6, -18, -20, 0.36, 0.72, 0.4, false },
		{ -0.78, 0.22, 0.02, 8, 0, 10, 0.52, 0.78, 0.56, false },
		{ 0.8, 0.2, 0.04, 6, 0, -12, 0.5, 0.74, 0.54, false },
		{ -0.7, -0.08, -0.08, 14, 8, 6, 0.4, 0.55, 0.42, false },
		{ 0.72, -0.05, -0.02, 12, -6, -8, 0.4, 0.52, 0.4, false },
		{ -0.12, 0.48, 0.72, 20, 10, 8, 0.48, 0.62, 0.5, false },
		{ 0.22, 0.12, 0.78, 16, -8, -6, 0.46, 0.7, 0.48, false },
		{ -0.02, -0.18, 0.68, 10, 4, 4, 0.5, 0.58, 0.46, false },
		{ 0.42, 0.7, 0.28, -10, -24, -16, 0.32, 0.5, 0.34, true },
		{ -0.46, 0.62, 0.22, -8, 22, 18, 0.32, 0.48, 0.34, true },
		{ 0.08, 0.55, -0.48, -32, -6, 4, 0.28, 0.36, 0.3, true },
		{ -0.48, 0.4, -0.28, -10, 28, 20, 0.3, 0.42, 0.32, true },
		{ 0.5, 0.36, -0.22, -8, -26, -18, 0.3, 0.4, 0.32, true },
		{ 0.16, -0.02, 0.62, 18, 12, -8, 0.36, 0.48, 0.34, true },
	}
	for index, lock in ipairs(locks) do
		if ctx.full or not lock[10] then
			local cf = head.CFrame * CFrame.new(lock[1], lock[2], lock[3]) * CFrame.Angles(math.rad(lock[4]), math.rad(lock[5]), math.rad(lock[6]))
			local color = index % 4 == 0 and Palette.HairEdge or Palette.Hair
			ctx.part("HairLock", Vector3.new(lock[7], lock[8], lock[9]), cf, color, Enum.Material.Fabric, head, index <= 6)
		end
	end
end

local function buildTorsoVolume(ctx, torso)
	local halfZ = math.max(torso.Size.Z * 0.5, 0.42)
	ctx.ball("Pec", Vector3.new(0.78, 0.52, 0.42), torso.CFrame * CFrame.new(-0.32, 0.12, -(halfZ + 0.02)), Palette.Skin, Enum.Material.SmoothPlastic, torso, false)
	ctx.ball("Pec", Vector3.new(0.78, 0.52, 0.42), torso.CFrame * CFrame.new(0.34, 0.1, -(halfZ + 0.02)), Palette.Skin, Enum.Material.SmoothPlastic, torso, false)
	ctx.ball("Abdomen", Vector3.new(0.62, 0.48, 0.32), torso.CFrame * CFrame.new(0.02, -0.38, -(halfZ - 0.02)), Palette.SkinShadow, Enum.Material.SmoothPlastic, torso, false)
	if ctx.full then
		ctx.ball("Oblique", Vector3.new(0.28, 0.36, 0.2), torso.CFrame * CFrame.new(-0.42, -0.28, -(halfZ - 0.02)), Palette.SkinDeep, Enum.Material.SmoothPlastic, torso, false)
		ctx.ball("Oblique", Vector3.new(0.28, 0.36, 0.2), torso.CFrame * CFrame.new(0.44, -0.26, -(halfZ - 0.02)), Palette.SkinDeep, Enum.Material.SmoothPlastic, torso, false)
	end
end

local function buildFur(ctx, torso)
	local halfX = math.max(torso.Size.X * 0.5, 0.85)
	local halfY = math.max(torso.Size.Y * 0.5, 0.55)
	local halfZ = math.max(torso.Size.Z * 0.5, 0.42)
	local furColors = { Palette.FurDark, Palette.Fur, Palette.FurMid, Palette.FurLight }

	ctx.part("FurMantle", Vector3.new(halfX * 2.15, 0.42, halfZ * 1.7), torso.CFrame * CFrame.new(0, halfY * 0.72, halfZ * 0.15), Palette.FurDark, Enum.Material.Fabric, torso, true)
	ctx.ball("FurShoulder", Vector3.new(1.15, 0.72, 0.95), torso.CFrame * CFrame.new(-(halfX + 0.18), halfY * 0.35, 0.02), Palette.Fur, Enum.Material.Fabric, torso, true)
	ctx.ball("FurShoulder", Vector3.new(1.05, 0.66, 0.9), torso.CFrame * CFrame.new(halfX + 0.12, halfY * 0.32, 0.04), Palette.FurMid, Enum.Material.Fabric, torso, true)

	-- Lembo a punta. Il cuneo nativo ha la faccia alta verso +Z e scende verso -Z.
	local flaps = {
		{ -0.55, 0.35, -0.42, 62, 18, 8, 0.48, 0.72, 0.42, 2, false },
		{ 0.58, 0.32, -0.4, 58, -16, -6, 0.5, 0.78, 0.4, 1, false },
		{ -0.95, 0.22, -0.12, 70, 8, 24, 0.46, 0.85, 0.4, 1, false },
		{ 0.98, 0.2, -0.08, 68, -10, -22, 0.44, 0.8, 0.38, 2, false },
		{ -1.15, 0.08, 0.2, 78, -12, 30, 0.42, 0.7, 0.36, 3, false },
		{ 1.12, 0.06, 0.22, 76, 14, -28, 0.4, 0.66, 0.34, 2, false },
		{ -0.35, 0.48, 0.48, 48, 140, 10, 0.55, 0.6, 0.4, 1, false },
		{ 0.4, 0.46, 0.5, 50, -150, -8, 0.52, 0.64, 0.38, 2, false },
		{ 0.0, 0.55, 0.55, 40, 180, 0, 0.7, 0.55, 0.42, 1, false },
		{ -0.72, 0.4, 0.28, 55, 70, 18, 0.4, 0.58, 0.34, 3, false },
		{ -0.28, 0.42, -0.55, 50, 8, -12, 0.36, 0.48, 0.3, 3, true },
		{ 0.32, 0.4, -0.52, 48, -6, 10, 0.34, 0.5, 0.3, 4, true },
		{ -1.28, -0.05, 0.05, 84, 0, 18, 0.32, 0.55, 0.28, 2, true },
		{ 1.25, -0.02, 0.08, 82, 0, -16, 0.32, 0.5, 0.28, 1, true },
		{ 0.15, 0.2, 0.62, 36, 170, 8, 0.4, 0.5, 0.3, 3, true },
		{ -0.85, 0.15, -0.35, 66, 24, 14, 0.3, 0.46, 0.26, 4, true },
	}
	for _, flap in ipairs(flaps) do
		if ctx.full or not flap[11] then
			local cf = torso.CFrame * CFrame.new(flap[1], flap[2], flap[3]) * CFrame.Angles(math.rad(flap[4]), math.rad(flap[5]), math.rad(flap[6]))
			ctx.wedge("FurFlap", Vector3.new(flap[7], flap[8], flap[9]), cf, furColors[flap[10]], Enum.Material.Fabric, torso, false)
		end
	end

	-- Cinghie di cuoio sotto la pelliccia, visibili sul petto.
	ctx.part("CollarStrap", Vector3.new(halfX * 1.5, 0.1, 0.16), torso.CFrame * CFrame.new(0, halfY * 0.15, -(halfZ + 0.08)) * CFrame.Angles(0, 0, math.rad(8)), Palette.Leather, Enum.Material.Leather, torso, false)
	ctx.part("CollarStrap", Vector3.new(0.16, 0.1, halfZ * 1.3), torso.CFrame * CFrame.new(-halfX * 0.2, halfY * 0.22, 0) * CFrame.Angles(math.rad(16), 0, 0), Palette.LeatherMid, Enum.Material.Leather, torso, false)

	local teeth = {
		{ -0.7, 0.25, -0.35, 0.22 },
		{ 0.62, 0.22, -0.32, 0.18 },
		{ -0.4, 0.38, 0.4, 0.16 },
		{ 0.85, 0.18, 0.15, 0.2 },
	}
	for index, tooth in ipairs(teeth) do
		if ctx.full or index <= 3 then
			local base = torso.CFrame * CFrame.new(tooth[1], tooth[2], tooth[3]) * CFrame.Angles(math.rad(20), 0, math.rad(index % 2 == 0 and 12 or -10))
			ctx.spike("CollarBone", base, tooth[4], 0.08, Palette.Bone, Enum.Material.SmoothPlastic, torso)
		end
	end
	return halfX, halfY, halfZ
end

local function buildSkull(ctx, torso, halfX, halfY)
	-- Spalla sinistra del Warrior. Lo snout del cranio guarda verso -X.
	local origin = torso.CFrame * CFrame.new(-(halfX + 0.22), halfY * 0.22, -0.06) * CFrame.Angles(math.rad(14), math.rad(86), math.rad(-18))
	local function place(name, kind, size, localCF, color, shadow)
		local cf = origin * localCF
		if kind == "ball" then
			return ctx.ball(name, size, cf, color, Enum.Material.SmoothPlastic, torso, shadow)
		end
		return ctx.part(name, size, cf, color, Enum.Material.SmoothPlastic, torso, shadow)
	end
	place("SkullCranium", "ball", Vector3.new(0.95, 0.74, 1.08), CFrame.new(), Palette.Bone, true)
	place("SkullSnout", "ball", Vector3.new(0.5, 0.4, 0.66), CFrame.new(0, -0.08, -0.55), Palette.Bone, false)
	place("SkullJaw", "block", Vector3.new(0.46, 0.16, 0.5), CFrame.new(0, -0.3, -0.4), Palette.BoneDark, false)
	place("SkullEye", "ball", Vector3.new(0.2, 0.17, 0.12), CFrame.new(-0.18, 0.08, -0.4), Palette.Socket, false)
	place("SkullEye", "ball", Vector3.new(0.2, 0.17, 0.12), CFrame.new(0.18, 0.06, -0.38), Palette.Socket, false)
	place("SkullNose", "ball", Vector3.new(0.14, 0.1, 0.1), CFrame.new(0, -0.06, -0.82), Palette.Socket, false)
	place("SkullCrack", "block", Vector3.new(0.06, 0.28, 0.4), CFrame.new(0.08, 0.12, 0.1) * CFrame.Angles(0, math.rad(18), math.rad(8)), Palette.BoneDark, false)
	for index, x in ipairs({ -0.16, -0.06, 0.05, 0.15 }) do
		ctx.spike("SkullTooth", origin * CFrame.new(x, -0.34, -0.58) * CFrame.Angles(math.rad(80), 0, 0), 0.16 + (index % 2) * 0.04, 0.07, Palette.Bone, Enum.Material.SmoothPlastic, torso)
	end
	local spikes = {
		CFrame.new(0.42, 0.2, -0.05) * CFrame.Angles(0, 0, math.rad(-55)),
		CFrame.new(-0.4, 0.22, 0.02) * CFrame.Angles(0, 0, math.rad(50)),
		CFrame.new(0.05, 0.4, -0.1) * CFrame.Angles(math.rad(-35), 0, 0),
		CFrame.new(0.22, 0.02, 0.42) * CFrame.Angles(math.rad(40), math.rad(20), 0),
		CFrame.new(-0.18, 0.0, 0.4) * CFrame.Angles(math.rad(32), math.rad(-16), 0),
		CFrame.new(0.3, -0.08, -0.2) * CFrame.Angles(0, 0, math.rad(-70)),
	}
	for index, localCF in ipairs(spikes) do
		if ctx.full or index <= 4 then
			ctx.spike("SkullSpike", origin * localCF, 0.22 + (index % 3) * 0.06, 0.09, Palette.Bone, Enum.Material.SmoothPlastic, torso)
		end
	end

	-- La spalla destra non ha il cranio: solo pelliccia e punte piccole.
	local right = torso.CFrame * CFrame.new(halfX + 0.35, halfY * 0.28, -0.02)
	ctx.spike("RightShoulderSpike", right * CFrame.Angles(0, 0, math.rad(50)), 0.28, 0.1, Palette.Bone, Enum.Material.SmoothPlastic, torso)
	ctx.spike("RightShoulderSpike", right * CFrame.new(0.12, -0.08, -0.12) * CFrame.Angles(math.rad(20), 0, math.rad(30)), 0.2, 0.08, Palette.BoneDark, Enum.Material.SmoothPlastic, torso)
	if ctx.full then
		ctx.spike("RightShoulderSpike", right * CFrame.new(-0.05, 0.1, 0.16) * CFrame.Angles(math.rad(-15), 0, math.rad(20)), 0.18, 0.07, Palette.Bone, Enum.Material.SmoothPlastic, torso)
	end
end

local function buildNecklace(ctx, torso, halfY, halfZ)
	local y = halfY * 0.02
	local z = -(halfZ + 0.16)
	ctx.part("NecklaceCord", Vector3.new(1.25, 0.1, 0.1), torso.CFrame * CFrame.new(0, y + 0.14, z) * CFrame.Angles(math.rad(16), 0, math.rad(5)), Palette.Leather, Enum.Material.Leather, torso, false)
	ctx.part("NecklaceCord", Vector3.new(0.7, 0.08, 0.08), torso.CFrame * CFrame.new(-0.28, y + 0.2, z + 0.02) * CFrame.Angles(math.rad(22), math.rad(12), math.rad(8)), Palette.LeatherMid, Enum.Material.Leather, torso, false)
	local fangs = {
		{ -0.46, 0.22, 6 },
		{ -0.28, 0.36, -8 },
		{ -0.12, 0.52, 4 },
		{ 0.02, 0.66, -3 },
		{ 0.16, 0.5, 7 },
		{ 0.32, 0.34, -5 },
		{ 0.46, 0.24, 9 },
	}
	for _, fang in ipairs(fangs) do
		local base = torso.CFrame * CFrame.new(fang[1], y - 0.02, z - 0.04) * CFrame.Angles(math.rad(12), 0, math.rad(fang[3])) * CFrame.Angles(math.rad(180), 0, 0)
		ctx.spike("BoneFang", base, fang[2], 0.11, Palette.Bone, Enum.Material.SmoothPlastic, torso)
	end
end

local function buildStrap(ctx, torso, halfX, halfY, halfZ)
	local startLocal = Vector3.new(halfX * 0.72, halfY * 0.42, -(halfZ + 0.12))
	local finishLocal = Vector3.new(-halfX * 0.55, -halfY * 0.95, -(halfZ + 0.06))
	for index = 1, 4 do
		local a = startLocal:Lerp(finishLocal, (index - 1) / 4)
		local b = startLocal:Lerp(finishLocal, index / 4)
		local cf, length = span(worldPos(torso, a), worldPos(torso, b))
		ctx.part("ChestStrap", Vector3.new(0.28, 0.12, length + 0.02), cf, index % 2 == 0 and Palette.Leather or Palette.LeatherMid, Enum.Material.Leather, torso, false)
	end
	local buckleAt = startLocal:Lerp(finishLocal, 0.62)
	ctx.part("ChestBuckle", Vector3.new(0.32, 0.26, 0.1), torso.CFrame * CFrame.new(buckleAt), Palette.Metal, Enum.Material.Metal, torso, false)
	ctx.part("ChestBuckle", Vector3.new(0.12, 0.16, 0.06), torso.CFrame * CFrame.new(buckleAt + Vector3.new(0, 0, -0.06)), Palette.LeatherWorn, Enum.Material.Leather, torso, false)
end

local function buildBelt(ctx, limbs, tiers)
	local waist = limbs.lowerTorso
	local y = limbs.r15 and waist.Size.Y * 0.2 or -waist.Size.Y * 0.32
	local forward = -(math.max(waist.Size.Z * 0.5, 0.4) + 0.08)
	local width = math.max(waist.Size.X, 1.5) + 0.35
	ctx.part("BeltBand", Vector3.new(width, 0.22, math.max(waist.Size.Z, 0.85) + 0.22), waist.CFrame * CFrame.new(0, y, 0), Palette.Leather, Enum.Material.Leather, waist, true)
	ctx.part("BeltBand", Vector3.new(width * 0.92, 0.12, math.max(waist.Size.Z, 0.8) + 0.28), waist.CFrame * CFrame.new(0, y - 0.16, -0.02), Palette.LeatherMid, Enum.Material.Leather, waist, false)
	if ctx.full then
		ctx.part("BeltBand", Vector3.new(width * 0.55, 0.08, 0.16), waist.CFrame * CFrame.new(0.15, y + 0.02, forward), Palette.LeatherWorn, Enum.Material.Leather, waist, false)
	end
	ctx.part("BeltBuckle", Vector3.new(0.34, 0.28, 0.1), waist.CFrame * CFrame.new(width * 0.28, y, forward - 0.02), Palette.Metal, Enum.Material.Metal, waist, false)
	ctx.part("BeltBuckle", Vector3.new(0.1, 0.12, 0.06), waist.CFrame * CFrame.new(width * 0.28, y, forward - 0.08), Palette.BoneDark, Enum.Material.SmoothPlastic, waist, false)

	ctx.spike("BoneFang", waist.CFrame * CFrame.new(-0.12, y - 0.18, forward - 0.02) * CFrame.Angles(math.rad(170), 0, math.rad(6)), 0.48, 0.12, Palette.Bone, Enum.Material.SmoothPlastic, waist)
	ctx.spike("BoneFang", waist.CFrame * CFrame.new(0.14, y - 0.16, forward - 0.04) * CFrame.Angles(math.rad(168), 0, math.rad(-8)), 0.42, 0.11, Palette.Bone, Enum.Material.SmoothPlastic, waist)
	ctx.part("LeatherTab", Vector3.new(0.22, 0.45, 0.08), waist.CFrame * CFrame.new(-0.48, y - 0.32, forward + 0.04) * CFrame.Angles(math.rad(8), 0, math.rad(6)), Palette.LeatherWorn, Enum.Material.Leather, waist, false)
	ctx.part("LeatherTab", Vector3.new(0.18, 0.36, 0.07), waist.CFrame * CFrame.new(0.52, y - 0.28, forward) * CFrame.Angles(math.rad(6), 0, math.rad(-8)), Palette.Leather, Enum.Material.Leather, waist, false)
	if tiers.hp >= 2 then
		ctx.spike("TierBone", waist.CFrame * CFrame.new(0.34, y - 0.2, forward) * CFrame.Angles(math.rad(160), 0, math.rad(12)), 0.3, 0.08, Palette.BoneDark, Enum.Material.SmoothPlastic, waist)
	end
	if ctx.full then
		for index = -1, 2 do
			ctx.part("Stitch", Vector3.new(0.05, 0.05, 0.04), waist.CFrame * CFrame.new(-0.2 + index * 0.16, y + 0.08, forward - 0.02), Palette.WoodDark, Enum.Material.SmoothPlastic, waist, false)
		end
	end
	return y
end

local function buildSkirt(ctx, waist, beltY)
	local panels = {
		{ -0.4, -0.5, 0.95, 0.48, 0.16, 1, 8, false },
		{ 0.05, -0.56, 0.7, 0.42, 0.14, 1, -4, false },
		{ 0.42, -0.48, 1.05, 0.46, 0.15, 2, 6, false },
		{ -0.92, -0.08, 1.15, 0.4, 0.18, 3, 12, false },
		{ 0.94, 0.02, 1.12, 0.42, 0.16, 4, -10, false },
		{ -0.32, 0.5, 1.2, 0.5, 0.16, 2, 6, false },
		{ 0.08, 0.56, 0.98, 0.55, 0.18, 1, 0, false },
		{ 0.42, 0.48, 1.16, 0.46, 0.15, 3, -8, false },
		{ -0.1, -0.4, 0.55, 0.22, 0.06, 2, 4, true },
		{ 0.55, 0.2, 0.6, 0.2, 0.06, 2, -6, true },
	}
	local colors = { Palette.FurDark, Palette.Leather, Palette.Fur, Palette.FurLight }
	for _, panel in ipairs(panels) do
		if ctx.full or not panel[8] then
			local hang = beltY - 0.2 - panel[3] * 0.45
			local cf = waist.CFrame * CFrame.new(panel[1], hang, panel[2]) * CFrame.Angles(math.rad(panel[7]), 0, math.rad(panel[1] * 4))
			ctx.wedge("SkirtPanel", Vector3.new(panel[4], panel[3], panel[5]), cf, colors[panel[6]], Enum.Material.Fabric, waist, false)
		end
	end
	ctx.spike("SkirtBone", waist.CFrame * CFrame.new(-0.22, beltY - 0.55, -0.48) * CFrame.Angles(math.rad(200), 0, math.rad(8)), 0.28, 0.08, Palette.Bone, Enum.Material.SmoothPlastic, waist)
	ctx.spike("SkirtBone", waist.CFrame * CFrame.new(0.3, beltY - 0.62, 0.2) * CFrame.Angles(math.rad(190), 0, math.rad(-10)), 0.24, 0.07, Palette.BoneDark, Enum.Material.SmoothPlastic, waist)
end

local function buildArm(ctx, upper, lower, hand, side)
	if not upper then
		return
	end
	local shoulderCF = upper.CFrame * CFrame.new(0, upper.Size.Y * 0.32, 0)
	ctx.ball("Deltoid", Vector3.new(1.05, 0.72, 0.95), shoulderCF, Palette.Skin, Enum.Material.SmoothPlastic, upper, false)
	ctx.ball("Bicep", Vector3.new(0.95, 0.7, 0.85), upper.CFrame * CFrame.new(0, 0.02, -0.08), Palette.Skin, Enum.Material.SmoothPlastic, upper, false)
	if ctx.full and lower and lower ~= upper then
		ctx.ball("Forearm", Vector3.new(0.78, 0.62, 0.7), lower.CFrame * CFrame.new(0, 0.05, -0.04), Palette.SkinShadow, Enum.Material.SmoothPlastic, lower, false)
	end

	local host = lower or upper
	local wristCF = host.CFrame * CFrame.new(0, -host.Size.Y * (host == upper and 0.3 or 0.22), 0)
	ctx.cylinder("WristCuff", 0.38, 0.96, wristCF, Palette.Leather, Enum.Material.Leather, host, true)
	ctx.cylinder("WristCuff", 0.14, 1.04, wristCF * CFrame.new(0, 0.18, 0), Palette.FurMid, Enum.Material.Fabric, host, false)
	ctx.part("WristStrap", Vector3.new(1.05, 0.1, 0.16), wristCF * CFrame.new(0, -0.02, 0) * CFrame.Angles(0, math.rad(20), math.rad(18 * side)), Palette.LeatherMid, Enum.Material.Leather, host, false)
	ctx.part("WristStrap", Vector3.new(0.16, 0.1, 1.05), wristCF * CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(70), 0, 0), Palette.LeatherWorn, Enum.Material.Leather, host, false)
	ctx.spike("WristBone", wristCF * CFrame.new(0.32 * side, 0.05, -0.2) * CFrame.Angles(math.rad(-40), 0, math.rad(20 * side)), 0.22, 0.08, Palette.Bone, Enum.Material.SmoothPlastic, host)
	if ctx.full then
		ctx.part("WristStrap", Vector3.new(0.9, 0.08, 0.1), wristCF * CFrame.new(0, 0.12, 0.15) * CFrame.Angles(math.rad(12), math.rad(40), 0), Palette.Leather, Enum.Material.Leather, host, false)
	end

	if hand then
		local mitt = Vector3.new(math.max(hand.Size.X, 0.7), math.max(hand.Size.Y, 0.42), math.max(hand.Size.Z, 0.72))
		ctx.part("HandShape", mitt, hand.CFrame, Palette.Skin, Enum.Material.SmoothPlastic, hand, false)
	end

	-- Pittura bianca sul braccio, a colpi larghi.
	local marks = {
		{ 0.12, 0.08, -0.42, 24, 0.5 },
		{ -0.05, -0.12, -0.4, -18, 0.36 },
	}
	for index, mark in ipairs(marks) do
		if ctx.full or index == 1 then
			local cf = upper.CFrame * CFrame.new(mark[1] * side, mark[2], mark[3]) * CFrame.Angles(0, 0, math.rad(mark[4] * side))
			ctx.part("PaintMark", Vector3.new(0.1, mark[5], 0.06), cf, Palette.Paint, Enum.Material.SmoothPlastic, upper, false)
		end
	end
end

local function outward(cf, torso, side, amount)
	if not torso then
		return cf * CFrame.new(amount * side, 0, 0)
	end
	local right = cf:VectorToObjectSpace(torso.CFrame.RightVector)
	if right.Magnitude < 0.2 then
		return cf * CFrame.new(amount * side, 0, 0)
	end
	return cf * CFrame.new(right.Unit * (amount * side))
end

local function buildLeg(ctx, torso, upper, lower, foot, side, r15)
	local thigh = upper or lower or foot
	if thigh then
		ctx.ball("Thigh", Vector3.new(1.02, 0.82, 0.92), thigh.CFrame * CFrame.new(0, r15 and 0.05 or thigh.Size.Y * 0.15, -0.04), Palette.Skin, Enum.Material.SmoothPlastic, thigh, false)
		local paintHost = thigh
		local slashes = {
			{ 0.1, 0.05, -0.42, 32, 0.62 },
			{ -0.12, -0.15, -0.4, -24, 0.48 },
			{ 0.02, 0.2, -0.38, 8, 0.28 },
		}
		for index, mark in ipairs(slashes) do
			if ctx.full or index <= 2 then
				local cf = paintHost.CFrame * CFrame.new(mark[1] * side, mark[2], mark[3]) * CFrame.Angles(math.rad(10), 0, math.rad(mark[4]))
				ctx.part("PaintMark", Vector3.new(0.14, mark[5], 0.06), cf, Palette.Paint, Enum.Material.SmoothPlastic, paintHost, false)
			end
		end
	end

	local bootHost = foot or lower or upper
	if not bootHost then
		return
	end
	local bootCF = bootHost.CFrame
	if not r15 or bootHost.Name == "Right Leg" or bootHost.Name == "Left Leg" then
		bootCF = bootHost.CFrame * CFrame.new(0, -bootHost.Size.Y * 0.32, -0.05)
	end
	bootCF = outward(bootCF, torso, side, 0.12)
	ctx.part("BootSole", Vector3.new(1.02, 0.24, 1.55), bootCF * CFrame.new(0, -0.22, -0.1), Palette.WoodDark, Enum.Material.Slate, bootHost, true)
	ctx.part("BootBody", Vector3.new(0.96, 0.55, 1.32), bootCF * CFrame.new(0, 0.02, -0.04), Palette.Leather, Enum.Material.Leather, bootHost, true)
	ctx.ball("BootToe", Vector3.new(0.84, 0.38, 0.62), bootCF * CFrame.new(0, -0.02, -0.55), Palette.LeatherMid, Enum.Material.Leather, bootHost, false)
	ctx.part("BootPatch", Vector3.new(0.4, 0.16, 0.32), bootCF * CFrame.new(0.16 * side, 0.08, -0.18), Palette.LeatherWorn, Enum.Material.Leather, bootHost, false)
	ctx.ball("BootCuff", Vector3.new(1.08, 0.3, 1.05), bootCF * CFrame.new(0, 0.32, 0.02), Palette.FurLight, Enum.Material.Fabric, bootHost, false)
	ctx.wedge("BootCuff", Vector3.new(0.35, 0.28, 0.45), bootCF * CFrame.new(-0.35 * side, 0.42, 0.1) * CFrame.Angles(math.rad(-20), 0, math.rad(15 * side)), Palette.Fur, Enum.Material.Fabric, bootHost, false)

	local strapHost = lower or bootHost
	local strapCF = strapHost.CFrame
	if strapHost == bootHost and (bootHost.Name == "Right Leg" or bootHost.Name == "Left Leg") then
		strapCF = bootHost.CFrame * CFrame.new(0, -bootHost.Size.Y * 0.12, 0)
	elseif r15 and lower then
		strapCF = lower.CFrame * CFrame.new(0, -lower.Size.Y * 0.2, 0)
	end
	ctx.part("BootStrap", Vector3.new(1.15, 0.1, 0.16), strapCF * CFrame.Angles(0, 0, math.rad(28 * side)), Palette.LeatherMid, Enum.Material.Leather, strapHost, false)
	ctx.part("BootStrap", Vector3.new(1.1, 0.1, 0.14), strapCF * CFrame.new(0, -0.22, 0) * CFrame.Angles(0, 0, math.rad(-24 * side)), Palette.Leather, Enum.Material.Leather, strapHost, false)
	ctx.part("BootBuckle", Vector3.new(0.18, 0.14, 0.08), strapCF * CFrame.new(0.32 * side, -0.05, -0.28), Palette.Metal, Enum.Material.Metal, strapHost, false)
	ctx.spike("BootBone", strapCF * CFrame.new(0.4 * side, 0.12, -0.1) * CFrame.Angles(0, 0, math.rad(40 * side)), 0.2, 0.08, Palette.Bone, Enum.Material.SmoothPlastic, strapHost)
end

local function buildPaintChest(ctx, torso, halfZ)
	local marks = {
		{ -0.2, 0.22, 0.4, -20 },
		{ 0.28, 0.05, 0.32, 16 },
		{ -0.05, -0.15, 0.28, 8 },
		{ 0.4, 0.28, 0.22, -12 },
	}
	for index, mark in ipairs(marks) do
		if ctx.full or index <= 3 then
			local cf = torso.CFrame * CFrame.new(mark[1], mark[2], -(halfZ + 0.2)) * CFrame.Angles(0, 0, math.rad(mark[4]))
			ctx.part("PaintMark", Vector3.new(0.1, mark[3], 0.05), cf, Palette.Paint, Enum.Material.SmoothPlastic, torso, false)
		end
	end
end

local function clubLayout(limbs)
	local hand = limbs.rightHand
	local foot = limbs.rightFoot or limbs.rightLowerLeg or limbs.lowerTorso
	local head = limbs.head
	local ground = foot.Position.Y - foot.Size.Y * 0.5
	local top = head.Position.Y + head.Size.Y * 0.5
	local stature = math.max(top - ground, 4.4)
	local grip = hand.Position.Y - ground
	local visualTop = top + 0.05
	local visualBottom = ground + Palette.ClubBottomClearance
	local visual = math.max(visualTop - visualBottom, 4.4)
	local shaft = math.clamp(visual - Palette.ClubStoneOverhang, Palette.ClubMinLength, Palette.ClubMaxLength)
	local below = math.clamp(grip - visualBottom, shaft * 0.3, shaft * 0.52)
	local shift = shaft * 0.5 - below
	return shaft, shift
end

local function buildClub(ctx, limbs, tiers)
	local hand = limbs.rightHand
	local length, shift = clubLayout(limbs)
	local stoneScale = 1 + tiers.dmg * 0.035
	local grip = hand.CFrame
	if not limbs.r15 then
		grip = hand.CFrame * CFrame.new(0, -hand.Size.Y * 0.4, 0)
	end
	-- +Y della mano è lo stesso asse usato dal vecchio WeaponMotor, verso l'alto del braccio.
	local axis = grip * CFrame.new(0.06, shift, -0.34) * CFrame.Angles(math.rad(8), math.rad(-7), math.rad(-6))
	local shaft = Instance.new("Part")
	shaft.Name = "Club"
	shaft.Size = Vector3.new(length, 0.4, 0.44)
	shaft.CFrame = axis * CFrame.Angles(0, 0, math.rad(90))
	shaft.Color = Palette.Wood
	shaft.Material = Enum.Material.Wood
	shaft.Shape = Enum.PartType.Cylinder
	shaft.Anchored = false
	shaft.CanCollide = false
	shaft.CanQuery = false
	shaft.CanTouch = false
	shaft.Massless = true
	shaft.CastShadow = true
	shaft.TopSurface = Enum.SurfaceType.Smooth
	shaft.BottomSurface = Enum.SurfaceType.Smooth
	shaft.Parent = ctx.folder
	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponMotor"
	motor.Part0 = hand
	motor.Part1 = shaft
	motor.C0 = hand.CFrame:ToObjectSpace(shaft.CFrame)
	motor.C1 = CFrame.new()
	motor:SetAttribute("Animate", true)
	motor.Parent = shaft
	ctx.count += 1

	local function onShaft(name, size, localCF, color, material, shape, shadow)
		local piece = ctx.part(name, size, axis * localCF, color, material, shaft, shadow)
		if shape then
			piece.Shape = shape
		end
		return piece
	end

	if ctx.full then
		for index = 1, 4 do
			local y = -length * 0.3 + index * length * 0.14
			onShaft("ClubBark", Vector3.new(0.18, 0.22, 0.16), CFrame.new(0.16, y, 0.08) * CFrame.Angles(0.2, index, 0.4), Palette.WoodBark, Enum.Material.Wood, nil, false)
		end
		onShaft("ClubCarve", Vector3.new(0.08, 0.35, 0.1), CFrame.new(0.12, -length * 0.05, 0.16), Palette.WoodDark, Enum.Material.Wood, nil, false)
		onShaft("ClubCarve", Vector3.new(0.1, 0.22, 0.08), CFrame.new(-0.14, length * 0.08, 0.12) * CFrame.Angles(0, 0, math.rad(20)), Palette.WoodDark, Enum.Material.Wood, nil, false)
	end

	local binds = { 0.22, -0.02, -0.28 }
	for _, fraction in ipairs(binds) do
		ctx.cylinder("ClubLeather", 0.14, 0.56, axis * CFrame.new(0, length * fraction, 0), Palette.Leather, Enum.Material.Leather, shaft, false)
	end
	ctx.spike("ClubTooth", axis * CFrame.new(0.2, length * 0.12, 0.12) * CFrame.Angles(0, 0, math.rad(-70)), 0.22, 0.07, Palette.Bone, Enum.Material.SmoothPlastic, shaft)
	ctx.spike("ClubTooth", axis * CFrame.new(-0.18, -length * 0.16, 0.14) * CFrame.Angles(0, 0, math.rad(80)), 0.18, 0.06, Palette.Bone, Enum.Material.SmoothPlastic, shaft)
	if ctx.full then
		ctx.spike("ClubTooth", axis * CFrame.new(0.05, -length * 0.3, 0.2) * CFrame.Angles(math.rad(-30), 0, 0), 0.16, 0.06, Palette.BoneDark, Enum.Material.SmoothPlastic, shaft)
	end

	local redSpots = { length * 0.36, -length * 0.22, -length * 0.4 }
	for index, y in ipairs(redSpots) do
		ctx.cylinder("ClubWrapRed", 0.16, 0.62, axis * CFrame.new(0, y, 0), index == 1 and Palette.ClothRed or Palette.ClothRedDark, Enum.Material.Fabric, shaft, false)
	end
	ctx.part("ClubWrapRed", Vector3.new(0.08, 0.55, 0.16), axis * CFrame.new(0.05, length * 0.3, -0.28) * CFrame.Angles(math.rad(18), 0, math.rad(8)), Palette.ClothRed, Enum.Material.Fabric, shaft, false)
	ctx.part("ClubWrapRed", Vector3.new(0.07, 0.42, 0.12), axis * CFrame.new(-0.16, -length * 0.26, -0.22) * CFrame.Angles(math.rad(12), 0, math.rad(-14)), Palette.ClothRedDark, Enum.Material.Fabric, shaft, false)

	local top = length * 0.5 - 0.05
	onShaft("ClubStone", Vector3.new(1.15, 0.95, 1.05) * stoneScale, CFrame.new(0.04, top, 0.02) * CFrame.Angles(0.2, 0.4, 0.25), Palette.Stone, Enum.Material.Slate, nil, true)
	onShaft("ClubStone", Vector3.new(0.72, 0.62, 0.7) * stoneScale, CFrame.new(-0.28, top + 0.18, 0.12) * CFrame.Angles(0.5, 0.2, 0.8), Palette.StoneDark, Enum.Material.Slate, nil, true)
	onShaft("ClubStone", Vector3.new(0.55, 0.5, 0.62) * stoneScale, CFrame.new(0.26, top + 0.12, -0.22) * CFrame.Angles(0.3, 0.8, 0.2), Palette.StoneLight, Enum.Material.Rock, nil, false)
	if tiers.dmg >= 2 or ctx.full then
		onShaft("ClubStone", Vector3.new(0.4, 0.36, 0.38) * stoneScale, CFrame.new(0.1, top + 0.38, 0.16) * CFrame.Angles(0.4, 0.3, 0.6), Palette.Stone, Enum.Material.Rock, nil, false)
	end

	local crystal = {
		{ CFrame.new(0.55, top + 0.1, 0.05) * CFrame.Angles(0, 0, math.rad(-70)), 0.72 },
		{ CFrame.new(-0.48, top + 0.05, 0.1) * CFrame.Angles(0, 0, math.rad(64)), 0.64 },
		{ CFrame.new(0.08, top + 0.48, -0.05) * CFrame.Angles(math.rad(-18), 0, 0), 0.58 },
		{ CFrame.new(0.15, top + 0.05, -0.5) * CFrame.Angles(math.rad(-75), 0, 0), 0.6 },
		{ CFrame.new(-0.1, top + 0.08, 0.48) * CFrame.Angles(math.rad(70), 0.2, 0), 0.5 },
		{ CFrame.new(0.32, top + 0.28, -0.28) * CFrame.Angles(math.rad(-30), 0, math.rad(-40)), 0.46 },
	}
	for index, item in ipairs(crystal) do
		if ctx.full or index <= 5 then
			ctx.spike("ClubSpike", axis * item[1], item[2] * stoneScale, 0.16, Palette.Bone, Enum.Material.SmoothPlastic, shaft)
		end
	end
	if tiers.dmg >= 3 then
		ctx.spike("ClubSpike", axis * CFrame.new(-0.35, top + 0.3, -0.2) * CFrame.Angles(0, 0, math.rad(40)), 0.4, 0.12, Palette.BoneDark, Enum.Material.SmoothPlastic, shaft)
	end

	ctx.spike("ClubPommel", axis * CFrame.new(0, -length * 0.5, 0) * CFrame.Angles(math.rad(180), 0, 0), 0.38, 0.28, Palette.StoneDark, Enum.Material.Slate, shaft)
	onShaft("ClubPommel", Vector3.new(0.34, 0.22, 0.32), CFrame.new(0, -length * 0.5 + 0.12, 0), Palette.WoodDark, Enum.Material.Wood, nil, false)

	if tiers.speed >= 1 then
		local high = Instance.new("Attachment")
		high.Name = "KurkitoTrailA"
		-- Il fusto è un cilindro: la lunghezza sta sull'asse X locale.
		high.Position = Vector3.new(length * 0.32, 0, 0)
		high.Parent = shaft
		local low = Instance.new("Attachment")
		low.Name = "KurkitoTrailB"
		low.Position = Vector3.new(-length * 0.32, 0, 0)
		low.Parent = shaft
		local ribbon = Instance.new("Trail")
		ribbon.Attachment0 = high
		ribbon.Attachment1 = low
		ribbon.Lifetime = 0.16 + tiers.speed * 0.04
		ribbon.MinLength = 0.05
		ribbon.LightEmission = 0.2
		ribbon.Color = ColorSequence.new(Palette.ClothRed)
		ribbon.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		ribbon.Parent = ctx.folder
	end
end

function WarriorVisualBuilder.Apply(character, heroState)
	if not character then
		return false
	end
	local generation = (character:GetAttribute("KurkitoVisualGen") or 0) + 1
	character:SetAttribute("KurkitoVisualGen", generation)
	local previous = character:FindFirstChild(FOLDER_NAME)
	if previous then
		previous:Destroy()
	end
	stripCosmetics(character)
	paintBody(character, Palette.Skin)
	guardCosmetics(character)

	local limbs = findLimbs(character)
	if not limbs then
		character:SetAttribute("KurkitoWarriorVisual", nil)
		return false
	end

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = character
	local full = character:GetAttribute("KurkitoVisualQuality") ~= "low"
	local ctx = makeCtx(folder, full)
	local tiers = tiersOf(heroState)

	buildHead(ctx, limbs)
	buildHair(ctx, limbs.head)
	buildTorsoVolume(ctx, limbs.upperTorso)
	local halfX, halfY, halfZ = buildFur(ctx, limbs.upperTorso)
	buildSkull(ctx, limbs.upperTorso, halfX, halfY)
	buildNecklace(ctx, limbs.upperTorso, halfY, halfZ)
	buildStrap(ctx, limbs.upperTorso, halfX, halfY, halfZ)
	buildPaintChest(ctx, limbs.upperTorso, halfZ)
	local beltY = buildBelt(ctx, limbs, tiers)
	buildSkirt(ctx, limbs.lowerTorso, beltY)
	buildArm(ctx, limbs.rightUpper, limbs.rightLower, limbs.rightHand, 1)
	if limbs.leftUpper or limbs.leftLower then
		buildArm(ctx, limbs.leftUpper or limbs.leftLower, limbs.leftLower or limbs.leftUpper, limbs.leftHand, -1)
	end
	buildLeg(ctx, limbs.upperTorso, limbs.rightUpperLeg, limbs.rightLowerLeg, limbs.rightFoot, 1, limbs.r15)
	buildLeg(ctx, limbs.upperTorso, limbs.leftUpperLeg, limbs.leftLowerLeg, limbs.leftFoot, -1, limbs.r15)
	buildClub(ctx, limbs, tiers)

	if tiers.hp >= 4 and ctx.full then
		local extra = limbs.upperTorso.CFrame * CFrame.new(halfX + 0.2, halfY * 0.55, 0.2) * CFrame.Angles(0, 0, math.rad(40))
		ctx.spike("TierBone", extra, 0.36, 0.1, Palette.Bone, Enum.Material.SmoothPlastic, limbs.upperTorso)
	end

	folder:SetAttribute("PartCount", ctx.count)
	folder:SetAttribute("VisualVersion", VISUAL_VERSION)
	folder:SetAttribute("HpTier", tiers.hp)
	folder:SetAttribute("DmgTier", tiers.dmg)
	folder:SetAttribute("SpeedTier", tiers.speed)
	if character:GetAttribute("KurkitoVisualGen") ~= generation then
		folder:Destroy()
		return false
	end
	character:SetAttribute("KurkitoWarriorVisual", VISUAL_VERSION)
	character:SetAttribute("KurkitoVisualParts", ctx.count)
	if ctx.count > 280 then
		warn("[Kurkito] Warrior visual part count is high: " .. tostring(ctx.count))
	end
	return true
end

return WarriorVisualBuilder
