local HttpService = game:GetService("HttpService")

local shared = require(script.Parent.SharedLoader)
local PetConfig = shared("PetConfig")
local GameConfig = shared("GameConfig")
local Rules = shared("Rules")
local WorldLayout = shared("WorldLayout")
local PlayerData = require(script.Parent.PlayerDataService)
local HeroService = require(script.Parent.HeroService)
local RuntimeState = require(script.Parent.RuntimeState)
local Notifier = require(script.Parent.Notifier)

local FusionService = {}

local function equippedPets(data)
	return Rules.EquippedPetLookup(data.equippedPets)
end

function FusionService.Fuse(player, uids)
	if not RuntimeState.TryLock(player, "fusion") then
		return { ok = false, error = "Fusione già in corso." }
	end
	local function finish(result)
		RuntimeState.Unlock(player, "fusion")
		return result
	end
	local data = PlayerData.Get(player)
	if not data then
		return finish({ ok = false, error = "Dati non caricati." })
	end
	local inLobby = HeroService.InLobby(player)
	local atAltar = HeroService.Near(player, WorldLayout.Fusion(), WorldLayout.Radii.Fusion)
	if not inLobby and not atAltar then
		return finish({ ok = false, error = "Fondi i Pet dalla lobby o dall'altare di fusione." })
	end
	if type(uids) ~= "table" then
		return finish({ ok = false, error = "Selezione non valida." })
	end
	local list = {}
	for _, uid in ipairs(uids) do
		table.insert(list, uid)
	end
	local ok, result = Rules.ApplyFuse(data.pets, equippedPets(data), list, GameConfig.Fusion.Required, function(evolution)
		return PetConfig.NextEvolution(evolution)
	end, HttpService:GenerateGUID(false))
	if not ok then
		return finish({ ok = false, error = result })
	end
	data.pets = result
	PlayerData.MarkDirty(player, true)
	PlayerData.Save(player, false)
	local created = result[#result]
	local pet = PetConfig.Get(created.petId)
	Notifier.Send(player, "drop", "Fusione riuscita: " .. (pet and pet.name or created.petId) .. " " .. created.evolution)
	HeroService.Refresh(player, false)
	return finish({ ok = true, evolution = created.evolution, petId = created.petId })
end

function FusionService.Bind(ctx)
	ctx.services.RemotesService.Bind(ctx, "FusePets", shared("GameConfig").Rates.FusePets, function(player, payload)
		return FusionService.Fuse(player, payload.uids)
	end)
end

return FusionService
