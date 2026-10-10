local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HeroConfig = require(Shared:WaitForChild("HeroConfig"))
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Rules = require(Shared:WaitForChild("Rules"))
local Strings = require(Shared:WaitForChild("Strings"))

local HUD = {}

local refs = {}

local function ensureBar(parent, name, color, y)
	local label = Widgets.Label(parent, name, UDim2.new(1, 0, 0, 16), true)
	label.LayoutOrder = y
	local back, fill = Widgets.Bar(parent, color, 1)
	back.LayoutOrder = y + 1
	return label, fill
end

function HUD.Mount(parent)
	local root = Instance.new("Frame")
	root.Name = "HUD"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = parent

	local left = Instance.new("Frame")
	left.Name = "Vitals"
	left.BackgroundColor3 = Theme.bg
	left.BackgroundTransparency = 0.18
	left.Position = UDim2.fromOffset(12, 12)
	left.Size = UDim2.new(0.42, 0, 0, 168)
	left.Parent = root
	Widgets.Corner(left, 12)
	Widgets.Stroke(left, Theme.gold, 1.2)
	Widgets.Padding(left, 10)
	Widgets.List(left, Enum.FillDirection.Vertical, 4)
	local sizeCap = Instance.new("UISizeConstraint")
	sizeCap.MaxSize = Vector2.new(340, 190)
	sizeCap.MinSize = Vector2.new(190, 140)
	sizeCap.Parent = left

	refs.hero = Widgets.Label(left, "Hero", UDim2.new(1, 0, 0, 20), true)
	refs.hero.LayoutOrder = 1
	refs.hpText, refs.hpFill = ensureBar(left, "HP", Theme.hp, 2)
	refs.manaText, refs.manaFill = ensureBar(left, "Mana", Theme.mana, 4)
	refs.xpText, refs.xpFill = ensureBar(left, "Mastery", Theme.xp, 6)

	local right = Instance.new("Frame")
	right.Name = "Wallet"
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.new(1, -12, 0, 12)
	right.Size = UDim2.new(0.4, 0, 0, 92)
	right.BackgroundColor3 = Theme.bg
	right.BackgroundTransparency = 0.18
	right.Parent = root
	Widgets.Corner(right, 12)
	Widgets.Stroke(right, Theme.gold, 1.2)
	Widgets.Padding(right, 10)
	Widgets.List(right, Enum.FillDirection.Vertical, 2)
	local rightCap = Instance.new("UISizeConstraint")
	rightCap.MaxSize = Vector2.new(260, 110)
	rightCap.MinSize = Vector2.new(150, 80)
	rightCap.Parent = right
	refs.coins = Widgets.Label(right, "Coins 0", UDim2.new(1, 0, 0, 22), true)
	refs.rebirth = Widgets.Label(right, "Rebirth 0", UDim2.new(1, 0, 0, 18), false)
	refs.meta = Widgets.Label(right, "", UDim2.new(1, 0, 0, 18), false)
	refs.coins.TextColor3 = Theme.gold

	local skills = Instance.new("Frame")
	skills.Name = "Skills"
	skills.AnchorPoint = Vector2.new(0.5, 1)
	skills.Position = UDim2.new(0.5, 0, 1, -72)
	skills.Size = UDim2.new(0.7, 0, 0, 64)
	skills.BackgroundTransparency = 1
	skills.Parent = root
	local skillLayout = Widgets.List(skills, Enum.FillDirection.Horizontal, 8)
	skillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	skillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	refs.skills = skills
	refs.skillCards = {}

	refs.root = root
	return root
end

local function skillCard(parent, ability)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(156, 58)
	card.BackgroundColor3 = Theme.panel
	card.Parent = parent
	Widgets.Corner(card, 8)
	Widgets.Stroke(card, Theme.stroke, 1)
	local name = Widgets.Label(card, ability.name, UDim2.new(1, -8, 0, 20), true)
	name.Position = UDim2.fromOffset(6, 4)
	local detail = Widgets.Label(card, "", UDim2.new(1, -8, 0, 16), false)
	detail.Position = UDim2.fromOffset(6, 24)
	detail.TextColor3 = Theme.muted
	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.45
	shade.Size = UDim2.fromScale(1, 1)
	shade.Visible = false
	shade.Parent = card
	Widgets.Corner(shade, 8)
	return { frame = card, name = name, detail = detail, shade = shade, ability = ability }
