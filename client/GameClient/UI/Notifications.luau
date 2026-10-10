local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Notifications = {}

local stack

function Notifications.Mount(gui)
	stack = Instance.new("Frame")
	stack.Name = "Notifications"
	stack.AnchorPoint = Vector2.new(1, 0)
	stack.Position = UDim2.new(1, -12, 0, 118)
	stack.Size = UDim2.new(0.42, 0, 0.45, 0)
	stack.BackgroundTransparency = 1
	stack.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(360, 420)
	constraint.MinSize = Vector2.new(180, 80)
	constraint.Parent = stack
	Widgets.List(stack, Enum.FillDirection.Vertical, 6)
end

function Notifications.Push(kind, text)
	if not stack or text == nil or text == "" then
		return
	end
	local color = Theme.gold
	if kind == "error" then
		color = Theme.danger
	elseif kind == "xp" then
		color = Theme.xp
	elseif kind == "coins" or kind == "drop" then
		color = Theme.gold
	elseif kind == "quest" then
		color = Color3.fromRGB(140, 120, 220)
	end
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 48)
	card.BackgroundColor3 = Theme.panel
	card.BackgroundTransparency = 0.08
	card.Parent = stack
	Widgets.Corner(card, 8)
	Widgets.Stroke(card, color, 1.4)
	local label = Widgets.Label(card, text, UDim2.new(1, -12, 1, -8), true)
	label.Position = UDim2.fromOffset(8, 4)
	label.TextColor3 = Theme.text
	task.delay(4.2, function()
		if card.Parent then
			card:Destroy()
		end
	end)
	local count = 0
	for _, child in ipairs(stack:GetChildren()) do
		if child:IsA("Frame") then
			count += 1
		end
	end
	if count > 5 then
		for _, child in ipairs(stack:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
				break
			end
		end
	end
end

return Notifications
