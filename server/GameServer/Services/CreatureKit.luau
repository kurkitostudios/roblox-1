-- Mostri e pet procedurali. Pochi pezzi per modello, niente asset esterni.
-- I Motor6D marcati Animate sono mossi dal client e non bloccano il MoveTo del server.

local CollectionService = game:GetService("CollectionService")

local shared = require(script.Parent.SharedLoader)
local EnemyConfig = shared("EnemyConfig")
local WorldTextConfig = shared("WorldTextConfig")
local PropKit = shared("PropKit")

local CreatureKit = {}

local FAMILY = {
	zombie = "zombie",
	zombie_corrotto = "zombie",
	rotfang = "zombie",
	grave_chieftain = "zombie",
	risen_dead = "zombie",
	scheletro = "skeleton",
	scheletro_arciere = "skeleton",
	goblin = "goblin",
	goblin_bruto = "goblin",
	lupo = "wolf",
	lupo_alfa = "wolf",
	bandito = "bandit",
	capo_banditi = "bandit",
	slime = "slime",
	slime_tossico = "slime",
	ragno = "spider",
	ragno_madre = "spider",
	cultista = "cultist",
	accolito = "cultist",
	orco = "orc",
	guardia_orchesca = "orc",
	orco_guerriero = "orc",
	warlord = "orc",
	spettro = "specter",
	wraith = "specter",
	golem = "golem",
	golem_runico = "golem",
	imp = "imp",
	demone = "demon",
	cavaliere_oscuro = "knight",
	campione_oscuro = "knight",
	progenie_abisso = "abyss",
	signore_abisso = "abyss",
}

