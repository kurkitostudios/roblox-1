-- UI generata a runtime. Non servono ScreenGui creati a mano in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 20)
if not sharedFolder then
	warn("[Kurkito] Manca ReplicatedStorage.Shared. Collega Script Sync a shared/Shared.")
	return
end

local RemoteNames = require(sharedFolder:WaitForChild("RemoteNames"))
local remotes = ReplicatedStorage:WaitForChild(RemoteNames.Folder, 20)
if not remotes then
	warn("[Kurkito] Remote non creati. Avvia il server con Main in ServerScriptService.GameServer.")
	return
end

local uiFolder = script.Parent:WaitForChild("UI")
local HUD = require(uiFolder:WaitForChild("HUD"))
local HeroSelect = require(uiFolder:WaitForChild("HeroSelect"))
local Menus = require(uiFolder:WaitForChild("Menus"))
local Notifications = require(uiFolder:WaitForChild("Notifications"))

local state = {
	profile = nil,
	ready = false,
	errorText = nil,
	vitals = {
		cooldowns = {},
		effects = {},
		shield = 0,
	},
}

local function invoke(name, payload)
	local remote = remotes:WaitForChild(name, 5)
	if not remote then
		return { ok = false, error = "Remote non disponibile." }
	end
	local ok, result = pcall(function()
		return remote:InvokeServer(payload or {})
	end)
	if not ok or type(result) ~= "table" then
		return { ok = false, error = "Richiesta non riuscita." }
	end
	return result
end

local gui = Instance.new("ScreenGui")
gui.Name = "KurkitoUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function notify(kind, text)
	Notifications.Push(kind, text)
end

Notifications.Mount(gui)
HUD.Mount(gui)
HeroSelect.Mount(gui, invoke, notify)
Menus.Mount(gui, invoke, notify, function()
	return state.profile
end)

local function refresh()
	HUD.Update(state.profile, state.vitals)
	HeroSelect.Update(state.profile, state.ready, state.errorText)
	Menus.Update()
end

remotes:WaitForChild("ProfileSync").OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	state.ready = payload.ready == true
	state.errorText = payload.error
	state.profile = payload.profile
	refresh()
end)

remotes:WaitForChild("Notification").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		notify(payload.kind, payload.text)
	end
end)

remotes:WaitForChild("Vitals").OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	state.vitals = payload
	HUD.Update(state.profile, state.vitals)
end)

refresh()
print("[Kurkito] Client Build 001 pronto.")
