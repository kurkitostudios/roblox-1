-- Anteprima isolata del Warrior. Usa WarriorVisualBuilder.Apply, lo stesso
-- codice del personaggio giocabile. Non parte da sola e non resta in un
-- server pubblicato.

local RunService = game:GetService("RunService")
local WarriorVisualBuilder = require(script.Parent.WarriorVisualBuilder)
local Palette = require(script.Parent.WarriorPalette)

local WarriorPreview = {}

local FOLDER_NAME = "KurkitoWarriorPreview"
-- Fuori dal lobby (il lobby arriva circa a Z = -250) e sopra il suolo.
local ORIGIN = CFrame.new(0, 18, -640)

-- Camera relativa all'HumanoidRootPart. Il volto guarda verso -Z.
local VIEWS = {
	front = { Vector3.new(0, 0.35, -12), Vector3.new(0, 0.15, 0) },
	back = { Vector3.new(0, 0.35, 12), Vector3.new(0, 0.15, 0) },
	left = { Vector3.new(-12, 0.35, 0), Vector3.new(0, 0.15, 0) },
	right = { Vector3.new(12, 0.35, 0), Vector3.new(0, 0.15, 0) },
	threequarter = { Vector3.new(7.5, 1.1, -9), Vector3.new(0, 0.25, 0) },
	face = { Vector3.new(0, 1.55, -4.2), Vector3.new(0, 1.65, 0) },
	chest = { Vector3.new(0.2, 0.55, -4.6), Vector3.new(0, 0.45, 0) },
	belt = { Vector3.new(0, -0.85, -4.4), Vector3.new(0, -1.05, 0) },
	boots = { Vector3.new(0, -1.6, -5.2), Vector3.new(0, -2.35, 0) },
	club = { Vector3.new(3.4, 1.15, -4.2), Vector3.new(1.35, 1.35, -0.2) },
}

function WarriorPreview.FolderName()
	return FOLDER_NAME
end

function WarriorPreview.DestroyIfPublished()
	if RunService:IsStudio() then
		return
	end
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
end

function WarriorPreview.Clear()
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
end

local function anchored(parent, name, size, cf, color, transparency)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cf
	piece.Color = color
	piece.Material = Enum.Material.SmoothPlastic
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = false
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.Transparency = transparency or 0
	piece.Parent = parent
	return piece
end

