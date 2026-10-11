local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HeroConfig = require(Shared:WaitForChild("HeroConfig"))
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))
local ArenaConfig = require(Shared:WaitForChild("ArenaConfig"))
local LootConfig = require(Shared:WaitForChild("LootConfig"))
local PetConfig = require(Shared:WaitForChild("PetConfig"))
local PotionConfig = require(Shared:WaitForChild("PotionConfig"))
local QuestConfig = require(Shared:WaitForChild("QuestConfig"))
local Rules = require(Shared:WaitForChild("Rules"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Strings = require(Shared:WaitForChild("Strings"))

local Menus = {}

local invoke
local notify
local shell
local body
local title
local openName
local inventoryTab = "equipment"
local fusionPick = {}
local rebirthArmed = false

local function effective(profile, heroOverride)
	local heroId = profile.selectedHero
	local hero = heroOverride or profile.heroes[heroId]
	local hpPct, dmgPct = Loadout.TalentRates()
	return Rules.ComputeStats({
		classId = heroId,
		classDef = HeroConfig.Classes[heroId],
		hero = hero,
		gearBonus = Loadout.GearBonus(profile, heroId),
		petBonus = Loadout.PetBonus(profile),
		talentHpPct = hpPct,
		talentDmgPct = dmgPct,
	})
end

local function statReadout(stats, statId)
	local ui = Strings.UI
	if statId == "HP" then
		return math.floor(stats.maxHp + 0.5), "HP"
	elseif statId == "DMG" then
		return math.floor(stats.damage + 0.5), ui.DamageWord
	elseif statId == "Speed" then
		return math.floor(stats.walkSpeed * 10 + 0.5) / 10, ui.SpeedWord
	elseif statId == "Mana" then
		return math.floor(stats.maxMana + 0.5), ui.ManaWord
	elseif statId == "AttackSpeed" then
		return math.floor(stats.attackInterval * 100 + 0.5) / 100, ui.IntervalWord
	end
	return 0, ""
end

local function renderHeroes(profile)
	local ui = Strings.UI
	local classDef = HeroConfig.Classes.Warrior
	local hero = profile.heroes.Warrior
	Widgets.Label(body, classDef.displayName .. ui.Active, UDim2.new(1, 0, 0, 22), true).TextColor3 = classDef.color:Lerp(Color3.new(1, 1, 1), 0.35)
	Widgets.Label(body, ui.OneHeroBody, UDim2.new(1, 0, 0, 40), false)
	if hero then
		Widgets.Label(body, Strings.HeroLine(hero.mastery, hero.rebirths, hero.skillPoints), UDim2.new(1, 0, 0, 20), false)
		Widgets.Label(body, classDef.description, UDim2.new(1, 0, 0, 36), false)
	end
end

local function renderUpgrades(profile)
	local ui = Strings.UI
	if profile.selectedHero == "" then
		Widgets.Label(body, ui.ChooseHeroFirst, nil, false)
		return
	end
	local hero = profile.heroes[profile.selectedHero]
	local classDef = HeroConfig.Classes[profile.selectedHero]
	local nowStats = effective(profile)
	Widgets.Label(body, ui.SkillPoints .. tostring(hero.skillPoints), nil, true)
	for _, statId in ipairs(classDef.stats) do
		local level = hero.stats[statId]
		local statDef = HeroConfig.StatDefs[statId]
		local currentValue, unit = statReadout(nowStats, statId)
		local cost = Rules.StatCost(level, statDef)
		local nextText = ui.MaxLevel
		if cost then
			local copy = Rules.DeepCopy(hero)
			copy.stats[statId] += 1
			local nextStats = effective(profile, copy)
			local nextValue = statReadout(nextStats, statId)
			nextText = Strings.NextStat(nextValue, nextValue - currentValue, Rules.FormatNumber(cost))
		end
		Widgets.Label(body, Strings.StatLine(statDef.label, level, currentValue, unit), UDim2.new(1, 0, 0, 36), true)
		Widgets.Label(body, nextText, UDim2.new(1, 0, 0, 32), false)
		if cost then
			Widgets.Button(body, ui.Upgrade .. statDef.label, function()
				local result = invoke("UpgradeStat", { statId = statId })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
	Widgets.Label(body, ui.Talents, nil, true)
	for _, talent in ipairs(HeroConfig.Talents) do
		local rank = hero.talents[talent.id] or 0
		Widgets.Label(body, Strings.TalentLine(talent.name, rank, talent.maxRank, talent.description), UDim2.new(1, 0, 0, 36), false)
		if rank < talent.maxRank then
			Widgets.Button(body, ui.SpendPoint .. talent.name, function()
				local result = invoke("SpendSkillPoint", { kind = "talent", id = talent.id })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
	Widgets.Label(body, ui.AbilitiesInSkills, UDim2.new(1, 0, 0, 32), false).TextColor3 = Theme.muted
end

local function renderSkills(profile)
	local ui = Strings.UI
	if profile.selectedHero == "" then
		Widgets.Label(body, ui.ChooseHeroFirst, nil, false)
		return
	end
	local hero = profile.heroes[profile.selectedHero]
	Widgets.Label(body, ui.SkillPoints .. tostring(hero.skillPoints), nil, true)
	for _, ability in ipairs(AbilityConfig[profile.selectedHero]) do
		local rank = hero.skillRanks[ability.id] or 0
		local unlocked = Rules.AbilityUnlocked(hero.mastery, ability)
		local state = unlocked and ui.Unlocked or (ui.MasteryRequired .. ability.masteryRequired)
		Widgets.Label(body, Strings.AbilityLine(ability.name, rank, AbilityConfig.MaxRank, state), UDim2.new(1, 0, 0, 36), false)
		Widgets.Label(body, ability.description, UDim2.new(1, 0, 0, 20), false).TextColor3 = Theme.muted
		if unlocked and rank < AbilityConfig.MaxRank then
			Widgets.Button(body, ui.Upgrade .. ability.name, function()
				local result = invoke("SpendSkillPoint", { kind = "skill", id = ability.id })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
end

local function itemName(itemId)
	local def = LootConfig.GetItem(itemId)
	return def and def.name or itemId
end

local function renderInventory(profile)
	local ui = Strings.UI
	local tabs = {
		{ id = "equipment", label = ui.EquipTab },
		{ id = "materials", label = ui.MaterialsTab },
		{ id = "potions", label = ui.PotionsTab },
		{ id = "collectibles", label = ui.RelicsTab },
	}
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 44)
	row.Parent = body
	Widgets.List(row, Enum.FillDirection.Horizontal, 6)
	for _, tab in ipairs(tabs) do
		local button = Widgets.Button(row, tab.label, function()
			inventoryTab = tab.id
			Menus.Refresh()
		end)
		button.Size = UDim2.new(0.23, 0, 1, 0)
	end
	if inventoryTab == "equipment" then
		local hero = profile.selectedHero ~= "" and profile.heroes[profile.selectedHero]
		if hero then
			Widgets.Label(body, Strings.GearSlots(hero.equippedGear.weapon ~= "", hero.equippedGear.armor ~= "", hero.equippedGear.charm ~= ""), UDim2.new(1, 0, 0, 36), false)
			for _, slot in ipairs({ "weapon", "armor", "charm" }) do
				if hero.equippedGear[slot] ~= "" then
					local slotName = slot == "weapon" and ui.Weapon or (slot == "armor" and ui.Armor or ui.Charm)
					Widgets.Button(body, ui.Unequip .. slotName, function()
						local result = invoke("UnequipItem", { slot = slot })
						if not result.ok then
							notify("error", result.error)
						end
					end)
				end
			end
		end
		local visibleGear = 0
		for _, entry in ipairs(profile.inventory.equipment) do
			local def = LootConfig.GetItem(entry.itemId)
			if def and (def.classId == nil or def.classId == "Warrior") then
				visibleGear += 1
				local bound = entry.boundHero and (" · " .. entry.boundHero) or ui.SharedItem
				Widgets.Label(body, itemName(entry.itemId) .. bound, UDim2.new(1, 0, 0, 22), true)
				Widgets.Button(body, ui.Equip .. def.name, function()
					local result = invoke("EquipItem", { uid = entry.uid })
					if not result.ok then
						notify("error", result.error)
					end
				end)
			end
		end
		if visibleGear == 0 then
			Widgets.Label(body, ui.NoGear, nil, false)
		end
		Widgets.Label(body, ui.MaterialsNote, UDim2.new(1, 0, 0, 40), false).TextColor3 = Theme.muted
	else
		local bucket = profile.inventory[inventoryTab]
		local any = false
		for itemId, count in pairs(bucket) do
			any = true
			local def = LootConfig.GetItem(itemId)
			local line = itemName(itemId) .. "  x" .. tostring(count)
			Widgets.Label(body, line, nil, false)
			if def and def.description then
				Widgets.Label(body, def.description, UDim2.new(1, 0, 0, 28), false).TextColor3 = Theme.muted
			end
		end
		if not any then
			Widgets.Label(body, ui.EmptyCategory, nil, false)
		end
	end
end

local function petLabel(pet)
	local def = PetConfig.Get(pet.petId)
	return (def and def.name or pet.petId) .. " · " .. pet.evolution .. " · " .. (def and def.rarity or "")
end

local function renderPets(profile)
	local ui = Strings.UI
	Widgets.Label(body, ui.PetLimit, UDim2.new(1, 0, 0, 40), false)
	for slot = 1, 3 do
		local uid = profile.equippedPets[slot]
		local text = string.format(ui.EmptySlot, slot)
		if uid ~= "" then
			for _, pet in ipairs(profile.pets) do
				if pet.uid == uid then
					text = string.format(ui.FilledSlot, slot, petLabel(pet))
				end
			end
		end
		Widgets.Label(body, text, UDim2.new(1, 0, 0, 22), true)
		if uid ~= "" then
			Widgets.Button(body, ui.ClearSlot .. slot, function()
				local result = invoke("UnequipPet", { slot = slot })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
	if #profile.pets == 0 then
		Widgets.Label(body, ui.NoPets, nil, false)
	end
	for _, pet in ipairs(profile.pets) do
		Widgets.Label(body, petLabel(pet), UDim2.new(1, 0, 0, 22), false)
		Widgets.Button(body, ui.EquipPet, function()
			local result = invoke("EquipPet", { uid = pet.uid })
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
end

local function renderFusion(profile)
	local ui = Strings.UI
	Widgets.Label(body, ui.FusionRule, UDim2.new(1, 0, 0, 56), false)
	local selected = {}
	local still = {}
	for _, uid in ipairs(fusionPick) do
		for _, pet in ipairs(profile.pets) do
			if pet.uid == uid then
				table.insert(selected, pet)
				table.insert(still, uid)
			end
		end
	end
	fusionPick = still
	if #selected > 0 then
		local first = selected[1]
		local same = true
		for _, pet in ipairs(selected) do
			if pet.petId ~= first.petId or pet.evolution ~= first.evolution then
				same = false
			end
		end
		local nextEvo = PetConfig.NextEvolution(first.evolution)
		local preview = same and nextEvo and ("Preview: " .. petLabel(first) .. " → " .. nextEvo) or ui.NotIdentical
		Widgets.Label(body, Strings.FusionPreview(#selected, preview), UDim2.new(1, 0, 0, 48), true)
	else
		Widgets.Label(body, ui.NoFusionPick, nil, false)
	end
	Widgets.Button(body, ui.ConfirmFusion, function()
		local result = invoke("FusePets", { uids = fusionPick })
		if result.ok then
			fusionPick = {}
		else
			notify("error", result.error)
		end
	end)
	Widgets.Button(body, ui.ClearFusion, function()
		fusionPick = {}
		Menus.Refresh()
	end)
	for _, pet in ipairs(profile.pets) do
		local marked = false
		for _, uid in ipairs(fusionPick) do
			if uid == pet.uid then
				marked = true
			end
		end
		Widgets.Button(body, (marked and "[x] " or "[ ] ") .. petLabel(pet), function()
			local nextPick = {}
			local removed = false
			for _, uid in ipairs(fusionPick) do
				if uid == pet.uid and not removed then
					removed = true
				else
					table.insert(nextPick, uid)
				end
			end
			if not removed then
				if #nextPick >= 5 then
					notify("error", Strings.Error.OnlyFivePets)
				else
					table.insert(nextPick, pet.uid)
				end
			end
			fusionPick = nextPick
			Menus.Refresh()
		end)
	end
end

local function renderPotions(profile)
	local ui = Strings.UI
	Widgets.Label(body, ui.PotionRule, UDim2.new(1, 0, 0, 40), false)
	local any = false
	for potionId, count in pairs(profile.inventory.potions) do
		any = true
		local def = PotionConfig.Get(potionId)
		Widgets.Label(body, (def and def.name or potionId) .. "  x" .. tostring(count), nil, true)
		if def and def.description then
			Widgets.Label(body, def.description, UDim2.new(1, 0, 0, 32), false).TextColor3 = Theme.muted
		end
		Widgets.Button(body, ui.Use, function()
			local result = invoke("UsePotion", { potionId = potionId })
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
	if not any then
		Widgets.Label(body, ui.NoPotions, nil, false)
	end
end

local function renderRebirth(profile)
	local ui = Strings.UI
	if profile.selectedHero == "" then
		Widgets.Label(body, ui.ChooseHeroFirst, nil, false)
		return
	end
	local hero = profile.heroes[profile.selectedHero]
	local classDef = HeroConfig.Classes[profile.selectedHero]
	Widgets.Label(body, Strings.RebirthSummary(classDef.displayName, hero.mastery, hero.rebirths), UDim2.new(1, 0, 0, 28), true)
	Widgets.Label(body, ui.RebirthAvailable, UDim2.new(1, 0, 0, 56), false)
	Widgets.Label(body, ui.RebirthLost, UDim2.new(1, 0, 0, 56), false)
	Widgets.Label(body, ui.RebirthKept, UDim2.new(1, 0, 0, 56), false)
	Widgets.Button(body, ui.PrepareRebirth, function()
		local result = invoke("Rebirth", { step = "preview" })
		if result.ok then
			rebirthArmed = true
			notify("info", ui.ConfirmWindow)
			Menus.Refresh()
			rebirthArmed = true
		else
			notify("error", result.error)
		end
	end)
	if rebirthArmed then
		Widgets.Button(body, ui.ConfirmRebirth, function()
			local result = invoke("Rebirth", { step = "confirm" })
			rebirthArmed = false
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
end

local function renderArenas(profile)
	local ui = Strings.UI
	local hero = profile.selectedHero ~= "" and profile.heroes[profile.selectedHero]
	Widgets.Label(body, ui.ArenaIntro, UDim2.new(1, 0, 0, 48), false)
	Widgets.Button(body, ui.ReturnLobby, function()
		local result = invoke("Teleport", { destination = "lobby" })
		if not result.ok then
			notify("error", result.error)
		end
	end)
	if not hero then
		return
	end
	for _, arena in ipairs(ArenaConfig) do
		if arena.index == 1 then
			local unlocked = hero.unlockedArenas["1"] == true
			Widgets.Label(body, Strings.ArenaRow(arena.index, arena.name, arena.mastery, Strings.Free(), unlocked), UDim2.new(1, 0, 0, 36), true)
			Widgets.Button(body, ui.EnterArena .. arena.index, function()
				local result = invoke("Teleport", { arenaIndex = 1 })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		else
			local saved = hero.unlockedArenas[tostring(arena.index)] == true
			Widgets.Label(body, arena.name .. " · " .. ui.ArenaLater .. (saved and " · saved" or ""), UDim2.new(1, 0, 0, 28), false).TextColor3 = Theme.muted
		end
	end
end

local function renderQuests(profile)
	local ui = Strings.UI
	for _, quest in ipairs(QuestConfig) do
		local state = profile.quests[quest.id] or { progress = 0, completed = false }
		local status = state.completed and ui.Completed or (tostring(state.progress) .. "/" .. tostring(quest.goal))
		Widgets.Label(body, quest.name .. " · " .. status, nil, true)
		Widgets.Label(body, quest.description, UDim2.new(1, 0, 0, 36), false)
	end
end

local function renderEggs(_profile)
	local ui = Strings.UI
	Widgets.Label(body, ui.EggIntro, UDim2.new(1, 0, 0, 56), false)
	for _, key in ipairs({ "coin", "advanced" }) do
		local egg = PetConfig.GetWorldEgg(key)
		Widgets.Label(body, egg.name .. " · " .. Strings.Coins(Rules.FormatNumber(egg.cost)) .. " · provisional", UDim2.new(1, 0, 0, 28), true)
		Widgets.Button(body, ui.OpenEgg .. egg.name, function()
			local result = invoke("OpenEgg", { worldEgg = key })
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
	local premium = PetConfig.GetWorldEgg("premium")
	Widgets.Label(body, premium.name .. ui.NotForSale, nil, true).TextColor3 = Theme.gold
	Widgets.Button(body, ui.ShowOdds, function()
		local result = invoke("OpenEgg", { worldEgg = "premium" })
		notify("info", result.error or ui.NoPurchase)
		if result.odds then
			notify("info", result.odds)
		end
	end)
end

local PAGES = {
	{ id = "heroes", title = Strings.UI.Heroes, render = renderHeroes },
	{ id = "upgrades", title = Strings.UI.Upgrades, render = renderUpgrades },
	{ id = "inventory", title = Strings.UI.Inventory, render = renderInventory },
	{ id = "pets", title = Strings.UI.Pets, render = renderPets },
	{ id = "skills", title = Strings.UI.Skills, render = renderSkills },
	{ id = "potions", title = Strings.UI.Potions, render = renderPotions },
	{ id = "rebirth", title = Strings.UI.Rebirth, render = renderRebirth },
	{ id = "quests", title = Strings.UI.Quests, render = renderQuests },
	{ id = "arenas", title = Strings.UI.Arenas, render = renderArenas },
	{ id = "fusion", title = Strings.UI.Fusion, render = renderFusion },
	{ id = "eggs", title = Strings.UI.Eggs, render = renderEggs },
}

function Menus.Refresh()
	if not body or not openName then
		return
	end
	local profile = Menus.GetProfile and Menus.GetProfile() or nil
	Widgets.Clear(body)
	if not profile then
		Widgets.Label(body, Strings.UI.Loading, nil, false)
		return
	end
	if profile.selectedHero == "" and openName ~= "heroes" and openName ~= "quests" then
		Widgets.Label(body, Strings.UI.ChooseHeroFirst, nil, false)
		return
	end
	for _, page in ipairs(PAGES) do
		if page.id == openName then
			title.Text = page.title
			page.render(profile)
		end
	end
end

function Menus.Mount(parent, invoker, notifier, getProfile)
	invoke = invoker
	notify = notifier
	Menus.GetProfile = getProfile

	local bar = Instance.new("ScrollingFrame")
	bar.Name = "MenuBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -8)
	bar.Size = UDim2.new(1, -16, 0, 52)
	bar.BackgroundColor3 = Theme.bg
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.ScrollBarThickness = 4
	bar.ScrollingDirection = Enum.ScrollingDirection.X
	bar.AutomaticCanvasSize = Enum.AutomaticSize.X
	bar.CanvasSize = UDim2.new()
	bar.Parent = parent
	Widgets.Corner(bar, 10)
	local layout = Widgets.List(bar, Enum.FillDirection.Horizontal, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	Widgets.Padding(bar, 6)

	shell = Instance.new("Frame")
	shell.Name = "Panel"
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.42)
	shell.Size = UDim2.fromScale(0.92, 0.62)
	shell.BackgroundColor3 = Theme.panel
	shell.Visible = false
	shell.Parent = parent
	Widgets.Corner(shell, 14)
	Widgets.Stroke(shell, Theme.gold, 1.4)
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(720, 560)
	cap.Parent = shell

	title = Widgets.Label(shell, "", UDim2.new(1, -120, 0, 36), true)
	title.Position = UDim2.fromOffset(16, 10)
	title.TextSize = 20
	local close = Widgets.Button(shell, Strings.UI.Close, function()
		shell.Visible = false
		openName = nil
	end)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 10)
	close.Size = UDim2.fromOffset(96, 36)

	body = Widgets.Scroll(shell)
	body.Position = UDim2.fromOffset(12, 54)
	body.Size = UDim2.new(1, -24, 1, -66)

	for _, page in ipairs(PAGES) do
		local button = Widgets.Button(bar, page.title, function()
			if openName == page.id and shell.Visible then
				shell.Visible = false
				openName = nil
				return
			end
			openName = page.id
			shell.Visible = true
			if page.id == "rebirth" then
				rebirthArmed = false
			end
			Menus.Refresh()
		end)
		button.Size = UDim2.fromOffset(108, 36)
	end
end

function Menus.Update()
	if shell and shell.Visible then
		local keepArmed = rebirthArmed
		Menus.Refresh()
		if openName == "rebirth" then
			rebirthArmed = keepArmed
		end
	end
end

return Menus
