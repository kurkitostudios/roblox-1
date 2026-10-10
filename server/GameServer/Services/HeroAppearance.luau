-- Aspetto fantasy procedurale. I livelli grafici seguono Rules.VisualTier
-- e non cambiano le statistiche. I pet equipaggiati seguono l'eroe.

local shared = require(script.Parent.SharedLoader)
local Rules = shared("Rules")
local HeroConfig = shared("HeroConfig")
local EnemyConfig = shared("EnemyConfig")
local CreatureKit = require(script.Parent.CreatureKit)

local HeroAppearance = {}

local function limb(character, names)
	for _, name in ipairs(names) do
		local found = character:FindFirstChild(name, true)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	return nil
end

local function adorn(folder, name, size, color, material, cf, target, shape, transparency)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.Color = color
	piece.Material = material or Enum.Material.SmoothPlastic
	piece.CFrame = cf
	piece.Shape = shape or Enum.PartType.Block
	piece.Transparency = transparency or 0
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.Massless = true
	piece.CastShadow = false
	piece.Anchored = false
	piece.Parent = folder
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = target
	weld.Part1 = piece
	weld.Parent = piece
	return piece
end

local function weaponMotor(folder, name, size, color, material, cf, target, shape)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.Color = color
	piece.Material = material or Enum.Material.Metal
	piece.CFrame = cf
	piece.Shape = shape or Enum.PartType.Block
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.Massless = true
	piece.CastShadow = false
	piece.Anchored = false
	piece.Parent = folder
	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponMotor"
	motor.Part0 = target
	motor.Part1 = piece
	motor.C0 = target.CFrame:ToObjectSpace(cf)
	motor.C1 = CFrame.new()
	motor:SetAttribute("Animate", true)
	motor.Parent = piece
	return piece
end

local function mesh(part, meshType, scale)
	local special = Instance.new("SpecialMesh")
	special.MeshType = meshType
	special.Scale = scale or Vector3.new(1, 1, 1)
	special.Parent = part
end

local function spark(part, color, rate)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ManaSpark"
	emitter.Rate = math.clamp(rate, 0, 8)
	emitter.Lifetime = NumberRange.new(0.35, 0.7)
	emitter.Speed = NumberRange.new(0.2, 0.9)
	emitter.LightEmission = 0.55
	emitter.Size = NumberSequence.new(0.16)
	emitter.Color = ColorSequence.new(color)
	emitter:SetAttribute("KurkitoBaseRate", emitter.Rate)
	emitter.Parent = part
	return emitter
end

