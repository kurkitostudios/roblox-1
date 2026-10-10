-- Anti-stack: per ogni famiglia resta un solo effetto.
-- Una nuova pozione della stessa famiglia sostituisce potenza e durata.
-- Non somma i moltiplicatori.

local shared = require(script.Parent.SharedLoader)
local PotionConfig = shared("PotionConfig")
local Rules = shared("Rules")
local GameConfig = shared("GameConfig")
local PlayerData = require(script.Parent.PlayerDataService)
local RuntimeState = require(script.Parent.RuntimeState)
local Notifier = require(script.Parent.Notifier)

local PotionService = {}

function PotionService.Use(player, potionId)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return { ok = false, error = "Nessun eroe attivo." }
	end
	if type(potionId) ~= "string" then
		return { ok = false, error = "Pozione non valida." }
	end
	local def = PotionConfig.Get(potionId)
	if not def then
		return { ok = false, error = "Pozione sconosciuta." }
	end
	local count = data.inventory.potions[potionId] or 0
	if count < 1 then
		return { ok = false, error = "Non possiedi questa pozione." }
	end
	local removed = Rules.AddStack(data.inventory.potions, potionId, -1, GameConfig.Inventory.MaxStack)
	if not removed then
		return { ok = false, error = "Impossibile consumare la pozione." }
	end
	local runtime = RuntimeState.Get(player)
	Rules.ApplyPotion(runtime.effects, def, os.clock())
	PlayerData.MarkDirty(player, true)
	Notifier.Send(player, "info", def.name .. " attiva per " .. tostring(def.duration) .. "s. Stessa famiglia: sostituisce, non si somma.")
	return { ok = true }
end

function PotionService.Tick(dt)
	local Players = game:GetService("Players")
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerData.IsLoaded(player) then
			local runtime = RuntimeState.Get(player)
			for family, effect in pairs(runtime.effects) do
				if effect.expiresAt <= now then
					runtime.effects[family] = nil
				elseif family == "HealthRegen" and now >= (effect.nextTick or 0) then
					effect.nextTick = now + 1
					local character = player.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (effect.healthPerSecond or 0))
					end
				end
			end
		end
	end
	return dt
end

function PotionService.Bind(ctx)
	ctx.services.RemotesService.Bind(ctx, "UsePotion", shared("GameConfig").Rates.UsePotion, function(player, payload)
		return PotionService.Use(player, payload.potionId)
	end)
end

return PotionService
