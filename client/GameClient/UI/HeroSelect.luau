local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HeroConfig = require(Shared:WaitForChild("HeroConfig"))

local HeroSelect = {}

local root
local chosen
local status

function HeroSelect.Mount(parent, invoke, notify)
	root = Instance.new("Frame")
	root.Name = "HeroSelect"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Theme.bg
	root.BackgroundTransparency = 0.15
	root.Visible = false
	root.ZIndex = 20
	root.Parent = parent

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.92, 0.78)
	panel.BackgroundColor3 = Theme.panel
	panel.Parent = root
	Widgets.Corner(panel, 14)
	Widgets.Stroke(panel, Theme.gold, 1.5)
	Widgets.Padding(panel, 16)
	Widgets.List(panel, Enum.FillDirection.Vertical, 10)
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(560, 640)
	cap.Parent = panel

	local title = Widgets.Label(panel, "Scegli il tuo primo eroe", UDim2.new(1, 0, 0, 32), true)
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Center
	Widgets.Label(panel, "La scelta è gratuita e definitiva. Gli altri eroi si sbloccano con le missioni.", UDim2.new(1, 0, 0, 40), false).TextXAlignment = Enum.TextXAlignment.Center

	for _, heroId in ipairs(HeroConfig.Order) do
		local classDef = HeroConfig.Classes[heroId]
		local button = Widgets.Button(panel, classDef.displayName .. "\n" .. classDef.description, function()
			chosen = heroId
			status.Text = "Selezionato: " .. classDef.displayName .. ". Conferma per continuare."
		end)
		button.Size = UDim2.new(1, 0, 0, 64)
		button.BackgroundColor3 = classDef.color:Lerp(Theme.panel, 0.55)
	end

	status = Widgets.Label(panel, "Tocca un eroe, poi conferma.", UDim2.new(1, 0, 0, 36), false)
	status.TextXAlignment = Enum.TextXAlignment.Center
	Widgets.Button(panel, "Conferma scelta", function()
		if not chosen then
			notify("error", "Seleziona un eroe prima di confermare.")
			return
		end
		local result = invoke("SelectHero", { heroId = chosen })
		if not result.ok then
			notify("error", result.error or "Scelta non riuscita.")
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
		status.Text = errorText or "Caricamento dati..."
		return
	end
	local needsChoice = profile and profile.firstHeroChosen ~= true
	root.Visible = needsChoice == true
	if needsChoice and not chosen then
		status.Text = "Tocca un eroe, poi conferma."
	end
end

return HeroSelect
