-- OrderedDataStore con aggiornamenti periodici, mai a ogni frame.
-- In Studio usa store dedicati, separati dalla produzione.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local RuntimeState = require(script.Parent.RuntimeState)
local HeroAppearance = require(script.Parent.HeroAppearance)

local LeaderboardService = {}

local stores = {}
local publicStore = nil
local ready = false
local lastSent = {}
local refreshing = false

local BOARDS = {
	{ id = "Rebirth", title = "MOST REBIRTH" },
	{ id = "Time", title = "MOST TIME PLAYED" },
	{ id = "Kills", title = "MOST KILLS" },
}

local function boardNames()
	if RunService:IsStudio() then
		return GameConfig.Data.StudioBoards, GameConfig.Data.StudioPublicStoreName
	end
	return GameConfig.Data.ProductionBoards, GameConfig.Data.ProductionPublicStoreName
end

local function valueOf(player, boardId)
	local data = PlayerData.Get(player)
	if not data then
		return nil
	end
	if boardId == "Rebirth" then
		return Rules.TotalRebirths(data)
	elseif boardId == "Time" then
		local runtime = RuntimeState.Get(player)
		return data.playTimeSeconds + math.floor(runtime.playtimeBuffer)
	end
	return data.totalKills
end

local function formatValue(boardId, value)
	if boardId == "Time" then
		local hours = math.floor(value / 3600)
		local minutes = math.floor((value % 3600) / 60)
		return string.format("%dh %02dm", hours, minutes)
	end
	return Rules.FormatNumber(value)
end

function LeaderboardService.Start(_ctx)
	local names, publicName = boardNames()
	local ok, err = pcall(function()
		for _, board in ipairs(BOARDS) do
			stores[board.id] = DataStoreService:GetOrderedDataStore(names[board.id])
		end
		publicStore = DataStoreService:GetDataStore(publicName)
	end)
	ready = ok
	if not ok then
		warn("[Kurkito][Leaderboard] DataStore non disponibile: " .. tostring(err))
	else
		print("[Kurkito][Leaderboard] Store attivi.")
	end
end

function LeaderboardService.PushPlayer(player)
	if not ready or not PlayerData.IsLoaded(player) then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local memory = lastSent[player.UserId]
	if not memory then
		memory = {}
		lastSent[player.UserId] = memory
	end
	for _, board in ipairs(BOARDS) do
		local value = valueOf(player, board.id)
		if value and value ~= memory[board.id] and value >= 0 then
			local store = stores[board.id]
			local wrote = pcall(function()
				store:SetAsync(tostring(player.UserId), math.floor(value))
			end)
			if wrote then
				memory[board.id] = math.floor(value)
			end
		end
	end
	if data.selectedHero ~= "" then
		local hero = data.heroes[data.selectedHero]
		pcall(function()
			publicStore:SetAsync(tostring(player.UserId), {
				displayName = player.DisplayName,
				heroId = data.selectedHero,
				stats = Rules.DeepCopy(hero.stats),
			})
		end)
	end
end

function LeaderboardService.PushAll()
	for _, player in ipairs(Players:GetPlayers()) do
		LeaderboardService.PushPlayer(player)
	end
end

local function podiumPart(boardId, place)
	local world = workspace:FindFirstChild("KurkitoWorld")
	if not world then
		return nil
	end
	return world:FindFirstChild("Podium_" .. boardId .. "_" .. tostring(place), true)
end

local function setLabel(podium, name, value)
	local gui = podium:FindFirstChild("PodiumGui")
	if not gui then
		return
	end
	local nameLabel = gui:FindFirstChild("NameLabel")
	local valueLabel = gui:FindFirstChild("ValueLabel")
	if nameLabel then
		nameLabel.Text = name
	end
	if valueLabel then
		valueLabel.Text = value
	end
end

local function clearFigures()
	local world = workspace:FindFirstChild("KurkitoWorld")
	local figures = world and world:FindFirstChild("PodiumFigures", true)
	if figures then
		figures:ClearAllChildren()
	end
	return figures
end

local function placeDummy(figures, podium, userId, snapshot)
	local top = podium.Position + Vector3.new(0, podium.Size.Y / 2 + 3, 0)
	local description = nil
	pcall(function()
		description = Players:GetHumanoidDescriptionFromUserId(userId)
	end)
	local model = nil
	if description then
		local ok, created = pcall(function()
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)
		if ok then
			model = created
		end
	end
	if not model then
		model = Instance.new("Model")
		model.Name = "Fallback"
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 4, 1)
		root.Color = Color3.fromRGB(140, 140, 150)
		root.Anchored = true
		root.Parent = model
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(1.4, 1.4, 1.4)
		head.Anchored = true
		head.CFrame = root.CFrame * CFrame.new(0, 2.4, 0)
		head.Parent = model
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
		model.PrimaryPart = root
	end
	model.Name = "Podium_" .. tostring(userId)
	model.Parent = figures
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if root then
		local hip = humanoid and (humanoid.HipHeight + root.Size.Y * 0.5) or 3
		model:PivotTo(CFrame.new(podium.Position + Vector3.new(0, podium.Size.Y / 2 + hip, 0)))
		root.Anchored = true
	end
	if snapshot and snapshot.heroId and snapshot.stats and HeroConfig.Classes[snapshot.heroId] then
		pcall(function()
			HeroAppearance.Apply(model, snapshot.heroId, { stats = snapshot.stats })
		end)
	end
	return top
end

function LeaderboardService.RefreshPodiums()
	if refreshing then
		return
	end
	refreshing = true
	local figures = clearFigures()
	for _, board in ipairs(BOARDS) do
		local entries = nil
		if ready and stores[board.id] then
			local ok, pages = pcall(function()
				return stores[board.id]:GetSortedAsync(false, 10)
			end)
			if ok and pages then
				local pageOk, page = pcall(function()
					return pages:GetCurrentPage()
				end)
				if pageOk then
					entries = page
				end
			end
		end
		for place = 1, 3 do
			local podium = podiumPart(board.id, place)
			if podium then
				local row = entries and entries[place]
				if not row then
					setLabel(podium, "—", ready and "" or "Data unavailable")
				else
					local userId = tonumber(row.key)
					local name = "Player " .. tostring(row.key)
					if userId then
						pcall(function()
							name = Players:GetNameFromUserIdAsync(userId)
						end)
					end
					setLabel(podium, "#" .. place .. " " .. name, formatValue(board.id, row.value))
					if figures and userId then
						local snapshot = nil
						if publicStore then
							pcall(function()
								snapshot = publicStore:GetAsync(tostring(userId))
							end)
						end
						pcall(function()
							placeDummy(figures, podium, userId, snapshot)
						end)
					end
				end
			end
		end
	end
	refreshing = false
end

return LeaderboardService
