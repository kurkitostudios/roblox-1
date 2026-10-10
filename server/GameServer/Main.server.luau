-- Bootstrap Build 003. Gli altri script di GameServer, come TestSync, restano indipendenti.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if _G.__KURKITO_SERVER_STARTED then
	warn("[Kurkito] Bootstrap already running. Second start ignored.")
	return
end
_G.__KURKITO_SERVER_STARTED = true

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 20)
if not sharedFolder then
	error("[Kurkito] Manca ReplicatedStorage.Shared. Crea la cartella e collega Script Sync a shared/Shared. Vedi docs/SETUP_ROBLOX_STUDIO.md")
end

local servicesFolder = script.Parent:WaitForChild("Services")

local function load(name)
	local module = servicesFolder:WaitForChild(name)
	return require(module)
end

local ctx = {
	services = {},
	remotes = {},
}

local RemotesService = load("RemotesService")
local Notifier = load("Notifier")
local WorldBuilder = load("WorldBuilder")
local PlayerDataService = load("PlayerDataService")
local HeroService = load("HeroService")
local UpgradeService = load("UpgradeService")
local ArenaService = load("ArenaService")
local InventoryService = load("InventoryService")
local PetService = load("PetService")
local EggService = load("EggService")
local MerchantService = load("MerchantService")
local FusionService = load("FusionService")
local PotionService = load("PotionService")
local RebirthService = load("RebirthService")
local EnemyService = load("EnemyService")
local CombatService = load("CombatService")
local LeaderboardService = load("LeaderboardService")
local PromptRouter = load("PromptRouter")
local StudioCommands = load("StudioCommands")
local GameLoop = load("GameLoop")

ctx.services.RemotesService = RemotesService
ctx.services.Notifier = Notifier
ctx.services.PlayerDataService = PlayerDataService
ctx.services.HeroService = HeroService
ctx.services.ArenaService = ArenaService
ctx.services.EggService = EggService
ctx.services.MerchantService = MerchantService
ctx.services.RebirthService = RebirthService
ctx.services.EnemyService = EnemyService
ctx.services.CombatService = CombatService
ctx.services.PotionService = PotionService
ctx.services.LeaderboardService = LeaderboardService

Players.RespawnTime = 3

RemotesService.Start(ctx)
Notifier.Start(ctx)
WorldBuilder.Build()
PlayerDataService.Start(ctx)
LeaderboardService.Start(ctx)
EnemyService.Start(ctx)

HeroService.Bind(ctx)
UpgradeService.Bind(ctx)
ArenaService.Bind(ctx)
InventoryService.Bind(ctx)
PetService.Bind(ctx)
EggService.Bind(ctx)
MerchantService.Bind(ctx)
FusionService.Bind(ctx)
PotionService.Bind(ctx)
RebirthService.Bind(ctx)
PromptRouter.Start(ctx)
StudioCommands.Start()
GameLoop.Start(ctx)
PlayerDataService.HookPlayers()

print("[Kurkito] Build 003 started. World 0 lobby, Arena 1, automatic combat.")
