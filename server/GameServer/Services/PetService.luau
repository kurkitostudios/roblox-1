local HttpService = game:GetService("HttpService")

local shared = require(script.Parent.SharedLoader)
local PetConfig = shared("PetConfig")
local GameConfig = shared("GameConfig")
local PlayerData = require(script.Parent.PlayerDataService)
local HeroService = require(script.Parent.HeroService)
local Notifier = require(script.Parent.Notifier)

local PetService = {}

local function findPet(data, uid)
	for _, pet in ipairs(data.pets) do
		if pet.uid == uid then
			return pet
		end
	end
	return nil
end

function PetService.Grant(player, petId, evolution)
	local data = PlayerData.Get(player)
	if not data then
		return nil, "Data is not loaded."
	end
	if not PetConfig.Get(petId) then
		return nil, "Unknown pet."
	end
	if not PetConfig.EvolutionMult[evolution or "Normal"] then
		return nil, "Invalid evolution."
	end
	if #data.pets >= GameConfig.Inventory.MaxPets then
		return nil, "Pet inventory is full."
	end
	local pet = {
		uid = HttpService:GenerateGUID(false),
		petId = petId,
		evolution = evolution or "Normal",
	}
	table.insert(data.pets, pet)
	PlayerData.MarkDirty(player, true)
	return pet, nil
end

function PetService.Equip(player, uid, slot)
	local data = PlayerData.Get(player)
	if not data then
		return { ok = false, error = "Data is not loaded." }
	end
	if type(uid) ~= "string" or not findPet(data, uid) then
		return { ok = false, error = "You do not own that pet." }
	end
	slot = slot or 0
	if type(slot) ~= "number" or slot ~= math.floor(slot) then
		return { ok = false, error = "Invalid slot." }
	end
	for index, equipped in ipairs(data.equippedPets) do
		if equipped == uid then
			data.equippedPets[index] = ""
		end
	end
	local target = slot
	if target < 1 or target > PetConfig.MaxEquipped then
		target = nil
		for index = 1, PetConfig.MaxEquipped do
			if data.equippedPets[index] == "" and not target then
				target = index
			end
		end
	end
	if not target then
		return { ok = false, error = "You already have 3 pets equipped." }
	end
	data.equippedPets[target] = uid
	PlayerData.MarkDirty(player, true)
	HeroService.Refresh(player, false)
	Notifier.Send(player, "info", "Pet equipped in slot " .. tostring(target) .. ".")
	return { ok = true }
end

function PetService.Unequip(player, slot)
	local data = PlayerData.Get(player)
	if not data then
		return { ok = false, error = "Data is not loaded." }
	end
	if type(slot) ~= "number" or slot < 1 or slot > PetConfig.MaxEquipped or slot ~= math.floor(slot) then
		return { ok = false, error = "Invalid slot." }
	end
	data.equippedPets[slot] = ""
	PlayerData.MarkDirty(player, true)
	HeroService.Refresh(player, false)
	return { ok = true }
end

function PetService.Bind(ctx)
	local rates = shared("GameConfig").Rates
	ctx.services.RemotesService.Bind(ctx, "EquipPet", rates.EquipPet, function(player, payload)
		return PetService.Equip(player, payload.uid, payload.slot)
	end)
	ctx.services.RemotesService.Bind(ctx, "UnequipPet", rates.UnequipPet, function(player, payload)
		return PetService.Unequip(player, payload.slot)
	end)
end

return PetService