local function buildRig(parent)
	local model = Instance.new("Model")
	model.Name = "Warrior"
	model.Parent = parent
	-- Pose neutra in piedi. I nomi sono quelli di un rig R15, così Apply
	-- aggancia gli stessi arti del personaggio giocabile.
	local specs = {
		{ "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 2.72, 0), 1 },
		{ "LowerTorso", Vector3.new(1.78, 0.78, 1.02), Vector3.new(0, 2.18, 0), 0 },
		{ "UpperTorso", Vector3.new(2.12, 1.28, 1.08), Vector3.new(0, 3.18, 0), 0 },
		{ "Head", Vector3.new(1.22, 1.16, 1.22), Vector3.new(0, 4.46, 0), 0 },
		{ "LeftUpperArm", Vector3.new(0.9, 1.08, 0.9), Vector3.new(-1.58, 3.38, 0.02), 0 },
		{ "LeftLowerArm", Vector3.new(0.82, 0.96, 0.82), Vector3.new(-1.62, 2.48, -0.12), 0 },
		{ "LeftHand", Vector3.new(0.74, 0.42, 0.8), Vector3.new(-1.62, 1.92, -0.16), 0 },
		{ "RightUpperArm", Vector3.new(0.9, 1.08, 0.9), Vector3.new(1.58, 3.38, 0.02), 0 },
		{ "RightLowerArm", Vector3.new(0.82, 0.96, 0.82), Vector3.new(1.62, 2.48, -0.16), 0 },
		{ "RightHand", Vector3.new(0.74, 0.42, 0.8), Vector3.new(1.62, 2.02, -0.28), 0 },
		{ "LeftUpperLeg", Vector3.new(0.98, 1.16, 0.92), Vector3.new(-0.46, 1.42, 0), 0 },
		{ "LeftLowerLeg", Vector3.new(0.86, 1.05, 0.8), Vector3.new(-0.46, 0.72, 0), 0 },
		{ "LeftFoot", Vector3.new(0.9, 0.4, 1.25), Vector3.new(-0.46, 0.2, -0.06), 0 },
		{ "RightUpperLeg", Vector3.new(0.98, 1.16, 0.92), Vector3.new(0.46, 1.42, 0), 0 },
		{ "RightLowerLeg", Vector3.new(0.86, 1.05, 0.8), Vector3.new(0.46, 0.72, 0), 0 },
		{ "RightFoot", Vector3.new(0.9, 0.4, 1.25), Vector3.new(0.46, 0.2, -0.06), 0 },
	}
	local root = nil
	for _, spec in ipairs(specs) do
		local piece = anchored(model, spec[1], spec[2], ORIGIN * CFrame.new(spec[3]), Palette.Skin, spec[4])
		if spec[1] == "HumanoidRootPart" then
			root = piece
		end
	end
	model.PrimaryPart = root
	return model
end

local function buildRoom(folder)
	local gray = Palette.PreviewBackdrop
	anchored(folder, "PreviewFloor", Vector3.new(36, 1, 36), ORIGIN * CFrame.new(0, -0.5, 0), gray, 0)
	anchored(folder, "PreviewWallBack", Vector3.new(36, 18, 1), ORIGIN * CFrame.new(0, 8.5, 14), gray, 0)
	anchored(folder, "PreviewWallLeft", Vector3.new(1, 18, 28), ORIGIN * CFrame.new(-14, 8.5, 2), gray, 0)
	anchored(folder, "PreviewWallRight", Vector3.new(1, 18, 28), ORIGIN * CFrame.new(14, 8.5, 2), gray, 0)
	local lamps = {
		Vector3.new(0, 7, -8),
		Vector3.new(-6, 5, 3),
		Vector3.new(6, 5, 3),
		Vector3.new(0, 4, 6),
	}
	for _, offset in ipairs(lamps) do
		local lamp = anchored(folder, "PreviewLight", Vector3.new(0.2, 0.2, 0.2), ORIGIN * CFrame.new(offset), gray, 1)
		local light = Instance.new("PointLight")
		light.Brightness = 1.35
		light.Range = 24
		light.Shadows = false
		light.Color = Palette.PreviewLight
		light.Parent = lamp
	end
end

function WarriorPreview.Build()
	if not RunService:IsStudio() then
		return nil
	end
	WarriorPreview.Clear()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder:SetAttribute("KurkitoPreview", true)
	folder.Parent = workspace
	buildRoom(folder)
	local model = buildRig(folder)
	local built = WarriorVisualBuilder.Apply(model, {
		stats = { HP = 1, DMG = 1, Speed = 1 },
	})
	-- Stessa geometria del giocatore. In anteprima i pezzi restano fermi,
	-- così la posa neutra non cade quando Studio simula.
	local visuals = model:FindFirstChild("KurkitoVisuals")
	if visuals then
		for _, child in ipairs(visuals:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Anchored = true
			end
		end
	end
	folder:SetAttribute("Built", built == true)
	folder:SetAttribute("PartCount", model:GetAttribute("KurkitoVisualParts") or 0)
	return folder
end

function WarriorPreview.AimCamera(view)
	if not RunService:IsStudio() then
		return false
	end
	local spec = VIEWS[view]
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	local model = folder and folder:FindFirstChild("Warrior")
	local root = model and model.PrimaryPart
	if not spec or not root then
		return false
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local eye = root.CFrame:PointToWorldSpace(spec[1])
	local focus = root.CFrame:PointToWorldSpace(spec[2])
	camera.CFrame = CFrame.lookAt(eye, focus)
	return true
end

function WarriorPreview.Views()
	local names = {}
	for name in pairs(VIEWS) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return WarriorPreview
