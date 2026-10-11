-- Aspetto del personaggio. Il Mondo 0 disegna solo il Warrior.
-- Geometria, materiali e clava stanno in WarriorVisualBuilder.
-- I pet equipaggiati restano un sistema a parte e seguono l'eroe.

local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local EnemyConfig = shared("EnemyConfig")
local CreatureKit = require(script.Parent.CreatureKit)
local WarriorVisualBuilder = require(script.Parent.WarriorVisualBuilder)

local HeroAppearance = {}

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
	-- Il Mondo 0 disegna solo il Warrior. Mage e Archer restano dati archiviati.
	if heroId ~= "Warrior" then
		heroId = "Warrior"
	end
	local classDef = HeroConfig.Classes[heroId]
	if not classDef then
		return
	end
	if heroId == "Warrior" then
		-- Il pezzo impugnato si chiama "Club". Il Motor6D resta "WeaponMotor".
		WarriorVisualBuilder.Apply(character, heroState)
		local visuals = character:FindFirstChild("KurkitoVisuals")
		local club = visuals and visuals:FindFirstChild("Club", true)
		if club then
			club:SetAttribute("KurkitoWeapon", "Club")
		end
	end
	attachPets(character, profile)
end

HeroAppearance.HasForeignCosmetics = WarriorVisualBuilder.HasForeignCosmetics

return HeroAppearance
