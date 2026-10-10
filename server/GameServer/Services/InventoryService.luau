local HttpService = game:GetService("HttpService")

local shared = require(script.Parent.SharedLoader)
local GameConfig = shared("GameConfig")
local LootConfig = shared("LootConfig")
local Rules = shared("Rules")
local PlayerData = require(script.Parent.PlayerDataService)
local Notifier = require(script.Parent.Notifier)

local InventoryService = {}

local slots = { weapon = true, armor = true, charm = true }

local function findEquipment(data, uid)
	for index, entry in ipairs(data.inventory.equipment) do
		if entry.uid == uid then
			return entry, index
		end
	end
	return nil, nil
end

function InventoryService.Grant(player, grants, boundHero)
	local data = PlayerData.Get(player)
	if not data then
		return {}
	end
	local accepted = {}
	for _, grant in ipairs(grants) do
		local def = LootConfig.GetItem(grant.itemId)
		if def then
			if def.category == "equipment" then
				if #data.inventory.equipment >= GameConfig.Inventory.MaxEquipment then
					Notifier.Send(player, "error", "Inventario equipaggiamenti pieno.")
				else
					local entry = {
						uid = HttpService:GenerateGUID(false),
						itemId = def.id,
						boundHero = def.classId,
					}
					if entry.boundHero and boundHero and entry.boundHero ~= boundHero then
						entry = nil
					end
					if entry then
						table.insert(data.inventory.equipment, entry)
						table.insert(accepted, { name = def.name, count = 1 })
					end
				end
			else
				local bucket = data.inventory[def.category]
				if bucket then
					local ok, reason = Rules.AddStack(bucket, def.id, grant.count or 1, GameConfig.Inventory.MaxStack)
					if ok then
						table.insert(accepted, { name = def.name, count = grant.count or 1 })
					else
						Notifier.Send(player, "error", reason or "Inventario pieno.")
					end
				end
			end
		end
	end
	if #accepted > 0 then
		PlayerData.MarkDirty(player, false)
	end
	return accepted
end

function InventoryService.Equip(player, uid)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return { ok = false, error = "Nessun eroe attivo." }
	end
	if type(uid) ~= "string" then
		return { ok = false, error = "Oggetto non valido." }
	end
	local entry = findEquipment(data, uid)
	if not entry then
		return { ok = false, error = "Oggetto non posseduto." }
	end
	local def = LootConfig.GetItem(entry.itemId)
	if not def or not slots[def.slot] then
		return { ok = false, error = "Non equipaggiabile." }
	end
	if def.classId and def.classId ~= data.selectedHero then
		return { ok = false, error = "Questo oggetto appartiene a un'altra classe." }
	end
	if entry.boundHero and entry.boundHero ~= data.selectedHero then
		return { ok = false, error = "Questo oggetto è vincolato a un altro eroe." }
	end
	for _, hero in pairs(data.heroes) do
		for slot, equipped in pairs(hero.equippedGear) do
			if equipped == uid then
				hero.equippedGear[slot] = ""
			end
		end
	end
	data.heroes[data.selectedHero].equippedGear[def.slot] = uid
	PlayerData.MarkDirty(player, true)
	local heroService = require(script.Parent.HeroService)
	heroService.Refresh(player, false)
	Notifier.Send(player, "info", "Equipaggiato: " .. def.name)
	return { ok = true }
end

function InventoryService.Unequip(player, slot)
	local data = PlayerData.Get(player)
	if not data or data.selectedHero == "" then
		return { ok = false, error = "Nessun eroe attivo." }
	end
	if not slots[slot] then
		return { ok = false, error = "Slot non valido." }
	end
	data.heroes[data.selectedHero].equippedGear[slot] = ""
	PlayerData.MarkDirty(player, true)
	require(script.Parent.HeroService).Refresh(player, false)
	return { ok = true }
end

function InventoryService.Bind(ctx)
	local rates = shared("GameConfig").Rates
	ctx.services.RemotesService.Bind(ctx, "EquipItem", rates.EquipItem, function(player, payload)
		return InventoryService.Equip(player, payload.uid)
	end)
	ctx.services.RemotesService.Bind(ctx, "UnequipItem", rates.UnequipItem, function(player, payload)
		return InventoryService.Unequip(player, payload.slot)
	end)
end

return InventoryService
