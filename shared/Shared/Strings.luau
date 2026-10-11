-- Testi visibili ai giocatori. Solo inglese.
-- Gli id interni (classi, nemici, quest, DataStore) non stanno qui.

local Strings = {
	Error = {
		DataNotLoaded = "Data is not loaded.",
		InvalidPlayer = "Invalid player.",
		InvalidRequest = "Invalid request.",
		InvalidResponse = "Invalid response.",
		RateLimited = "Too many requests. Wait a moment.",
		Internal = "Internal error.",
		SelectHero = "The Warrior is the only hero.",
		NoActiveHero = "No active hero.",
		InvalidHero = "Invalid hero.",
		NoOtherHero = "World 0 has one hero: the Warrior.",
		OneHero = "World 0 has one hero: the Warrior.",
		SwitchInLobby = "World 0 has one hero: the Warrior.",
		ArenaUnavailable = "This arena is not available in World 0. Saved progress is kept.",
		TradingSoon = "Trading will be available soon.",
		WorldEggOnly = "Arena eggs are not available in World 0.",
		UpgradeInLobby = "Upgrade in the lobby or at the upgrade post.",
		SpendInLobby = "Spend points in the lobby or at the hero post.",
		StatUnavailable = "That stat is not available for this hero.",
		MaxLevel = "Maximum level.",
		UnknownAbility = "Unknown ability.",
		UnknownTalent = "Unknown talent.",
		InvalidType = "Invalid type.",
		InvalidPotion = "Invalid potion.",
		UnknownPotion = "Unknown potion.",
		NoPotion = "You do not own that potion.",
		CannotUsePotion = "Could not use that potion.",
		InvalidEgg = "Invalid egg.",
		EggUnavailable = "That egg is not available.",
		MoveCloserEgg = "Move closer to the egg.",
		UnlockArenaFirst = "That egg is not available.",
		EmptyEgg = "Egg table is empty. Coins refunded.",
		PetNotGranted = "Pet was not granted. Coins refunded.",
		InvalidShowcase = "Invalid showcase.",
		MoveCloserShowcase = "Move closer to the showcase.",
		RobuxDisabled = "Robux purchases are disabled in this build.",
		MoveCloserMerchant = "Move closer to the Tribal Merchant.",
		MerchantNoBuy = "The merchant does not buy that.",
		NothingToSell = "You do not have that loot.",
		AdvancedEggLocked = "The Advanced Coin Egg is a fixed World 0 egg.",
		FusionBusy = "Fusion is already in progress.",
		FuseInLobby = "Fuse pets in the lobby or at the fusion altar.",
		InvalidSelection = "Invalid selection.",
		OnlyFivePets = "You can select only 5 pets.",
		UnknownPet = "Unknown pet.",
		InvalidEvolution = "Invalid evolution.",
		PetInventoryFull = "Pet inventory is full.",
		PetNotOwned = "You do not own that pet.",
		InvalidSlot = "Invalid slot.",
		PetSlotsFull = "You already have 3 pets equipped.",
		EquipmentFull = "Equipment inventory is full.",
		InventoryFull = "Inventory is full.",
		InvalidItem = "Invalid item.",
		ItemNotOwned = "You do not own that item.",
		NotEquippable = "That item cannot be equipped.",
		WrongClass = "That item belongs to another class.",
		BoundOtherHero = "That item is bound to another hero.",
		ArenaMissing = "Arena does not exist.",
		UnlockAtGate = "Unlock the arena at its gate or from the lobby.",
		TravelLimited = "Travel is available from the lobby, gates, or arenas.",
		ArenaLocked = "Arena locked for this hero.",
		CharacterNotReady = "Character is not ready.",
		CannotReturn = "You cannot return to the lobby from here.",
		InvalidArena = "Invalid arena.",
		InvalidDestination = "Invalid destination.",
		ArenaStillLocked = "This arena is not unlocked for your active hero.",
		RebirthBusy = "Rebirth is already in progress.",
		MoveCloserRebirth = "Move closer to the Rebirth altar.",
		RebirthExpired = "Confirmation expired. Prepare Rebirth again.",
		RemoteMissing = "Remote is unavailable.",
		RequestFailed = "Request failed.",
		LoadFailed = "Could not load your data. Rejoin in a moment. Nothing was overwritten.",
		Loading = "Loading data...",
	},
}

function Strings.Coins(amount)
	return tostring(amount) .. " Coins"
end

function Strings.Free()
	return "Free"
end

function Strings.XpCoins(xp, coins)
	return "+" .. tostring(xp) .. " XP  +" .. tostring(coins) .. " Coins"
end

function Strings.MasteryUp(level, points)
	return "Mastery " .. tostring(level) .. " (+" .. tostring(points) .. " Skill Points)"
end

function Strings.SkillUnlocked(name)
	return "Skill unlocked: " .. name
end

function Strings.FirstHero(name)
	return name .. " is your first hero."
end

function Strings.ActiveHero(name)
	return "Active hero: " .. name
end

function Strings.ArenaUnlocked(name)
	return "Arena unlocked: " .. name
end

