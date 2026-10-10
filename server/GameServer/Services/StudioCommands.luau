-- Comandi disponibili solo in Roblox Studio. Non esistono nei server pubblicati.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local PotionConfig = shared("PotionConfig")
local PetConfig = shared("PetConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Notifier)
local PetService = require(script.Parent.PetService)
local HeroService = require(script.Parent.HeroService)

local StudioCommands = {}

local function reply(player, text)
	Notifier.Send(player, "info", text)
end

function StudioCommands.Start()
	if not RunService:IsStudio() then
		return
	end
	local function hook(player)
		player.Chatted:Connect(function(message)
			if not RunService:IsStudio() then
				return
			end
			local data = PlayerData.Get(player)
			if not data then
				return
			end
			local command, arg = string.match(message, "^/(%w+)%s*(.*)$")
			if not command then
				return
			end
			command = string.lower(command)
			if command == "coins" then
				local amount = tonumber(arg)
				if not amount or amount <= 0 then
					reply(player, "Uso: /coins 1000")
					return
				end
				data.coins = Rules.AddCoins(data.coins, math.floor(amount), GameConfig.MaxCoins)
				PlayerData.MarkDirty(player, true)
				reply(player, "Monete di test: " .. tostring(data.coins))
			elseif command == "mastery" then
				if data.selectedHero == "" then
					return
				end
				local level = tonumber(arg)
				if not level then
					reply(player, "Uso: /mastery 50")
					return
				end
				level = math.clamp(math.floor(level), 0, GameConfig.MaxMastery)
				local hero = data.heroes[data.selectedHero]
				local spent = 0
				for _, rank in pairs(hero.skillRanks) do
					spent += rank
				end
				for _, rank in pairs(hero.talents) do
					spent += rank
				end
				if level < spent then
					reply(player, "Maestria inferiore ai punti già spesi.")
					return
				end
				hero.mastery = level
				hero.xp = 0
				hero.skillPoints = level - spent
				PlayerData.MarkDirty(player, true)
				reply(player, "Maestria di test: " .. tostring(level))
			elseif command == "xp" then
				local amount = tonumber(arg)
				if amount and amount > 0 and data.selectedHero ~= "" then
					require(script.Parent.MasteryService).AddBaseXp(player, math.floor(amount))
					reply(player, "XP di test aggiunta.")
				end
			elseif command == "pet" then
				local petId = arg ~= "" and arg or "zombie"
				if not PetConfig.Get(petId) then
					reply(player, "Pet sconosciuto.")
					return
				end
				local pet, err = PetService.Grant(player, petId, "Normal")
				reply(player, pet and ("Pet di test: " .. petId) or (err or "Pet non creato."))
			elseif command == "potion" then
				local potionId = arg ~= "" and arg or "health_common"
				if not PotionConfig.Get(potionId) then
					reply(player, "Pozione sconosciuta.")
					return
				end
				local ok, reason = Rules.AddStack(data.inventory.potions, potionId, 1, GameConfig.Inventory.MaxStack)
				if ok then
					PlayerData.MarkDirty(player, true)
					reply(player, "Pozione di test: " .. potionId)
				else
					reply(player, reason or "Pozione non aggiunta.")
				end
			elseif command == "kills" then
				local amount = math.floor(tonumber(arg) or 1)
				if amount > 0 and amount <= 100 then
					local quests = require(script.Parent.QuestService)
					for _ = 1, amount do
						data.totalKills += 1
						quests.OnKill(player)
					end
					PlayerData.MarkDirty(player, true)
					HeroService.Refresh(player, false)
					reply(player, "Kill di test: " .. tostring(amount))
				end
			end
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in ipairs(Players:GetPlayers()) do
		hook(player)
	end
	print("[Kurkito] Comandi Studio: /coins /mastery /xp /pet /potion /kills")
end

return StudioCommands
