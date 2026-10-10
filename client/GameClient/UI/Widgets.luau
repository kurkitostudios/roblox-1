local Theme = require(script.Parent.Theme)

local Widgets = {}

function Widgets.Corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

function Widgets.Stroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.stroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = 0.35
	stroke.Parent = parent
	return stroke
end

function Widgets.Padding(parent, px)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, px)
	padding.PaddingBottom = UDim.new(0, px)
	padding.PaddingLeft = UDim.new(0, px)
	padding.PaddingRight = UDim.new(0, px)
	padding.Parent = parent
	return padding
end

function Widgets.List(parent, direction, gap)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, gap or 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

function Widgets.Label(parent, text, size, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size or UDim2.new(1, 0, 0, 22)
	label.Font = bold and Theme.fontBold or Theme.font
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextColor3 = Theme.text
	label.TextWrapped = true
	label.Text = text or ""
	label.Parent = parent
	return label
end

function Widgets.Button(parent, text, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 44)
	button.BackgroundColor3 = Theme.panelAlt
	button.TextColor3 = Theme.text
	button.Font = Theme.fontBold
	button.TextSize = 16
	button.TextWrapped = true
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent
	Widgets.Corner(button, 8)
	Widgets.Stroke(button, Theme.gold, 1)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 186, 170))
	gradient.Parent = button
	if callback then
		button.Activated:Connect(callback)
	end
	return button
end

function Widgets.Bar(parent, color, ratio)
	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, 0, 0, 16)
	back.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
	back.BorderSizePixel = 0
	back.Parent = parent
	Widgets.Corner(back, 6)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(math.clamp(ratio or 0, 0, 1), 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back
	Widgets.Corner(fill, 6)
	return back, fill
end

function Widgets.Scroll(parent)
	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Theme.gold
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent
	Widgets.List(scroll, Enum.FillDirection.Vertical, 8)
	Widgets.Padding(scroll, 4)
	return scroll
end

function Widgets.Clear(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

return Widgets
