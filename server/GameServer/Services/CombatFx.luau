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
	character:SetAttribute("KurkitoSwing", workspace:GetServerTimeNow())
	character:SetAttribute("KurkitoSwingKind", kind or "Attack")
end

function CombatFx.BasicHit(player, heroId, fromPos, targetPos, color, kind)
	CombatFx.MarkSwing(player, kind or "attack1")
	if not allow() or not targetPos then
		return
	end
	local tint = color or Color3.fromRGB(255, 220, 160)
	heroId = "Warrior"
	if heroId == "Warrior" then
		local impact = targetPos + Vector3.new(0, 1.6, 0)
		local heavy = kind == "smash"
		local arc = ghost(Vector3.new(heavy and 0.6 or 0.35, heavy and 4.8 or 3.2, heavy and 4.8 or 3.2), Color3.fromRGB(214, 176, 120), CFrame.new(impact) * CFrame.Angles(0, 0, math.rad(heavy and 80 or 68)), Enum.PartType.Cylinder)
		arc.Transparency = 0.28
		TweenService:Create(arc, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = arc.Size * 1.45,
		}):Play()
		Debris:AddItem(arc, 0.32)
		local dust = ghost(Vector3.new(0.2, 2.6, 2.6), Color3.fromRGB(140, 108, 72), CFrame.new(targetPos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
		dust.Transparency = 0.4
		TweenService:Create(dust, TweenInfo.new(0.32), { Transparency = 1, Size = dust.Size * 1.6 }):Play()
		Debris:AddItem(dust, 0.36)
		local spark = ghost(Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(255, 214, 150), CFrame.new(impact), Enum.PartType.Ball)
		TweenService:Create(spark, TweenInfo.new(0.16), { Transparency = 1, Size = spark.Size * 1.8 }):Play()
		Debris:AddItem(spark, 0.2)
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

function CombatFx.Strike(move, fromPos, targetPos, color)
	if not allow() or not targetPos then
		return
	end
	local tint = color or Color3.fromRGB(170, 255, 120)
	local impact = targetPos + Vector3.new(0, 1.5, 0)
	local origin = fromPos or targetPos
	if move == "smash" or move == "slam" then
		local arc = ghost(Vector3.new(0.55, 4.2, 4.2), Color3.fromRGB(255, 140, 50), CFrame.new(impact) * CFrame.Angles(math.rad(80), 0, 0), Enum.PartType.Cylinder)
		arc.Transparency = 0.25
		TweenService:Create(arc, TweenInfo.new(0.32), { Transparency = 1, Size = arc.Size * 1.3 }):Play()
		Debris:AddItem(arc, 0.36)
		CombatFx.Ring(targetPos, Color3.fromRGB(255, 120, 40), move == "slam" and 14 or 8, 0.35)
	elseif move == "bash" then
		local shock = ghost(Vector3.new(0.3, 2.8, 2.8), Color3.fromRGB(230, 210, 170), CFrame.new(impact), Enum.PartType.Ball)
		TweenService:Create(shock, TweenInfo.new(0.22), { Transparency = 1, Size = shock.Size * 1.5 }):Play()
		Debris:AddItem(shock, 0.26)
	elseif move == "leap" or move == "charge" then
		local delta = impact - origin
		local length = math.max(1, delta.Magnitude)
		local streak = ghost(Vector3.new(0.35, 0.35, length), tint, CFrame.lookAt(origin + Vector3.new(0, 1, 0), impact) * CFrame.new(0, 0, -length * 0.5))
		TweenService:Create(streak, TweenInfo.new(0.18), { Transparency = 1 }):Play()
		Debris:AddItem(streak, 0.22)
	elseif move == "roar" or move == "summon" then
		CombatFx.Ring(origin, move == "roar" and Color3.fromRGB(255, 80, 40) or Color3.fromRGB(120, 255, 90), move == "roar" and 16 or 10, 0.4)
		if move == "summon" then
			for index = 1, 3 do
				local ghostBody = ghost(Vector3.new(0.8, 1.8, 0.6), Color3.fromRGB(80, 160, 70), CFrame.new(origin + Vector3.new(-2 + index * 1.4, 0.2, -1.5)), Enum.PartType.Block)
				ghostBody.Transparency = 0.45
				TweenService:Create(ghostBody, TweenInfo.new(0.45), {
					Transparency = 1,
					CFrame = ghostBody.CFrame + Vector3.new(0, 2.2, 0),
				}):Play()
				Debris:AddItem(ghostBody, 0.5)
			end
		end
	elseif move == "claw" then
		local slash = ghost(Vector3.new(0.16, 2.2, 1.4), tint, CFrame.new(impact) * CFrame.Angles(0.4, 0.6, 0.8))
		TweenService:Create(slash, TweenInfo.new(0.14), { Transparency = 1, Size = slash.Size * 1.3 }):Play()
		Debris:AddItem(slash, 0.18)
	elseif move ~= "recover" then
		local swipe = ghost(Vector3.new(0.16, 2.2, 2.2), tint, CFrame.new(impact) * CFrame.Angles(0, 0, math.rad(75)), Enum.PartType.Cylinder)
		swipe.Transparency = 0.35
		TweenService:Create(swipe, TweenInfo.new(0.16), { Transparency = 1 }):Play()
		Debris:AddItem(swipe, 0.2)
	end
end

function CombatFx.Telegraph(position, color, radius, life)
	if not position then
		return nil
	end
	local ring = ghost(Vector3.new(0.18, math.max(2, radius * 2), math.max(2, radius * 2)), color or Color3.fromRGB(255, 90, 40), CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.72
	TweenService:Create(ring, TweenInfo.new(life or 0.4), { Transparency = 0.35 }):Play()
	Debris:AddItem(ring, (life or 0.4) + 0.05)
	return ring
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
