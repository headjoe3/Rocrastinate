local function LoggerMiddleware(store)
	return function(nextDispatch)
		return function(action)
			print(action.type)
			nextDispatch(action)
		end
	end
end

return LoggerMiddleware