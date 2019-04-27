local function ThunkMiddleware(store)
	return function(nextMiddleware)
		return function(action)
			if typeof(action) == "function" then
				action(store.dispatch, store.getState)
				return
			end
			nextMiddleware(action)
		end
	end
end

return ThunkMiddleware