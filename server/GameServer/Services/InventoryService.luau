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
					Notifier.Send(player, "error", "Equipment inventory is full.")
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
						Notifier.Send(player, "error", reason or "Inventory is full.")
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
	local hero = data and data.heroes and data.heroes.Warrior
	if not data or type(hero) ~= "table" then
		return { ok = false, error = "No active hero." }
	end
	data.selectedHero = "Warrior"
	if type(uid) ~= "string" then
		return { ok = false, error = "Invalid item." }
	end
	local entry = findEquipment(data, uid)
	if not entry then
		return { ok = false, error = "You do not own that item." }
	end
	local def = LootConfig.GetItem(entry.itemId)
	if not def or not slots[def.slot] then
		return { ok = false, error = "That item cannot be equipped." }
	end
	if def.classId and def.classId ~= "Warrior" then
		return { ok = false, error = "That item belongs to another class." }
	end
	if entry.boundHero and entry.boundHero ~= "Warrior" then
		return { ok = false, error = "That item is bound to another hero." }
	end
	for _, hero in pairs(data.heroes) do
		for slot, equipped in pairs(hero.equippedGear) do
			if equipped == uid then
				hero.equippedGear[slot] = ""
			end
		end
	end
	hero.equippedGear[def.slot] = uid
	PlayerData.MarkDirty(player, true)
	local heroService = require(script.Parent.HeroService)
	heroService.Refresh(player, false)
	Notifier.Send(player, "info", "Equipped: " .. def.name)
	return { ok = true }
end

function InventoryService.Unequip(player, slot)
	local data = PlayerData.Get(player)
	local hero = data and data.heroes and data.heroes.Warrior
	if not data or type(hero) ~= "table" then
		return { ok = false, error = "No active hero." }
	end
	if not slots[slot] then
		return { ok = false, error = "Invalid slot." }
	end
	hero.equippedGear[slot] = ""
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
