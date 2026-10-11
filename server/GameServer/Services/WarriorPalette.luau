-- Colori e misure del Warrior del Mondo 0.
-- Un solo costume, quello dei fogli approvati. Nessun asset esterno.

local WarriorPalette = {
	Skin = Color3.fromRGB(224, 163, 118),
	SkinShadow = Color3.fromRGB(196, 132, 92),
	SkinDeep = Color3.fromRGB(168, 108, 74),

	Hair = Color3.fromRGB(36, 24, 18),
	HairEdge = Color3.fromRGB(58, 38, 26),

	FurDark = Color3.fromRGB(42, 30, 22),
	Fur = Color3.fromRGB(74, 50, 34),
	FurMid = Color3.fromRGB(108, 76, 50),
	FurLight = Color3.fromRGB(150, 118, 86),

	Leather = Color3.fromRGB(62, 40, 28),
	LeatherMid = Color3.fromRGB(96, 62, 40),
	LeatherWorn = Color3.fromRGB(128, 84, 52),

	Bone = Color3.fromRGB(232, 220, 198),
	BoneDark = Color3.fromRGB(186, 168, 140),
	Socket = Color3.fromRGB(28, 22, 20),

	Wood = Color3.fromRGB(92, 60, 36),
	WoodDark = Color3.fromRGB(54, 34, 22),
	WoodBark = Color3.fromRGB(70, 46, 28),

	Stone = Color3.fromRGB(108, 106, 102),
	StoneDark = Color3.fromRGB(62, 60, 58),
	StoneLight = Color3.fromRGB(148, 144, 136),

	ClothRed = Color3.fromRGB(148, 36, 38),
	ClothRedDark = Color3.fromRGB(108, 24, 28),

	Paint = Color3.fromRGB(236, 230, 216),
	Metal = Color3.fromRGB(118, 96, 72),

	EyeWhite = Color3.fromRGB(244, 238, 228),
	Iris = Color3.fromRGB(42, 26, 18),
	Pupil = Color3.fromRGB(12, 8, 8),
	Mouth = Color3.fromRGB(92, 48, 44),
	Brow = Color3.fromRGB(24, 16, 12),

	PreviewBackdrop = Color3.fromRGB(132, 132, 136),
	PreviewLight = Color3.fromRGB(255, 248, 240),

	-- Testa cubica arrotondata, indipendente dalla mesh dell'avatar.
	HeadShell = Vector3.new(1.5, 1.36, 1.38),

	-- La clava è alta circa quanto il personaggio. Il grip sta sul fusto, non sulla pietra.
	ClubBottomClearance = 0.2,
	ClubStoneOverhang = 0.58,
	ClubMinLength = 4.15,
	ClubMaxLength = 5.35,
}

return WarriorPalette
