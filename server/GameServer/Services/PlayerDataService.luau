-- Persistenza centrale. Un profilo non caricato non viene mai sovrascritto.
-- In Studio si usa un DataStore separato. Se le API sono spente, la sessione
-- resta solo in memoria e non viene scritta.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local Rules = shared("Rules")
local ProfileTemplate = shared("ProfileTemplate")
local ProfileSanitizer = require(script.Parent.ProfileSanitizer)
local RuntimeState = require(script.Parent.RuntimeState)
local RateLimiter = require(script.Parent.RateLimiter)

local PlayerDataService = {}

local ctx
local sessions = {}
local store
local storeReady = false
local sessionId

local function log(message)
	print("[Kurkito][Data] " .. message)
end

local function warnLog(message)
	warn("[Kurkito][Data] " .. message)
end

local function newSessionId()
	local jobId = game.JobId
	if type(jobId) == "string" and jobId ~= "" then
		return jobId
	end
	return "studio_" .. HttpService:GenerateGUID(false)
end

local function storeName()
	if RunService:IsStudio() then
		return GameConfig.Data.StudioStoreName
	end
	return GameConfig.Data.ProductionStoreName
end

local function keyFor(userId)
	return "u_" .. tostring(userId)
end

local function startingCoins()
	if RunService:IsStudio() then
		return GameConfig.Data.StudioStartingCoins
	end
	return 0
end

function PlayerDataService.Start(context)
	ctx = context
	sessionId = newSessionId()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(storeName())
	end)
	if ok then
		store = result
		storeReady = true
		log("DataStore attivo: " .. storeName())
	else
		storeReady = false
		warnLog("DataStore non disponibile (" .. storeName() .. "): " .. tostring(result))
	end
end

local function pushNow(player)
	local session = sessions[player]
	local remote = ctx and ctx.remotes and ctx.remotes.ProfileSync
	if not remote or player.Parent == nil then
		return
	end
	if not session or not session.loaded then
		remote:FireClient(player, {
			ready = false,
			error = session and session.error or "Data is not loaded.",
		})
		return
	end
	remote:FireClient(player, {
		ready = true,
		studio = RunService:IsStudio(),
		persist = session.persist,
		profile = Rules.DeepCopy(session.data),
	})
end

local function schedulePush(player, immediate)
	local session = sessions[player]
	if not session then
		return
	end
	if immediate then
		session.pushToken = (session.pushToken or 0) + 1
		pushNow(player)
		return
	end
	if session.pushQueued then
		return
	end
	session.pushQueued = true
	local token = (session.pushToken or 0) + 1
	session.pushToken = token
	task.delay(0.15, function()
		local current = sessions[player]
		if not current or current.pushToken ~= token then
			return
		end
		current.pushQueued = false
		pushNow(player)
	end)
end

function PlayerDataService.MarkDirty(player, immediatePush)
	local session = sessions[player]
	if not session or not session.loaded then
		return
	end
	session.dirty = true
	session.mutationGen = (session.mutationGen or 0) + 1
	schedulePush(player, immediatePush == true)
end

function PlayerDataService.Get(player)
	local session = sessions[player]
	if not session or not session.loaded then
		return nil
	end
	return session.data
end

function PlayerDataService.IsLoaded(player)
	local session = sessions[player]
	return session ~= nil and session.loaded == true
end

function PlayerDataService.Push(player, immediate)
	schedulePush(player, immediate == true)
end

local function releaseCorruptLock(userId)
	if not storeReady then
		return
	end
	pcall(function()
		store:UpdateAsync(keyFor(userId), function(old)
			if type(old) ~= "table" then
				return nil
			end
			if type(old.session) == "table" and old.session.owner == sessionId then
				old.session = nil
				return old
			end
			return nil
		end)
	end)
end

local function claim(userId)
	local captured = nil
	local ok, result = pcall(function()
		return store:UpdateAsync(keyFor(userId), function(old)
			if old == nil then
				local fresh = ProfileTemplate.Create(startingCoins())
				fresh.session = { owner = sessionId, at = os.time() }
				return fresh
			end
			if type(old) ~= "table" then
				return nil
			end
			local lock = old.session
			if type(lock) == "table" and lock.owner ~= sessionId then
				local age = os.time() - (tonumber(lock.at) or 0)
				if age < GameConfig.Data.LockSeconds then
					return nil
				end
			end
			old.session = { owner = sessionId, at = os.time() }
			return old
		end)
	end)
	if not ok then
		return nil, tostring(result)
	end
	captured = result
	if type(captured) ~= "table" then
		return nil, "locked"
	end
	return captured, nil
end

local function loadFromStore(userId)
	local lastReason = "unknown"
	for _ = 1, GameConfig.Data.LoadRetries do
		local blob, reason = claim(userId)
		if blob then
			local copy = Rules.DeepCopy(blob)
			copy.session = nil
			local data, sanitizeReason = ProfileSanitizer.Sanitize(copy)
			if not data then
				releaseCorruptLock(userId)
				return nil, sanitizeReason or "Profilo corrotto."
			end
			return data, nil
		end
		lastReason = reason or lastReason
		if reason == "locked" then
			task.wait(1.5)
		else
			task.wait(0.8)
		end
	end
	return nil, lastReason
end

