local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local cache = {}

return function(name)
	if cache[name] == nil then
		cache[name] = require(Shared:WaitForChild(name))
	end
	return cache[name]
end
