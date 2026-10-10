-- Nomi dei remote creati dal server in ReplicatedStorage.KurkitoRemotes.
-- Il client non crea remote e non assegna ricompense.

local RemoteNames = {
	Folder = "KurkitoRemotes",

	Functions = {
		"SelectHero",
		"SwitchHero",
		"UpgradeStat",
		"SpendSkillPoint",
		"UnlockArena",
		"Teleport",
		"Rebirth",
		"OpenEgg",
		"FusePets",
		"UsePotion",
		"EquipPet",
		"UnequipPet",
		"EquipItem",
		"UnequipItem",
		"SellLoot",
	},

	Events = {
		"ProfileSync",
		"Notification",
		"Vitals",
		"OpenMerchant",
	},
}

return RemoteNames
