-- Pannello del mercante tribale. Si apre dal ProximityPrompt, non dalla barra menu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local LootConfig = require(Shared:WaitForChild("LootConfig"))
local MerchantConfig = require(Shared:WaitForChild("MerchantConfig"))

local Merchant = {}

local shell
local body
local invoke
local notify
local getProfile
local visible = false

local function rowsFor(profile)
	local list = {}
	if not profile or type(profile.inventory) ~= "table" then
		return list
	end
	for _, category in ipairs({ "materials", "collectibles" }) do
		local bucket = profile.inventory[category]
		if type(bucket) == "table" then
			local ids = {}
			for itemId, count in pairs(bucket) do
				if type(count) == "number" and count > 0 then
					table.insert(ids, itemId)
				end
			end
			table.sort(ids)
			for _, itemId in ipairs(ids) do
				local def = LootConfig.GetItem(itemId)
				local rate = MerchantConfig.Rates[category]
				if def and rate then
					table.insert(list, {
						itemId = itemId,
						name = def.name,
						count = bucket[itemId],
						rate = rate,
					})
				end
			end
		end
	end
	return list
end

local function sell(itemId, count)
	local result = invoke("SellLoot", { itemId = itemId, count = count })
	if not result.ok then
		notify("error", result.error or Strings.Error.RequestFailed)
	end
end

local function render()
	if not body then
		return
	end
	Widgets.Clear(body)
	local ui = Strings.UI
	Widgets.Label(body, ui.MerchantHint, UDim2.new(1, 0, 0, 48), false)
	Widgets.Label(body, ui.MerchantStay, UDim2.new(1, 0, 0, 22), false).TextColor3 = Theme.muted
	local profile = getProfile and getProfile() or nil
	if not profile then
		Widgets.Label(body, ui.Loading, nil, false)
		return
	end
	local rows = rowsFor(profile)
	if #rows == 0 then
		Widgets.Label(body, ui.MerchantEmpty, UDim2.new(1, 0, 0, 44), false)
		return
	end
	for _, row in ipairs(rows) do
		Widgets.Label(body, string.format("%s  x%d   %d Coins each", row.name, row.count, row.rate), UDim2.new(1, 0, 0, 24), true)
		local sellOne = Widgets.Button(body, ui.SellOne, function()
			sell(row.itemId, 1)
		end)
		sellOne.Size = UDim2.new(1, 0, 0, 40)
		local sellAll = Widgets.Button(body, ui.SellAll .. " (" .. tostring(math.min(row.count, MerchantConfig.MaxPerSale)) .. ")", function()
			sell(row.itemId, math.min(row.count, MerchantConfig.MaxPerSale))
		end)
		sellAll.Size = UDim2.new(1, 0, 0, 40)
	end
end

function Merchant.Mount(parent, invoker, notifier, profileGetter)
	invoke = invoker
	notify = notifier
	getProfile = profileGetter
	local ui = Strings.UI

	shell = Instance.new("Frame")
	shell.Name = "TribalMerchant"
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.42)
	shell.Size = UDim2.fromScale(0.9, 0.62)
	shell.BackgroundColor3 = Theme.panel
	shell.Visible = false
	shell.ZIndex = 12
	shell.Parent = parent
	Widgets.Corner(shell, 14)
	Widgets.Stroke(shell, Theme.gold, 1.6)
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(640, 540)
	cap.Parent = shell

	local title = Widgets.Label(shell, ui.MerchantTitle, UDim2.new(1, -120, 0, 28), true)
	title.Position = UDim2.fromOffset(16, 8)
	title.TextSize = 22
	local subtitle = Widgets.Label(shell, ui.MerchantSell, UDim2.new(1, -120, 0, 20), false)
	subtitle.Position = UDim2.fromOffset(16, 34)
	subtitle.TextColor3 = Theme.gold

	local close = Widgets.Button(shell, ui.Close, function()
		visible = false
		shell.Visible = false
	end)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 10)
	close.Size = UDim2.fromOffset(96, 36)

	body = Widgets.Scroll(shell)
	body.Position = UDim2.fromOffset(12, 64)
	body.Size = UDim2.new(1, -24, 1, -76)
end

function Merchant.Open()
	visible = true
	if shell then
		shell.Visible = true
	end
	render()
end

function Merchant.Update()
	if visible then
		render()
	end
end

return Merchant
