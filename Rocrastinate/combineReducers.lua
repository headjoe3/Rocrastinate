local function combineReducers(reducersMap)
	-- Build into an array
	local gets = {}
	local sets = {}
	local reducers = {}
	for k, reducer in pairs(reducersMap) do
		local i = #reducers + 1
		reducers[i] = reducer
		gets[i] = function(get)
			return function(...)
				return get(k, ...)
			end
		end
		sets[i] = function(set)
			return function(...)
				set(k, ...)
			end
		end
	end
	
	-- Run action through array
	return function(action, get, set)
		for i = 1, #reducers do
			reducers[i](action, gets[i](get), sets[i](set))
		end
	end
end

return combineReducers