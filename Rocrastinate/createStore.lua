local FastSpawn = require(script.Parent.Util.FastSpawn)
local DeepCopyTable = require(script.Parent.Util.DeepCopyTable)

local function voidSelf(self, ...)
	if ( ... ) == self then
		return select(2, ...)
	else
		return ...
	end
end

local function createStore(reducer, initialState)
	local store = {}
	
	local store_enhancedDispatchChain = function(action)
		reducer(
			action,
			store.getState,
			store.setState
		)
	end
	local store_observers = {}
	local store_state = initialState
	
	function store.applyMiddleware(...)
		local middleware = voidSelf(store, ...)
		
		local nextHandler = middleware(store)
		store_enhancedDispatchChain = nextHandler(store_enhancedDispatchChain)
	end
	
	function store.dispatch(...)
		local action = voidSelf(store, ...)
		
		-- Dispatch to last middleware in the chain
		store_enhancedDispatchChain(action)
	end
	
	function store.getState(...)
		local keypath = { voidSelf(store, ...) }
		
		local base = store_state
		for i = 1, #keypath do
			if typeof(base) ~= "table" then
				return nil
			end
			base = base[keypath[i]]
		end
		
		-- Copy accessed tables to prevent mutation
		if type(base) == "table" then
			return DeepCopyTable(base)
		end
		return base
	end
	
	function store.setState(...)
		local keypath = { voidSelf(store, ...) }
		
		local value = keypath[#keypath]
		keypath[#keypath] = nil
		
		-- Mark each keypath that was visited
		local visitedPaths = {''}
		local lastVisitedPath = nil
		for i = 1, #keypath do
			local key = keypath[i]
			local nextVisitedPath
			if lastVisitedPath then
				nextVisitedPath = lastVisitedPath .. "." .. key
			else
				nextVisitedPath = key
			end
			lastVisitedPath = nextVisitedPath
			visitedPaths[#visitedPaths + 1] = nextVisitedPath
		end
		
		-- Find base to mutate
		local base = store_state
		for i = 1, #keypath - 1 do
			if typeof(base) ~= "table" then
				error("Attempt to set non-table key")
			end
			local key = keypath[i]
			base = base[key]
		end
		
		if #keypath == 0 then
			store_state = value
		else
			local lastKey = keypath[#keypath]
			if typeof(base) ~= "table" then
				error("Attempt to set non-table key")
			end
			base[lastKey] = value
		end
		
		-- Call subscribed listeners
		for i = 1, #visitedPaths do
			local observers = store_observers[visitedPaths[i]]
			if observers then
				local saveObservers = {}
				for j = 1, #observers do
					saveObservers[j] = observers[j]
				end
				
				for j = 1, #saveObservers do
					FastSpawn(saveObservers[j])
				end
			end
		end
	end
	
	function store.subscribe(...)
		local strKeypath, callback = voidSelf(store, ...)
		
		local observers = store_observers[strKeypath]
		if not observers then
			observers = {}
			store_observers[strKeypath] = observers
		end
		
		observers[#observers + 1] = callback
		
		-- Swap remove unsubscribe function (also maidable)
		return function()
			for i = 1, #observers do
				if observers[i] == callback then
					observers[i] = observers[#observers]
					observers[#observers] = nil
					break
				end
			end
			if #observers == 0 then
				store_observers[strKeypath] = nil
			end
		end
	end
	
	return store
end

return createStore