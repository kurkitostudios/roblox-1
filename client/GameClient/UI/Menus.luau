local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HeroConfig = require(Shared:WaitForChild("HeroConfig"))
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))
local ArenaConfig = require(Shared:WaitForChild("ArenaConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local LootConfig = require(Shared:WaitForChild("LootConfig"))
local PetConfig = require(Shared:WaitForChild("PetConfig"))
local PotionConfig = require(Shared:WaitForChild("PotionConfig"))
local QuestConfig = require(Shared:WaitForChild("QuestConfig"))
local Rules = require(Shared:WaitForChild("Rules"))
local Loadout = require(Shared:WaitForChild("Loadout"))

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

local function profileOf(getProfile)
	return getProfile()
end

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
	if statId == "HP" then
		return math.floor(stats.maxHp + 0.5), "HP"
	elseif statId == "DMG" then
		return math.floor(stats.damage + 0.5), "danno"
	elseif statId == "Speed" then
		return math.floor(stats.walkSpeed * 10 + 0.5) / 10, "velocità"
	elseif statId == "Mana" then
		return math.floor(stats.maxMana + 0.5), "mana"
	elseif statId == "AttackSpeed" then
		return math.floor(stats.attackInterval * 100 + 0.5) / 100, "intervallo"
	end
	return 0, ""
end

local function renderHeroes(profile)
	for _, heroId in ipairs(HeroConfig.Order) do
		local classDef = HeroConfig.Classes[heroId]
		local hero = profile.heroes[heroId]
		local unlocked = profile.unlockedHeroes[heroId] == true
		local active = profile.selectedHero == heroId
		local header = active and " (attivo)" or ""
		Widgets.Label(body, classDef.displayName .. header, UDim2.new(1, 0, 0, 22), true).TextColor3 = classDef.color:Lerp(Color3.new(1, 1, 1), 0.35)
		if not unlocked then
			Widgets.Label(body, "Bloccato. Completa le missioni per sbloccarlo in modo permanente.", UDim2.new(1, 0, 0, 36), false)
		else
			Widgets.Label(body, string.format("Maestria %d · Rebirth %d · Punti %d", hero.mastery, hero.rebirths, hero.skillPoints), UDim2.new(1, 0, 0, 20), false)
			if not active then
				Widgets.Button(body, "Usa " .. classDef.displayName, function()
					local result = invoke("SwitchHero", { heroId = heroId })
					if not result.ok then
						notify("error", result.error)
					end
				end)
			end
		end
	end
end

local function renderUpgrades(profile)
	if profile.selectedHero == "" then
		Widgets.Label(body, "Seleziona un eroe.", nil, false)
		return
	end
	local hero = profile.heroes[profile.selectedHero]
	local classDef = HeroConfig.Classes[profile.selectedHero]
	local nowStats = effective(profile)
	Widgets.Label(body, "Skill Point: " .. tostring(hero.skillPoints), nil, true)
	for _, statId in ipairs(classDef.stats) do
		local level = hero.stats[statId]
		local statDef = HeroConfig.StatDefs[statId]
		local currentValue, unit = statReadout(nowStats, statId)
		local cost = Rules.StatCost(level, statDef)
		local nextText = "Livello massimo"
		if cost then
			local copy = Rules.DeepCopy(hero)
			copy.stats[statId] += 1
			local nextStats = effective(profile, copy)
			local nextValue = statReadout(nextStats, statId)
			nextText = string.format("Prossimo: %s (%+0.2f) · %s monete", tostring(nextValue), nextValue - currentValue, Rules.FormatNumber(cost))
		end
		Widgets.Label(body, string.format("%s livello %d · effettivo %s %s", statDef.label, level, tostring(currentValue), unit), UDim2.new(1, 0, 0, 36), true)
		Widgets.Label(body, nextText, UDim2.new(1, 0, 0, 32), false)
		if cost then
			Widgets.Button(body, "Upgrade " .. statDef.label, function()
				local result = invoke("UpgradeStat", { statId = statId })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
	Widgets.Label(body, "Talenti", nil, true)
	for _, talent in ipairs(HeroConfig.Talents) do
		local rank = hero.talents[talent.id] or 0
		Widgets.Label(body, string.format("%s %d/%d — %s", talent.name, rank, talent.maxRank, talent.description), UDim2.new(1, 0, 0, 36), false)
		if rank < talent.maxRank then
			Widgets.Button(body, "Spendi punto: " .. talent.name, function()
				local result = invoke("SpendSkillPoint", { kind = "talent", id = talent.id })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
	Widgets.Label(body, "Abilità", nil, true)
	for _, ability in ipairs(AbilityConfig[profile.selectedHero]) do
		local rank = hero.skillRanks[ability.id] or 0
		local unlocked = Rules.AbilityUnlocked(hero.mastery, ability)
		local state = unlocked and "sbloccata" or ("Maestria " .. ability.masteryRequired)
		Widgets.Label(body, string.format("%s · rango %d/%d · %s", ability.name, rank, AbilityConfig.MaxRank, state), UDim2.new(1, 0, 0, 36), false)
		Widgets.Label(body, ability.description, UDim2.new(1, 0, 0, 20), false).TextColor3 = Theme.muted
		if unlocked and rank < AbilityConfig.MaxRank then
			Widgets.Button(body, "Potenzia " .. ability.name, function()
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
	local tabs = {
		{ id = "equipment", label = "Equip" },
		{ id = "materials", label = "Materiali" },
		{ id = "potions", label = "Pozioni" },
		{ id = "collectibles", label = "Reliquie" },
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
			Widgets.Label(body, string.format("Slot: arma %s · armatura %s · amuleto %s", hero.equippedGear.weapon ~= "" and "sì" or "no", hero.equippedGear.armor ~= "" and "sì" or "no", hero.equippedGear.charm ~= "" and "sì" or "no"), UDim2.new(1, 0, 0, 36), false)
			for _, slot in ipairs({ "weapon", "armor", "charm" }) do
				if hero.equippedGear[slot] ~= "" then
					Widgets.Button(body, "Togli " .. slot, function()
						local result = invoke("UnequipItem", { slot = slot })
						if not result.ok then
							notify("error", result.error)
						end
					end)
				end
			end
		end
		if #profile.inventory.equipment == 0 then
			Widgets.Label(body, "Nessun equipaggiamento.", nil, false)
		end
		for _, entry in ipairs(profile.inventory.equipment) do
			local def = LootConfig.GetItem(entry.itemId)
			local bound = entry.boundHero and (" · " .. entry.boundHero) or " · condiviso"
			Widgets.Label(body, itemName(entry.itemId) .. bound, UDim2.new(1, 0, 0, 22), true)
			if def then
				Widgets.Button(body, "Equipaggia " .. def.name, function()
					local result = invoke("EquipItem", { uid = entry.uid })
					if not result.ok then
						notify("error", result.error)
					end
				end)
			end
		end
		Widgets.Label(body, "I materiali non hanno una forgia in questa build: restano nell'inventario.", UDim2.new(1, 0, 0, 40), false).TextColor3 = Theme.muted
	else
		local bucket = profile.inventory[inventoryTab]
		local any = false
		for itemId, count in pairs(bucket) do
			any = true
			Widgets.Label(body, itemName(itemId) .. "  x" .. tostring(count), nil, false)
		end
		if not any then
			Widgets.Label(body, "Categoria vuota.", nil, false)
		end
	end
end

local function petLabel(pet)
	local def = PetConfig.Get(pet.petId)
	return (def and def.name or pet.petId) .. " · " .. pet.evolution .. " · " .. (def and def.rarity or "")
end

local function renderPets(profile)
	Widgets.Label(body, "Massimo 3 Pet equipaggiati. L'inventario è condiviso e sopravvive al Rebirth.", UDim2.new(1, 0, 0, 40), false)
	for slot = 1, 3 do
		local uid = profile.equippedPets[slot]
		local text = "Slot " .. slot .. ": vuoto"
		if uid ~= "" then
			for _, pet in ipairs(profile.pets) do
				if pet.uid == uid then
					text = "Slot " .. slot .. ": " .. petLabel(pet)
				end
			end
		end
		Widgets.Label(body, text, UDim2.new(1, 0, 0, 22), true)
		if uid ~= "" then
			Widgets.Button(body, "Togli slot " .. slot, function()
				local result = invoke("UnequipPet", { slot = slot })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
	if #profile.pets == 0 then
		Widgets.Label(body, "Nessun Pet. Le uova sono nella zona a sud della lobby.", nil, false)
	end
	for _, pet in ipairs(profile.pets) do
		Widgets.Label(body, petLabel(pet), UDim2.new(1, 0, 0, 22), false)
		Widgets.Button(body, "Equipaggia", function()
			local result = invoke("EquipPet", { uid = pet.uid })
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
end

local function renderFusion(profile)
	Widgets.Label(body, "5 Pet con lo stesso id e la stessa evoluzione diventano 1 del livello successivo. I Pet equipaggiati non si possono fondere.", UDim2.new(1, 0, 0, 56), false)
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
		local preview = same and nextEvo and ("Anteprima: " .. petLabel(first) .. " → " .. nextEvo) or "I Pet selezionati non sono identici."
		if #selected ~= 5 then
			preview = "Selezionati " .. tostring(#selected) .. "/5. " .. preview
		end
		Widgets.Label(body, preview, UDim2.new(1, 0, 0, 48), true)
	else
		Widgets.Label(body, "Nessun Pet selezionato.", nil, false)
	end
	Widgets.Button(body, "Conferma fusione", function()
		local result = invoke("FusePets", { uids = fusionPick })
		if result.ok then
			fusionPick = {}
		else
			notify("error", result.error)
		end
	end)
	Widgets.Button(body, "Azzera selezione", function()
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
					notify("error", "Puoi selezionare solo 5 Pet.")
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
	Widgets.Label(body, "Due pozioni della stessa famiglia non si sommano: la nuova sostituisce durata e potenza.", UDim2.new(1, 0, 0, 40), false)
	local any = false
	for potionId, count in pairs(profile.inventory.potions) do
		any = true
		local def = PotionConfig.Get(potionId)
		Widgets.Label(body, (def and def.name or potionId) .. "  x" .. tostring(count), nil, true)
		Widgets.Button(body, "Usa", function()
			local result = invoke("UsePotion", { potionId = potionId })
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
	if not any then
		Widgets.Label(body, "Nessuna pozione.", nil, false)
	end
end

local function renderRebirth(profile)
	if profile.selectedHero == "" then
		Widgets.Label(body, "Seleziona un eroe.", nil, false)
		return
	end
	local hero = profile.heroes[profile.selectedHero]
	local classDef = HeroConfig.Classes[profile.selectedHero]
	Widgets.Label(body, classDef.displayName .. " · Maestria " .. tostring(hero.mastery) .. " · Rebirth " .. tostring(hero.rebirths), UDim2.new(1, 0, 0, 28), true)
	Widgets.Label(body, "Disponibile a Maestria 50, solo all'altare a est. Ogni Rebirth dà +10% XP e +10% monete permanenti a questo eroe.", UDim2.new(1, 0, 0, 56), false)
	Widgets.Label(body, "Si azzerano: Maestria, XP, statistiche, Skill Point, talenti, abilità, arene e gli equipaggiamenti vincolati a questo eroe.", UDim2.new(1, 0, 0, 56), false)
	Widgets.Label(body, "Restano: monete, Pet, materiali, pozioni, collezionabili, eroi sbloccati, gli altri eroi e gli oggetti senza vincolo di eroe.", UDim2.new(1, 0, 0, 56), false)
	Widgets.Button(body, "Prepara Rebirth", function()
		local result = invoke("Rebirth", { step = "preview" })
		if result.ok then
			rebirthArmed = true
			notify("info", "Conferma entro 30 secondi.")
			Menus.Refresh()
			rebirthArmed = true
		else
			notify("error", result.error)
		end
	end)
	if rebirthArmed then
		Widgets.Button(body, "Conferma Rebirth", function()
			local result = invoke("Rebirth", { step = "confirm" })
			rebirthArmed = false
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
end

local function renderArenas(profile)
	local hero = profile.selectedHero ~= "" and profile.heroes[profile.selectedHero]
	Widgets.Label(body, "L'accesso è dell'eroe attivo. Servono Maestria e pagamento. Il Mondo 2 non ha un portale funzionante.", UDim2.new(1, 0, 0, 48), false)
	Widgets.Button(body, "Torna in lobby", function()
		local result = invoke("Teleport", { destination = "lobby" })
		if not result.ok then
			notify("error", result.error)
		end
	end)
	if not hero then
		return
	end
	for _, arena in ipairs(ArenaConfig) do
		local unlocked = hero.unlockedArenas[tostring(arena.index)] == true
		local cost = arena.cost > 0 and (Rules.FormatNumber(arena.cost) .. " monete") or "gratis"
		Widgets.Label(body, string.format("%d. %s · Maestria %d · %s%s", arena.index, arena.name, arena.mastery, cost, unlocked and " · aperta" or ""), UDim2.new(1, 0, 0, 36), true)
		if unlocked then
			Widgets.Button(body, "Entra nell'arena " .. arena.index, function()
				local result = invoke("Teleport", { arenaIndex = arena.index })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		else
			Widgets.Button(body, "Sblocca arena " .. arena.index, function()
				local result = invoke("UnlockArena", { arenaIndex = arena.index })
				if not result.ok then
					notify("error", result.error)
				end
			end)
		end
	end
end

local function renderQuests(profile)
	for _, quest in ipairs(QuestConfig) do
		local state = profile.quests[quest.id] or { progress = 0, completed = false }
		local status = state.completed and "Completata" or (tostring(state.progress) .. "/" .. tostring(quest.goal))
		Widgets.Label(body, quest.name .. " · " .. status, nil, true)
		Widgets.Label(body, quest.description, UDim2.new(1, 0, 0, 36), false)
	end
end

local function renderEggs(profile)
	local hero = profile.selectedHero ~= "" and profile.heroes[profile.selectedHero]
	Widgets.Label(body, "Apri le uova normali vicino al modello, con l'arena sbloccata. Le uova Robux sono solo vetrine.", UDim2.new(1, 0, 0, 48), false)
	for index = 1, 15 do
		local egg = PetConfig.GetEgg(index)
		local open = hero and hero.unlockedArenas[tostring(index)] == true
		Widgets.Label(body, egg.name .. " · " .. Rules.FormatNumber(egg.cost) .. " monete" .. (open and "" or " · arena bloccata"), UDim2.new(1, 0, 0, 32), true)
		Widgets.Button(body, "Apri uovo " .. index, function()
			local result = invoke("OpenEgg", { arenaIndex = index })
			if not result.ok then
				notify("error", result.error)
			end
		end)
	end
	for specialIndex, egg in ipairs(PetConfig.SpecialEggs) do
		Widgets.Label(body, egg.name .. " · non acquistabile", nil, true).TextColor3 = Theme.gold
		Widgets.Button(body, "Mostra probabilità (nessun acquisto)", function()
			local result = invoke("OpenEgg", { kind = "robux", specialIndex = specialIndex })
			notify("info", result.error or "Nessun acquisto effettuato.")
			if result.odds then
				notify("info", result.odds)
			end
		end)
	end
end

local PAGES = {
	{ id = "heroes", title = "Eroi", render = renderHeroes },
	{ id = "upgrades", title = "Potenziamenti", render = renderUpgrades },
	{ id = "inventory", title = "Inventario", render = renderInventory },
	{ id = "pets", title = "Pet", render = renderPets },
	{ id = "fusion", title = "Fusione", render = renderFusion },
	{ id = "potions", title = "Pozioni", render = renderPotions },
	{ id = "rebirth", title = "Rebirth", render = renderRebirth },
	{ id = "arenas", title = "Arene", render = renderArenas },
	{ id = "quests", title = "Missioni", render = renderQuests },
	{ id = "eggs", title = "Uova", render = renderEggs },
}

function Menus.Refresh()
	if not body or not openName then
		return
	end
	local profile = Menus.GetProfile and Menus.GetProfile() or nil
	Widgets.Clear(body)
	if not profile then
		Widgets.Label(body, "Caricamento dati...", nil, false)
		return
	end
	if profile.selectedHero == "" and openName ~= "heroes" and openName ~= "quests" then
		Widgets.Label(body, "Scegli prima un eroe.", nil, false)
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
	bar.BackgroundTransparency = 0.2
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
	shell.Position = UDim2.fromScale(0.5, 0.46)
	shell.Size = UDim2.fromScale(0.94, 0.72)
	shell.BackgroundColor3 = Theme.panel
	shell.Visible = false
	shell.Parent = parent
	Widgets.Corner(shell, 14)
	Widgets.Stroke(shell, Theme.gold, 1.4)
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(760, 680)
	cap.Parent = shell

	title = Widgets.Label(shell, "", UDim2.new(1, -120, 0, 36), true)
	title.Position = UDim2.fromOffset(16, 10)
	title.TextSize = 20
	local close = Widgets.Button(shell, "Chiudi", function()
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
		button.Size = UDim2.fromOffset(118, 36)
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