function Strings.PetHatched(name, rarity)
	return "Hatched " .. name .. " (" .. rarity .. ", Normal)"
end

function Strings.PetEquipped(slot)
	return "Pet equipped in slot " .. tostring(slot) .. "."
end

function Strings.FusionDone(name, evolution)
	return "Fusion complete: " .. name .. " " .. evolution
end

function Strings.Equipped(name)
	return "Equipped: " .. name
end

function Strings.PotionUsed(name, seconds)
	return name .. " active for " .. tostring(seconds) .. "s. Same family replaces the previous one."
end

function Strings.QuestDone(name, heroName, coins)
	local message = "Quest complete: " .. name
	if heroName then
		message ..= ". Hero unlocked: " .. heroName
	end
	if coins and coins > 0 then
		message ..= ". +" .. tostring(coins) .. " Coins"
	end
	return message
end

function Strings.RebirthReady(name)
	return "Rebirth ready for " .. name .. ". Confirm within 30 seconds."
end

function Strings.RebirthDone(name, percent)
	return name .. " completed a Rebirth. Permanent bonus: +" .. tostring(percent) .. "% XP and Coins."
end

function Strings.PointSpent(remaining)
	return "Point spent. Skill Points left: " .. tostring(remaining)
end

function Strings.StatLevel(label, level)
	return label .. " level " .. tostring(level)
end

function Strings.UpgradeHint(statId, cost)
	if cost then
		return "Open the Upgrades menu. Next " .. statId .. ": " .. tostring(cost) .. " Coins."
	end
	return "Open the Upgrades menu. " .. statId .. " is at maximum level."
end

function Strings.ChooseHeroFirst()
	return "The Warrior is ready. Open the Upgrades menu."
end

function Strings.FusionHint()
	return "Select 5 identical pets in the Fusion menu. Unequip them first."
end

function Strings.World2Closed()
	return "The World 2 portal is not active."
end

function Strings.RobuxShowcase(name)
	return name .. " cannot be purchased. No Product ID is configured. Odds are on the sign."
end

function Strings.CoinsRefunded(reason)
	return (reason or "Pet was not granted.") .. " Coins refunded."
end

function Strings.StudioMemory()
	return "Studio session is memory-only. Production data is untouched and this session will not be saved."
end

function Strings.ArenaSign(index, name, mastery, cost)
	local price = cost > 0 and Strings.Coins(cost) or Strings.Free()
	return string.format("Arena %d\n%s\nMastery %d · %s", index, name, mastery, price)
end

function Strings.EggSign(index, cost, odds)
	return string.format("Arena %d Egg\n%s\n%s", index, Strings.Coins(cost), odds)
end

function Strings.RobuxEggSign(name, odds)
	return name .. "\nNOT FOR SALE\nNo Product ID\n" .. odds
end

function Strings.CoinEggSign(cost, odds)
	return "Coin Egg\n" .. Strings.Coins(cost) .. "\nProvisional price\n" .. odds
end

function Strings.AdvancedEggSign(cost)
	return "Advanced Coin Egg\n" .. Strings.Coins(cost) .. "\nWorld 0 pets\nProvisional price"
end

function Strings.PremiumEggSign(odds)
	return "Premium Egg\nNOT FOR SALE\nNo Product ID\n" .. odds
end

function Strings.SoldLoot(name, count, coins)
	return "Sold " .. tostring(count) .. " " .. name .. " for " .. tostring(coins) .. " Coins."
end

