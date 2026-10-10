local Players = game:GetService("Players")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")

local GameLoop = {}

function GameLoop.Start(ctx)
	local enemy = ctx.services.EnemyService
	local combat = ctx.services.CombatService
	local potions = ctx.services.PotionService
	local arenas = ctx.services.ArenaService
	local data = ctx.services.PlayerDataService
	local boards = ctx.services.LeaderboardService
	local elapsed = {
		arena = 0,
		vitals = 0,
		play = 0,
		save = 0,
		board = 0,
		podium = 0,
	}
	task.spawn(function()
		while true do
			local dt = GameConfig.TickInterval
			task.wait(dt)
			local ok, err = xpcall(function()
				enemy.Tick(dt)
				combat.Tick(dt)
				potions.Tick(dt)
				elapsed.arena += dt
				elapsed.vitals += dt
				elapsed.play += dt
				elapsed.save += dt
				elapsed.board += dt
				elapsed.podium += dt
				if elapsed.arena >= GameConfig.ArenaEnforceInterval then
					elapsed.arena = 0
					arenas.EnforceAll()
				end
				if elapsed.vitals >= GameConfig.VitalsInterval then
					elapsed.vitals = 0
					for _, player in ipairs(Players:GetPlayers()) do
						combat.PushVitals(player)
					end
				end
				for _, player in ipairs(Players:GetPlayers()) do
					data.AddPlaytime(player, dt)
				end
				if elapsed.play >= GameConfig.PlaytimeFlushInterval then
					elapsed.play = 0
					for _, player in ipairs(Players:GetPlayers()) do
						data.FlushPlaytime(player)
					end
				end
				if elapsed.save >= GameConfig.AutosaveInterval then
					elapsed.save = 0
					data.Autosave()
				end
				if elapsed.board >= GameConfig.LeaderboardInterval then
					elapsed.board = 0
					boards.PushAll()
				end
				if elapsed.podium >= GameConfig.PodiumInterval then
					elapsed.podium = 0
					task.spawn(function()
						boards.RefreshPodiums()
					end)
				end
			end, debug.traceback)
			if not ok then
				warn("[Kurkito][Loop] " .. tostring(err))
			end
		end
	end)
	task.delay(8, function()
		boards.RefreshPodiums()
	end)
end

return GameLoop
