-- Combattimento server-authoritative. Il client non decide danni né ricompense.
-- Kill credit predefinito: chi ha inflitto più danni. In parità, l'ultimo colpo.
-- Le abilità partono da sole, solo con un bersaglio valido e fuori dal cooldown.

local Players = game:GetService("Players")

local shared = require(script.Parent.SharedLoader)
local AbilityConfig = shared("AbilityConfig")
local GameConfig = shared("GameConfig")
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local EnemyService = require(script.Parent.EnemyService)
local PlayerData = require(script.Parent.PlayerDataService)
local StatsService = require(script.Parent.StatsService)
local RuntimeState = require(script.Parent.RuntimeState)
local MasteryService = require(script.Parent.MasteryService)
local EconomyService = require(script.Parent.EconomyService)
local LootService = require(script.Parent.LootService)
local QuestService = require(script.Parent.QuestService)
local Notifier = require(script.Parent.Notifier)
local CombatFx = require(script.Parent.CombatFx)

local sharedStrings = shared("Strings")

local CombatService = {}

local projectiles = {}

local function effectsFolder()
	local world = workspace:FindFirstChild("KurkitoWorld")
	return (world and world:FindFirstChild("Effects")) or workspace
end

local function characterParts(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return root, humanoid
end

local function distance(a, b)
	return (a - b).Magnitude
end

local function arenaAllowed(player, enemy)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return false
	end
	local hero = data.heroes[data.selectedHero]
	return hero.unlockedArenas[tostring(enemy.arenaIndex)] == true
end

function CombatService.DamagePlayer(player, rawAmount)
	local stats = StatsService.Compute(player)
	if not stats then
		return
	end
	local _, humanoid = characterParts(player)
	if not humanoid then
		return
	end
	local amount = rawAmount * (1 - stats.damageReduction)
	local runtime = RuntimeState.Get(player)
	if runtime.shieldUntil > 0 and os.clock() > runtime.shieldUntil then
		runtime.shield = 0
		runtime.shieldUntil = 0
	end
	if runtime.shield > 0 then
		local absorbed = math.min(runtime.shield, amount)
		runtime.shield -= absorbed
		amount -= absorbed
	end
	if amount > 0 then
		humanoid:TakeDamage(amount)
	end
end

local function pickCredit(enemy)
	local damage = {}
	for userId, amount in pairs(enemy.damageByUserId) do
		damage[userId] = amount
	end
	for _ = 1, 8 do
		local userId = Rules.PickKillCredit(damage, enemy.lastHitUserId, GameConfig.Combat.KillCredit)
		if not userId then
			return nil
		end
		local player = Players:GetPlayerByUserId(userId)
		if player and PlayerData.IsLoaded(player) then
			local data = PlayerData.Get(player)
			if data and data.selectedHero ~= "" and arenaAllowed(player, enemy) then
				return player
			end
		end
		damage[userId] = nil
	end
	return nil
end

function CombatService.GrantRewards(enemy)
	local player = pickCredit(enemy)
	if not player then
		return
	end
	local xp = MasteryService.AddBaseXp(player, enemy.def.xp)
	local coins = EconomyService.GrantBase(player, enemy.def.coins)
	local data = PlayerData.Get(player)
	if data then
		data.totalKills += 1
		PlayerData.MarkDirty(player, false)
	end
	QuestService.OnKill(player)
	LootService.GrantEnemyDrops(player, enemy.def)
	Notifier.Send(player, "reward", sharedStrings.XpCoins(xp.applied, coins))
end

local function threatList(player, runtime, maxDistance)
	local root = characterParts(player)
	if not root then
		return {}
	end
	local list = {}
	for _, enemy in ipairs(EnemyService.GetAlive()) do
		if not enemy.rewarded and enemy.state ~= "Dead" and enemy.state ~= "Respawning" and runtime.engaged[enemy.id] then
			if arenaAllowed(player, enemy) then
				local gap = distance(root.Position, enemy.root.Position)
				if gap <= maxDistance then
					table.insert(list, { enemy = enemy, distance = gap })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.distance < b.distance
	end)
	return list
