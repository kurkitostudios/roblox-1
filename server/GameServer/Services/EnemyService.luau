-- AI dei mostri a 5 Hz. Stati: Idle, Aggro, Chasing, Attacking, Returning, Dead, Respawning.
-- Oltre la distanza di leash parte un timer di 5 secondi. Poi il nemico torna
-- allo spawn e, finché è in Returning, ignora l'aggro.

local PhysicsService = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")

local shared = require(script.Parent.SharedLoader)
local EnemyConfig = shared("EnemyConfig")
local WorldLayout = shared("WorldLayout")
local GameConfig = shared("GameConfig")

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

local function weld(part0, part1)
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = part0
	joint.Part1 = part1
	joint.Parent = part1
end

local function buildModel(def, position)
	local scale = def.scale or 1
	local height = 4.2 * scale
	local model = Instance.new("Model")
	model.Name = def.id
	local color = EnemyConfig.BodyColor[def.rarity] or Color3.fromRGB(90, 120, 90)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.2 * scale, height, 1.3 * scale)
	root.Color = color
	root.Material = def.rarity == "Boss" and Enum.Material.Neon or Enum.Material.SmoothPlastic
	root.CanCollide = true
	root.CollisionGroup = "KurkitoEnemies"
	root.CFrame = CFrame.new(position)
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5) * scale
	head.Color = color:Lerp(Color3.new(1, 1, 1), 0.15)
	head.Material = root.Material
	head.CanCollide = false
	head.Massless = true
	head.CollisionGroup = "KurkitoEnemies"
	head.CFrame = root.CFrame * CFrame.new(0, height * 0.55, 0)
	head.Parent = model
	weld(root, head)

	local ring = Instance.new("Part")
	ring.Name = "AggroRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.25, def.aggro * 2, def.aggro * 2)
	ring.Color = Color3.fromRGB(190, 40, 40)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.72
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Massless = true
	ring.CFrame = CFrame.new(position - Vector3.new(0, height * 0.5 - 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = model
	weld(root, ring)

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = def.name
	humanoid.MaxHealth = def.hp
	humanoid.Health = def.hp
	humanoid.WalkSpeed = def.speed
	humanoid.HipHeight = height * 0.5
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
	humanoid.NameDisplayDistance = 80
	humanoid.HealthDisplayDistance = 80
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.Parent = model

	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = true
	align.Parent = root

	model.PrimaryPart = root
	model:SetAttribute("EnemyTypeId", def.id)
	model:SetAttribute("Rarity", def.rarity)
	return model, humanoid, root
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
	for arenaIndex = 1, 15 do
		local center = WorldLayout.ArenaCenter(arenaIndex)
		for _, spawn in ipairs(EnemyConfig.SpawnPlan(arenaIndex)) do
			local offset = EnemyConfig.SpawnOffset(spawn.slot, spawn.boss)
			local def = spawn.def
			local hip = (4.2 * (def.scale or 1)) * 0.5
			local position = Vector3.new(center.X + offset.X, 1 + hip, center.Z + offset.Z)
			local id = string.format("a%d_s%d", arenaIndex, spawn.slot)
			local model, humanoid, root = buildModel(def, position)
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
				spawnPosition = position,
				state = "Idle",
				target = nil,
				stateSince = os.clock(),
				leashStartedAt = nil,
				lastAttack = 0,
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
	local hero = data.heroes[data.selectedHero]
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
	local model, humanoid, root = buildModel(enemy.def, enemy.spawnPosition)
	model.Name = "Enemy_" .. enemy.id
	model.Parent = parent
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	enemy.model = model
	enemy.humanoid = humanoid
	enemy.root = root
	enemy.rewarded = false
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
	enemy.humanoid.WalkSpeed = 0
	enemy.root.Anchored = true
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
	local popup = Instance.new("Part")
	popup.Anchored = true
	popup.CanCollide = false
	popup.CanQuery = false
	popup.Transparency = 1
	popup.Size = Vector3.new(0.2, 0.2, 0.2)
	popup.Position = enemy.root.Position + Vector3.new(math.random(-1, 1), 3.2, 0)
	popup.Parent = effectsFolder()
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(70, 28)
	billboard.AlwaysOnTop = true
	billboard.Parent = popup
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 120)
	label.TextStrokeTransparency = 0.4
	label.Text = tostring(amount)
	label.Parent = billboard
	Debris:AddItem(popup, 0.7)
	if enemy.humanoid.Health <= 0 then
		EnemyService.Kill(enemy)
	end
end

function EnemyService.Tick(_dt)
	local now = os.clock()
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
						if distance <= enemy.def.range then
							setState(enemy, "Attacking")
							enemy.humanoid.WalkSpeed = 0
							if now - enemy.lastAttack >= enemy.def.interval then
								enemy.lastAttack = now
								if ctx and ctx.services.CombatService then
									ctx.services.CombatService.DamagePlayer(enemy.target, enemy.def.dmg)
								end
							end
						else
							setState(enemy, "Chasing")
							enemy.humanoid.WalkSpeed = enemy.def.speed
							enemy.humanoid:MoveTo(targetRoot.Position)
						end
					end
				end
			end
		end
	end
end

return EnemyService
