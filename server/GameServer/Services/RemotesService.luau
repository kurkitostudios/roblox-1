local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = require(script.Parent.SharedLoader)
local RemoteNames = shared("RemoteNames")
local RateLimiter = require(script.Parent.RateLimiter)

local RemotesService = {}

local function ensure(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing.ClassName == className then
			return existing
		end
		existing:Destroy()
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = parent
	return created
end

function RemotesService.Start(ctx)
	local folder = ReplicatedStorage:FindFirstChild(RemoteNames.Folder)
	if folder and not folder:IsA("Folder") then
		folder:Destroy()
		folder = nil
	end
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = RemoteNames.Folder
		folder.Parent = ReplicatedStorage
	end

	ctx.remotes = {}
	for _, name in ipairs(RemoteNames.Functions) do
		ctx.remotes[name] = ensure("RemoteFunction", name, folder)
	end
	for _, name in ipairs(RemoteNames.Events) do
		ctx.remotes[name] = ensure("RemoteEvent", name, folder)
	end
	ctx.remoteFolder = folder
end

function RemotesService.Bind(ctx, name, limit, handler)
	local remote = ctx.remotes[name]
	if not remote then
		error("[Kurkito] Missing remote: " .. tostring(name))
	end
	remote.OnServerInvoke = function(player, payload)
		if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent == nil then
			return { ok = false, error = "Invalid player." }
		end
		if payload ~= nil and type(payload) ~= "table" then
			return { ok = false, error = "Invalid request." }
		end
		if type(payload) == "table" then
			local count = 0
			for key, value in pairs(payload) do
				count += 1
				if count > 12 or type(key) ~= "string" then
					return { ok = false, error = "Invalid request." }
				end
				if type(value) == "table" then
					local inner = 0
					for innerKey, innerValue in pairs(value) do
						inner += 1
						if inner > 8 or (type(innerValue) ~= "string" and type(innerValue) ~= "number") then
							return { ok = false, error = "Invalid request." }
						end
						if type(innerKey) ~= "number" and type(innerKey) ~= "string" then
							return { ok = false, error = "Invalid request." }
						end
					end
				elseif type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then
					return { ok = false, error = "Invalid request." }
				end
			end
		end
		if not RateLimiter.Allow(player, name, limit, 10) then
			return { ok = false, error = "Too many requests. Wait a moment." }
		end
		local ok, result = xpcall(handler, debug.traceback, player, payload or {})
		if not ok then
			warn("[Kurkito] Remote error " .. name .. ": " .. tostring(result))
			return { ok = false, error = "Internal error." }
		end
		if type(result) ~= "table" then
			return { ok = false, error = "Invalid response." }
		end
		return result
	end
end

return RemotesService
