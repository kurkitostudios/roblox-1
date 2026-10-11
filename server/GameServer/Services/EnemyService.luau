-- AI dei mostri a 5 Hz. Stati: Idle, Aggro, Chasing, Attacking, Returning, Dead, Respawning.
-- Oltre la distanza di leash parte un timer di 5 secondi. Poi il nemico torna
-- allo spawn e, finché è in Returning, ignora l'aggro.

local PhysicsService = game:GetService("PhysicsService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local shared = require(script.Parent.SharedLoader)
local EnemyConfig = shared("EnemyConfig")
local WorldLayout = shared("WorldLayout")
local GameConfig = shared("GameConfig")
local Rules = shared("Rules")
local WorldTextConfig = shared("WorldTextConfig")
local CreatureKit = require(script.Parent.CreatureKit)
local CombatFx = require(script.Parent.CombatFx)

local EnemyService = {}

local ctx
local enemies = {}
local byId = {}

local function ensureCollisionGroup()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("KurkitoEnemies")
	end)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable("KurkitoEnemies", "KurkitoEnemies", false)
	end)
end

local function effectsFolder()
	local world = workspace:FindFirstChild("KurkitoWorld")
	if not world then
		return workspace
	end
	return world:FindFirstChild("Effects") or world
end

local popupLive = 0

local function spawnDamagePopup(position, amount)
	if popupLive >= 24 then
		return
	end
	popupLive += 1
	local popup = Instance.new("Part")
	popup.Anchored = true
	popup.CanCollide = false
	popup.CanQuery = false
	popup.CanTouch = false
	popup.Transparency = 1
	popup.Size = Vector3.new(0.2, 0.2, 0.2)
	popup.Position = position + Vector3.new(math.random(-10, 10) / 10, 3.4, 0)
	popup.Parent = effectsFolder()
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(84, 32)
	billboard.StudsOffset = Vector3.new(0, 0.4, 0)
	billboard.Parent = popup
	WorldTextConfig.Mark(billboard, "DamageNumber")
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = amount >= 40 and Color3.fromRGB(255, 196, 96) or Color3.fromRGB(255, 236, 214)
	label.TextStrokeColor3 = Color3.fromRGB(48, 28, 16)
	label.TextStrokeTransparency = 0.2
	label.Text = tostring(amount)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(48, 28, 16)
	stroke.Thickness = 1.4
	stroke.Parent = label
	label.Parent = billboard
	TweenService:Create(popup, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = popup.Position + Vector3.new(0, 2.1, 0),
	}):Play()
	task.delay(0.65, function()
		popupLive = math.max(0, popupLive - 1)
		if popup.Parent then
			popup:Destroy()
		end
	end)
end

local function playerRoot(player)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return root, humanoid
end