end

local function refreshEngagement(player, runtime, root)
	local seen = {}
	for _, enemy in ipairs(EnemyService.GetAlive()) do
		if not enemy.rewarded and enemy.state ~= "Dead" and enemy.state ~= "Respawning" then
			local gap = distance(root.Position, enemy.root.Position)
			if gap <= enemy.def.aggro then
				runtime.engaged[enemy.id] = true
			end
			if runtime.engaged[enemy.id] then
				seen[enemy.id] = true
				if enemy.state == "Idle" and gap > enemy.def.aggro then
					runtime.engaged[enemy.id] = nil
					seen[enemy.id] = nil
				end
			end
		end
	end
	for id in pairs(runtime.engaged) do
		if not seen[id] then
			runtime.engaged[id] = nil
		end
	end
end

local function readyCooldown(runtime, ability, now)
	local untilTime = runtime.cooldowns[ability.id] or 0
	return now >= untilTime
end

local function startCooldown(runtime, ability, now)
	runtime.cooldowns[ability.id] = now + ability.cooldown
end

local function spendMana(runtime, stats, cost)
	if cost <= 0 then
		return true
	end
	if stats.maxMana <= 0 or runtime.mana < cost then
		return false
	end
	runtime.mana -= cost
	return true
end

local function multiplier(ability, rank)
	return (ability.baseMultiplier or 1) + rank * (ability.perRank or 0)
end

