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

local function stepGrave(actor, model, now)
	local motors = actor.motors
	local state = model:GetAttribute("KurkitoState") or "Idle"
	local behavior = model:GetAttribute("KurkitoBehavior") or ""
	local move = model:GetAttribute("KurkitoMove") or ""
	local synced = workspace:GetServerTimeNow()
	local age = synced - (model:GetAttribute("KurkitoSwing") or synced)
	local strike = math.sin(math.clamp(age / 0.48, 0, 1) * math.pi)
	if state == "Dead" or state == "Respawning" then
		pose(motors.ArmL, math.rad(80), 0, math.rad(24))
		pose(motors.ArmR, math.rad(80), 0, math.rad(-24))
		pose(motors.LegL, math.rad(28), 0, 0)
		pose(motors.LegR, math.rad(-8), 0, 0)
		pose(motors.Head, math.rad(40), 0, 0)
		pose(motors.Torso, math.rad(30), 0, 0)
		return
	end
	local hitAge = synced - (model:GetAttribute("KurkitoHitAt") or 0)
	if hitAge >= 0 and hitAge < 0.16 then
		pose(motors.Head, math.rad(22), 0, math.rad(8))
		pose(motors.Torso, math.rad(14), 0, 0)
		return
	end
	if state == "Attacking" then
		if move == "leap" then
			pose(motors.ArmL, math.rad(-70) * strike, 0, math.rad(-20))
			pose(motors.ArmR, math.rad(-80) * strike, 0, math.rad(16))
			pose(motors.Torso, math.rad(-20) * strike, 0, 0)
			pose(motors.LegL, math.rad(30) * strike, 0, 0)
			pose(motors.LegR, math.rad(-10) * strike, 0, 0)
		elseif move == "bash" then
			pose(motors.ArmL, math.rad(-50) * strike, math.rad(30) * strike, 0)
			pose(motors.Shield, 0, 0, math.rad(-25) * strike)
			pose(motors.Torso, 0, math.rad(-18) * strike, 0)
		elseif move == "smash" or move == "slam" then
			local heavy = math.sin(math.clamp(age / 0.7, 0, 1) * math.pi)
			pose(motors.ArmL, math.rad(-120) * heavy, 0, math.rad(-10))
			pose(motors.ArmR, math.rad(-130) * heavy, 0, math.rad(10))
			pose(motors.Torso, math.rad(16) * heavy, 0, 0)
			pose(motors.Totem, math.rad(-30) * heavy, 0, 0)
		elseif move == "claw" then
			local side = math.sin(now * 18) > 0
			pose(motors.ArmL, side and math.rad(-75) * strike or math.rad(20), 0, math.rad(-30) * strike)
			pose(motors.ArmR, side and math.rad(15) or math.rad(-85) * strike, 0, math.rad(28) * strike)
			pose(motors.Torso, math.rad(10) * strike, math.rad(side and -16 or 16), 0)
		elseif move == "roar" or move == "summon" then
			pose(motors.ArmL, math.rad(-80) * strike, 0, math.rad(-30))
			pose(motors.ArmR, math.rad(-80) * strike, 0, math.rad(30))
			pose(motors.Head, math.rad(-28) * strike, 0, 0)
			pose(motors.Torso, math.rad(-12) * strike, 0, 0)
		elseif move == "charge" then
			pose(motors.Torso, math.rad(22), 0, 0)
			pose(motors.ArmL, math.rad(30), 0, math.rad(-16))
			pose(motors.ArmR, math.rad(30), 0, math.rad(16))
			pose(motors.LegL, math.rad(24) * strike, 0, 0)
			pose(motors.LegR, math.rad(-24) * strike, 0, 0)
		elseif move == "recover" then
			pose(motors.Torso, math.rad(28), 0, 0)
			pose(motors.ArmL, math.rad(55), 0, math.rad(-18))
			pose(motors.ArmR, math.rad(55), 0, math.rad(18))
			pose(motors.Head, math.rad(18), 0, 0)
			pose(motors.LegL, math.rad(22), 0, 0)
			pose(motors.LegR, math.rad(16), 0, 0)
		else
			pose(motors.ArmR, math.rad(-65) * strike, 0, math.rad(20) * strike)
			pose(motors.ArmL, math.rad(-20) * strike, 0, 0)
			pose(motors.Head, math.rad(-8) * strike, 0, 0)
		end
		return
	end
	local moving = state == "Chasing" or state == "Returning" or state == "Aggro"
	local pace = 2.2
	if behavior == "scavenger" then
		pace = moving and 11 or 3.4
	elseif behavior == "bonewalker" or behavior == "chieftain" then
		pace = moving and 4.2 or 1.3
	elseif behavior == "rotfang" then
		pace = move == "lunge" and 12 or (moving and 5 or 2)
	end
	local swing = math.sin(now * pace + actor.phase)
	local crouch = 0
	if behavior == "rotfang" and move == "stalk" then
		crouch = math.rad(16)
	elseif behavior == "scavenger" then
		crouch = math.rad(8)
	end
	pose(motors.Torso, crouch + (moving and 0 or math.rad(2) * math.sin(now * 1.4 + actor.phase)), 0, 0)
	pose(motors.ArmL, math.rad(behavior == "bonewalker" and 18 or 28) * swing, 0, math.rad(-8))
	pose(motors.ArmR, math.rad(-26) * swing, 0, math.rad(8))
	pose(motors.Head, math.rad(behavior == "scavenger" and 8 or 3) * math.sin(now * (behavior == "scavenger" and 3.2 or 1.2) + actor.phase), 0, 0)
	local step = moving and swing or math.sin(now * 1.3 + actor.phase) * 0.2
	pose(motors.LegL, math.rad(behavior == "bonewalker" and 16 or 30) * step, 0, 0)
	pose(motors.LegR, math.rad(behavior == "bonewalker" and -16 or -30) * step, 0, 0)
	pose(motors.Jaw, math.rad(6) * math.sin(now * 2 + actor.phase), 0, 0)
