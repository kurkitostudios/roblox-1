local Notifier = {}

local ctx

function Notifier.Start(context)
	ctx = context
end

function Notifier.Send(player, kind, text)
	if not ctx or not player or player.Parent == nil then
		return
	end
	local remote = ctx.remotes.Notification
	if remote then
		remote:FireClient(player, {
			kind = kind or "info",
			text = tostring(text or ""),
		})
	end
end

return Notifier
