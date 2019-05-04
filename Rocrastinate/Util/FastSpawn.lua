local function FunctionWrapper(callback, ...)
	coroutine.yield()
	callback(...)
end

local Bindable = Instance.new("BindableEvent")
Bindable.Event:Connect(function(callback) callback() end)

local function FastSpawn(callback, ...)
	assert(type(callback) == "function", "Invalid arguments (function expected, got " .. typeof(callback) .. ")")
	local func = coroutine.wrap(FunctionWrapper)
	func(callback, ...)
	Bindable:Fire(func)
end

return FastSpawn
