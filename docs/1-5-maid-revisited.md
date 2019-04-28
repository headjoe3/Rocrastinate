
# 1.5 Maid Revisited

Next tutorial: [1.6 Usage Examples](1-6-usage-examples.md)

Previous tutorial: [1.4 Component Types](1-4-component-types.md)

[Directory](../README.md#tutorial)

## A Utility for Preventing Memory Leaks

I'm not sure where "Maid" class originated, but I have seen it floading around in many of roblox's core scripts, and it seems to be unique to roblox. While it is a utility class, it is a core part of Rocrastinate Components, and the primary way of making sure components can be both created and destroyed safely.

Let us create a non-rocrastinate component for a moment:

```lua
local function createTouchTrackerUI(part)
    local label = Instance.new("TextLabel")
    local touches = 0
    part.Touched:Connect(function()
        touches = touches + 1
        label.Text = "Touches: " .. touches
    end)
    return label
end

local myGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
local touchTrackerLabel = createTouchTrackerUI(game.Workspace.Part)
touchTrackerLabel.Parent = myGui

. . .

myGui:Destroy()
```
This example poses a huge potential memory leak: Namely, when `myGui` is destroyed (and `touchTrackerLabel` along with it), the `Touched` event we listened to will never be disconnected. This means that, even after the UI is destroyed, our label will still be tracking the number of times a part is touched and updating its text, even after it has been destroyed. Events are the easiest portions of memory to leak. In this example, we *could* return the event with the label in the pseudo-component's function—however, this increases the complexity and the number of things we have to track:
```lua
local function createTouchTrackerUI(part)
    local label = Instance.new("TextLabel")
    local touches = 0
    local conn = part.Touched:Connect(function()
        touches = touches + 1
        label.Text = "Touches: " .. touches
    end)
    return label, conn
end

local myGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
local touchTrackerLabel, conn = createTouchTrackerUI(game.Workspace.Part)
touchTrackerLabel.Parent = myGui

. . .

myGui:Destroy()
conn:Disconnect()
```
This can get unmanageable very fast, especially when our UI gets more complex and we have more events we need to listen to.

The Maid class is a utility that tracks resources in the same place that they are created, so that we can simply collect all of the things needing to be destroyed, and clean them up later on.

In this alternative example, which functions similar to Rocrastinate components, we can simply collect things together in a maid, and only return the tasks that need to be cleaned up.
```lua
local function createTouchTrackerUI(part, parent)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    local touches = 0
    local conn = part.Touched:Connect(function()
        touches = touches + 1
        label.Text = "Touches: " .. touches
    end)
    return conn
end
. . .

local maid = Maid.new()
local myGui = maid:GiveTask(
    Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
)
maid:GiveTask( createTouchTrackerUI(game.Workspace.Part) )
. . .

maid:CleanupAllTasks() -- This will destroy the Gui, the label, and the connection updating the label.
```

In a similar way, all Rocrastinate Components have a property of being Maidable—meaning that `local myComponent = MyComponent.new()` should always return an object on which `myComponent:Destroy()` can be called without causing any memory leaks.


The Maid object in Components has the following functions:

* `self.maid:GiveTask(...tasks)` - Collects a task that can be destroyed when the component is destroyed
* `self.maid:Cleanup(task)` - Destroys a given task, and removes it from the maid's queue if it exists (allowing it to be garbage collected)
* `self.maid:Remove(task)` - Removes a task from the maid without destroying it
* `self.maid:CleanupAllTasks()` - This is automatically called when `myComponent:Destroy()` is called.

The following object types are considered maidable:

* RBXScriptConnections - The result of calling `someEvent:Connect(...)` - these will be `:Disconnect()`ed
* Instances - These will be `:Destroy()`ed
* Rocrastinate Components and other tables with a `:Destroy()` method - These will be handled by calling the `:Destroy()` method
* functions - These will be called when the maid cleans up this task
* strings - These will be treated as RenderStep bindings (i.e. `game:GetService("RunService"):BindToRenderStep(someString)`)

Here is the internal code used to handle maid tasks:

```lua
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
```

If there are any other tasks or composite tasks that cannot be handled regularly, we can use maidable functions to handle our cleanup tasks for us:

```lua
local someCache = {}
function MyComponent:constructor()
    someCache[self] = true -- This can leak if we're not careful
    self.maid:GiveTask(function() -- This prevents the leak
        someCache[self] = nil
    end)
end
```

We can also use the Maid for the [object pooling pattern](https://en.wikipedia.org/wiki/Object_pool_pattern)
```lua
function MyComponent:constructor()
    local someRapidlyCreatedOrDestroyedInstance = someObjectPool:GetObject()
    self.maid:GiveTask(function()
        someObjectPool:Recycle(someRapidlyCreatedOrDestroyedInstance)
    end)
end
```

As mentioned earlier, the function `maid:GiveTask()` offers two features for syntactic convenience:
1. `maid:GiveTask(...)` will return the arguments it is passed
2. `maid:GiveTask(a, b, c)` will add a, b, and c as separate tasks

---

Next tutorial: [1.6 Usage Examples](1-6-usage-examples.md)

Previous tutorial: [1.4 Component Types](1-4-component-types.md)

[Directory](../README.md#tutorial)