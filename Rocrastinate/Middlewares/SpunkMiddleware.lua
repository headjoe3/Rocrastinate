--[[
	Spunk stands for "Spawned Thunk", which asynchronously
	spawns thunks rather than calling them synchronously.
	
	This could be preferable due to Roblox not being NodeJS
	or having a Promise library (unless you use roblox-ts)
--]]

local FastSpawn = require(script.Parent.Parent.Util.FastSpawn)

local function SpunkMiddleware(store)
	return function(nextMiddleware)
		return function(action)
			if typeof(action) == "function" then
				FastSpawn(action, store.dispatch, store.getState)
				return
			end
			nextMiddleware(action)
		end
	end
end

return SpunkMiddleware