end

local function stepEnemy(actor, model, now)
	if (model:GetAttribute("KurkitoBehavior") or "") ~= "" then
		stepGrave(actor, model, now)
		return
	end
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
		local synced = workspace:GetServerTimeNow()
		local jab = math.clamp((synced - (model:GetAttribute("KurkitoSwing") or synced)) * 6, 0, 1)
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

local heroRigs = {}

local function findMotor(character, names)
	for _, name in ipairs(names) do
		local found = character:FindFirstChild(name, true)
		if found and found:IsA("Motor6D") then
			return found
		end
	end
	return nil
end

local function heroRig(character)
	local cached = heroRigs[character]
	if not cached then
		cached = {}
		heroRigs[character] = cached
	end
	cached.shoulderR = findMotor(character, { "RightShoulder", "Right Shoulder" })
	cached.shoulderL = findMotor(character, { "LeftShoulder", "Left Shoulder" })
	cached.hipR = findMotor(character, { "RightHip", "Right Hip" })
	cached.hipL = findMotor(character, { "LeftHip", "Left Hip" })
	cached.neck = findMotor(character, { "Neck" })
	cached.waist = findMotor(character, { "Waist", "RootJoint" })
	cached.weapon = character:FindFirstChild("WeaponMotor", true)
	cached.root = character:FindFirstChild("HumanoidRootPart")
	cached.humanoid = character:FindFirstChildOfClass("Humanoid")
	return cached
end

