local StarterPlayer = game:GetService("StarterPlayer")

local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local WorldLayout = shared("WorldLayout")
local GameConfig = shared("GameConfig")
local PlayerData = require(script.Parent.PlayerDataService)
local RuntimeState = require(script.Parent.RuntimeState)
local StatsService = require(script.Parent.StatsService)
local Notifier = require(script.Parent.Notifier)

-- L'avatar salvato del giocatore copriva il costume. Il Mondo 0 ha un solo aspetto.
pcall(function()
	StarterPlayer.LoadCharacterAppearance = false
end)

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
	local quality = player:GetAttribute("KurkitoVisualQuality")
	if quality == "low" or quality == "full" then
		character:SetAttribute("KurkitoVisualQuality", quality)
	end
	local appearance = require(script.Parent.HeroAppearance)
	appearance.Apply(character, data.selectedHero, data.heroes[data.selectedHero], data)
end

function HeroService.Refresh(player, fullHeal)
	applyHumanoid(player, fullHeal == true)
end

local function rigReady(character)
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	return head ~= nil and torso ~= nil and hand ~= nil
end

local function awaitRig(player, character)
	local deadline = os.clock() + 8
	while character.Parent and player.Character == character and os.clock() < deadline do
		if rigReady(character) then
			return true
		end
		task.wait(0.05)
	end
	return player.Character == character and rigReady(character)
end

local function awaitAppearance(player, character)
	if player:HasAppearanceLoaded() then
		return
	end
	local done = false
	local connection = player.CharacterAppearanceLoaded:Connect(function(appeared)
		if appeared == character then
			done = true
		end
	end)
	local deadline = os.clock() + 2.5
	while not done and player.Character == character and os.clock() < deadline do
		if player:HasAppearanceLoaded() then
			break
		end
		task.wait(0.1)
	end
	if connection.Connected then
		connection:Disconnect()
	end
end

local function foreignCosmetics(character)
	local appearance = require(script.Parent.HeroAppearance)
	return appearance.HasForeignCosmetics(character)
end

-- Le statistiche partono subito. Il costume viene ricostruito dopo il caricamento
-- dell'aspetto, perché quello è il momento in cui vestiti e viso coprivano il modello.
local function presentCharacter(player, character)
	if player.Character ~= character or not character.Parent then
		return
	end
	local humanoid = character:WaitForChild("Humanoid", 8)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if not humanoid or not root or player.Character ~= character then
		return
	end
	applyHumanoid(player, true)
	local safe = RuntimeState.Get(player).safeCFrame
	if safe and root.Parent then
		root.CFrame = safe
		root.AssemblyLinearVelocity = Vector3.zero
	end
	task.spawn(function()
		awaitAppearance(player, character)
		if not awaitRig(player, character) then
			return
		end
		if player.Character ~= character then
			return
		end
		applyHumanoid(player, false)
		task.delay(0.7, function()
			if player.Character ~= character or not character.Parent then
				return
			end
			if foreignCosmetics(character) or character:GetAttribute("KurkitoWarriorVisual") ~= "003.2" then
				applyHumanoid(player, false)
			end
		end)
	end)
end

local function hookCharacter(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			presentCharacter(player, character)
		end)
	end)
	if player.Character then
		local existing = player.Character
		task.spawn(function()
			presentCharacter(player, existing)
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
	if heroId ~= "Warrior" then
		return { ok = false, error = "World 0 has one hero: the Warrior." }
	end
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
	Notifier.Send(player, "info", "The Warrior is ready.")
	return { ok = true }
end

function HeroService.Switch(player, heroId)
	local data = PlayerData.Get(player)
	if not data then
		return { ok = false, error = "Data is not loaded." }
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

function HeroService.SwitchNext(_player)
	return { ok = false, error = "World 0 has one hero: the Warrior." }
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
