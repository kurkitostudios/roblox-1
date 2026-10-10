-- Nasconde e sfuma i testi 3D in base alla distanza.
-- Non tocca la UI del giocatore: solo i cartelli marcati KurkitoWorldText.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local WorldTextConfig = require(Shared:WaitForChild("WorldTextConfig"))

local WorldText = {}

local function origin()
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position
	end
	if camera then
		return camera.CFrame.Position
	end
	return Vector3.zero
end

local function adorneeOf(gui)
	if gui:IsA("BillboardGui") then
		local adornee = gui.Adornee
		if adornee and adornee:IsA("BasePart") then
			return adornee
		end
	end
	if gui.Parent and gui.Parent:IsA("BasePart") then
		return gui.Parent
	end
	return nil
end

local function fadeLabel(label, alpha)
	if label:GetAttribute("KurkitoReady") ~= true then
		label:SetAttribute("KurkitoBaseText", label.TextTransparency)
		label:SetAttribute("KurkitoBaseBg", label.BackgroundTransparency)
		label:SetAttribute("KurkitoBaseStroke", label.TextStrokeTransparency)
		label:SetAttribute("KurkitoReady", true)
	end
	local baseText = label:GetAttribute("KurkitoBaseText") or 0
	local baseBg = label:GetAttribute("KurkitoBaseBg") or 1
	local baseStroke = label:GetAttribute("KurkitoBaseStroke") or 1
	label.TextTransparency = baseText + (1 - baseText) * alpha
	label.TextStrokeTransparency = baseStroke + (1 - baseStroke) * alpha
	if baseBg < 0.99 then
		label.BackgroundTransparency = baseBg + (1 - baseBg) * alpha
	end
end

local function apply(gui, distance, maxDistance)
	local fadeStart = maxDistance * WorldTextConfig.FadeStart
	local alpha = 0
	if distance >= maxDistance then
		alpha = 1
	elseif distance > fadeStart then
		alpha = (distance - fadeStart) / math.max(0.1, maxDistance - fadeStart)
	end
	local visible = distance < maxDistance
	if gui:IsA("SurfaceGui") or gui:IsA("BillboardGui") then
		gui.Enabled = visible
	end
	if not visible then
		return
	end
	for _, child in ipairs(gui:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			fadeLabel(child, alpha)
		end
	end
end

function WorldText.Start()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < WorldTextConfig.UpdateInterval then
			return
		end
		elapsed = 0
		local from = origin()
		for _, gui in ipairs(CollectionService:GetTagged(WorldTextConfig.Tag)) do
			if gui.Parent then
				local part = adorneeOf(gui)
				local maxDistance = gui:GetAttribute("KurkitoMaxDistance") or WorldTextConfig.Distance(gui:GetAttribute("KurkitoText"))
				if part and maxDistance then
					apply(gui, (part.Position - from).Magnitude, maxDistance)
				end
			end
		end
	end)
end

return WorldText