local LOOK = {
	zombie = { skin = Color3.fromRGB(118, 138, 86), cloth = Color3.fromRGB(62, 48, 36), eyes = Color3.fromRGB(110, 255, 130), hair = Color3.fromRGB(22, 16, 12), bone = Color3.fromRGB(196, 176, 140) },
	zombie_corrotto = { skin = Color3.fromRGB(142, 124, 96), cloth = Color3.fromRGB(74, 52, 36), eyes = Color3.fromRGB(255, 150, 40), hair = Color3.fromRGB(36, 28, 22), bone = Color3.fromRGB(214, 196, 160) },
	rotfang = { skin = Color3.fromRGB(92, 118, 68), cloth = Color3.fromRGB(48, 28, 22), eyes = Color3.fromRGB(150, 255, 70), hair = Color3.fromRGB(16, 10, 8), bone = Color3.fromRGB(180, 160, 130) },
	grave_chieftain = { skin = Color3.fromRGB(156, 114, 80), cloth = Color3.fromRGB(128, 32, 28), eyes = Color3.fromRGB(255, 96, 36), hair = Color3.fromRGB(18, 12, 10), bone = Color3.fromRGB(220, 200, 170) },
	risen_dead = { skin = Color3.fromRGB(96, 122, 72), cloth = Color3.fromRGB(48, 36, 28), eyes = Color3.fromRGB(140, 255, 110), hair = Color3.fromRGB(18, 14, 12), bone = Color3.fromRGB(180, 164, 140) },
	scheletro = { skin = Color3.fromRGB(214, 208, 190), cloth = Color3.fromRGB(90, 86, 80), eyes = Color3.fromRGB(120, 220, 255) },
	scheletro_arciere = { skin = Color3.fromRGB(200, 196, 180), cloth = Color3.fromRGB(70, 78, 54), eyes = Color3.fromRGB(140, 230, 160) },
	goblin = { skin = Color3.fromRGB(78, 150, 62), cloth = Color3.fromRGB(120, 78, 40), eyes = Color3.fromRGB(255, 220, 80) },
	goblin_bruto = { skin = Color3.fromRGB(62, 120, 48), cloth = Color3.fromRGB(90, 70, 50), eyes = Color3.fromRGB(255, 160, 40) },
	lupo = { skin = Color3.fromRGB(92, 78, 64), cloth = Color3.fromRGB(60, 52, 44), eyes = Color3.fromRGB(255, 180, 40) },
	lupo_alfa = { skin = Color3.fromRGB(70, 70, 78), cloth = Color3.fromRGB(40, 40, 48), eyes = Color3.fromRGB(255, 80, 40) },
	bandito = { skin = Color3.fromRGB(196, 156, 120), cloth = Color3.fromRGB(90, 48, 40), eyes = Color3.fromRGB(40, 40, 40) },
	capo_banditi = { skin = Color3.fromRGB(180, 140, 110), cloth = Color3.fromRGB(120, 36, 32), eyes = Color3.fromRGB(255, 200, 80) },
	slime = { skin = Color3.fromRGB(70, 170, 90), cloth = Color3.fromRGB(40, 120, 60), eyes = Color3.fromRGB(230, 255, 230) },
	slime_tossico = { skin = Color3.fromRGB(120, 180, 40), cloth = Color3.fromRGB(70, 110, 20), eyes = Color3.fromRGB(200, 255, 80) },
	ragno = { skin = Color3.fromRGB(50, 40, 46), cloth = Color3.fromRGB(90, 30, 40), eyes = Color3.fromRGB(255, 40, 40) },
	ragno_madre = { skin = Color3.fromRGB(40, 28, 36), cloth = Color3.fromRGB(140, 40, 60), eyes = Color3.fromRGB(255, 80, 120) },
	cultista = { skin = Color3.fromRGB(170, 150, 140), cloth = Color3.fromRGB(46, 28, 64), eyes = Color3.fromRGB(180, 80, 255) },
	accolito = { skin = Color3.fromRGB(160, 140, 150), cloth = Color3.fromRGB(70, 30, 80), eyes = Color3.fromRGB(255, 120, 200) },
	orco = { skin = Color3.fromRGB(70, 120, 58), cloth = Color3.fromRGB(90, 70, 48), eyes = Color3.fromRGB(255, 210, 60) },
	guardia_orchesca = { skin = Color3.fromRGB(60, 100, 50), cloth = Color3.fromRGB(70, 72, 78), eyes = Color3.fromRGB(255, 160, 40) },
	orco_guerriero = { skin = Color3.fromRGB(54, 96, 48), cloth = Color3.fromRGB(120, 50, 40), eyes = Color3.fromRGB(255, 90, 40) },
	warlord = { skin = Color3.fromRGB(48, 80, 42), cloth = Color3.fromRGB(90, 28, 28), eyes = Color3.fromRGB(255, 60, 30) },
	spettro = { skin = Color3.fromRGB(180, 200, 220), cloth = Color3.fromRGB(140, 160, 190), eyes = Color3.fromRGB(200, 240, 255) },
	wraith = { skin = Color3.fromRGB(120, 140, 180), cloth = Color3.fromRGB(40, 48, 80), eyes = Color3.fromRGB(140, 180, 255) },
	golem = { skin = Color3.fromRGB(120, 118, 110), cloth = Color3.fromRGB(80, 78, 72), eyes = Color3.fromRGB(80, 200, 180) },
	golem_runico = { skin = Color3.fromRGB(110, 120, 130), cloth = Color3.fromRGB(50, 90, 100), eyes = Color3.fromRGB(80, 230, 210) },
	imp = { skin = Color3.fromRGB(170, 60, 50), cloth = Color3.fromRGB(80, 30, 30), eyes = Color3.fromRGB(255, 200, 60) },
	demone = { skin = Color3.fromRGB(140, 36, 36), cloth = Color3.fromRGB(40, 20, 24), eyes = Color3.fromRGB(255, 140, 40) },
	cavaliere_oscuro = { skin = Color3.fromRGB(40, 42, 52), cloth = Color3.fromRGB(24, 26, 34), eyes = Color3.fromRGB(140, 180, 255) },
	campione_oscuro = { skin = Color3.fromRGB(32, 34, 48), cloth = Color3.fromRGB(180, 150, 70), eyes = Color3.fromRGB(255, 220, 120) },
	progenie_abisso = { skin = Color3.fromRGB(46, 28, 70), cloth = Color3.fromRGB(20, 16, 32), eyes = Color3.fromRGB(190, 80, 255) },
	signore_abisso = { skin = Color3.fromRGB(28, 18, 48), cloth = Color3.fromRGB(90, 40, 140), eyes = Color3.fromRGB(220, 140, 255) },
}

local RARITY_RATE = { Common = 0, Uncommon = 2, Rare = 3, Elite = 4, Boss = 5 }

local function familyOf(def)
	return FAMILY[def.id] or "zombie"
end

function CreatureKit.Family(def)
	return familyOf(def)
end

function CreatureKit.Hip(def)
	local scale = def.scale or 1
	local family = familyOf(def)
	local height = 4.2 * scale
	if family == "slime" then
		height = 3.2 * scale
	elseif family == "wolf" or family == "spider" then
		height = 2.8 * scale
	elseif family == "imp" then
		height = 3.4 * scale
	end
	return height * 0.5
end