local function castAbility(player, runtime, stats, ability, rank, root)
	local now = os.clock()
	if not readyCooldown(runtime, ability, now) then
		return false
	end
	local threats = threatList(player, runtime, math.max(stats.attackRange, ability.radius or stats.attackRange))
	if #threats == 0 then
		return false
	end
	if not spendMana(runtime, stats, ability.mana or 0) then
		return false
	end
	local power = multiplier(ability, rank)
	local kind = ability.kind
	if kind == "aoe_self" then
		local hit = 0
		for _, entry in ipairs(threats) do
			if entry.distance <= (ability.radius or 12) then
				EnemyService.Damage(entry.enemy, player, stats.damage * power)
				hit += 1
			end
		end
		if hit == 0 then
			runtime.mana += ability.mana or 0
			return false
		end
		CombatFx.MarkSwing(player, "Special")
		CombatFx.Ring(root.Position, Color3.fromRGB(255, 170, 80), (ability.radius or 12) * 2, 0.3)
	elseif kind == "projectile" then
		local target = threats[1].enemy
		if threats[1].distance > (ability.radius or stats.attackRange) then
			runtime.mana += ability.mana or 0
			return false
		end
		CombatFx.MarkSwing(player, "Special")
		local orb = Instance.new("Part")
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.4, 1.4, 1.4)
		orb.Material = Enum.Material.Neon
		orb.Color = Color3.fromRGB(255, 120, 40)
		orb.Anchored = true
		orb.CanCollide = false
		orb.CanQuery = false
		orb.CastShadow = false
		orb.CFrame = CFrame.new(root.Position + Vector3.new(0, 1.5, 0))
		orb.Parent = effectsFolder()
		local trailA = Instance.new("Attachment")
		trailA.Position = Vector3.new(0, 0.4, 0)
		trailA.Parent = orb
		local trailB = Instance.new("Attachment")
		trailB.Position = Vector3.new(0, -0.4, 0)
		trailB.Parent = orb
		local ribbon = Instance.new("Trail")
		ribbon.Attachment0 = trailA
		ribbon.Attachment1 = trailB
		ribbon.Lifetime = 0.2
		ribbon.Color = ColorSequence.new(Color3.fromRGB(255, 140, 50))
		ribbon.Transparency = NumberSequence.new(0.3)
		ribbon.Parent = orb
		table.insert(projectiles, {
			player = player,
			enemy = target,
			damage = stats.damage * power,
			from = orb.Position,
			started = now,
			travel = ability.travelTime or 0.35,
			part = orb,
		})
	elseif kind == "buff_defense" then
		local remain = runtime.buffs.defenseUntil - now
		if remain > ability.duration * 0.3 then
			runtime.mana += ability.mana or 0
			return false
		end
		runtime.buffs.defenseUntil = now + ability.duration
		runtime.buffs.defenseReduction = math.clamp((ability.baseReduction or 0.2) + rank * (ability.perRank or 0), 0, 0.75)
		CombatFx.NamedAura(player.Character, "DefenseAura", Color3.fromRGB(160, 190, 220), Vector3.new(5.5, 6.5, 5.5))
	elseif kind == "buff_damage" then
		local remain = runtime.buffs.furyUntil - now
		if remain > ability.duration * 0.3 then
			runtime.mana += ability.mana or 0
			return false
		end
		runtime.buffs.furyUntil = now + ability.duration
		runtime.buffs.furyBonus = (ability.baseBonus or 0.3) + rank * (ability.perRank or 0)
		CombatFx.NamedAura(player.Character, "FuryAura", Color3.fromRGB(220, 70, 48), Vector3.new(4.2, 5.2, 4.2))
		CombatFx.MarkSwing(player, "Special")
	elseif kind == "buff_shield" then
		if runtime.shield > 15 then
			runtime.mana += ability.mana or 0
			return false
		end
		runtime.shield = (ability.baseShield or 30) + rank * (ability.perRank or 0) + stats.damage * 0.4
		runtime.shieldUntil = now + (ability.duration or 8)
		CombatFx.NamedAura(player.Character, "BarrierAura", Color3.fromRGB(90, 150, 255), Vector3.new(6, 6.5, 6))
	elseif kind == "buff_hawk" then
		local remain = runtime.buffs.hawkUntil - now
		if remain > ability.duration * 0.3 then
			runtime.mana += ability.mana or 0
			return false
		end
		runtime.buffs.hawkUntil = now + ability.duration
		runtime.buffs.hawkBonus = (ability.baseBonus or 0.3) + rank * (ability.perRank or 0)
		runtime.buffs.hawkRange = ability.rangeBonus or 8
		CombatFx.Burst(root.Position + Vector3.new(0, 2.4, 0), Color3.fromRGB(120, 220, 140), Vector3.new(1.4, 1.4, 1.4), 0.3)
	elseif kind == "multi_hit" then
		local count = 0
		local limit = ability.targets or 3
		for _, entry in ipairs(threats) do
			if count >= limit then
				break
			end
			if entry.distance <= (ability.radius or stats.attackRange) then
				EnemyService.Damage(entry.enemy, player, stats.damage * power)
				CombatFx.BasicHit(player, "Archer", root.Position, entry.enemy.root.Position, Color3.fromRGB(230, 230, 180))
				count += 1
			end
		end
		if count == 0 then
			runtime.mana += ability.mana or 0
			return false
		end
	elseif kind == "pierce" then
		local primary = threats[1]
		if primary.distance > (ability.radius or stats.attackRange) then
			runtime.mana += ability.mana or 0
			return false
		end
		local origin = root.Position
		local aim = primary.enemy.root.Position
		local hit = 0
		for _, entry in ipairs(threats) do
			if hit >= (ability.maxTargets or 4) then
				break
			end
			local segment = aim - origin
			local length = segment.Magnitude
			local rel = entry.enemy.root.Position - origin
			local along = 0
			if length > 0.1 then
				along = math.clamp(rel:Dot(segment.Unit), 0, length)
			end
			local closest = origin + (length > 0.1 and segment.Unit * along or Vector3.zero)
			if (entry.enemy.root.Position - closest).Magnitude <= (ability.width or 6) then
				EnemyService.Damage(entry.enemy, player, stats.damage * power)
				hit += 1
			end
		end
		if hit == 0 then
			runtime.mana += ability.mana or 0
			return false
		end
		CombatFx.BasicHit(player, "Archer", origin, aim, Color3.fromRGB(200, 230, 255))
		CombatFx.MarkSwing(player, "Special")
	else
		runtime.mana += ability.mana or 0
		return false
	end
	startCooldown(runtime, ability, now)
	return true
