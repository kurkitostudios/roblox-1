-- Geometria del Mondo 0. Unica fonte per mappa, spawn e controlli di prossimità.
-- Il rettangolo del lobby contiene villaggio, uova, mercante e classifiche.
-- Le arene 2–15 restano sul percorso nord e non vengono ridisegnate in questa build.

local WorldLayout = {}

WorldLayout.ArenaSize = 150
WorldLayout.FirstArenaZ = 430
WorldLayout.ArenaSpacing = 210
WorldLayout.LobbySize = 220
WorldLayout.WallHeight = 28
WorldLayout.FloorThickness = 2

-- Rettangolo lungo: ovest villaggio, sud uova, est classifiche, nord Arena 1.
WorldLayout.Lobby = {
	center = Vector3.new(0, 0, -20),
	size = Vector3.new(640, 2, 460),
}

WorldLayout.Radii = {
	Hero = 32,
	Upgrade = 32,
	Rebirth = 28,
	Fusion = 32,
	Egg = 16,
	ArenaPad = 24,
	Portal = 22,
	Merchant = 16,
}

function WorldLayout.FloorTop(centerY)
	return (centerY or 0) + WorldLayout.FloorThickness * 0.5
end

function WorldLayout.ArenaCenter(index)
	return Vector3.new(0, 0, WorldLayout.FirstArenaZ + (index - 1) * WorldLayout.ArenaSpacing)
end

function WorldLayout.ArenaHalf()
	return WorldLayout.ArenaSize * 0.5
end

function WorldLayout.InsideArena(position, index)
	local center = WorldLayout.ArenaCenter(index)
	local half = WorldLayout.ArenaHalf() - 2
	return math.abs(position.X - center.X) <= half and math.abs(position.Z - center.Z) <= half
end

function WorldLayout.ArenaIndexAt(position)
	if typeof(position) ~= "Vector3" then
		return nil
	end
	for index = 1, 15 do
		if WorldLayout.InsideArena(position, index) then
			return index
		end
	end
	return nil
end

function WorldLayout.ArenaEntry(index)
	local center = WorldLayout.ArenaCenter(index)
	return Vector3.new(center.X, 6, center.Z - 58)
end

function WorldLayout.ArenaGate(index)
	local center = WorldLayout.ArenaCenter(index)
	local half = WorldLayout.ArenaHalf()
	return Vector3.new(center.X, 4, center.Z - half - 8)
end

function WorldLayout.LobbySpawn()
	return Vector3.new(0, 8, 46)
end

function WorldLayout.HeroSwitch()
	return Vector3.new(-78, 4, 36)
end

function WorldLayout.Upgrades()
	return Vector3.new(42, 4, 72)
end

function WorldLayout.Rebirth()
	return Vector3.new(86, 4, 18)
end

function WorldLayout.Fusion()
	return Vector3.new(8, 4, -96)
end

function WorldLayout.Portal()
	return Vector3.new(168, 4, 172)
end

function WorldLayout.Merchant()
	return Vector3.new(-116, 4, -28)
end

function WorldLayout.CoinEgg()
	return Vector3.new(-36, 4, -156)
end

function WorldLayout.AdvancedEgg()
	return Vector3.new(0, 4, -178)
end

function WorldLayout.PremiumEgg()
	return Vector3.new(36, 4, -156)
end

function WorldLayout.FindArenaEgg(arenaIndex)
	if type(arenaIndex) ~= "number" then
		return nil, nil
	end
	if arenaIndex == 1 then
		return WorldLayout.CoinEgg(), { index = 1 }
	end
	if arenaIndex >= 2 and arenaIndex <= 15 then
		return WorldLayout.AdvancedEgg(), { index = 2 }
	end
	return nil, nil
end

function WorldLayout.FindSpecialEgg(specialIndex)
	if type(specialIndex) ~= "number" or specialIndex < 1 or specialIndex > 3 then
		return nil, nil
	end
	return WorldLayout.PremiumEgg(), { special = specialIndex }
end

function WorldLayout.InLobby(position)
	if typeof(position) ~= "Vector3" then
		return false
	end
	local center = WorldLayout.Lobby.center
	local half = WorldLayout.Lobby.size * 0.5
	return math.abs(position.X - center.X) <= half.X - 6
		and math.abs(position.Z - center.Z) <= half.Z - 6
		and position.Y > -8
		and position.Y < 48
end

function WorldLayout.Near(position, target, radius)
	if typeof(position) ~= "Vector3" or typeof(target) ~= "Vector3" then
		return false
	end
	return (position - target).Magnitude <= radius
end

function WorldLayout.LeaderboardBoards()
	return {
		{ id = "Kills", title = "MOST KILLS" },
		{ id = "Rebirth", title = "MOST REBIRTHS" },
		{ id = "Time", title = "MOST TIME PLAYED" },
		{ id = "Coins", title = "MOST COINS" },
	}
end

function WorldLayout.LeaderboardOrigin()
	return Vector3.new(236, 0, -16)
end

function WorldLayout.BoardAnchor(boardIndex)
	local origin = WorldLayout.LeaderboardOrigin()
	local z = origin.Z + (boardIndex - 2.5) * 80
	return Vector3.new(origin.X, origin.Y, z)
end

function WorldLayout.PodiumSpec(boardIndex, place)
	local anchor = WorldLayout.BoardAnchor(boardIndex)
	local heights = { 6.6, 4.6, 3.1 }
	local height = heights[place] or 3
	local zOffset = ({ 0, -7.2, 7.2 })[place] or 0
	local xOffset = ({ -22, -14.5, -14.5 })[place] or -14
	local center = Vector3.new(anchor.X + xOffset, 1 + height / 2, anchor.Z + zOffset)
	return center, Vector3.new(7, height, 6.2)
end

function WorldLayout.PodiumName(boardId, place)
	return "Podium_" .. boardId .. "_" .. tostring(place)
end

return WorldLayout
