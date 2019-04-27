local Maid = require(script.Parent.Maid)
local FastSpawn = require(script.Parent.Util.FastSpawn)
local ParseKeypath = require(script.Parent.Util.ParseKeypath)
local RunService = game:GetService("RunService")

-- Frame loop bindings
local bindingHandlerActive = {}
local function getBindingHandler(queue)
	return function()
		bindingHandlerActive[queue] = true
		local requeueNextFrame = {}
		local handled = {}
		
		local component = next(queue)
		while component do
			queue[component] = nil
			if handled[component] then
				requeueNextFrame[component] = true
			else
				handled[component] = true
				
				FastSpawn(component.Redraw, component, component.getReducedState())
			end
			
			component = next(queue)
		end
		bindingHandlerActive[queue] = false
		
		for component in pairs(requeueNextFrame) do
			queue[component] = true
		end
	end
end

local renderStepQueue = {}
RunService:BindToRenderStep(
	"Rocrastinate Redraw",
	Enum.RenderPriority.Last.Value + 1,
	getBindingHandler(renderStepQueue)
)

local renderStepTwiceQueue = {}
RunService:BindToRenderStep(
	"Rocrastinate Second Redraw",
	Enum.RenderPriority.Last.Value + 2,
	getBindingHandler(renderStepTwiceQueue)
)

local heartbeatQueue = {}
RunService.Heartbeat:Connect(getBindingHandler(heartbeatQueue))

-- Abstract class
local Component = {}

function Component:constructor(store)
	local useStore = true
	if type(store) ~= "table"
	or type(store.getState) ~= "function"
	or type(store.setState) ~= "function" then
		useStore = false
		
		if self.Reduction then
			warn(
				"Components with a state reduction must have a store as the first argument of their constructor",
				debug.traceback()
			)
		end
	end
	
	
	self.maid = Maid.new()
	
	-- Map reduction
	local mappedStateKeys = {}
	local mappedKeypaths = {}
	if self.Reduction then
		for k, strKeypath in pairs(self.Reduction) do
			mappedStateKeys[#mappedStateKeys + 1] = k
			mappedKeypaths[#mappedKeypaths + 1] = ParseKeypath(strKeypath)
		end
	end
	
	if useStore then
		self.getReducedState = function()
			local reducedState = {}
			for i = 1, #mappedStateKeys do
				local stateKey = mappedStateKeys[i]
				local keypath = mappedKeypaths[i]
				
				reducedState[stateKey] = store.getState(unpack(keypath))
			end
			return reducedState
		end
	else
		self.getReducedState = function()
			return {}
		end
	end
	
	-- Bind queueRedraw
	
	self.queueRedraw = function()
		if self.RedrawBinding == "RenderStep" then
			renderStepQueue[self] = true
		elseif self.RedrawBinding == "RenderStepTwice" then
			if bindingHandlerActive[renderStepQueue] then
				renderStepTwiceQueue[self] = true
			else
				renderStepQueue[self] = true
			end
		elseif self.RedrawBinding == "Heartbeat" then
			heartbeatQueue[self] = true
		end
	end
	
	-- Subscribe to reduction
	if useStore and self.Reduction then
		for k, strKeypath in pairs(self.Reduction) do
			self.maid:GiveTask(store.subscribe(strKeypath, self.queueRedraw))
		end
	end
end

local reservedStatics = {
	new = true,
	Destroy = true,
}
local componentStaticMT = {
	__newindex = function(self, k, v)
		if reservedStatics[k] then
			error("Cannot override Component member '" .. k .. "'; key is reserved")
		else
			rawset(self, k, v)
		end
	end,
}

function Component:extend()
	local componentStatics = {}
	local componentMT = {
		__index = componentStatics
	}
	
	-- Construction/destruction
	function componentStatics.new(store, ...)
		local self = setmetatable({}, componentMT)
		Component.constructor(self, store)
		if componentStatics.constructor then
			componentStatics.constructor(self, store, ...)
		end
		
		self.queueRedraw()
		
		return self
	end
	function componentStatics:Destroy()
		self.maid:CleanupAllTasks()
		renderStepQueue[self] = nil
		heartbeatQueue[self] = nil
		renderStepTwiceQueue[self] = nil
	end
	
	-- Default redraw behavior
	componentStatics.RedrawBinding = "Heartbeat"
	
	-- Default noop
	function componentStatics:Redraw(reducedState) end
	
	return setmetatable(componentStatics, componentStaticMT)
end

return Component