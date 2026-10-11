local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Notifier)

local PromptRouter = {}

function PromptRouter.Start(ctx)
	local world = workspace:FindFirstChild("KurkitoWorld")
	if not world then
		warn("[Kurkito] Prompts were not connected: the world is missing.")
		return
	end
	local arena = ctx.services.ArenaService
	local eggs = ctx.services.EggService
	local rebirth = ctx.services.RebirthService
	for _, descendant in ipairs(world:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function(player)
				local action = descendant:GetAttribute("KurkitoAction")
				if action == "Arena" then
					local index = descendant:GetAttribute("ArenaIndex")
					local data = PlayerData.Get(player)
					local hero = data and data.selectedHero ~= "" and data.heroes[data.selectedHero]
					if hero and hero.unlockedArenas[tostring(index)] then
						local result = arena.TeleportToArena(player, index)
						if not result.ok then
							Notifier.Send(player, "error", result.error)
						end
					else
						local result = arena.Unlock(player, index)
						if result.ok then
							arena.TeleportToArena(player, index)
						else
							Notifier.Send(player, "error", result.error)
						end
					end
				elseif action == "Lobby" then
					local result = arena.TeleportLobby(player)
					if not result.ok then
						Notifier.Send(player, "error", result.error)
					end
				elseif action == "OpenWorldEgg" then
					local result = eggs.OpenWorld(player, descendant:GetAttribute("WorldEgg"))
					if not result.ok then
						Notifier.Send(player, "error", result.error)
					end
				elseif action == "OpenEgg" then
					local result = eggs.OpenArena(player, descendant:GetAttribute("ArenaIndex"))
					if not result.ok then
						Notifier.Send(player, "error", result.error)
					end
				elseif action == "RobuxEgg" then
					local result = eggs.InspectRobux(player, descendant:GetAttribute("SpecialIndex"))
					if result.error then
						Notifier.Send(player, "error", result.error)
					end
				elseif action == "Hero" then
					Notifier.Send(player, "info", "World 0 has one hero: the Warrior.")
				elseif action == "UpgradeInfo" then
					local data = PlayerData.Get(player)
					if not data or data.selectedHero == "" then
						Notifier.Send(player, "info", "The Warrior is ready. Open the Upgrades menu.")
					else
						local statId = HeroConfig.Classes.Warrior.stats[1]
						local hero = data.heroes.Warrior
						if hero and hero.stats then
							local cost = Rules.StatCost(hero.stats[statId], HeroConfig.StatDefs[statId])
							Notifier.Send(player, "info", "Open the Upgrades menu. Next " .. statId .. ": " .. tostring(cost or "MAX") .. " Coins.")
						else
							Notifier.Send(player, "info", "The Warrior is ready. Open the Upgrades menu.")
						end
					end
				elseif action == "FusionInfo" then
					Notifier.Send(player, "info", "Select 5 identical pets in the Fusion menu. Unequip them first.")
				elseif action == "Rebirth" then
					local result = rebirth.Preview(player)
					if not result.ok then
						Notifier.Send(player, "error", result.error)
					end
				elseif action == "Portal" then
					Notifier.Send(player, "info", "The World 2 portal is not active.")
				elseif action == "OpenBestEgg" then
					local result = eggs.OpenBest(player)
					if not result.ok then
						Notifier.Send(player, "error", result.error)
					end
				elseif action == "Merchant" then
					local merchant = ctx.services.MerchantService
					if merchant then
						local result = merchant.Open(player)
						if not result.ok then
							Notifier.Send(player, "error", result.error)
						end
					end
				end
			end)
		end
	end
end

return PromptRouter
