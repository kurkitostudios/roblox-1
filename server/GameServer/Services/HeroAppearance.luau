-- Aspetto prototipo costruito con parti. Non sono asset definitivi.
-- Guerriero: arma da DMG, armatura da HP, scia da Speed.
-- Mago: cappello da DMG, scintille da Mana, vesti da HP.
-- Arciere: arco da DMG e Attack Speed, equipaggiamento leggero da HP.

local shared = require(script.Parent.SharedLoader)
local Rules = shared("Rules")
local HeroConfig = shared("HeroConfig")

local HeroAppearance = {}

local function limb(character, names)
	for _, name in ipairs(names) do
		local found = character:FindFirstChild(name, true)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function weld(part, target)
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = target
	joint.Part1 = part
	joint.Parent = part
end

local function part(parent, name, size, color, material)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.Color = color
	piece.Material = material or Enum.Material.SmoothPlastic
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.Massless = true
	piece.Anchored = false
	piece.Parent = parent
	return piece
end

local function tierColor(base, tier)
	local accent = Color3.fromRGB(230, 200, 110)
	return base:Lerp(accent, math.clamp(tier / 6, 0, 0.75))
end

function HeroAppearance.Apply(character, heroId, heroState)
	if not character or not heroState then
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
	for _, descendant in character:GetDescendants() do
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
	if not head or not torso or not hand then
		return
	end

	local robe = part(folder, "Robe", torso.Size * Vector3.new(1.08, 1.05, 1.08), tierColor(classDef.color, hpTier), Enum.Material.Fabric)
	robe.Transparency = 0.15 + math.max(0, 0.15 - hpTier * 0.03)
	robe.CFrame = torso.CFrame
	weld(robe, torso)

	if heroId == "Warrior" then
		local speedTier = Rules.VisualTier(heroState.stats.Speed or 1)
		local bladeLength = 2.2 + dmgTier * 0.55
		local blade = part(folder, "Blade", Vector3.new(0.25, bladeLength, 0.45), tierColor(Color3.fromRGB(180, 190, 200), dmgTier), Enum.Material.Metal)
		blade.CFrame = hand.CFrame * CFrame.new(0, -1.1 - dmgTier * 0.08, -0.4)
		weld(blade, hand)
		if dmgTier >= 2 then
			local guard = part(folder, "Guard", Vector3.new(1.1 + dmgTier * 0.08, 0.18, 0.28), Color3.fromRGB(212, 175, 80), Enum.Material.Metal)
			guard.CFrame = blade.CFrame * CFrame.new(0, bladeLength * 0.42, 0)
			weld(guard, blade)
		end
		if dmgTier >= 4 then
			blade.Material = Enum.Material.Neon
		end
		local plate = part(folder, "Chest", Vector3.new(2.1, 1.3, 1.05), tierColor(Color3.fromRGB(120, 130, 145), hpTier), Enum.Material.Metal)
		plate.CFrame = torso.CFrame * CFrame.new(0, 0.15, -0.55)
		weld(plate, torso)
		if speedTier >= 2 then
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(0, 1, 0)
			a0.Parent = torso
			a0.Name = "KurkitoTrailA"
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(0, -1, 0)
			a1.Parent = torso
			a1.Name = "KurkitoTrailB"
			local trail = Instance.new("Trail")
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Lifetime = 0.25
			trail.MinLength = 0.1
			trail.Color = ColorSequence.new(classDef.color)
			trail.Transparency = NumberSequence.new(0.4)
			trail.Parent = folder
		end
	elseif heroId == "Mage" then
		local manaTier = Rules.VisualTier(heroState.stats.Mana or 1)
		local hatHeight = 1.2 + dmgTier * 0.28
		local hat = part(folder, "Hat", Vector3.new(1.5, hatHeight, 1.5), tierColor(Color3.fromRGB(48, 60, 130), dmgTier), Enum.Material.Fabric)
		hat.CFrame = head.CFrame * CFrame.new(0, 0.8 + hatHeight * 0.35, 0)
		weld(hat, head)
		local brim = part(folder, "Brim", Vector3.new(2.1 + dmgTier * 0.12, 0.18, 2.1 + dmgTier * 0.12), Color3.fromRGB(30, 34, 70), Enum.Material.Fabric)
		brim.CFrame = head.CFrame * CFrame.new(0, 0.65, 0)
		weld(brim, head)
		if dmgTier >= 3 then
			hat.Material = Enum.Material.Neon
		end
		if manaTier >= 2 then
			local spark = Instance.new("ParticleEmitter")
			spark.Name = "ManaSpark"
			spark.Rate = 4 + manaTier * 2
			spark.Lifetime = NumberRange.new(0.4, 0.8)
			spark.Speed = NumberRange.new(0.4, 1.2)
			spark.Size = NumberSequence.new(0.18)
			spark.LightEmission = 0.6
			spark.Color = ColorSequence.new(Color3.fromRGB(120, 170, 255))
			spark.Parent = torso
			spark.Parent = folder
			local anchor = part(folder, "SparkAnchor", Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
			anchor.Transparency = 1
			anchor.CFrame = torso.CFrame * CFrame.new(0, 1.2, 0)
			weld(anchor, torso)
			spark.Parent = anchor
		end
	elseif heroId == "Archer" then
		local attackTier = Rules.VisualTier(heroState.stats.AttackSpeed or 1)
		local bowTier = math.max(dmgTier, attackTier)
		local bow = part(folder, "Bow", Vector3.new(0.25, 2.4 + bowTier * 0.35, 0.25), tierColor(Color3.fromRGB(120, 78, 40), bowTier), Enum.Material.Wood)
		bow.CFrame = hand.CFrame * CFrame.new(0, -0.4, -0.5)
		weld(bow, hand)
		local stringPart = part(folder, "BowString", Vector3.new(0.06, 2.1 + bowTier * 0.3, 0.06), Color3.fromRGB(230, 230, 220), Enum.Material.Fabric)
		stringPart.CFrame = bow.CFrame * CFrame.new(0, 0, 0.35)
		weld(stringPart, bow)
		if bowTier >= 3 then
			local gem = part(folder, "BowGem", Vector3.new(0.28, 0.28, 0.28), Color3.fromRGB(80, 220, 140), Enum.Material.Neon)
			gem.CFrame = bow.CFrame * CFrame.new(0, 0.2, 0)
			weld(gem, bow)
		end
		local quiver = part(folder, "Quiver", Vector3.new(0.45, 1.3 + hpTier * 0.08, 0.45), tierColor(Color3.fromRGB(92, 64, 40), hpTier), Enum.Material.Wood)
		quiver.CFrame = torso.CFrame * CFrame.new(0.7, 0.2, 0.7)
		weld(quiver, torso)
	end
end

return HeroAppearance
