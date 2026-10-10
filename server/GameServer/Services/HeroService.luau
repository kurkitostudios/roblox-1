local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local WorldLayout = shared("WorldLayout")
local GameConfig = shared("GameConfig")
local PlayerData = require(script.Parent.PlayerDataService)
local RuntimeState = require(script.Parent.RuntimeState)
local StatsService = require(script.Parent.StatsService)
local Notifier = require(script.Parent.Notifier)

local HeroService = {}

local valid = {}
for _, heroId in ipairs(HeroConfig.Order) do
	valid[heroId] = true
end

local function characterOf(player)
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return nil
	end
	return character, humanoid, root
end

function HeroService.Position(player)
	local _, _, root = characterOf(player)
	if not root then
		return nil
	end
	return root.Position
end

function HeroService.Near(player, target, radius)
	local position = HeroService.Position(player)
	if not position then
		return false
	end
	return WorldLayout.Near(position, target, radius + GameConfig.ProximitySlack)
end

function HeroService.InLobby(player)
	local position = HeroService.Position(player)
	if not position then
		return false
	end
	if WorldLayout.InLobby(position) then
		return true
	end
	return HeroService.Near(player, WorldLayout.HeroSwitch(), WorldLayout.Radii.Hero)
		or HeroService.Near(player, WorldLayout.Upgrades(), WorldLayout.Radii.Upgrade)
		or HeroService.Near(player, WorldLayout.Fusion(), WorldLayout.Radii.Fusion)
		or HeroService.Near(player, WorldLayout.Rebirth(), WorldLayout.Radii.Rebirth)
end

local function applyHumanoid(player, fullHeal)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return
	end
	local character, humanoid = characterOf(player)
	if not character then
		return
	end
	local stats = StatsService.Compute(player)
	if not stats then
		return
	end
	local runtime = RuntimeState.Get(player)
	if runtime.heroId ~= data.selectedHero or not runtime.manaInitialized then
		runtime.mana = stats.maxMana
		runtime.manaInitialized = true
		runtime.heroId = data.selectedHero
		runtime.cooldowns = {}
		runtime.shield = 0
	end
	if stats.maxMana > 0 and runtime.mana > stats.maxMana then
		runtime.mana = stats.maxMana
	end
	humanoid.WalkSpeed = stats.walkSpeed
	local oldMax = humanoid.MaxHealth
	humanoid.MaxHealth = stats.maxHp
	if fullHeal or humanoid.Health <= 0 then
		humanoid.Health = stats.maxHp
	elseif stats.maxHp >= oldMax then
		humanoid.Health = math.min(stats.maxHp, humanoid.Health + (stats.maxHp - oldMax))
	else
		humanoid.Health = math.min(humanoid.Health, stats.maxHp)
	end
	player:SetAttribute("KurkitoHero", data.selectedHero)
	character:SetAttribute("KurkitoHero", data.selectedHero)
	local appearance = require(script.Parent.HeroAppearance)
	appearance.Apply(character, data.selectedHero, data.heroes[data.selectedHero], data)
end

function HeroService.Refresh(player, fullHeal)
	applyHumanoid(player, fullHeal == true)
end

local function hookCharacter(player)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			local character = player.Character
			if not character then
				return
			end
			character:WaitForChild("Humanoid", 10)
			local root = character:WaitForChild("HumanoidRootPart", 10)
			applyHumanoid(player, true)
			local safe = RuntimeState.Get(player).safeCFrame
			if safe and root and root.Parent then
				root.CFrame = safe
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end)
	end)
	if player.Character then
		task.defer(function()
			applyHumanoid(player, true)
		end)
	end
end

function HeroService.OnPlayerLoaded(player)
	if player:GetAttribute("KurkitoHeroHooked") then
		applyHumanoid(player, true)
		return
	end
	player:SetAttribute("KurkitoHeroHooked", true)
	hookCharacter(player)
end

local function requireManageZone(player)
	if HeroService.InLobby(player) then
		return true
	end
	return false
end

function HeroService.Select(player, heroId)
	local data = PlayerData.Get(player)
	if not data then
		return { ok = false, error = "Data is not loaded." }
	end
	local ok, reason = Rules.SelectFirstHero(data, heroId, valid)
	if not ok then
		return { ok = false, error = reason }
	end
	PlayerData.MarkDirty(player, true)
	PlayerData.Save(player, false)
	applyHumanoid(player, true)
	Notifier.Send(player, "info", HeroConfig.Classes[heroId].displayName .. " is your first hero.")
	return { ok = true }
end

function HeroService.Switch(player, heroId)
	local data = PlayerData.Get(player)
	if not data then
		return { ok = false, error = "Data is not loaded." }
	end
	if not requireManageZone(player) then
		return { ok = false, error = "Switch heroes in the lobby or at the hero post." }
	end
	local ok, reason = Rules.SwitchHero(data, heroId)
	if not ok then
		return { ok = false, error = reason }
	end
	local runtime = RuntimeState.Get(player)
	runtime.heroId = ""
	runtime.manaInitialized = false
	runtime.engaged = {}
	runtime.cooldowns = {}
	runtime.shield = 0
	runtime.shieldUntil = 0
	runtime.buffs.furyUntil = 0
	runtime.buffs.defenseUntil = 0
	runtime.buffs.hawkUntil = 0
	PlayerData.MarkDirty(player, true)
	applyHumanoid(player, true)
	Notifier.Send(player, "info", "Active hero: " .. HeroConfig.Classes[heroId].displayName)
	return { ok = true }
end

function HeroService.SwitchNext(player)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return { ok = false, error = "No active hero." }
	end
	local startIndex = 1
	for index, heroId in ipairs(HeroConfig.Order) do
		if heroId == data.selectedHero then
			startIndex = index
		end
	end
	for offset = 1, #HeroConfig.Order do
		local heroId = HeroConfig.Order[((startIndex + offset - 1) % #HeroConfig.Order) + 1]
		if data.unlockedHeroes[heroId] and heroId ~= data.selectedHero then
			return HeroService.Switch(player, heroId)
		end
	end
	return { ok = false, error = "You have no other unlocked hero." }
end

function HeroService.Bind(ctx)
	local rates = shared("GameConfig").Rates
	ctx.services.RemotesService.Bind(ctx, "SelectHero", rates.SelectHero, function(player, payload)
		local heroId = payload.heroId
		if type(heroId) ~= "string" then
			return { ok = false, error = "Invalid hero." }
		end
		return HeroService.Select(player, heroId)
	end)
	ctx.services.RemotesService.Bind(ctx, "SwitchHero", rates.SwitchHero, function(player, payload)
		local heroId = payload.heroId
		if type(heroId) ~= "string" then
			return { ok = false, error = "Invalid hero." }
		end
		return HeroService.Switch(player, heroId)
	end)
end

return HeroService