local function piece(model, name, size, cf, color, material, shape, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function joint(part0, part1, motorName)
	local motor = Instance.new("Motor6D")
	motor.Name = motorName
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	motor.C1 = CFrame.new()
	motor:SetAttribute("Animate", true)
	motor.Parent = part1
	return motor
end

local function eye(model, root, cf, color, scale)
	local orb = piece(model, "Eye", Vector3.new(0.22, 0.22, 0.22) * scale, cf, color, Enum.Material.Neon, Enum.PartType.Ball, 0)
	joint(root, orb, "Eye")
	return orb
end

local function emitter(part, color, rate)
	if rate <= 0 then
		return
	end
	local spark = Instance.new("ParticleEmitter")
	spark.Name = "Aura"
	spark.Rate = rate
	spark.Lifetime = NumberRange.new(0.4, 0.8)
	spark.Speed = NumberRange.new(0.2, 0.8)
	spark.LightEmission = 0.4
	spark.Size = NumberSequence.new(0.22)
	spark.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	spark.Color = ColorSequence.new(color)
	spark:SetAttribute("KurkitoBaseRate", rate)
	spark.Parent = part
end

local function styleEvolution(model, evolution, base)
	local material = Enum.Material.SmoothPlastic
	local color = base
	local glow = 0
	if evolution == "Gold" then
		material = Enum.Material.Metal
		color = Color3.fromRGB(214, 170, 64)
	elseif evolution == "Diamond" then
		material = Enum.Material.Glass
		color = Color3.fromRGB(170, 225, 240)
		glow = 2
	elseif evolution == "Platinum" then
		material = Enum.Material.Metal
		color = Color3.fromRGB(214, 220, 230)
	elseif evolution == "Stellar" then
		material = Enum.Material.Neon
		color = Color3.fromRGB(255, 214, 120)
		glow = 3
	elseif evolution == "Void" then
		material = Enum.Material.Neon
		color = Color3.fromRGB(70, 28, 110)
		glow = 4
	end
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" and child.Name ~= "AggroRing" then
			child.Color = child.Color:Lerp(color, evolution == "Normal" and 0 or 0.72)
			if evolution ~= "Normal" and child.Name ~= "Eye" then
				child.Material = material
			end
		end
	end
	local root = model.PrimaryPart
	if root and glow > 0 then
		local tint = evolution == "Void" and Color3.fromRGB(170, 80, 255) or color
		emitter(root, tint, glow)
	end
end

local function addHumanoid(model, root, def, hip, pet)
	if pet then
		return nil
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = def.name
	humanoid.MaxHealth = def.hp
	humanoid.Health = def.hp
	humanoid.WalkSpeed = def.speed
	humanoid.HipHeight = hip
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.NameDisplayDistance = WorldTextConfig.MaxDistance.EnemyName
	humanoid.HealthDisplayDistance = WorldTextConfig.MaxDistance.EnemyHealth
	humanoid.NameOcclusion = Enum.NameOcclusion.OccludeAll
	humanoid.AutoRotate = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.Parent = model
	return humanoid
end

local function addRing(model, root, def, hip)
	local ring = piece(model, "AggroRing", Vector3.new(0.06, def.aggro * 2, def.aggro * 2), root.CFrame * CFrame.new(0, -hip + 0.12, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(176, 64, 52), Enum.Material.Neon, Enum.PartType.Cylinder, 0.88)
	ring.CanCollide = false
	joint(root, ring, "Ring")
	return ring
end

local function addFaceAlign(root)
	local attachment = Instance.new("Attachment")
	attachment.Name = "Face"
	attachment.Parent = root
	local align = Instance.new("AlignOrientation")
	align.Name = "FaceAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = false
	align.Responsiveness = 12
	align.MaxTorque = 80000
	align.Enabled = false
	align.Parent = root
	return align
end

local function finish(model, root, def, hip, pet, evolution)
	model.PrimaryPart = root
	model:SetAttribute("EnemyTypeId", def.id)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("KurkitoFamily", familyOf(def))
	model:SetAttribute("KurkitoBehavior", def.behavior or "")
	model:SetAttribute("KurkitoActor", pet and "Pet" or "Enemy")
	model:SetAttribute("KurkitoState", "Idle")
	if evolution then
		model:SetAttribute("KurkitoEvolution", evolution)
		styleEvolution(model, evolution, LOOK[def.id] and LOOK[def.id].skin or Color3.new(1, 1, 1))
	end
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = false
			if pet then
				child.CanCollide = false
				child.Massless = true
			end
		end
	end
	if not pet then
		root.CanCollide = true
		root.Massless = false
		root.CollisionGroup = "KurkitoEnemies"
	else
		root.CanCollide = false
		root.Massless = true
	end
	CollectionService:AddTag(model, "KurkitoMotion")
	return model
end

local function humanoidBody(model, root, cf, scale, look, family, def)
	local skin = look.skin
	local cloth = look.cloth
	local mat = family == "golem" and Enum.Material.Slate or (family == "knight" and Enum.Material.Metal or Enum.Material.SmoothPlastic)
	local torso = piece(model, "Torso", Vector3.new(1.7, 1.5, 0.9) * scale, cf * CFrame.new(0, 0.15 * scale, 0), cloth, mat)
	joint(root, torso, "Torso")
	local head = piece(model, "Head", Vector3.new(1.15, 1.15, 1.15) * scale, cf * CFrame.new(0, 1.25 * scale, 0), skin, mat, Enum.PartType.Ball)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.15, 1.05, 1.15)
	headMesh.Parent = head
	joint(root, head, "Head")
	eye(model, head, head.CFrame * CFrame.new(-0.22 * scale, 0.08 * scale, -0.42 * scale), look.eyes, scale)
	eye(model, head, head.CFrame * CFrame.new(0.22 * scale, 0.08 * scale, -0.42 * scale), look.eyes, scale)
	if family == "zombie" or family == "goblin" or family == "orc" then
		local jaw = piece(model, "Jaw", Vector3.new(0.55, 0.22, 0.35) * scale, head.CFrame * CFrame.new(0, -0.38 * scale, -0.28 * scale), Color3.fromRGB(30, 24, 24), Enum.Material.SmoothPlastic)
		joint(head, jaw, "Jaw")
	end
	local armL = piece(model, "ArmL", Vector3.new(0.42, 1.5, 0.42) * scale, cf * CFrame.new(-1.05 * scale, 0.05 * scale, 0), skin, mat)
	local armR = piece(model, "ArmR", Vector3.new(0.42, 1.5, 0.42) * scale, cf * CFrame.new(1.05 * scale, 0.05 * scale, 0), skin, mat)
	joint(torso, armL, "ArmL")
	joint(torso, armR, "ArmR")
	local legL = piece(model, "LegL", Vector3.new(0.48, 1.7, 0.48) * scale, cf * CFrame.new(-0.38 * scale, -1.35 * scale, 0), skin:Lerp(Color3.new(0, 0, 0), 0.15), mat)
	local legR = piece(model, "LegR", Vector3.new(0.48, 1.7, 0.48) * scale, cf * CFrame.new(0.38 * scale, -1.35 * scale, 0), skin:Lerp(Color3.new(0, 0, 0), 0.15), mat)
	joint(torso, legL, "LegL")
	joint(torso, legR, "LegR")
	if family == "skeleton" then
		for index = 1, 3 do
			local rib = piece(model, "Rib" .. index, Vector3.new(1.3, 0.1, 0.7) * scale, torso.CFrame * CFrame.new(0, 0.35 * scale - index * 0.28 * scale, -0.15 * scale), skin, Enum.Material.SmoothPlastic)
			joint(torso, rib, "Rib" .. index)
		end
		if def.id == "scheletro_arciere" then
			local bow = piece(model, "Bow", Vector3.new(0.15, 1.6, 0.15) * scale, armL.CFrame * CFrame.new(0, -0.2 * scale, -0.35 * scale), Color3.fromRGB(120, 78, 40), Enum.Material.Wood)
			joint(armL, bow, "Prop")
		end
	elseif family == "goblin" then
		local earL = piece(model, "EarL", Vector3.new(0.15, 0.55, 0.28) * scale, head.CFrame * CFrame.new(-0.55 * scale, 0.15 * scale, 0), skin, Enum.Material.SmoothPlastic)
		local earR = piece(model, "EarR", Vector3.new(0.15, 0.55, 0.28) * scale, head.CFrame * CFrame.new(0.55 * scale, 0.15 * scale, 0), skin, Enum.Material.SmoothPlastic)
		joint(head, earL, "EarL")
		joint(head, earR, "EarR")
	elseif family == "orc" or family == "abyss" then
		local tuskL = piece(model, "TuskL", Vector3.new(0.12, 0.4, 0.12) * scale, head.CFrame * CFrame.new(-0.18 * scale, -0.4 * scale, -0.4 * scale), Color3.fromRGB(230, 220, 190), Enum.Material.SmoothPlastic)
		local tuskR = piece(model, "TuskR", Vector3.new(0.12, 0.4, 0.12) * scale, head.CFrame * CFrame.new(0.18 * scale, -0.4 * scale, -0.4 * scale), Color3.fromRGB(230, 220, 190), Enum.Material.SmoothPlastic)
		joint(head, tuskL, "TuskL")
		joint(head, tuskR, "TuskR")
	elseif family == "bandit" or family == "cultist" then
		local hood = piece(model, "Hood", Vector3.new(1.3, 0.7, 1.3) * scale, head.CFrame * CFrame.new(0, 0.35 * scale, 0.05 * scale), cloth, Enum.Material.Fabric, Enum.PartType.Ball, 0)
		joint(head, hood, "Hood")
	elseif family == "knight" then
		local helm = piece(model, "Helm", Vector3.new(1.25, 0.7, 1.25) * scale, head.CFrame * CFrame.new(0, 0.25 * scale, 0), cloth, Enum.Material.Metal)
		joint(head, helm, "Helm")
		local pauldron = piece(model, "Pauldron", Vector3.new(0.7, 0.35, 0.7) * scale, torso.CFrame * CFrame.new(-0.85 * scale, 0.55 * scale, 0), cloth:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Metal, Enum.PartType.Ball)
		joint(torso, pauldron, "Pauldron")
	end
	if family == "imp" or family == "demon" or family == "specter" or family == "abyss" then
		local wingL = piece(model, "WingL", Vector3.new(0.12, 1.3, 1.1) * scale, torso.CFrame * CFrame.new(-0.4 * scale, 0.3 * scale, 0.55 * scale), cloth, Enum.Material.SmoothPlastic, nil, family == "specter" and 0.35 or 0)
		local wingR = piece(model, "WingR", Vector3.new(0.12, 1.3, 1.1) * scale, torso.CFrame * CFrame.new(0.4 * scale, 0.3 * scale, 0.55 * scale), cloth, Enum.Material.SmoothPlastic, nil, family == "specter" and 0.35 or 0)
		joint(torso, wingL, "WingL")
		joint(torso, wingR, "WingR")
	end
	if family == "specter" then
		torso.Transparency = 0.35
		head.Transparency = 0.28
		armL.Transparency = 0.4
		armR.Transparency = 0.4
		legL.Transparency = 0.45
		legR.Transparency = 0.45
	end
	if family == "golem" then
		local rune = piece(model, "Rune", Vector3.new(0.45, 0.45, 0.12) * scale, torso.CFrame * CFrame.new(0, 0.1 * scale, -0.48 * scale), look.eyes, Enum.Material.Neon)
		joint(torso, rune, "Rune")
	end
	return torso, head
end

local function beastBody(model, root, cf, scale, look, legs)
	local body = piece(model, "Torso", Vector3.new(1.2, 1.05, 2.4) * scale, cf, look.skin, Enum.Material.SmoothPlastic)
	joint(root, body, "Torso")
	local head = piece(model, "Head", Vector3.new(0.9, 0.8, 1.05) * scale, cf * CFrame.new(0, 0.25 * scale, -1.45 * scale), look.skin:Lerp(Color3.new(0, 0, 0), 0.1), Enum.Material.SmoothPlastic)
	joint(body, head, "Head")
	eye(model, head, head.CFrame * CFrame.new(-0.22 * scale, 0.1 * scale, -0.4 * scale), look.eyes, scale)
	eye(model, head, head.CFrame * CFrame.new(0.22 * scale, 0.1 * scale, -0.4 * scale), look.eyes, scale)
	local names = { "LegFL", "LegFR", "LegBL", "LegBR" }
	local offsets = {
		Vector3.new(-0.45, -0.7, -0.7),
		Vector3.new(0.45, -0.7, -0.7),
		Vector3.new(-0.45, -0.7, 0.7),
		Vector3.new(0.45, -0.7, 0.7),
	}
	for index = 1, legs do
		local leg = piece(model, names[index], Vector3.new(0.28, 0.9, 0.28) * scale, cf * CFrame.new(offsets[index] * scale), look.skin:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.SmoothPlastic)
		joint(body, leg, names[index])
	end
	local tail = piece(model, "Tail", Vector3.new(0.22, 0.22, 1.1) * scale, cf * CFrame.new(0, 0.2 * scale, 1.5 * scale), look.cloth, Enum.Material.SmoothPlastic)
	joint(body, tail, "Tail")
	return body, head
end

local function spiderBody(model, root, cf, scale, look)
	local body = piece(model, "Torso", Vector3.new(1.5, 0.8, 1.8) * scale, cf, look.skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	joint(root, body, "Torso")
	local head = piece(model, "Head", Vector3.new(0.8, 0.6, 0.8) * scale, cf * CFrame.new(0, 0.1 * scale, -1.05 * scale), look.cloth, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	joint(body, head, "Head")
	eye(model, head, head.CFrame * CFrame.new(-0.18 * scale, 0.12 * scale, -0.28 * scale), look.eyes, scale * 0.8)
	eye(model, head, head.CFrame * CFrame.new(0.18 * scale, 0.12 * scale, -0.28 * scale), look.eyes, scale * 0.8)
	for index = 1, 4 do
		local z = -0.55 + (index - 1) * 0.38
		local legL = piece(model, "LegL" .. index, Vector3.new(0.12, 0.12, 1.5) * scale, cf * CFrame.new(-0.95 * scale, -0.15 * scale, z * scale) * CFrame.Angles(0, math.rad(28), math.rad(18)), look.skin, Enum.Material.SmoothPlastic)
		local legR = piece(model, "LegR" .. index, Vector3.new(0.12, 0.12, 1.5) * scale, cf * CFrame.new(0.95 * scale, -0.15 * scale, z * scale) * CFrame.Angles(0, math.rad(-28), math.rad(-18)), look.skin, Enum.Material.SmoothPlastic)
		joint(body, legL, "LegL" .. index)
		joint(body, legR, "LegR" .. index)
	end
	return body, head
end

local function slimeBody(model, root, cf, scale, look)
	local body = piece(model, "Torso", Vector3.new(2.2, 1.8, 2.2) * scale, cf * CFrame.new(0, -0.15 * scale, 0), look.skin, Enum.Material.Glass, Enum.PartType.Ball, 0.18)
	joint(root, body, "Torso")
	local core = piece(model, "Core", Vector3.new(1.1, 0.9, 1.1) * scale, cf, look.cloth, Enum.Material.Neon, Enum.PartType.Ball, 0.15)
	joint(body, core, "Core")
	eye(model, body, cf * CFrame.new(-0.35 * scale, 0.25 * scale, -0.75 * scale), look.eyes, scale)
	eye(model, body, cf * CFrame.new(0.35 * scale, 0.25 * scale, -0.75 * scale), look.eyes, scale)
	return body, body
end

local function graveBody(model, root, cf, scale, look, def)
	local behavior = def.behavior or "scavenger"
	local bone = look.bone or Color3.fromRGB(210, 196, 170)
	local hairColor = look.hair or Color3.fromRGB(20, 14, 12)
	local hunch = 0
	local torsoSize = Vector3.new(1.55, 1.45, 0.9)
	local armSize = Vector3.new(0.4, 1.45, 0.4)
	if behavior == "scavenger" then
		hunch = 18
		torsoSize = Vector3.new(1.2, 1.3, 0.7)
		armSize = Vector3.new(0.32, 1.55, 0.32)
	elseif behavior == "bonewalker" then
		hunch = 6
		torsoSize = Vector3.new(1.95, 1.65, 1.05)
		armSize = Vector3.new(0.5, 1.5, 0.5)
	elseif behavior == "rotfang" then
		hunch = 24
		torsoSize = Vector3.new(1.85, 1.5, 1)
		armSize = Vector3.new(0.48, 1.6, 0.48)
	elseif behavior == "chieftain" then
		hunch = 4
		torsoSize = Vector3.new(2.2, 1.85, 1.25)
		armSize = Vector3.new(0.58, 1.7, 0.58)
	end
	local torso = piece(model, "Torso", torsoSize * scale, cf * CFrame.new(0, 0.12 * scale, 0) * CFrame.Angles(math.rad(hunch), 0, 0), look.cloth, Enum.Material.Fabric)
	joint(root, torso, "Torso")
	local head = piece(model, "Head", Vector3.new(1.05, 1.05, 1.05) * scale, torso.CFrame * CFrame.new(0, 1.15 * scale, -0.05 * scale), look.skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	joint(torso, head, "Head")
	eye(model, head, head.CFrame * CFrame.new(-0.22 * scale, 0.06 * scale, -0.4 * scale), look.eyes, scale)
	eye(model, head, head.CFrame * CFrame.new(0.22 * scale, 0.06 * scale, -0.4 * scale), look.eyes, scale)
	local jaw = piece(model, "Jaw", Vector3.new(0.5, 0.2, 0.32) * scale, head.CFrame * CFrame.new(0, -0.36 * scale, -0.22 * scale), Color3.fromRGB(28, 22, 18), Enum.Material.SmoothPlastic)
	joint(head, jaw, "Jaw")
	local hairCount = behavior == "rotfang" and 7 or (behavior == "scavenger" and 5 or 3)
	for index = 1, hairCount do
		local angle = (index / hairCount) * math.pi * 2
		local length = behavior == "rotfang" and 1.15 or 0.7
		local clump = piece(model, "Hair" .. index, Vector3.new(0.22, length, 0.28) * scale, head.CFrame * CFrame.new(math.cos(angle) * 0.32 * scale, 0.35 * scale, math.sin(angle) * 0.2 * scale) * CFrame.Angles(0, 0, math.rad(18)), hairColor, Enum.Material.Fabric)
		joint(head, clump, "Hair" .. index)
	end
	local armL = piece(model, "ArmL", armSize * scale, torso.CFrame * CFrame.new(-0.85 * scale, -0.05 * scale, 0), look.skin, Enum.Material.SmoothPlastic)
	local armR = piece(model, "ArmR", armSize * scale, torso.CFrame * CFrame.new(0.85 * scale, -0.05 * scale, 0), look.skin, Enum.Material.SmoothPlastic)
	joint(torso, armL, "ArmL")
	joint(torso, armR, "ArmR")
	local legL = piece(model, "LegL", Vector3.new(0.46, 1.55, 0.46) * scale, cf * CFrame.new(-0.34 * scale, -1.25 * scale, 0), look.skin:Lerp(Color3.new(0, 0, 0), 0.18), Enum.Material.SmoothPlastic)
	local legR = piece(model, "LegR", Vector3.new(0.46, 1.55, 0.46) * scale, cf * CFrame.new(0.34 * scale, -1.25 * scale, 0), look.skin:Lerp(Color3.new(0, 0, 0), 0.18), Enum.Material.SmoothPlastic)
	joint(torso, legL, "LegL")
	joint(torso, legR, "LegR")
	local clawColor = behavior == "rotfang" and look.eyes or bone
	local clawL = piece(model, "ClawL", Vector3.new(0.12, 0.45, 0.12) * scale, armL.CFrame * CFrame.new(0, -0.85 * scale, -0.12 * scale), clawColor, Enum.Material.SmoothPlastic)
	local clawR = piece(model, "ClawR", Vector3.new(0.12, 0.45, 0.12) * scale, armR.CFrame * CFrame.new(0, -0.85 * scale, -0.12 * scale), clawColor, Enum.Material.SmoothPlastic)
	joint(armL, clawL, "ClawL")
	joint(armR, clawR, "ClawR")
	if behavior == "scavenger" then
		for index = 1, 3 do
			local rag = piece(model, "Rag" .. index, Vector3.new(0.45, 0.8, 0.08) * scale, torso.CFrame * CFrame.new(-0.4 * scale + index * 0.28 * scale, -0.55 * scale, -0.4 * scale), look.cloth:Lerp(bone, 0.2), Enum.Material.Fabric)
			joint(torso, rag, "Rag" .. index)
		end
	elseif behavior == "bonewalker" then
		local plate = piece(model, "BonePlate", Vector3.new(1.3, 1.1, 0.18) * scale, torso.CFrame * CFrame.new(0, 0.05 * scale, -0.55 * scale), bone, Enum.Material.SmoothPlastic)
		joint(torso, plate, "BonePlate")
		local shield = piece(model, "Shield", Vector3.new(1.35, 1.6, 0.18) * scale, armL.CFrame * CFrame.new(-0.15 * scale, -0.15 * scale, -0.35 * scale), bone, Enum.Material.SmoothPlastic)
		joint(armL, shield, "Shield")
		local shin = piece(model, "Shin", Vector3.new(0.5, 0.7, 0.2) * scale, legL.CFrame * CFrame.new(0, -0.2 * scale, -0.2 * scale), bone, Enum.Material.SmoothPlastic)
		joint(legL, shin, "Shin")
		local mask = piece(model, "Mask", Vector3.new(0.9, 0.45, 0.25) * scale, head.CFrame * CFrame.new(0, -0.05 * scale, -0.45 * scale), bone, Enum.Material.SmoothPlastic)
		joint(head, mask, "Mask")
	elseif behavior == "rotfang" then
		local sash = piece(model, "Sash", Vector3.new(1.4, 0.35, 0.2) * scale, torso.CFrame * CFrame.new(0, -0.2 * scale, -0.5 * scale), Color3.fromRGB(120, 36, 28), Enum.Material.Fabric)
		joint(torso, sash, "Sash")
		local fangL = piece(model, "FangL", Vector3.new(0.1, 0.35, 0.1) * scale, head.CFrame * CFrame.new(-0.16 * scale, -0.42 * scale, -0.32 * scale), bone, Enum.Material.SmoothPlastic)
		local fangR = piece(model, "FangR", Vector3.new(0.1, 0.35, 0.1) * scale, head.CFrame * CFrame.new(0.16 * scale, -0.42 * scale, -0.32 * scale), bone, Enum.Material.SmoothPlastic)
		joint(head, fangL, "FangL")
		joint(head, fangR, "FangR")
	else
		local wrap = piece(model, "RedWrap", Vector3.new(1.7, 0.55, 1.15) * scale, torso.CFrame * CFrame.new(0, -0.35 * scale, -0.1 * scale), look.cloth, Enum.Material.Fabric)
		joint(torso, wrap, "RedWrap")
		local crown = piece(model, "BoneCrown", Vector3.new(1.15, 0.28, 1.15) * scale, head.CFrame * CFrame.new(0, 0.55 * scale, 0), bone, Enum.Material.SmoothPlastic)
		joint(head, crown, "BoneCrown")
		local spike = piece(model, "Spike", Vector3.new(0.16, 0.7, 0.16) * scale, crown.CFrame * CFrame.new(0, 0.4 * scale, 0), bone, Enum.Material.SmoothPlastic)
		joint(crown, spike, "Spike")
		local totem = piece(model, "Totem", Vector3.new(0.28, 2.4, 0.28) * scale, armR.CFrame * CFrame.new(0, -0.4 * scale, -0.3 * scale), Color3.fromRGB(92, 58, 36), Enum.Material.Wood)
		joint(armR, totem, "Totem")
		local totemSkull = piece(model, "TotemSkull", Vector3.new(0.45, 0.4, 0.4) * scale, totem.CFrame * CFrame.new(0, -1 * scale, 0), bone, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		joint(totem, totemSkull, "TotemSkull")
		local belt = piece(model, "SkullBelt", Vector3.new(0.4, 0.4, 0.4) * scale, torso.CFrame * CFrame.new(0, -0.7 * scale, -0.55 * scale), bone, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		joint(torso, belt, "SkullBelt")
	end
	return torso, head
end

local function rarityTrim(model, torso, head, def, scale, look, pet)
	local rarity = def.rarity
	local grave = def.behavior == "scavenger" or def.behavior == "bonewalker" or def.behavior == "rotfang" or def.behavior == "chieftain"
	if not grave and (rarity == "Uncommon" or rarity == "Rare" or rarity == "Elite" or rarity == "Boss") then
		local gem = piece(model, "Gem", Vector3.new(0.28, 0.28, 0.28) * scale, torso.CFrame * CFrame.new(0, 0.15 * scale, -0.5 * scale), EnemyConfig.RarityColor[rarity], Enum.Material.Neon, Enum.PartType.Ball)
		joint(torso, gem, "Gem")
	end
	if not grave and (rarity == "Elite" or rarity == "Boss") then
		local hornL = piece(model, "HornL", Vector3.new(0.16, 0.7, 0.16) * scale, head.CFrame * CFrame.new(-0.28 * scale, 0.55 * scale, 0) * CFrame.Angles(0, 0, math.rad(18)), look.cloth, Enum.Material.SmoothPlastic)
		local hornR = piece(model, "HornR", Vector3.new(0.16, 0.7, 0.16) * scale, head.CFrame * CFrame.new(0.28 * scale, 0.55 * scale, 0) * CFrame.Angles(0, 0, math.rad(-18)), look.cloth, Enum.Material.SmoothPlastic)
		joint(head, hornL, "HornL")
		joint(head, hornR, "HornR")
	end
	if rarity == "Boss" and not grave then
		local crown = piece(model, "Crown", Vector3.new(1.2, 0.28, 1.2) * scale, head.CFrame * CFrame.new(0, 0.62 * scale, 0), Color3.fromRGB(212, 170, 60), Enum.Material.Metal)
		joint(head, crown, "Crown")
	end
	if rarity == "Boss" and not pet then
		local highlight = Instance.new("Highlight")
		highlight.Name = "BossGlow"
		highlight.FillColor = EnemyConfig.RarityColor.Boss
		highlight.OutlineColor = Color3.fromRGB(255, 210, 140)
		highlight.FillTransparency = 0.84
		highlight.OutlineTransparency = 0.4
		highlight.Parent = model
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 120, 50)
		light.Range = 12
		light.Brightness = 0.4
		light.Shadows = false
		light.Parent = torso
	end
	emitter(torso, EnemyConfig.RarityColor[rarity] or look.eyes, RARITY_RATE[rarity] or 0)
end

local function build(def, cf, pet, evolution)
	local scale = (def.scale or 1) * (pet and 0.4 or 1)
	local family = familyOf(def)
	local look = LOOK[def.id] or LOOK.zombie
	local model = Instance.new("Model")
	model.Name = def.id
	local hip = CreatureKit.Hip(def) * (pet and 0.4 or 1)
	local rootSize = Vector3.new(1.8 * scale, hip * 2, 1.1 * scale)
	if family == "wolf" then
		rootSize = Vector3.new(1.4 * scale, hip * 2, 2.2 * scale)
	elseif family == "spider" then
		rootSize = Vector3.new(2 * scale, hip * 2, 2 * scale)
	elseif family == "slime" then
		rootSize = Vector3.new(2.1 * scale, hip * 2, 2.1 * scale)
	end
	local root = piece(model, "HumanoidRootPart", rootSize, cf, look.skin, Enum.Material.SmoothPlastic)
	root.Transparency = 1
	root.Massless = false
	local torso, head
	if def.behavior == "scavenger" or def.behavior == "bonewalker" or def.behavior == "rotfang" or def.behavior == "chieftain" then
		torso, head = graveBody(model, root, cf, scale, look, def)
	elseif family == "wolf" then
		torso, head = beastBody(model, root, cf, scale, look, 4)
	elseif family == "spider" then
		torso, head = spiderBody(model, root, cf, scale, look)
	elseif family == "slime" then
		torso, head = slimeBody(model, root, cf, scale, look)
	else
		torso, head = humanoidBody(model, root, cf, scale, look, family, def)
	end
	rarityTrim(model, torso, head, def, scale, look, pet)
	local humanoid = addHumanoid(model, root, def, hip, pet)
	local align = nil
	if not pet then
		addRing(model, root, def, hip)
		align = addFaceAlign(root)
		PropKit.Billboard(head, def.rarity, "EnemyRarity", UDim2.fromOffset(120, 28), Vector3.new(0, 1.6 * (def.scale or 1), 0), EnemyConfig.RarityColor[def.rarity])
	end
	finish(model, root, def, hip, pet, evolution)
	return model, humanoid, root, align
end

function CreatureKit.Build(def, position)
	return build(def, CFrame.new(position), false, nil)
end

function CreatureKit.BuildPet(def, evolution)
	local model = build(def, CFrame.new(0, 4, 0), true, evolution or "Normal")
	model.Name = "Pet_" .. def.id
	return model
end

return CreatureKit
