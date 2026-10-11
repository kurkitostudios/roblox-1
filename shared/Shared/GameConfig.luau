-- Kurkito Studios — Build 003
-- Configurazione globale. I valori di bilanciamento sono PROVVISORI.

local GameConfig = {
	BuildName = "Kurkito Battle Survival",
	BuildVersion = "003.1",
	WorldBuildId = "world0-build003-1",

	-- Loop AI e combattimento. Non usare un controllo per frame.
	TickInterval = 0.2,
	VitalsInterval = 0.5,
	ArenaEnforceInterval = 0.5,
	AutosaveInterval = 45,
	MinSaveGap = 12,
	PlaytimeFlushInterval = 30,
	LeaderboardInterval = 90,
	PodiumInterval = 120,

	MaxCoins = 1000000000000,
	MaxMastery = 50,

	-- PROVVISORIO: XP per passare da `mastery` a `mastery + 1`
	-- = floor(base * (mastery + 1) ^ exponent)
	MasteryCurve = {
		base = 40,
		exponent = 1.45,
	},

	Combat = {
		-- HighestDamage: chi ha inflitto più danni ottiene kill, XP, Coins e loot.
		-- In parità vince l'ultimo colpo. LastHit: solo l'ultimo colpo.
		KillCredit = "HighestDamage",
		LeashSeconds = 5,
		AggroStateSeconds = 0.35,
		ReturnArriveDistance = 6,
		IdleLeash = 10,
	},

	Inventory = {
		MaxEquipment = 80,
		MaxPets = 200,
		MaxStack = 9999,
	},

	Fusion = {
		Required = 5,
	},

	Data = {
		ProductionStoreName = "Kurkito_Player_v1",
		StudioStoreName = "Kurkito_Studio_Player_v1",
		ProductionPublicStoreName = "Kurkito_Public_v1",
		StudioPublicStoreName = "Kurkito_Studio_Public_v1",
		ProductionBoards = {
			Rebirth = "Kurkito_LB_Rebirth_v1",
			Time = "Kurkito_LB_Time_v1",
			Kills = "Kurkito_LB_Kills_v1",
			Coins = "Kurkito_LB_Coins_v1",
		},
		StudioBoards = {
			Rebirth = "Kurkito_Studio_LB_Rebirth_v1",
			Time = "Kurkito_Studio_LB_Time_v1",
			Kills = "Kurkito_Studio_LB_Kills_v1",
			Coins = "Kurkito_Studio_LB_Coins_v1",
		},
		LockSeconds = 120,
		LoadRetries = 4,
		SaveRetries = 3,
		-- Solo profili NUOVI creati in Studio. Non tocca i dati di produzione.
		StudioStartingCoins = 500,
	},

	Rates = {
		SelectHero = 3,
		SwitchHero = 5,
		UpgradeStat = 10,
		SpendSkillPoint = 10,
		UnlockArena = 5,
		Teleport = 5,
		Rebirth = 3,
		OpenEgg = 5,
		SellLoot = 8,
		FusePets = 4,
		UsePotion = 6,
		EquipPet = 8,
		UnequipPet = 8,
		EquipItem = 8,
		UnequipItem = 8,
	},

	ProximitySlack = 10,
}

return GameConfig
