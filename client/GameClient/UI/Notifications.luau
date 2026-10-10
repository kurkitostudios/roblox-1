local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Notifications = {}

local stack
local MAX_CARDS = 4

local COLORS = {
	error = Theme.danger,
	xp = Theme.xp,
	reward = Theme.xp,
	mastery = Theme.xp,
	coins = Theme.gold,
	drop = Theme.gold,
	item = Theme.gold,
	pet = Color3.fromRGB(150, 110, 220),
	arena = Color3.fromRGB(90, 160, 210),
	skill = Color3.fromRGB(140, 120, 220),
	rebirth = Color3.fromRGB(180, 120, 220),
	quest = Color3.fromRGB(140, 120, 220),
}

function Notifications.Mount(gui)
	stack = Instance.new("Frame")
	stack.Name = "Notifications"
	stack.AnchorPoint = Vector2.new(1, 0)
	stack.Position = UDim2.new(1, -12, 0, 118)
	stack.Size = UDim2.new(0.38, 0, 0, 220)
	stack.BackgroundTransparency = 1
	stack.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(320, 240)
	constraint.MinSize = Vector2.new(180, 40)
	constraint.Parent = stack
	Widgets.List(stack, Enum.FillDirection.Vertical, 6)
end

local function trim()
	local cards = {}
	for _, child in ipairs(stack:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(cards, child)
		end
	end
	while #cards > MAX_CARDS do
		local oldest = table.remove(cards, 1)
		oldest:Destroy()
	end
end

function Notifications.Push(kind, text)
	if not stack or text == nil or text == "" then
		return
	end
	local color = COLORS[kind] or Theme.gold
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 40)
	card.BackgroundColor3 = Theme.panel
	card.BackgroundTransparency = 0.08
	card.Parent = stack
	Widgets.Corner(card, 8)
	Widgets.Stroke(card, color, 1.3)
	local label = Widgets.Label(card, text, UDim2.new(1, -12, 1, -8), true)
	label.Position = UDim2.fromOffset(8, 4)
	label.TextSize = 14
	label.TextColor3 = Theme.text
	card.Position = UDim2.fromOffset(24, 0)
	TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(0, 0),
	}):Play()
	trim()
	task.delay(3.4, function()
		if card.Parent then
			local fade = TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
			fade:Play()
			task.delay(0.2, function()
				if card.Parent then
					card:Destroy()
				end
			end)
		end
	end)
end

return Notifications