Strings.UI = {
	Close = "Close",
	Loading = "Loading data...",
	ChooseHeroFirst = "The Warrior is ready. Open the Upgrades menu.",
	Heroes = "Warrior",
	Upgrades = "Upgrades",
	Inventory = "Inventory",
	Pets = "Pets",
	Skills = "Skills",
	Potions = "Potions",
	Rebirth = "Rebirth",
	Quests = "Quests",
	Arenas = "Arenas",
	Fusion = "Fusion",
	Eggs = "Eggs",
	Active = " (active)",
	LockedHero = "Locked.",
	UseHero = "Use ",
	OneHeroBody = "World 0 has one hero. Mastery, skills, and Rebirth belong to the Warrior.",
	SkillPoints = "Skill Points: ",
	MaxLevel = "Maximum level",
	Talents = "Talents",
	SpendPoint = "Spend point: ",
	AbilitiesInSkills = "Ability ranks are upgraded in the Skills menu.",
	Unlocked = "unlocked",
	Upgrade = "Upgrade ",
	EquipTab = "Gear",
	MaterialsTab = "Materials",
	PotionsTab = "Potions",
	RelicsTab = "Relics",
	Unequip = "Unequip ",
	NoGear = "No equipment.",
	Equip = "Equip ",
	SharedItem = " · shared",
	MaterialsNote = "Materials have no forge in this build. They stay in your inventory.",
	EmptyCategory = "This category is empty.",
	PetLimit = "Up to 3 pets can be equipped. The pet inventory is shared and survives Rebirth.",
	EmptySlot = "Slot %d: empty",
	FilledSlot = "Slot %d: %s",
	ClearSlot = "Clear slot ",
	NoPets = "No pets yet. The World 0 eggs stand in the center of the lobby.",
	EquipPet = "Equip",
	FusionRule = "5 pets with the same id and evolution become 1 of the next tier. Equipped pets cannot be fused.",
	NoFusionPick = "No pets selected.",
	ConfirmFusion = "Confirm fusion",
	ClearFusion = "Clear selection",
	NotIdentical = "Selected pets are not identical.",
	PotionRule = "Two potions of the same family do not stack. The new one replaces duration and strength.",
	Use = "Use",
	NoPotions = "No potions.",
	PrepareRebirth = "Prepare Rebirth",
	ConfirmRebirth = "Confirm Rebirth",
	ConfirmWindow = "Confirm within 30 seconds.",
	ReturnLobby = "Return to lobby",
	EnterArena = "Enter arena ",
	UnlockArena = "Unlock arena ",
	OpenEgg = "Open egg ",
	ShowOdds = "Show odds (no purchase)",
	NotForSale = " · not for sale",
	NoPurchase = "No purchase was made.",
	SelectHeroTitle = "World 0 Warrior",
	SelectHeroBody = "You enter as the Warrior, a prehistoric survivor with a heavy club.",
	Selected = "Selected: ",
	ConfirmHint = ". Confirm to continue.",
	TapHero = "Enter as the Warrior.",
	ConfirmChoice = "Enter World 0",
	SelectBeforeConfirm = "Enter as the Warrior.",
	ChoiceFailed = "Could not choose that hero.",
	RebirthAvailable = "Available at Mastery 50, only at the tribal altar. Each Rebirth grants +10% XP and +10% Coins permanently for this hero.",
	RebirthLost = "Reset: Mastery, XP, stats, Skill Points, talents, abilities, arenas, and equipment bound to this hero.",
	RebirthKept = "Kept: Coins, pets, materials, potions, collectibles, and unbound items.",
	ArenaIntro = "Grave Wilds is the playable arena. Arenas 2–15 keep saved progress and are not open in this build. World 2 has no working portal.",
	ArenaLater = "Not available in World 0. Saved progress is kept.",
	EggIntro = "Three World 0 eggs. Coin and Advanced use provisional coin prices. Premium Egg is not for sale.",
	TradingSoon = "Trading will be available soon.",
	MerchantHint = "The chief is here. Trading will be available soon.",
	MerchantTitle = "Tribal Merchant",
	MerchantSell = "Sell Loot",
	MerchantEmpty = "Nothing is for sale.",
	MerchantStay = "Stay near the chief.",
	SellOne = "Sell 1",
	SellAll = "Sell all",
	Open = " · open",
	LockedArena = " · arena locked",
	Completed = "Completed",
	Weapon = "weapon",
	Armor = "armor",
	Charm = "charm",
	Yes = "yes",
	No = "no",
	DamageWord = "Damage",
	SpeedWord = "speed",
	IntervalWord = "interval",
	Ready = "Ready",
	Shield = "Shield ",
	MasteryWord = "Mastery",
	RebirthWord = "Rebirth",
	TotalWord = "total",
	PointsWord = "Points",
	Cooldown = "Cooldown %.1fs",
	MasteryRequired = "Mastery ",
	ManaWord = "mana",
	DataUnavailable = "Data unavailable",
	PlayerFallback = "Player ",
}

function Strings.HeroLine(mastery, rebirths, points)
	return string.format("Mastery %d · Rebirth %d · Points %d", mastery, rebirths, points)
end

function Strings.NextStat(nextValue, delta, cost)
	return string.format("Next: %s (%+0.2f) · %s Coins", tostring(nextValue), delta, cost)
end

function Strings.StatLine(label, level, value, unit)
	return string.format("%s level %d · effective %s %s", label, level, tostring(value), unit)
end

function Strings.TalentLine(name, rank, maxRank, description)
	return string.format("%s %d/%d — %s", name, rank, maxRank, description)
end

function Strings.AbilityLine(name, rank, maxRank, state)
	return string.format("%s · rank %d/%d · %s", name, rank, maxRank, state)
end

function Strings.GearSlots(weapon, armor, charm)
	local function flag(value)
		return value and Strings.UI.Yes or Strings.UI.No
	end
	return string.format("Slots: weapon %s · armor %s · charm %s", flag(weapon), flag(armor), flag(charm))
end

function Strings.FusionPreview(count, preview)
	if count ~= 5 then
		return "Selected " .. tostring(count) .. "/5. " .. preview
	end
	return preview
end

function Strings.RebirthSummary(name, mastery, rebirths)
	return name .. " · Mastery " .. tostring(mastery) .. " · Rebirth " .. tostring(rebirths)
end

function Strings.ArenaRow(index, name, mastery, cost, unlocked)
	local state = unlocked and Strings.UI.Open or ""
	return string.format("%d. %s · Mastery %d · %s%s", index, name, mastery, cost, state)
end

function Strings.EggRow(name, cost, locked)
	return name .. " · " .. cost .. (locked and Strings.UI.LockedArena or "")
end

return Strings