end

function HUD.Update(profile, vitals)
	if not refs.root then
		return
	end
	local show = profile and profile.firstHeroChosen and profile.selectedHero ~= ""
	refs.root.Visible = show == true
	if not show then
		return
	end
	local ui = Strings.UI
	local classDef = HeroConfig.Classes[profile.selectedHero]
	local hero = profile.heroes[profile.selectedHero]
	refs.hero.Text = classDef.displayName .. "  ·  " .. ui.MasteryWord .. " " .. tostring(hero.mastery)
	local hp = vitals.hp or 0
	local maxHp = vitals.maxHp or 1
	refs.hpText.Text = string.format("HP  %d / %d", math.floor(hp + 0.5), math.floor(maxHp + 0.5))
	refs.hpFill.Size = UDim2.fromScale(math.clamp(hp / math.max(1, maxHp), 0, 1), 1)
	local isMage = profile.selectedHero == "Mage"
	refs.manaText.Visible = isMage
	refs.manaFill.Parent.Visible = isMage
	if isMage then
		local mana = vitals.mana or 0
		local maxMana = vitals.maxMana or 1
		refs.manaText.Text = string.format("Mana  %d / %d", math.floor(mana + 0.5), math.floor(maxMana + 0.5))
		refs.manaFill.Size = UDim2.fromScale(math.clamp(mana / math.max(1, maxMana), 0, 1), 1)
	end
	local need = Rules.XpToNext(hero.mastery, GameConfig.MasteryCurve, GameConfig.MaxMastery)
	local ratio = 1
	if need then
		ratio = hero.xp / need
		refs.xpText.Text = string.format("XP  %d / %d   ·   %s %d", hero.xp, need, ui.PointsWord, hero.skillPoints)
	else
		refs.xpText.Text = ui.MasteryWord .. " 50  ·  " .. ui.PointsWord .. " " .. tostring(hero.skillPoints)
	end
	refs.xpFill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	refs.coins.Text = "Coins  " .. Rules.FormatNumber(profile.coins)
	refs.rebirth.Text = ui.RebirthWord .. "  " .. tostring(hero.rebirths) .. "   ·   " .. ui.TotalWord .. " " .. tostring(Rules.TotalRebirths(profile))
	local shield = math.floor(vitals.shield or 0)
	refs.meta.Text = shield > 0 and (ui.Shield .. tostring(shield)) or (ui.DamageWord .. " " .. tostring(math.floor((vitals.damage or 0) + 0.5)))

	local abilities = AbilityConfig[profile.selectedHero]
	if refs.skillSignature ~= profile.selectedHero then
		refs.skillSignature = profile.selectedHero
		for _, child in ipairs(refs.skills:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		refs.skillCards = {}
		for _, ability in ipairs(abilities) do
			table.insert(refs.skillCards, skillCard(refs.skills, ability))
		end
	end
	for _, card in ipairs(refs.skillCards) do
		local unlocked = Rules.AbilityUnlocked(hero.mastery, card.ability)
		local remain = vitals.cooldowns and vitals.cooldowns[card.ability.id] or 0
		if not unlocked then
			card.detail.Text = ui.MasteryRequired .. tostring(card.ability.masteryRequired)
			card.shade.Visible = true
		elseif remain > 0.05 then
			card.detail.Text = string.format(ui.Cooldown, remain)
			card.shade.Visible = true
		else
			local mana = card.ability.mana or 0
			card.detail.Text = mana > 0 and (tostring(mana) .. " " .. ui.ManaWord) or ui.Ready
			card.shade.Visible = false
		end
	end
end

return HUD
