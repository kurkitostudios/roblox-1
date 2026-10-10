-- Profilo iniziale e struttura per eroe.
-- schemaVersion 1.

local HeroConfig = require(script.Parent.HeroConfig)
local AbilityConfig = require(script.Parent.AbilityConfig)
local QuestConfig = require(script.Parent.QuestConfig)

local ProfileTemplate = {}

ProfileTemplate.SchemaVersion = 1

function ProfileTemplate.CreateHero(classId)
	local classDef = HeroConfig.Classes[classId]
	local stats = {}
	for _, statId in classDef.stats do
		stats[statId] = 1
	end
	local skillRanks = {}
	for _, ability in AbilityConfig[classId] do
		skillRanks[ability.id] = 0
	end
	local talents = {}
	for _, talent in HeroConfig.Talents do
		talents[talent.id] = 0
	end
	return {
		mastery = 0,
		xp = 0,
		skillPoints = 0,
		rebirths = 0,
		stats = stats,
		skillRanks = skillRanks,
		talents = talents,
		unlockedArenas = { ["1"] = true },
		equippedGear = { weapon = "", armor = "", charm = "" },
	}
end

function ProfileTemplate.Create(startingCoins)
	local quests = {}
	for _, quest in ipairs(QuestConfig) do
		quests[quest.id] = { progress = 0, completed = false }
	end
	return {
		schemaVersion = ProfileTemplate.SchemaVersion,
		coins = startingCoins or 0,
		selectedHero = "",
		firstHeroChosen = false,
		unlockedHeroes = {
			Warrior = false,
			Mage = false,
			Archer = false,
		},
		playTimeSeconds = 0,
		totalKills = 0,
		quests = quests,
		pets = {},
		equippedPets = { "", "", "" },
		inventory = {
			equipment = {},
			materials = {},
			potions = {},
			collectibles = {},
		},
		heroes = {
			Warrior = ProfileTemplate.CreateHero("Warrior"),
			Mage = ProfileTemplate.CreateHero("Mage"),
			Archer = ProfileTemplate.CreateHero("Archer"),
		},
	}
end

return ProfileTemplate
