-- Geometria del Mondo 1. Unica fonte per mappa, spawn e controlli di prossimità.
-- Geometrie prototipo: parti Roblox, non asset definitivi.

local WorldLayout = {}

WorldLayout.ArenaSize = 150
WorldLayout.FirstArenaZ = 430
WorldLayout.ArenaSpacing = 210
WorldLayout.LobbySize = 220
WorldLayout.WallHeight = 28
WorldLayout.FloorThickness = 2

WorldLayout.Radii = {
	Hero = 32,
	Upgrade = 32,
	Rebirth = 28,
	Fusion = 32,
	Egg = 16,
	ArenaPad = 24,
	Portal = 22,
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

-- Pad sicuro interno, vicino al cancello sud, lontano dagli spawn nemici.
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
	return Vector3.new(0, 8, 36)
end

function WorldLayout.HeroSwitch()
	return Vector3.new(236, 4, -36)
end

function WorldLayout.Upgrades()
	return Vector3.new(236, 4, 36)
end

function WorldLayout.Rebirth()
	return Vector3.new(340, 4, 0)
end

function WorldLayout.Fusion()
	return Vector3.new(236, 4, 118)
end

function WorldLayout.Portal()
	return Vector3.new(450, 16, 210)
end

function WorldLayout.LeaderboardOrigin()
	return Vector3.new(-280, 0, 0)
end

function WorldLayout.EggTerraces()
	return {
		{ index = 1, position = Vector3.new(0, 0, -310), arenas = { 1, 2, 3, 4, 5 }, special = 1 },
		{ index = 2, position = Vector3.new(0, 16, -490), arenas = { 6, 7, 8, 9, 10 }, special = 2 },
		{ index = 3, position = Vector3.new(0, 32, -670), arenas = { 11, 12, 13, 14, 15 }, special = 3 },
	}
end

function WorldLayout.EggPosition(terrace, slot)
	-- slot 1..5 uova arena, slot 6 uovo Robux.
	local origin = terrace.position
	local x = -80 + (slot - 1) * 32
	return Vector3.new(origin.X + x, origin.Y + 4, origin.Z)
end

function WorldLayout.FindArenaEgg(arenaIndex)
	for _, terrace in WorldLayout.EggTerraces() do
		for slot, arena in ipairs(terrace.arenas) do
			if arena == arenaIndex then
				return WorldLayout.EggPosition(terrace, slot), terrace
			end
		end
	end
	return nil, nil
end

function WorldLayout.FindSpecialEgg(specialIndex)
	local terraces = WorldLayout.EggTerraces()
	local terrace = terraces[specialIndex]
	if not terrace then
		return nil
	end
	return WorldLayout.EggPosition(terrace, 6), terrace
end

function WorldLayout.InLobby(position)
	if typeof(position) ~= "Vector3" then
		return false
	end
	return math.abs(position.X) <= 125 and math.abs(position.Z) <= 125 and position.Y > -8 and position.Y < 30
end

function WorldLayout.Near(position, target, radius)
	if typeof(position) ~= "Vector3" or typeof(target) ~= "Vector3" then
		return false
	end
	return (position - target).Magnitude <= radius
end

function WorldLayout.PodiumSpec(boardIndex, place)
	local origin = WorldLayout.LeaderboardOrigin()
	local heights = { 8, 5.5, 3.5 }
	local height = heights[place]
	local zOffset = ({ -12, 0, 12 })[place]
	local center = Vector3.new(origin.X + (boardIndex - 2) * 52, 1 + height / 2, origin.Z + zOffset)
	return center, Vector3.new(9, height, 9)
end

function WorldLayout.PodiumName(boardId, place)
	return "Podium_" .. boardId .. "_" .. tostring(place)
end

return WorldLayout