local function trail(folder, part, color, lifetime)
	local a0 = Instance.new("Attachment")
	a0.Name = "KurkitoTrailA"
	a0.Position = Vector3.new(0, part.Size.Y * 0.35, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Name = "KurkitoTrailB"
	a1.Position = Vector3.new(0, -part.Size.Y * 0.35, 0)
	a1.Parent = part
	local ribbon = Instance.new("Trail")
	ribbon.Attachment0 = a0
	ribbon.Attachment1 = a1
	ribbon.Lifetime = lifetime or 0.18
	ribbon.MinLength = 0.05
	ribbon.LightEmission = 0.4
	ribbon.Color = ColorSequence.new(color)
	ribbon.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	ribbon.Parent = folder
	return ribbon
end

local function clearPets(character)
	local existing = character:FindFirstChild("KurkitoPets")
	if existing then
		existing:Destroy()
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		for _, child in ipairs(root:GetChildren()) do
			if string.sub(child.Name, 1, 7) == "PetSlot" then
				child:Destroy()
			end
		end
	end
end

local function attachPets(character, profile)
	clearPets(character)
	if not profile or type(profile.pets) ~= "table" or type(profile.equippedPets) ~= "table" then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "KurkitoPets"
	folder.Parent = character
	local shown = 0
	for slot = 1, 3 do
		local uid = profile.equippedPets[slot]
		if type(uid) == "string" and uid ~= "" then
			local record = nil
			for _, pet in ipairs(profile.pets) do
				if pet.uid == uid then
					record = pet
				end
			end
			local def = record and EnemyConfig.Get(record.petId)
			if def then
				shown += 1
				local model = CreatureKit.BuildPet(def, record.evolution or "Normal")
				model.Parent = folder
				local petRoot = model.PrimaryPart
				local anchor = Instance.new("Attachment")
				anchor.Name = "PetSlot" .. tostring(slot)
				anchor.Position = Vector3.new(-2.4 + (shown - 1) * 1.7, 1.4, 2.8)
				anchor.Parent = root
				local follower = Instance.new("Attachment")
				follower.Parent = petRoot
				local align = Instance.new("AlignPosition")
				align.Mode = Enum.PositionAlignmentMode.TwoAttachment
				align.Attachment0 = follower
				align.Attachment1 = anchor
				align.Responsiveness = 16
				align.MaxForce = 200000
				align.Parent = petRoot
				local orient = Instance.new("AlignOrientation")
				orient.Mode = Enum.OrientationAlignmentMode.TwoAttachment
				orient.Attachment0 = follower
				orient.Attachment1 = anchor
				orient.Responsiveness = 12
				orient.MaxTorque = 200000
				orient.Parent = petRoot
				pcall(function()
					petRoot:SetNetworkOwner(nil)
				end)
			end
		end
	end
end

function HeroAppearance.Apply(character, heroId, heroState, profile)
	if not character or not heroState or not heroState.stats then
		return
	end
	local classDef = HeroConfig.Classes[heroId]
	if not classDef then
		return
	end
	local existing = character:FindFirstChild("KurkitoVisuals")
	if existing then
		existing:Destroy()
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant.Name == "KurkitoTrailA" or descendant.Name == "KurkitoTrailB" or descendant.Name == "ManaSpark" then
			descendant:Destroy()
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "KurkitoVisuals"
	folder.Parent = character

	local hpTier = Rules.VisualTier(heroState.stats.HP or 1)
	local dmgTier = Rules.VisualTier(heroState.stats.DMG or 1)
	local head = limb(character, { "Head" })
	local torso = limb(character, { "UpperTorso", "Torso" })
	local hand = limb(character, { "RightHand", "Right Arm" })
	local offHand = limb(character, { "LeftHand", "Left Arm" })
	local footL = limb(character, { "LeftFoot", "Left Leg" })
	local footR = limb(character, { "RightFoot", "Right Leg" })
	if not head or not torso or not hand then
		attachPets(character, profile)
		return
	end

	local hide = Color3.fromRGB(112, 72, 44)
	local fur = Color3.fromRGB(62, 42, 30)
	local bone = Color3.fromRGB(214, 198, 168)
	local wood = Color3.fromRGB(86, 56, 34)
	local cloth = classDef.color:Lerp(Color3.fromRGB(240, 220, 190), 0.12)

	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if heroId == "Warrior" and bodyColors then
		local skin = Color3.fromRGB(198, 146, 108)
		bodyColors.HeadColor3 = skin
		bodyColors.LeftArmColor3 = skin
		bodyColors.RightArmColor3 = skin
		bodyColors.LeftLegColor3 = Color3.fromRGB(120, 78, 52)
		bodyColors.RightLegColor3 = Color3.fromRGB(120, 78, 52)
		bodyColors.TorsoColor3 = Color3.fromRGB(92, 58, 38)
	end

	if heroId == "Warrior" then
		local speedTier = Rules.VisualTier(heroState.stats.Speed or 1)
		adorn(folder, "HideTunic", Vector3.new(2.05, 1.55, 1.05), hide, Enum.Material.Fabric, torso.CFrame * CFrame.new(0, 0.05, -0.15), torso)
		adorn(folder, "FurMantle", Vector3.new(2.2, 0.55, 1.15), fur, Enum.Material.Fabric, torso.CFrame * CFrame.new(0, 0.55, -0.2), torso)
		adorn(folder, "BoneShoulderL", Vector3.new(0.7, 0.38, 0.7), bone, Enum.Material.SmoothPlastic, torso.CFrame * CFrame.new(-1.05, 0.65, 0), torso, Enum.PartType.Ball)
		adorn(folder, "BoneShoulderR", Vector3.new(0.75, 0.4, 0.75), bone, Enum.Material.SmoothPlastic, torso.CFrame * CFrame.new(1.05, 0.62, 0), torso, Enum.PartType.Ball)
		if hpTier >= 2 then
			adorn(folder, "ExtraBoneL", Vector3.new(0.22, 0.7, 0.22), bone, Enum.Material.SmoothPlastic, torso.CFrame * CFrame.new(-1.15, 1.05, 0) * CFrame.Angles(0, 0, math.rad(20)), torso)
			adorn(folder, "ExtraBoneR", Vector3.new(0.22, 0.7, 0.22), bone, Enum.Material.SmoothPlastic, torso.CFrame * CFrame.new(1.15, 1.05, 0) * CFrame.Angles(0, 0, math.rad(-20)), torso)
		end
		adorn(folder, "HideSkirt", Vector3.new(1.7, 0.9, 1), hide:Lerp(fur, 0.35), Enum.Material.Fabric, torso.CFrame * CFrame.new(0, -1.05, -0.05), torso)
		if hpTier >= 3 then
			local backFur = adorn(folder, "BackFur", Vector3.new(1.5, 1.8, 0.16), fur, Enum.Material.Fabric, torso.CFrame * CFrame.new(0, -0.35, 0.65), torso)
			backFur.Transparency = 0.05
		end
		for index = 1, 4 do
			adorn(folder, "Tooth" .. index, Vector3.new(0.12, 0.2, 0.1), bone, Enum.Material.SmoothPlastic, torso.CFrame * CFrame.new(-0.45 + index * 0.18, 0.85, -0.6), torso)
		end
		for index = 1, 4 do
			adorn(folder, "Hair" .. index, Vector3.new(0.28, 0.55 + (index % 2) * 0.2, 0.32), Color3.fromRGB(28, 18, 14), Enum.Material.Fabric, head.CFrame * CFrame.new(-0.35 + index * 0.18, 0.45, 0.05) * CFrame.Angles(0, 0, math.rad((index - 2.5) * 8)), head)
		end
		adorn(folder, "FacePaint", Vector3.new(0.16, 0.55, 0.08), Color3.fromRGB(120, 42, 32), Enum.Material.SmoothPlastic, head.CFrame * CFrame.new(0, 0.02, -0.58), head)
		if hpTier >= 4 then
			adorn(folder, "BoneCirclet", Vector3.new(1.15, 0.16, 1.15), bone, Enum.Material.SmoothPlastic, head.CFrame * CFrame.new(0, 0.35, 0), head)
		end
		adorn(folder, "WrapR", Vector3.new(0.48, 0.4, 0.48), hide, Enum.Material.Fabric, hand.CFrame, hand, Enum.PartType.Ball)
		if offHand then
			adorn(folder, "WrapL", Vector3.new(0.46, 0.38, 0.46), hide, Enum.Material.Fabric, offHand.CFrame, offHand, Enum.PartType.Ball)
		end
		if footL then
			adorn(folder, "FootWrapL", Vector3.new(0.7, 0.32, 1), hide, Enum.Material.Fabric, footL.CFrame * CFrame.new(0, -0.12, -0.05), footL)
		end
		if footR then
			adorn(folder, "FootWrapR", Vector3.new(0.7, 0.32, 1), hide, Enum.Material.Fabric, footR.CFrame * CFrame.new(0, -0.12, -0.05), footR)
		end
		local clubLength = 3.3 + dmgTier * 0.28
		local club = weaponMotor(folder, "Club", Vector3.new(0.42, clubLength, 0.42), wood, Enum.Material.Wood, hand.CFrame * CFrame.new(0, -0.55 - clubLength * 0.28, -0.25) * CFrame.Angles(math.rad(16), 0, math.rad(8)), hand)
		local headSize = 1.05 + dmgTier * 0.08
		local clubHead = adorn(folder, "ClubHead", Vector3.new(headSize, 0.85, headSize), Color3.fromRGB(96, 90, 82), Enum.Material.Slate, club.CFrame * CFrame.new(0, -clubLength * 0.46, 0), club, Enum.PartType.Ball)
		adorn(folder, "BindingA", Vector3.new(0.5, 0.16, 0.5), hide, Enum.Material.Fabric, club.CFrame * CFrame.new(0, clubLength * 0.18, 0), club)
		adorn(folder, "BindingB", Vector3.new(0.48, 0.14, 0.48), Color3.fromRGB(70, 42, 28), Enum.Material.Fabric, club.CFrame * CFrame.new(0, -clubLength * 0.22, 0), club)
		if dmgTier >= 2 then
			adorn(folder, "ClubSpike", Vector3.new(0.16, 0.45, 0.16), bone, Enum.Material.SmoothPlastic, clubHead.CFrame * CFrame.new(0.2, -0.2, -0.35), clubHead)
		end
		if dmgTier >= 3 then
			adorn(folder, "ClubTooth", Vector3.new(0.14, 0.4, 0.14), bone, Enum.Material.SmoothPlastic, clubHead.CFrame * CFrame.new(-0.25, 0.1, -0.3), clubHead)
		end
		if speedTier >= 1 then
			trail(folder, clubHead, Color3.fromRGB(210, 180, 130), 0.16 + speedTier * 0.03)
		end
		if speedTier >= 3 then
			spark(torso, Color3.fromRGB(255, 170, 90), 2)
		end
	elseif heroId == "Mage" then
		local manaTier = Rules.VisualTier(heroState.stats.Mana or 1)
		local robe = adorn(folder, "Robe", Vector3.new(2.05, 2.3, 1.15), cloth, Enum.Material.Fabric, torso.CFrame * CFrame.new(0, -0.55, 0), torso, nil, 0.05)
		if hpTier >= 2 then
			adorn(folder, "RobeTrim", Vector3.new(2.1, 0.16, 1.2), Color3.fromRGB(230, 200, 120), Enum.Material.Fabric, robe.CFrame * CFrame.new(0, -1.05, 0), robe)
			adorn(folder, "Mantle", Vector3.new(2.3, 0.35, 1.2), cloth:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Fabric, torso.CFrame * CFrame.new(0, 0.65, 0), torso)
		end
		if hpTier >= 4 then
			adorn(folder, "RuneCloth", Vector3.new(0.35, 0.35, 0.08), Color3.fromRGB(140, 190, 255), Enum.Material.Neon, robe.CFrame * CFrame.new(0, 0.2, -0.6), robe)
		end
		local hatHeight = 1.15 + dmgTier * 0.22
		local hat = adorn(folder, "Hat", Vector3.new(1.15, hatHeight, 1.15), Color3.fromRGB(36, 42, 92):Lerp(Color3.fromRGB(120, 170, 255), math.clamp(dmgTier / 8, 0, 0.55)), dmgTier >= 4 and Enum.Material.Neon or Enum.Material.Fabric, head.CFrame * CFrame.new(0, 0.55 + hatHeight * 0.35, 0), head)
		mesh(hat, Enum.MeshType.Head, Vector3.new(0.85, 1.35, 0.85))
		adorn(folder, "Brim", Vector3.new(0.14, 2.15 + dmgTier * 0.08, 2.15 + dmgTier * 0.08), Color3.fromRGB(24, 28, 58), Enum.Material.Fabric, head.CFrame * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, math.rad(90)), head, Enum.PartType.Cylinder)
		if dmgTier >= 2 then
			adorn(folder, "HatGem", Vector3.new(0.28, 0.28, 0.28), Color3.fromRGB(120, 190, 255), Enum.Material.Neon, hat.CFrame * CFrame.new(0, hatHeight * 0.35, -0.35), hat, Enum.PartType.Ball)
		end
		local staff = weaponMotor(folder, "Staff", Vector3.new(0.22, 3.3 + dmgTier * 0.15, 0.22), Color3.fromRGB(92, 64, 40), Enum.Material.Wood, hand.CFrame * CFrame.new(0, -0.4, -0.45), hand, Enum.PartType.Cylinder)
		local focus = adorn(folder, "Focus", Vector3.new(0.55 + dmgTier * 0.04, 0.55 + dmgTier * 0.04, 0.55 + dmgTier * 0.04), Color3.fromRGB(255, 140, 60):Lerp(Color3.fromRGB(140, 190, 255), math.clamp(dmgTier / 6, 0, 0.7)), Enum.Material.Neon, staff.CFrame * CFrame.new(0, 1.7, 0), staff, Enum.PartType.Ball)
		if dmgTier >= 3 then
			adorn(folder, "FocusRing", Vector3.new(0.12, 0.9, 0.9), Color3.fromRGB(230, 200, 120), Enum.Material.Metal, focus.CFrame * CFrame.Angles(0, 0, math.rad(90)), focus, Enum.PartType.Cylinder)
		end
		if manaTier >= 1 then
			spark(focus, Color3.fromRGB(130, 180, 255), 2 + manaTier)
		end
		if manaTier >= 2 then
			adorn(folder, "RuneA", Vector3.new(0.28, 0.28, 0.08), Color3.fromRGB(150, 190, 255), Enum.Material.Neon, robe.CFrame * CFrame.new(-0.45, 0.3, -0.58), robe)
			adorn(folder, "RuneB", Vector3.new(0.28, 0.28, 0.08), Color3.fromRGB(150, 190, 255), Enum.Material.Neon, robe.CFrame * CFrame.new(0.45, -0.1, -0.58), robe)
		end
		if manaTier >= 4 then
			spark(torso, Color3.fromRGB(160, 140, 255), 2)
		end
	elseif heroId == "Archer" then
		local attackTier = Rules.VisualTier(heroState.stats.AttackSpeed or 1)
		local bowTier = math.max(dmgTier, attackTier)
		adorn(folder, "Jerkin", Vector3.new(1.85, 1.45, 0.4), cloth, Enum.Material.Fabric, torso.CFrame * CFrame.new(0, 0.05, -0.5), torso)
		if hpTier >= 1 then
			adorn(folder, "ShoulderL", Vector3.new(0.55, 0.28, 0.55), Color3.fromRGB(110, 78, 48), Enum.Material.Wood, torso.CFrame * CFrame.new(-0.95, 0.65, 0), torso)
		end
		if hpTier >= 2 then
			adorn(folder, "Hood", Vector3.new(1.25, 0.7, 1.25), cloth:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Fabric, head.CFrame * CFrame.new(0, 0.25, 0.05), head, Enum.PartType.Ball)
		end
		if hpTier >= 3 then
			adorn(folder, "Cloak", Vector3.new(1.4, 1.8, 0.1), classDef.color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Fabric, torso.CFrame * CFrame.new(0, -0.35, 0.65), torso)
		end
		adorn(folder, "Glove", Vector3.new(0.4, 0.28, 0.4), Color3.fromRGB(70, 52, 36), Enum.Material.Fabric, hand.CFrame, hand, Enum.PartType.Ball)
		if footL then
			adorn(folder, "BootL", Vector3.new(0.65, 0.35, 1), Color3.fromRGB(78, 54, 36), Enum.Material.Wood, footL.CFrame * CFrame.new(0, -0.15, -0.05), footL)
		end
		if footR then
			adorn(folder, "BootR", Vector3.new(0.65, 0.35, 1), Color3.fromRGB(78, 54, 36), Enum.Material.Wood, footR.CFrame * CFrame.new(0, -0.15, -0.05), footR)
		end
		local bowColor = Color3.fromRGB(120, 78, 42):Lerp(Color3.fromRGB(210, 180, 90), math.clamp(bowTier / 7, 0, 0.7))
		local bow = weaponMotor(folder, "Bow", Vector3.new(0.18, 2.5 + bowTier * 0.18, 0.18), bowColor, bowTier >= 4 and Enum.Material.Neon or Enum.Material.Wood, hand.CFrame * CFrame.new(0, -0.2, -0.45), hand)
		adorn(folder, "LimbTop", Vector3.new(0.14, 0.9, 0.14), bowColor, Enum.Material.Wood, bow.CFrame * CFrame.new(0.15, 0.85, 0.2) * CFrame.Angles(0, 0, math.rad(-18)), bow)
		adorn(folder, "LimbBot", Vector3.new(0.14, 0.9, 0.14), bowColor, Enum.Material.Wood, bow.CFrame * CFrame.new(0.15, -0.85, 0.2) * CFrame.Angles(0, 0, math.rad(18)), bow)
		adorn(folder, "BowString", Vector3.new(0.05, 2.15 + bowTier * 0.12, 0.05), Color3.fromRGB(236, 232, 220), Enum.Material.Fabric, bow.CFrame * CFrame.new(0.28, 0, 0.15), bow)
		if bowTier >= 2 then
			adorn(folder, "BowGem", Vector3.new(0.26, 0.26, 0.26), Color3.fromRGB(80, 220, 140), Enum.Material.Neon, bow.CFrame, bow, Enum.PartType.Ball)
		end
		local quiver = adorn(folder, "Quiver", Vector3.new(0.45, 1.35 + hpTier * 0.05, 0.45), Color3.fromRGB(92, 64, 40), Enum.Material.Wood, torso.CFrame * CFrame.new(0.55, 0.15, 0.6), torso, Enum.PartType.Cylinder)
		local arrows = 2 + math.clamp(attackTier, 0, 3)
		for index = 1, arrows do
			adorn(folder, "Arrow" .. index, Vector3.new(0.06, 0.7, 0.06), Color3.fromRGB(230, 220, 190), Enum.Material.Wood, quiver.CFrame * CFrame.new((index - 2) * 0.08, 0.7, 0), quiver)
		end
		if attackTier >= 2 then
			spark(quiver, Color3.fromRGB(180, 255, 160), 2)
		end
		if attackTier >= 3 then
			trail(folder, bow, Color3.fromRGB(180, 255, 170), 0.12)
		end
	end

	attachPets(character, profile)
end

return HeroAppearance
