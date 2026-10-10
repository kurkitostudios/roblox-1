local RateLimiter = {}

local buckets = {}

function RateLimiter.Allow(player, action, limit, windowSeconds)
	if limit == nil then
		return true
	end
	windowSeconds = windowSeconds or 10
	local now = os.clock()
	local userId = player.UserId
	local userBuckets = buckets[userId]
	if not userBuckets then
		userBuckets = {}
		buckets[userId] = userBuckets
	end
	local stamps = userBuckets[action]
	if not stamps then
		stamps = {}
		userBuckets[action] = stamps
	end
	local kept = {}
	for _, stamp in stamps do
		if now - stamp < windowSeconds then
			table.insert(kept, stamp)
		end
	end
	if #kept >= limit then
		userBuckets[action] = kept
		return false
	end
	table.insert(kept, now)
	userBuckets[action] = kept
	return true
end

function RateLimiter.Clear(player)
	buckets[player.UserId] = nil
end

return RateLimiter
