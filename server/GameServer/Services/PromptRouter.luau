local shared = require(script.Parent.SharedLoader)
local HeroConfig = shared("HeroConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Notifier)

local PromptRouter = {}

function PromptRouter.Start(ctx)
	local world = workspace:FindFirstChild("KurkitoWorld")
	if not world then
		warn("[Kurkito] Prompt non collegati: mondo assente.")
		return
	end
	local arena = ctx.services.ArenaService
	local eggs = ctx.services.EggService
	local heroes = ctx.services.HeroService
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
					local result = heroes.SwitchNext(player)
					if not result.ok then
						Notifier.Send(player, "error", result.error)
					end
				elseif action == "UpgradeInfo" then
					local data = PlayerData.Get(player)
					if not data or data.selectedHero == "" then
						Notifier.Send(player, "info", "Choose a hero, then open the Upgrades menu.")
					else
						local statId = HeroConfig.Classes[data.selectedHero].stats[1]
						local hero = data.heroes[data.selectedHero]
						local cost = Rules.StatCost(hero.stats[statId], HeroConfig.StatDefs[statId])
						Notifier.Send(player, "info", "Open the Upgrades menu. Next " .. statId .. ": " .. tostring(cost or "MAX") .. " Coins.")
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
				end
			end)
		end
	end
end

return PromptRouter