function PlayerDataService.Save(player, releaseLock)
	local session = sessions[player]
	if not session or not session.loaded or session.persist ~= true or not storeReady then
		return false
	end
	if session.saving then
		session.saveQueued = true
		session.releaseAfterSave = session.releaseAfterSave or releaseLock
		return false
	end
	session.saving = true
	local capturedGen = nil
	local attempts = 0
	local saved = false
	local lastError = nil
	while attempts < GameConfig.Data.SaveRetries and not saved do
		attempts += 1
		local ok, result = pcall(function()
			return store:UpdateAsync(keyFor(session.userId), function(old)
				if type(old) == "table" and type(old.session) == "table" and old.session.owner ~= sessionId then
					return nil
				end
				capturedGen = session.mutationGen
				local blob = Rules.DeepCopy(session.data)
				if releaseLock then
					blob.session = nil
				else
					blob.session = { owner = sessionId, at = os.time() }
				end
				return blob
			end)
		end)
		if ok and type(result) == "table" then
			saved = true
		else
			lastError = result
			task.wait(0.6 * attempts)
		end
	end
	session.saving = false
	if saved then
		session.lastSave = os.clock()
		if session.mutationGen ~= capturedGen then
			session.dirty = true
		else
			session.dirty = false
		end
	else
		session.dirty = true
		warnLog("Salvataggio fallito per " .. tostring(session.userId) .. ": " .. tostring(lastError))
	end
	if session.saveQueued and player.Parent ~= nil and not releaseLock then
		session.saveQueued = false
		local alsoRelease = session.releaseAfterSave
		session.releaseAfterSave = false
		task.spawn(function()
			PlayerDataService.Save(player, alsoRelease == true)
		end)
	end
	return saved
end

local function flushPlaytime(player)
	local session = sessions[player]
	if not session or not session.loaded then
		return
	end
	local runtime = RuntimeState.Get(player)
	local whole = math.floor(runtime.playtimeBuffer)
	if whole > 0 then
		session.data.playTimeSeconds += whole
		runtime.playtimeBuffer -= whole
		session.dirty = true
		session.mutationGen += 1
	end
end

function PlayerDataService.FlushPlaytime(player)
	flushPlaytime(player)
end

function PlayerDataService.AddPlaytime(player, dt)
	local session = sessions[player]
	if not session or not session.loaded then
		return
	end
	local runtime = RuntimeState.Get(player)
	runtime.playtimeBuffer += dt
end

local function onLoaded(player)
	local heroService = ctx.services.HeroService
	if heroService then
		heroService.OnPlayerLoaded(player)
	end
	schedulePush(player, true)
	local session = sessions[player]
	if session and not session.persist then
		ctx.services.Notifier.Send(player, "error", "Studio session is memory-only. Production data is untouched and this session will not be saved.")
	end
end

function PlayerDataService.LoadPlayer(player)
	if sessions[player] then
		return
	end
	local session = {
		loaded = false,
		persist = false,
		dirty = false,
		mutationGen = 0,
		saving = false,
		userId = player.UserId,
		error = "Loading data...",
	}
	sessions[player] = session
	schedulePush(player, true)

	local data, reason
	if storeReady then
		data, reason = loadFromStore(player.UserId)
	end
	if data then
		session.data = data
		session.loaded = true
		session.persist = true
		session.error = nil
		log("Profilo caricato per " .. player.Name .. " (" .. storeName() .. ")")
	elseif RunService:IsStudio() then
		session.data = ProfileTemplate.Create(startingCoins())
		session.loaded = true
		session.persist = false
		session.error = nil
		warnLog("Fallback memoria Studio per " .. player.Name .. ": " .. tostring(reason))
	else
		session.loaded = false
		session.persist = false
		session.error = "Could not load your data. Rejoin in a moment. Nothing was overwritten."
		warnLog("Caricamento rifiutato per " .. player.Name .. ": " .. tostring(reason))
	end
	if player.Parent == nil then
		if session.loaded and session.persist then
			PlayerDataService.Save(player, true)
		end
		sessions[player] = nil
		return
	end
	onLoaded(player)
end

local function unload(player)
	local session = sessions[player]
	if not session then
		return
	end
	flushPlaytime(player)
	if ctx and ctx.services.EnemyService then
		ctx.services.EnemyService.ClearPlayer(player)
	end
	if ctx and ctx.services.LeaderboardService and session.loaded then
		pcall(function()
			ctx.services.LeaderboardService.PushPlayer(player)
		end)
	end
	if session.loaded and session.persist then
		local started = os.clock()
		while session.saving and os.clock() - started < 12 do
			session.saveQueued = true
			session.releaseAfterSave = true
			task.wait(0.2)
		end
		PlayerDataService.Save(player, true)
	end
	sessions[player] = nil
	RuntimeState.Clear(player)
	RateLimiter.Clear(player)
end

function PlayerDataService.HookPlayers()
	local function handle(player)
		task.spawn(function()
			PlayerDataService.LoadPlayer(player)
		end)
	end
	Players.PlayerAdded:Connect(handle)
	Players.PlayerRemoving:Connect(unload)
	for _, player in ipairs(Players:GetPlayers()) do
		handle(player)
	end
	game:BindToClose(function()
		local pending = 0
		for _, player in ipairs(Players:GetPlayers()) do
			pending += 1
			task.spawn(function()
				unload(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 20 do
			task.wait(0.2)
		end
	end)
end

function PlayerDataService.Autosave()
	local now = os.clock()
	for player, session in pairs(sessions) do
		if session.loaded and session.persist and session.dirty and not session.saving then
			if now - (session.lastSave or 0) >= GameConfig.AutosaveInterval then
				PlayerDataService.Save(player, false)
			end
		end
	end
end

return PlayerDataService
