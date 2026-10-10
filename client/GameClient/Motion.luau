-- Animazioni procedurali locali. Non replicano Transform e non comandano il movimento.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Motion = {}

local actors = {}
local near = {}
local heroSwing = {}
local clock = 0

local function hash(name)
	local value = 0
	for index = 1, #name do
		value = (value + string.byte(name, index) * index) % 997
	end
	return value / 997 * math.pi * 2
end

local function motorsOf(model)
	local found = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant:GetAttribute("Animate") == true then
			found[descendant.Name] = descendant
		end
	end
	return found
end

local function track(model)
	if actors[model] then
		return
	end
	actors[model] = {
		motors = motorsOf(model),
		phase = hash(model.Name),
		lastSwing = 0,
	}
end

local function forget(model)
	actors[model] = nil
end

local function pose(motor, pitch, yaw, roll)
	if motor then
		motor.Transform = CFrame.Angles(pitch or 0, yaw or 0, roll or 0)
	end
end

local function stepEnemy(actor, model, now)
	local motors = actor.motors
	local state = model:GetAttribute("KurkitoState") or "Idle"
	local moving = state == "Chasing" or state == "Returning" or state == "Aggro"
	local speed = moving and 8 or 2.2
	local swing = math.sin(now * speed + actor.phase)
	if state == "Dead" or state == "Respawning" then
		pose(motors.ArmL, math.rad(70), 0, math.rad(20))
		pose(motors.ArmR, math.rad(70), 0, math.rad(-20))
		pose(motors.LegL, math.rad(20), 0, 0)
		pose(motors.LegR, math.rad(-10), 0, 0)
		pose(motors.Head, math.rad(30), 0, 0)
		return
	end
	if state == "Attacking" then
		local jab = math.clamp((now - (model:GetAttribute("KurkitoSwing") or 0)) * 6, 0, 1)
		local strike = math.sin(math.min(jab, 1) * math.pi)
		pose(motors.ArmR, math.rad(-80) * strike, 0, 0)
		pose(motors.ArmL, math.rad(-30) * strike, 0, 0)
		pose(motors.Head, math.rad(-8), 0, 0)
	else
		pose(motors.ArmL, math.rad(22) * swing, 0, 0)
		pose(motors.ArmR, math.rad(-22) * swing, 0, 0)
		pose(motors.Head, math.rad(4) * math.sin(now * 1.5 + actor.phase), 0, 0)
	end
	local step = moving and swing or math.sin(now * 1.4 + actor.phase) * 0.25
	pose(motors.LegL, math.rad(28) * step, 0, 0)
	pose(motors.LegR, math.rad(-28) * step, 0, 0)
	pose(motors.LegFL, math.rad(24) * step, 0, 0)
	pose(motors.LegFR, math.rad(-24) * step, 0, 0)
	pose(motors.LegBL, math.rad(-24) * step, 0, 0)
	pose(motors.LegBR, math.rad(24) * step, 0, 0)
	for index = 1, 4 do
		local wave = math.sin(now * speed + index + actor.phase)
		pose(motors["LegL" .. index], 0, math.rad(12) * wave, math.rad(8) * wave)
		pose(motors["LegR" .. index], 0, math.rad(-12) * wave, math.rad(-8) * wave)
	end
	pose(motors.WingL, math.rad(18) * math.sin(now * 3 + actor.phase), 0, 0)
	pose(motors.WingR, math.rad(-18) * math.sin(now * 3 + actor.phase), 0, 0)
	pose(motors.Torso, moving and 0 or math.rad(2) * math.sin(now * 1.6 + actor.phase), 0, 0)
	if model:GetAttribute("KurkitoActor") == "Pet" then
		pose(motors.Torso, math.rad(8) * math.sin(now * 2 + actor.phase), 0, 0)
	end
end

local function stepHero(character, now)
	local swingAt = character:GetAttribute("KurkitoSwing") or 0
	if swingAt <= 0 then
		return
	end
	local state = heroSwing[character]
	if not state or state.at ~= swingAt then
		state = { at = swingAt, done = false }
		heroSwing[character] = state
	end
	local motor = character:FindFirstChild("WeaponMotor", true)
	local shoulder = character:FindFirstChild("RightShoulder", true) or character:FindFirstChild("Right Shoulder", true)
	local age = now - swingAt
	if age > 0.45 then
		if not state.done then
			state.done = true
			if motor and motor:IsA("Motor6D") then
				motor.Transform = CFrame.new()
			end
			if shoulder and shoulder:IsA("Motor6D") then
				shoulder.Transform = CFrame.new()
			end
		end
		return
	end
	local strike = math.sin(math.clamp(age / 0.45, 0, 1) * math.pi)
	if motor and motor:IsA("Motor6D") then
		motor.Transform = CFrame.Angles(math.rad(-70) * strike, 0, math.rad(25) * strike)
	end
	if shoulder and shoulder:IsA("Motor6D") then
		shoulder.Transform = CFrame.Angles(math.rad(-55) * strike, 0, 0)
	end
end

local function flashHit(model, actor, now)
	local hitAt = model:GetAttribute("KurkitoHitAt")
	if not hitAt or actor.lastHit == hitAt or now - hitAt > 0.16 then
		return
	end
	actor.lastHit = hitAt
	local highlight = Instance.new("Highlight")
	highlight.Name = "HitFlash"
	highlight.FillColor = Color3.fromRGB(255, 240, 220)
	highlight.OutlineTransparency = 1
	highlight.FillTransparency = 0.4
	highlight.Parent = model
	task.delay(0.14, function()
		if highlight.Parent then
			highlight:Destroy()
		end
	end)
end

local function cullEmitters(model, distance)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			local base = descendant:GetAttribute("KurkitoBaseRate")
			if base == nil then
				descendant:SetAttribute("KurkitoBaseRate", descendant.Rate)
				base = descendant.Rate
			end
			if distance > 90 then
				if descendant.Rate ~= 0 then
					descendant.Rate = 0
				end
			elseif descendant.Rate ~= base then
				descendant.Rate = base
			end
		end
	end
end

function Motion.Start()
	CollectionService:GetInstanceAddedSignal("KurkitoMotion"):Connect(function(model)
		if model:IsA("Model") then
			track(model)
		end
	end)
	CollectionService:GetInstanceRemovedSignal("KurkitoMotion"):Connect(function(model)
		forget(model)
	end)
	for _, model in ipairs(CollectionService:GetTagged("KurkitoMotion")) do
		if model:IsA("Model") then
			track(model)
		end
	end

	local scan = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		scan += dt
		local camera = workspace.CurrentCamera
		local from = camera and camera.CFrame.Position or Vector3.zero
		if scan > 0.4 then
			scan = 0
			table.clear(near)
			for model, actor in pairs(actors) do
				if model.Parent then
					local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
					if root then
						local distance = (root.Position - from).Magnitude
						cullEmitters(model, distance)
						if distance < 110 then
							actor.motors = motorsOf(model)
							table.insert(near, model)
						end
					end
				else
					actors[model] = nil
				end
			end
		end
		for _, model in ipairs(near) do
			local actor = actors[model]
			if actor and model.Parent then
				stepEnemy(actor, model, clock)
				if model:GetAttribute("KurkitoActor") == "Enemy" then
					flashHit(model, actor, clock)
				end
			end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character and character:GetAttribute("KurkitoHero") then
				stepHero(character, clock)
			end
		end
	end)
end

return Motion
