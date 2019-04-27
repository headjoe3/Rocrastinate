local FastSpawn = require(script.Parent.Util.FastSpawn)

local function taskDestructor(task)
	local taskType = typeof(task)
	if taskType == "function" then
		-- Callbacks
		FastSpawn(task)
	elseif taskType == "RBXScriptConnection" then
		-- Connections
		task:Disconnect()
	elseif taskType == "string" then
		-- Render step bindings
		pcall(function()
			game:GetService("RunService"):UnbindFromRenderStep(task)
		end)
	elseif taskType == "Instance" or (taskType == "table" and task.Destroy) then
		-- Instances and custom objects with a :Destroy() method
		task:Destroy()
	else
		warn("Unhandled maid task '" .. tostring(task) .. "' of type '" .. taskType .. "'", debug.traceback())
	end
end

local Maid = {}
Maid.__index = Maid

function Maid:GiveTask(...)
	local tasksToAdd = { ... }
	for i = 1, #tasksToAdd do
		self.tasks[#self.tasks + 1] = tasksToAdd[i]
	end
	return ... -- Return for the sake of syntactic convenience.
end

function Maid:CleanupAllTasks()
	local tasks = self.tasks
	
	-- Disconnect all events first as we know this is safe
	for index, task in pairs(tasks) do
		if typeof(task) == "RBXScriptConnection" then
			tasks[index] = nil
			task:Disconnect()
		end
	end

	-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid
	local index, task = next(tasks)
	while task ~= nil do
		tasks[index] = nil
		taskDestructor(task)
		index, task = next(tasks)
	end
end

-- Removes an individual task from the maid's task queue and destroys it
function Maid:Cleanup(task)
	self:RemoveTask(task)
	taskDestructor(task)
end

-- Removes a task from the maid's task queue without destroying it
function Maid:RemoveTask(task)
	local tasks = self.tasks
	for index, otherTask in pairs(tasks) do
		if otherTask == task then
			tasks[index] = nil
			break
		end
	end
end

function Maid.new()
	local self = setmetatable({}, Maid)
	self.tasks = {}
	
	return self
end

return Maid