local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HeroConfig = require(Shared:WaitForChild("HeroConfig"))
local Strings = require(Shared:WaitForChild("Strings"))

local HeroSelect = {}

local root
local chosen
local status

function HeroSelect.Mount(parent, invoke, notify)
	local ui = Strings.UI
	root = Instance.new("Frame")
	root.Name = "HeroSelect"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Theme.bg
	root.BackgroundTransparency = 0.12
	root.Visible = false
	root.ZIndex = 20
	root.Parent = parent

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.46)
	panel.Size = UDim2.fromScale(0.9, 0.72)
	panel.BackgroundColor3 = Theme.panel
	panel.Parent = root
	Widgets.Corner(panel, 14)
	Widgets.Stroke(panel, Theme.gold, 1.5)
	Widgets.Padding(panel, 16)
	Widgets.List(panel, Enum.FillDirection.Vertical, 10)
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(520, 620)
	cap.Parent = panel

	local title = Widgets.Label(panel, ui.SelectHeroTitle, UDim2.new(1, 0, 0, 32), true)
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Center
	local body = Widgets.Label(panel, ui.SelectHeroBody, UDim2.new(1, 0, 0, 40), false)
	body.TextXAlignment = Enum.TextXAlignment.Center

	chosen = "Warrior"
	Widgets.Label(panel, "Warrior\n" .. HeroConfig.Classes.Warrior.description, UDim2.new(1, 0, 0, 64), true).TextXAlignment = Enum.TextXAlignment.Center

	status = Widgets.Label(panel, ui.TapHero, UDim2.new(1, 0, 0, 36), false)
	status.TextXAlignment = Enum.TextXAlignment.Center
	Widgets.Button(panel, ui.ConfirmChoice, function()
		local result = invoke("SelectHero", { heroId = "Warrior" })
		if not result.ok then
			notify("error", result.error or ui.ChoiceFailed)
		end
	end)
	return root
end

function HeroSelect.Update(profile, ready, errorText)
	if not root then
		return
	end
	if not ready then
		root.Visible = true
		status.Text = errorText or Strings.UI.Loading
		return
	end
	local needsChoice = profile and profile.firstHeroChosen ~= true
	root.Visible = needsChoice == true
	if needsChoice and not chosen then
		status.Text = Strings.UI.TapHero
	end
end

return HeroSelect
