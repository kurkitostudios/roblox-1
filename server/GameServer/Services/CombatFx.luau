-- Effetti visivi del combattimento. Non applicano danni.
-- Il server resta l'unica autorità su colpi, cooldown e ricompense.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CombatFx = {}

local live = 0
local CAP = 36

local function effectsFolder()
	local world = workspace:FindFirstChild("KurkitoWorld")
	return (world and world:FindFirstChild("Effects")) or workspace
end

local function allow()
	if live >= CAP then
		return false
	end
	live += 1
	task.delay(0.8, function()
		live = math.max(0, live - 1)
	end)
	return true
end

local function ghost(size, color, cframe, shape)
	local piece = Instance.new("Part")
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = false
	piece.Material = Enum.Material.Neon
	piece.Color = color
	piece.Size = size
	piece.CFrame = cframe
	piece.Transparency = 0.25
	piece.Shape = shape or Enum.PartType.Block
	piece.Parent = effectsFolder()
	return piece
end

function CombatFx.MarkSwing(player, kind)
	local character = player and player.Character
	if not character then
		return
	end
	character:SetAttribute("KurkitoSwing", os.clock())
	character:SetAttribute("KurkitoSwingKind", kind or "Attack")
end

function CombatFx.BasicHit(player, heroId, fromPos, targetPos, color)
	CombatFx.MarkSwing(player, "Attack")
	if not allow() or not targetPos then
		return
	end
	local tint = color or Color3.fromRGB(255, 220, 160)
	if heroId == "Warrior" then
		local slash = ghost(Vector3.new(0.2, 2.4, 2.4), tint, CFrame.new(targetPos + Vector3.new(0, 1.2, 0)), Enum.PartType.Cylinder)
		slash.CFrame = CFrame.new(targetPos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(80))
		TweenService:Create(slash, TweenInfo.new(0.18), { Transparency = 1, Size = slash.Size * 1.35 }):Play()
		Debris:AddItem(slash, 0.22)
	elseif heroId == "Mage" then
		local origin = (fromPos or targetPos) + Vector3.new(0, 1.6, 0)
		local bolt = ghost(Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(120, 170, 255), CFrame.new(origin), Enum.PartType.Ball)
		TweenService:Create(bolt, TweenInfo.new(0.16, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(targetPos + Vector3.new(0, 1.2, 0)),
			Transparency = 0.15,
		}):Play()
		Debris:AddItem(bolt, 0.2)
	else
		local origin = (fromPos or targetPos) + Vector3.new(0, 1.5, 0)
		local aim = targetPos + Vector3.new(0, 1.2, 0)
		local delta = aim - origin
		local length = math.max(0.4, delta.Magnitude)
		local arrow = ghost(Vector3.new(0.12, 0.12, length), Color3.fromRGB(230, 220, 170), CFrame.lookAt(origin, aim) * CFrame.new(0, 0, -length * 0.5))
		TweenService:Create(arrow, TweenInfo.new(0.12), { Transparency = 1 }):Play()
		Debris:AddItem(arrow, 0.16)
	end
end

function CombatFx.Ring(position, color, radius, life)
	if not allow() then
		return nil
	end
	local ring = ghost(Vector3.new(0.35, radius, radius), color, CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	ring.Transparency = 0.4
	TweenService:Create(ring, TweenInfo.new(life or 0.28), { Transparency = 1, Size = ring.Size * 1.15 }):Play()
	Debris:AddItem(ring, life or 0.3)
	return ring
end

function CombatFx.Burst(position, color, size, life)
	if not allow() then
		return nil
	end
	local piece = ghost(size, color, CFrame.new(position), Enum.PartType.Ball)
	TweenService:Create(piece, TweenInfo.new(life or 0.25), { Transparency = 1, Size = size * 1.4 }):Play()
	Debris:AddItem(piece, life or 0.28)
	return piece
end

function CombatFx.NamedAura(character, name, color, size)
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local existing = character:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local aura = ghost(size, color, root.CFrame, Enum.PartType.Ball)
	aura.Name = name
	aura.Transparency = 0.55
	aura.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = aura
	weld.Parent = aura
	aura.Parent = character
	Debris:AddItem(aura, 6.2)
end

return CombatFx