local function stepWarrior(character, now)
	local rig = heroRig(character)
	local humanoid = rig.humanoid
	if humanoid and humanoid.Health <= 0 then
		pose(rig.shoulderR, math.rad(70), 0, 0)
		pose(rig.shoulderL, math.rad(70), 0, 0)
		pose(rig.hipR, math.rad(20), 0, 0)
		pose(rig.hipL, math.rad(10), 0, 0)
		pose(rig.waist, math.rad(40), 0, 0)
		pose(rig.neck, math.rad(30), 0, 0)
		pose(rig.weapon, math.rad(40), 0, 0)
		return
	end
	local synced = workspace:GetServerTimeNow()
	local stunnedUntil = character:GetAttribute("KurkitoStunnedUntil") or 0
	if stunnedUntil > synced and synced > stunnedUntil - 3 then
		local wobble = math.sin(now * 9)
		pose(rig.waist, math.rad(18), math.rad(12) * wobble, 0)
		pose(rig.neck, math.rad(22), math.rad(8) * wobble, 0)
		pose(rig.shoulderR, math.rad(46), 0, math.rad(12))
		pose(rig.shoulderL, math.rad(40), 0, math.rad(-10))
		pose(rig.hipR, math.rad(8), 0, 0)
		pose(rig.hipL, math.rad(6), 0, 0)
		pose(rig.weapon, math.rad(24), 0, 0)
		return
	end
	local hitAt = character:GetAttribute("KurkitoHitAt") or 0
	if hitAt > 0 and synced - hitAt < 0.28 then
		local flinch = math.sin(math.clamp((synced - hitAt) / 0.28, 0, 1) * math.pi)
		pose(rig.waist, math.rad(16) * flinch, 0, 0)
		pose(rig.neck, math.rad(18) * flinch, 0, 0)
		pose(rig.shoulderR, math.rad(24) * flinch, 0, 0)
		pose(rig.shoulderL, math.rad(20) * flinch, 0, 0)
		return
	end
	local victoryAt = character:GetAttribute("KurkitoVictory") or 0
	if victoryAt > 0 and synced - victoryAt < 1.7 and (character:GetAttribute("KurkitoSwing") or 0) < victoryAt then
		local rise = math.clamp((synced - victoryAt) / 0.35, 0, 1)
		pose(rig.shoulderR, math.rad(-130) * rise, 0, math.rad(16))
		pose(rig.shoulderL, math.rad(-120) * rise, 0, math.rad(-16))
		pose(rig.weapon, math.rad(-20) * rise, 0, 0)
		pose(rig.waist, math.rad(-6) * rise, 0, 0)
		return
	end
	local swingAt = character:GetAttribute("KurkitoSwing") or 0
	local kind = character:GetAttribute("KurkitoSwingKind") or ""
	if swingAt > 0 then
		local age = synced - swingAt
		local window = kind == "spinning_slash" and 0.78 or (kind == "smash" and 0.72 or 0.64)
		if age >= 0 and age <= window then
			local t = math.clamp(age / window, 0, 1)
			local stage = "recover"
			local amount = 0
			if t < 0.22 then
				stage = "windup"
				amount = t / 0.22
			elseif t < 0.48 then
				stage = "swing"
				amount = (t - 0.22) / 0.26
			elseif t < 0.62 then
				stage = "impact"
				amount = 1
			elseif t < 0.82 then
				stage = "follow"
				amount = 1 - ((t - 0.62) / 0.2)
			else
				stage = "recover"
				amount = 1 - ((t - 0.82) / 0.18)
			end
			local power = stage == "windup" and amount or (stage == "recover" and math.max(0, amount) or 1)
			if kind == "steel_skin" then
				pose(rig.shoulderR, math.rad(-18) * power, 0, math.rad(-48) * power)
				pose(rig.shoulderL, math.rad(-18) * power, 0, math.rad(48) * power)
				pose(rig.waist, math.rad(6) * power, 0, 0)
				pose(rig.weapon, math.rad(16) * power, 0, 0)
				pose(rig.neck, math.rad(-6) * power, 0, 0)
			elseif kind == "fury" then
				pose(rig.shoulderR, math.rad(-100) * power, 0, math.rad(18))
				pose(rig.shoulderL, math.rad(-100) * power, 0, math.rad(-18))
				pose(rig.waist, math.rad(-10) * power, 0, 0)
				pose(rig.weapon, math.rad(-40) * power, 0, 0)
				pose(rig.hipR, math.rad(12) * power, 0, 0)
				pose(rig.hipL, math.rad(12) * power, 0, 0)
			elseif kind == "spinning_slash" or kind == "smash" then
				local lift = stage == "windup" and -0.35 * amount or (stage == "swing" and (-0.35 + 1.2 * amount) or (stage == "impact" and 0.9 or 0.35 * power))
				pose(rig.shoulderR, math.rad(-130) * lift, 0, math.rad(16))
				pose(rig.shoulderL, math.rad(-40) * power, 0, math.rad(-12))
				pose(rig.waist, math.rad(22) * (stage == "windup" and amount or power), math.rad(kind == "spinning_slash" and 70 or 28) * power, 0)
				pose(rig.weapon, math.rad(-70) * lift, 0, math.rad(18) * power)
				pose(rig.hipR, math.rad(16) * power, 0, 0)
				pose(rig.hipL, math.rad(-8) * power, 0, 0)
				pose(rig.neck, math.rad(stage == "impact" and 10 or -4), 0, 0)
			elseif kind == "attack2" then
				local sweep = stage == "windup" and -0.4 * amount or (stage == "swing" and (-0.2 + amount) or power)
				pose(rig.shoulderR, math.rad(-70) * sweep, math.rad(30) * power, math.rad(24) * power)
				pose(rig.shoulderL, math.rad(20) * power, 0, math.rad(-16))
				pose(rig.waist, math.rad(8) * power, math.rad(-36) * sweep, 0)
				pose(rig.weapon, math.rad(-30) * sweep, 0, math.rad(20) * power)
				pose(rig.hipR, math.rad(14) * power, 0, 0)
				pose(rig.hipL, math.rad(-10) * power, 0, 0)
			else
				local sweep = stage == "windup" and -0.45 * amount or (stage == "swing" and amount or power * 0.4)
				pose(rig.shoulderR, math.rad(-90) * sweep, 0, math.rad(20) * power)
				pose(rig.shoulderL, math.rad(-16) * power, 0, math.rad(-8))
				pose(rig.waist, math.rad(12) * power, math.rad(24) * sweep, 0)
				pose(rig.weapon, math.rad(-48) * sweep, 0, math.rad(10) * power)
				pose(rig.hipR, math.rad(10) * power, 0, 0)
				pose(rig.hipL, math.rad(-6) * power, 0, 0)
				pose(rig.neck, math.rad(stage == "impact" and 8 or 0), 0, 0)
			end
			return
		end
	end
	if not rig.readyAt then
		rig.readyAt = now
	end
	if now - rig.readyAt < 1.05 then
		local plant = math.clamp((now - rig.readyAt) / 1.05, 0, 1)
		pose(rig.shoulderR, math.rad(28) * plant, 0, math.rad(10))
		pose(rig.weapon, math.rad(-12) * plant, 0, 0)
		pose(rig.waist, math.rad(4) * math.sin(plant * math.pi), 0, 0)
		return
	end
	local root = rig.root
	local horizontal = 0
	if root then
		local velocity = root.AssemblyLinearVelocity
		horizontal = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	end
	local moving = horizontal > 1.4
	local running = horizontal > 16
	if not moving and character:GetAttribute("KurkitoCombat") == true then
		local brace = math.sin(now * 2.2)
		pose(rig.waist, math.rad(10), math.rad(8), 0)
		pose(rig.shoulderR, math.rad(-36) + math.rad(4) * brace, 0, math.rad(18))
		pose(rig.shoulderL, math.rad(12), 0, math.rad(-14))
		pose(rig.weapon, math.rad(-22), 0, math.rad(8))
		pose(rig.hipR, math.rad(12), 0, 0)
		pose(rig.hipL, math.rad(8), 0, 0)
		pose(rig.neck, math.rad(-4), 0, 0)
		return
	end
	if running then
		local step = math.sin(now * 12)
		pose(rig.waist, math.rad(14), 0, math.rad(4) * step)
		pose(rig.hipR, math.rad(36) * step, 0, 0)
		pose(rig.hipL, math.rad(-36) * step, 0, 0)
		pose(rig.shoulderR, math.rad(-24) * step, 0, math.rad(8))
		pose(rig.shoulderL, math.rad(24) * step, 0, math.rad(-8))
		pose(rig.weapon, math.rad(-8) * step, 0, 0)
		pose(rig.neck, math.rad(6), 0, 0)
	elseif moving then
		local step = math.sin(now * 7)
		pose(rig.waist, math.rad(6), 0, 0)
		pose(rig.hipR, math.rad(24) * step, 0, 0)
		pose(rig.hipL, math.rad(-24) * step, 0, 0)
		pose(rig.shoulderR, math.rad(16) * step, 0, math.rad(8))
		pose(rig.shoulderL, math.rad(-12) * step, 0, 0)
		pose(rig.weapon, math.rad(6) * step, 0, 0)
		pose(rig.neck, math.rad(3) * math.sin(now * 2), 0, 0)
	else
		local breathe = math.sin(now * 1.5)
		pose(rig.waist, math.rad(2) * breathe, 0, 0)
		pose(rig.neck, math.rad(-3) + math.rad(2) * breathe, math.sin(now * 0.6) * 0.08, 0)
		pose(rig.shoulderR, math.rad(16) + math.rad(3) * breathe, 0, math.rad(10))
		pose(rig.shoulderL, math.rad(8), 0, math.rad(-6))
		pose(rig.weapon, math.rad(-6) * breathe, 0, 0)
		pose(rig.hipR, 0, 0, 0)
		pose(rig.hipL, 0, 0, 0)
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
	local age = workspace:GetServerTimeNow() - swingAt
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
	local synced = workspace:GetServerTimeNow()
	if not hitAt or actor.lastHit == hitAt or synced - hitAt > 0.16 then
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
		for character in pairs(heroRigs) do
			if not character.Parent then
				heroRigs[character] = nil
			end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character and character.Parent then
				stepWarrior(character, clock)
			end
		end
	end)
end

return Motion