end

local function stepProjectiles()
	local now = os.clock()
	for index = #projectiles, 1, -1 do
		local shot = projectiles[index]
		local alpha = 1
		if shot.travel > 0 then
			alpha = math.clamp((now - shot.started) / shot.travel, 0, 1)
		end
		local targetPos = shot.from
		if shot.enemy and shot.enemy.root and shot.enemy.root.Parent then
			targetPos = shot.enemy.root.Position
		end
		if shot.part and shot.part.Parent then
			shot.part.CFrame = CFrame.new(shot.from:Lerp(targetPos, alpha))
		end
		if alpha >= 1 then
			if shot.enemy and not shot.enemy.rewarded and shot.player and shot.player.Parent then
				EnemyService.Damage(shot.enemy, shot.player, shot.damage)
				CombatFx.Burst(targetPos + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 140, 50), Vector3.new(2.2, 2.2, 2.2), 0.28)
			end
			if shot.part then
				shot.part:Destroy()
			end
			table.remove(projectiles, index)
		end
	end
end

function CombatService.Tick(dt)
	stepProjectiles()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData.Get(player)
		if data and data.selectedHero ~= "" then
			local root = characterParts(player)
			local stats = StatsService.Compute(player)
			if root and stats then
				local runtime = RuntimeState.Get(player)
				if stats.maxMana > 0 then
					runtime.mana = math.min(stats.maxMana, runtime.mana + stats.manaRegen * dt)
				end
				refreshEngagement(player, runtime, root)
				local threats = threatList(player, runtime, stats.attackRange)
				if #threats > 0 and now - runtime.lastAttack >= stats.attackInterval then
					runtime.lastAttack = now
					EnemyService.Damage(threats[1].enemy, player, stats.damage)
					CombatFx.BasicHit(player, data.selectedHero, root.Position, threats[1].enemy.root.Position, HeroConfig.Classes[data.selectedHero].color)
				end
				local hero = data.heroes[data.selectedHero]
				for _, ability in ipairs(AbilityConfig[data.selectedHero]) do
					if Rules.AbilityUnlocked(hero.mastery, ability) then
						-- Il rango 0 è il valore base. I punti aumentano il rango.
						castAbility(player, runtime, stats, ability, hero.skillRanks[ability.id] or 0, root)
					end
				end
			end
		end
	end
end

function CombatService.PushVitals(player)
	local remote = nil
	-- Il GameLoop passa dal servizio già avviato: il remote è letto in modo pigro.
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild(shared("RemoteNames").Folder)
	remote = folder and folder:FindFirstChild("Vitals")
	if not remote then
		return
	end
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return
	end
	local stats = StatsService.Compute(player)
	if not stats then
		return
	end
	local _, humanoid = characterParts(player)
	local runtime = RuntimeState.Get(player)
	local now = os.clock()
	local cooldowns = {}
	for _, ability in ipairs(AbilityConfig[data.selectedHero]) do
		local untilTime = runtime.cooldowns[ability.id] or 0
		cooldowns[ability.id] = math.max(0, untilTime - now)
	end
	local effects = {}
	for family, effect in pairs(runtime.effects) do
		effects[family] = math.max(0, effect.expiresAt - now)
	end
	remote:FireClient(player, {
		hp = humanoid and humanoid.Health or stats.maxHp,
		maxHp = stats.maxHp,
		mana = runtime.mana,
		maxMana = stats.maxMana,
		cooldowns = cooldowns,
		effects = effects,
		shield = runtime.shield,
		walkSpeed = stats.walkSpeed,
		damage = stats.damage,
	})
end

return CombatService
