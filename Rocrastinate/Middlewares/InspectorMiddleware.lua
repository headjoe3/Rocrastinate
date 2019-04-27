local function keyToStr(key)
	if type(key) == "string" then
		return key
	else
		return '[' .. tostring(key) .. ']'
	end
end

local function valueToStr(val)
	if type(val) == "string" then
		if val:find("'") then
			if val:find('"') then
				return '[[' .. val .. ']]'
			else
				return '"' .. val .. '"'
			end
		else
			return "'" .. val .. "'"
		end
	else
		return tostring(val)
	end
end

local function inspect(object, depth, maxDepth)
	local indent = string.rep("  ", depth)
	for k, v in pairs(object) do
		if type(v) == "table" and depth < maxDepth then
			print(indent .. keyToStr(k) .. " = {")
			inspect(v, depth + 1, maxDepth)
			print(indent .. "},")
		else
			print(indent .. keyToStr(k) .. " = " .. valueToStr(v) .. ",")
		end
	end
end

local function createInspectorMiddleware(options)
	options = options or {}
	local maxDepth = options.maxDepth or 4
	
	return function(store)
		return function(nextMiddleware)
			return function(action)
				print('{')
				inspect(action, 1, maxDepth + 1)
				print('}')
				nextMiddleware(action)
			end
		end
	end
end

return {
	createInspectorMiddleware = createInspectorMiddleware,
}