function EnemyService.Start(context)
	ctx = context
	ensureCollisionGroup()
	local world = workspace:FindFirstChild("KurkitoWorld")
	local parent = world and world:FindFirstChild("Enemies")
	if parent then
		parent:ClearAllChildren()
	end
	table.clear(enemies)
	table.clear(byId)
	for arenaIndex = 1, 1 do
		local center = WorldLayout.ArenaCenter(arenaIndex)
		for _, spawn in ipairs(EnemyConfig.SpawnPlan(arenaIndex)) do
			local offset = EnemyConfig.SpawnOffset(spawn.slot, spawn.boss)
			local def = spawn.def
			local hip = CreatureKit.Hip(def)
			local position = Vector3.new(center.X + offset.X, 1 + hip, center.Z + offset.Z)
			local id = string.format("a%d_s%d", arenaIndex, spawn.slot)
			local model, humanoid, root, align = CreatureKit.Build(def, position)
			model.Name = "Enemy_" .. id
			model.Parent = parent or workspace
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
			local record = {
				id = id,
				def = def,
				arenaIndex = arenaIndex,
				model = model,
				humanoid = humanoid,
				root = root,
				align = align,
				spawnPosition = position,
				state = "Idle",
				target = nil,
				stateSince = os.clock(),
				leashStartedAt = nil,
				lastAttack = 0,
				nextAttack = 0,
				attackIndex = 0,
				pending = nil,
				damageByUserId = {},
				lastHitUserId = nil,
				rewarded = false,
				generation = 1,
			}
			local generation = record.generation
			humanoid.Died:Connect(function()
				if record.generation == generation then
					EnemyService.Kill(record)
				end
			end)
			table.insert(enemies, record)
			byId[id] = record
		end
	end
	print("[Kurkito] Nemici generati: " .. tostring(#enemies))
end

function EnemyService.GetAlive()
	return enemies
end

function EnemyService.ClearPlayer(player)
	for _, enemy in ipairs(enemies) do
		if enemy.target == player then
			enemy.target = nil
			if enemy.state == "Aggro" or enemy.state == "Chasing" or enemy.state == "Attacking" then
				enemy.state = "Idle"
			end
		end
		enemy.damageByUserId[player.UserId] = nil
		if enemy.lastHitUserId == player.UserId then
			enemy.lastHitUserId = nil
		end
	end
end

local function targetAllowed(player, arenaIndex)
	local dataService = ctx and ctx.services.PlayerDataService
	if not player or not dataService or not dataService.IsLoaded(player) then
		return false
	end
	local data = dataService.Get(player)
	if not data or data.selectedHero == "" then
		return false
	end
	local hero = data.heroes.Warrior
	return hero ~= nil and hero.unlockedArenas[tostring(arenaIndex)] == true
end

local function nearestPlayer(origin, radius, arenaIndex)
	local Players = game:GetService("Players")
	local best = nil
	local bestDistance = radius
	for _, player in ipairs(Players:GetPlayers()) do
		local root = playerRoot(player)
		if root and targetAllowed(player, arenaIndex) then
			local distance = (root.Position - origin).Magnitude
			if distance <= bestDistance then
				best = player
				bestDistance = distance
			end
		end
	end
	return best, bestDistance
end

local function setState(enemy, state)
	if enemy.state ~= state then
		enemy.state = state
		enemy.stateSince = os.clock()
		if enemy.model then
			enemy.model:SetAttribute("KurkitoState", state)
		end
	end
end

local function faceTarget(enemy, targetPosition)
	local align = enemy.align
	local root = enemy.root
	if not align or not root then
		return
	end
	local flat = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
	if (flat - root.Position).Magnitude < 1.25 then
		align.Enabled = false
		return
	end
	align.Enabled = true
	align.CFrame = CFrame.lookAt(root.Position, flat)
end

local function releaseFacing(enemy)
	if enemy.align then
		enemy.align.Enabled = false
	end
end

local function nudgeAroundObstacle(enemy, targetPosition, now)
	local root = enemy.root
	local flat = targetPosition - root.Position
	flat = Vector3.new(flat.X, 0, flat.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	local side = Vector3.new(-flat.Z, 0, flat.X).Unit * 8 * (enemy.sideSign or 1)
	enemy.sideSign = -(enemy.sideSign or 1)
	enemy.humanoid:MoveTo(root.Position + side + flat.Unit * 6)
	if (enemy.stuck or 0) > 3.2 and now - (enemy.pathAt or 0) > 2.4 then
		enemy.pathAt = now
		local path = PathfindingService:CreatePath({
			AgentRadius = 2.2,
			AgentHeight = 5,
			AgentCanJump = false,
			WaypointSpacing = 8,
		})
		local ok = pcall(function()
			path:ComputeAsync(root.Position, targetPosition)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			local nextPoint = waypoints[2] or waypoints[1]
			if nextPoint then
				enemy.humanoid:MoveTo(nextPoint.Position)
				enemy.pathHold = now + 0.55
			end
		end
	end
end

function EnemyService.Respawn(enemy)
	local world = workspace:FindFirstChild("KurkitoWorld")
	local parent = world and world:FindFirstChild("Enemies")
	if not parent then
		return
	end
	enemy.generation += 1
	local generation = enemy.generation
	local previous = enemy.model
	local model, humanoid, root, align = CreatureKit.Build(enemy.def, enemy.spawnPosition)
	model.Name = "Enemy_" .. enemy.id
	model.Parent = parent
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	enemy.model = model
	enemy.humanoid = humanoid
	enemy.root = root
	enemy.align = align
	enemy.rewarded = false
	enemy.pending = nil
	enemy.attackIndex = 0
	enemy.nextAttack = 0
	enemy.damageByUserId = {}
	enemy.lastHitUserId = nil
	enemy.target = nil
	enemy.leashStartedAt = nil
	setState(enemy, "Idle")
	humanoid.Died:Connect(function()
		if enemy.generation == generation then
			EnemyService.Kill(enemy)
		end
	end)
	if previous then
		previous:Destroy()
	end
end

function EnemyService.Kill(enemy)
	if enemy.rewarded or enemy.state == "Respawning" then
		return
	end
	enemy.rewarded = true
	setState(enemy, "Dead")
	enemy.target = nil
	if enemy.humanoid then
		enemy.humanoid.WalkSpeed = 0
	end
	if enemy.root then
		enemy.root.Anchored = true
	end
	if enemy.def and enemy.def.behavior == "chieftain" then
		EnemyService.DismissSummons(enemy)
	end
	if enemy.noReward then
		enemy.expired = true
		task.delay(1.2, function()
			if enemy.model then
				enemy.model:Destroy()
			end
		end)
		return
	end
	if ctx and ctx.services.CombatService then
		ctx.services.CombatService.GrantRewards(enemy)
	end
	local fade = enemy.root.Color
	enemy.root.Color = fade:Lerp(Color3.new(0, 0, 0), 0.55)
	task.delay(enemy.def.respawn, function()
		if enemy.state == "Dead" then
			setState(enemy, "Respawning")
			EnemyService.Respawn(enemy)
		end
	end)
end

function EnemyService.Damage(enemy, player, amount)
	if enemy.rewarded or enemy.state == "Dead" or enemy.state == "Respawning" then
		return
	end
	if not player or player.Parent == nil then
		return
	end
	amount = math.floor(amount + 0.5)
	if amount < 1 then
		amount = 1
	end
	enemy.damageByUserId[player.UserId] = (enemy.damageByUserId[player.UserId] or 0) + amount
	enemy.lastHitUserId = player.UserId
	enemy.humanoid.Health -= amount
	if enemy.model then
		enemy.model:SetAttribute("KurkitoHitAt", workspace:GetServerTimeNow())
	end
	spawnDamagePopup(enemy.root.Position, amount)
	if enemy.humanoid.Health <= 0 then
		EnemyService.Kill(enemy)
	end
end

local function windupFor(move)
	if move == "smash" or move == "slam" then
		return 0.42
	elseif move == "roar" or move == "summon" then
		return 0.4
	elseif move == "bash" or move == "charge" then
		return 0.28
	elseif move == "leap" then
		return 0.22
	elseif move == "claw" then
		return 0.14
	end
	return 0.16
end

local function cooldownFor(enemy, move)
	local base = enemy.def.interval
	if move == "smash" then
		return base * 1.35
	elseif move == "bash" then
		return base * 1.1
	elseif move == "claw" then
		return 0.4
	elseif move == "recover" then
		return 1.05
	elseif move == "roar" or move == "summon" then
		return 1.9
	elseif move == "slam" or move == "charge" then
		return 1.55
	elseif move == "leap" then
		return base * 0.95
	end
	return base
end

local function damageFor(enemy, move)
	local amount = enemy.def.dmg
	if move == "recover" then
		return 0
	elseif move == "smash" then
		return amount * 1.35
	elseif move == "slam" then
		return amount * 1.45
	elseif move == "charge" then
		return amount * 1.25
	elseif move == "claw" then
		if (enemy.attackIndex or 1) % 4 == 3 then
			return amount * 1.15
		end
		return amount * 0.7
	elseif move == "roar" then
		return amount * 0.5
	elseif move == "summon" then
		return 0
	elseif move == "leap" then
		return amount * 1.05
	end
	return amount
end

local function chooseMove(enemy)
	enemy.attackIndex = (enemy.attackIndex or 0) + 1
	local behavior = enemy.def.behavior
	local index = enemy.attackIndex
	if behavior == "scavenger" then
		return index % 3 == 0 and "leap" or "swipe"
	elseif behavior == "bonewalker" then
		return index % 2 == 0 and "smash" or "bash"
	elseif behavior == "rotfang" then
		if (index - 1) % 4 == 3 then
			return "recover"
		end
		return "claw"
	elseif behavior == "chieftain" then
		local cycle = { "roar", "slam", "summon", "charge" }
		return cycle[((index - 1) % #cycle) + 1]
	end
	return "swipe"
end

local function dashToward(enemy, targetPosition, distance)
	local flat = Vector3.new(targetPosition.X - enemy.root.Position.X, 0, targetPosition.Z - enemy.root.Position.Z)
	if flat.Magnitude < 2 then
		return
	end
	local step = math.min(distance, flat.Magnitude - 1.5)
	local dest = enemy.root.Position + flat.Unit * step
	enemy.root.CFrame = CFrame.new(dest, dest + flat)
end

local function strikeColor(enemy)
	local behavior = enemy.def.behavior
	if behavior == "bonewalker" then
		return Color3.fromRGB(230, 186, 120)
	elseif behavior == "chieftain" then
		return Color3.fromRGB(255, 96, 42)
	end
	return Color3.fromRGB(130, 255, 120)
end

local function chaseProfile(enemy, distance)
	local speed = enemy.def.speed
	local move = ""
	local behavior = enemy.def.behavior
	if behavior == "scavenger" then
		speed *= 1.12
		move = "run"
	elseif behavior == "bonewalker" then
		speed *= 0.76
		move = "march"
	elseif behavior == "rotfang" then
		if distance > 16 then
			speed *= 0.68
			move = "stalk"
		else
			speed *= 1.35
			move = "lunge"
		end
	elseif behavior == "chieftain" then
		speed *= 0.9
		move = "march"
	end
	return speed, move
end

local summonSerial = 0

function EnemyService.DismissSummons(boss)
	for _, enemy in ipairs(enemies) do
		if enemy.summonedBy == boss.id and not enemy.expired then
			enemy.expired = true
			enemy.rewarded = true
			enemy.target = nil
			setState(enemy, "Dead")
			if enemy.humanoid then
				enemy.humanoid.WalkSpeed = 0
			end
			if enemy.model then
				enemy.model:Destroy()
			end
		end
	end
end

local function countSummons(bossId)
	local alive = 0
	for _, enemy in ipairs(enemies) do
		if enemy.summonedBy == bossId and not enemy.expired and enemy.state ~= "Dead" then
			alive += 1
		end
	end
	return alive
end

function EnemyService.SummonDead(boss)
	if not boss or not boss.root or boss.def.behavior ~= "chieftain" then
		return 0
	end
	local limits = EnemyConfig.Summon
	local room = Rules.SummonRoom(countSummons(boss.id), limits.MaxActive, limits.PerCast)
	if room <= 0 then
		return 0
	end
	local world = workspace:FindFirstChild("KurkitoWorld")
	local parent = world and world:FindFirstChild("Enemies")
	if not parent then
		return 0
	end
	local def = EnemyConfig.RisenDead
	local spawned = 0
	for index = 1, room do
		local angle = (index / room) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 7, 0, math.sin(angle) * 7)
		local position = boss.root.Position + offset
		local center = WorldLayout.ArenaCenter(boss.arenaIndex)
		local flat = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
		if flat.Magnitude > WorldLayout.ArenaHalf() - 18 then
			position = center + flat.Unit * (WorldLayout.ArenaHalf() - 18)
		end
		position = Vector3.new(position.X, boss.spawnPosition.Y, position.Z)
		summonSerial += 1
		local id = boss.id .. "_summon_" .. tostring(summonSerial)
		local model, humanoid, root, align = CreatureKit.Build(def, position)
		model.Name = "Enemy_" .. id
		model.Parent = parent
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		local record = {
			id = id,
			def = def,
			arenaIndex = boss.arenaIndex,
			model = model,
			humanoid = humanoid,
			root = root,
			align = align,
			spawnPosition = position,
			state = "Idle",
			target = nil,
			stateSince = os.clock(),
			leashStartedAt = nil,
			lastAttack = 0,
			nextAttack = 0,
			attackIndex = 0,
			pending = nil,
			damageByUserId = {},
			lastHitUserId = nil,
			rewarded = false,
			generation = 1,
			summonedBy = boss.id,
			noReward = true,
		}
		local generation = record.generation
		humanoid.Died:Connect(function()
			if record.generation == generation then
				EnemyService.Kill(record)
			end
		end)
		table.insert(enemies, record)
		byId[id] = record
		spawned += 1
	end
	return spawned
end

function EnemyService.Tick(_dt)
	local now = os.clock()
	for index = #enemies, 1, -1 do
		if enemies[index].expired then
			byId[enemies[index].id] = nil
			table.remove(enemies, index)
		end
	end
	local leashSeconds = GameConfig.Combat.LeashSeconds
	for _, enemy in ipairs(enemies) do
		if enemy.state ~= "Dead" and enemy.state ~= "Respawning" and enemy.root.Parent then
			if enemy.root.Position.Y < -15 then
				enemy.root.CFrame = CFrame.new(enemy.spawnPosition)
				setState(enemy, "Idle")
				enemy.target = nil
			end
			local away = (enemy.root.Position - enemy.spawnPosition).Magnitude
			if enemy.state == "Returning" then
				releaseFacing(enemy)
				enemy.humanoid.WalkSpeed = enemy.def.speed * 1.45
				enemy.humanoid:MoveTo(enemy.spawnPosition)
				if away <= GameConfig.Combat.ReturnArriveDistance or now - enemy.stateSince > 12 then
					enemy.root.CFrame = CFrame.new(enemy.spawnPosition)
					enemy.humanoid.WalkSpeed = enemy.def.speed
					enemy.leashStartedAt = nil
					enemy.target = nil
					setState(enemy, "Idle")
				end
			else
				if away > enemy.def.leash then
					if not enemy.leashStartedAt then
						enemy.leashStartedAt = now
					elseif now - enemy.leashStartedAt >= leashSeconds then
						enemy.target = nil
						if enemy.def.behavior == "chieftain" then
							EnemyService.DismissSummons(enemy)
						end
						setState(enemy, "Returning")
						continue
					end
				else
					enemy.leashStartedAt = nil
				end

				if enemy.target and not targetAllowed(enemy.target, enemy.arenaIndex) then
					enemy.target = nil
				end
				local targetRoot = playerRoot(enemy.target)
				if enemy.state == "Idle" then
					releaseFacing(enemy)
					local nearest = nearestPlayer(enemy.root.Position, enemy.def.aggro, enemy.arenaIndex)
					if nearest then
						enemy.target = nearest
						setState(enemy, "Aggro")
					elseif away > GameConfig.Combat.IdleLeash then
						enemy.humanoid.WalkSpeed = enemy.def.speed
						enemy.humanoid:MoveTo(enemy.spawnPosition)
					end
				elseif enemy.state == "Aggro" then
					if not targetRoot then
						enemy.target = nil
						setState(enemy, "Idle")
					elseif now - enemy.stateSince >= GameConfig.Combat.AggroStateSeconds then
						setState(enemy, "Chasing")
					end
				else
					if not targetRoot then
						enemy.target = nil
						setState(enemy, "Idle")
					else
						local distance = (targetRoot.Position - enemy.root.Position).Magnitude
						faceTarget(enemy, targetRoot.Position)
						local reach = enemy.def.range + (enemy.def.behavior == "bonewalker" and 0.8 or 0)
						if distance <= reach or enemy.pending then
							setState(enemy, "Attacking")
							enemy.humanoid.WalkSpeed = 0
							enemy.stuck = 0
							if enemy.pending then
								if distance > reach + 10 then
									enemy.pending = nil
								elseif now >= (enemy.windupUntil or 0) then
									local move = enemy.pending
									enemy.pending = nil
									enemy.lastAttack = now
									enemy.nextAttack = now + cooldownFor(enemy, move)
									local amount = damageFor(enemy, move)
									local aim = enemy.aim or targetRoot.Position
									if move == "leap" then
										dashToward(enemy, aim, 8)
									elseif move == "charge" then
										dashToward(enemy, aim, EnemyConfig.Summon.ChargeDistance)
									elseif move == "summon" then
										EnemyService.SummonDead(enemy)
									end
									CombatFx.Strike(move, enemy.root.Position, aim, strikeColor(enemy))
									local hitRange = enemy.def.range
									if move == "roar" then
										hitRange = EnemyConfig.Summon.RoarRadius
									elseif move == "slam" then
										hitRange = EnemyConfig.Summon.SlamRadius
									elseif move == "leap" or move == "charge" then
										hitRange = enemy.def.range + 2.5
									elseif move == "smash" then
										hitRange = enemy.def.range + 1.2
									elseif move == "recover" or move == "summon" then
										hitRange = 0
									end
									local gap = (targetRoot.Position - enemy.root.Position).Magnitude
									if amount > 0 and gap <= hitRange then
										if ctx and ctx.services.CombatService then
											ctx.services.CombatService.DamagePlayer(enemy.target, amount)
											if move == "roar" then
												ctx.services.CombatService.ApplySlow(enemy.target, EnemyConfig.Summon.RoarSlowSeconds, EnemyConfig.Summon.RoarSlow)
											end
										end
									end
								end
							elseif now >= (enemy.nextAttack or 0) then
								if enemy.def.behavior then
									local move = chooseMove(enemy)
									enemy.pending = move
									enemy.aim = targetRoot.Position
									enemy.windupUntil = now + windupFor(move)
									enemy.model:SetAttribute("KurkitoMove", move)
									enemy.model:SetAttribute("KurkitoSwing", workspace:GetServerTimeNow())
									if move == "slam" or move == "roar" or move == "charge" then
										local at = enemy.root.Position
										local radius = move == "roar" and EnemyConfig.Summon.RoarRadius or (move == "slam" and EnemyConfig.Summon.SlamRadius or 4)
										if move == "charge" then
											local flat = Vector3.new(targetRoot.Position.X - at.X, 0, targetRoot.Position.Z - at.Z)
											if flat.Magnitude > 1 then
												at = at + flat.Unit * 8
											end
										end
										CombatFx.Telegraph(at, strikeColor(enemy), radius, windupFor(move))
									end
								elseif now - enemy.lastAttack >= enemy.def.interval then
									enemy.lastAttack = now
									enemy.nextAttack = now + enemy.def.interval
									enemy.model:SetAttribute("KurkitoMove", "swipe")
									enemy.model:SetAttribute("KurkitoSwing", workspace:GetServerTimeNow())
									CombatFx.Strike("swipe", enemy.root.Position, targetRoot.Position, Color3.fromRGB(255, 220, 180))
									if ctx and ctx.services.CombatService then
										ctx.services.CombatService.DamagePlayer(enemy.target, enemy.def.dmg)
									end
								end
							end
						else
							setState(enemy, "Chasing")
							local speed, move = chaseProfile(enemy, distance)
							enemy.humanoid.WalkSpeed = speed
							if enemy.model then
								enemy.model:SetAttribute("KurkitoMove", move)
							end
							local previous = enemy.previousGap
							if previous and distance > previous - 0.35 then
								enemy.stuck = (enemy.stuck or 0) + 0.2
							else
								enemy.stuck = 0
							end
							enemy.previousGap = distance
							if enemy.pathHold and now < enemy.pathHold then
								-- Un waypoint è già stato assegnato.
							elseif (enemy.stuck or 0) > 1.5 then
								nudgeAroundObstacle(enemy, targetRoot.Position, now)
							else
								enemy.humanoid:MoveTo(targetRoot.Position)
							end
						end
					end
				end
			end
		end
	end
end

return EnemyService
