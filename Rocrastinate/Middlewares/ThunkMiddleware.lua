local function ThunkMiddleware(store)
	return function(nextDispatch)
		return function(action)
			if typeof(action) == "function" then
				action(store.dispatch, store.getState)
				return
			end
			nextDispatch(action)
		end
	end
end

return ThunkMiddleware