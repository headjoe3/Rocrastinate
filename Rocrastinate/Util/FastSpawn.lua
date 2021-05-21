--!strict

local FAST_SPAWN_BINDABLE = Instance.new('BindableFunction')
local FAST_SPAWN_CALLER = function(cb: () -> (), ...)
	cb(...)
end :: any
local LOCK_IS_INVOKING = false
FAST_SPAWN_BINDABLE.OnInvoke = FAST_SPAWN_CALLER

local function FastSpawn(func: () -> (), ...: any)
	if LOCK_IS_INVOKING then
		local nestedCallFastSpawnBindable = Instance.new('BindableFunction')
		nestedCallFastSpawnBindable.OnInvoke = FAST_SPAWN_CALLER
		coroutine.resume(
			coroutine.create(function()
				nestedCallFastSpawnBindable:Invoke(func, ...)
			end)
		)
	else
		LOCK_IS_INVOKING = true
		coroutine.resume(
			coroutine.create(function()
				FAST_SPAWN_BINDABLE:Invoke(func, ...)
			end)
		)
		LOCK_IS_INVOKING = false
	end
end

return FastSpawn
