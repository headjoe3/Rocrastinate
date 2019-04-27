local function LoggerMiddleware(store)
	return function(nextMiddleware)
		return function(action)
			print(action.type)
			nextMiddleware(action)
		end
	end
end

return LoggerMiddleware