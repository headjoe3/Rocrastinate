# 1.3 Component State Reduction

Next tutorial: [1.4 Component Types](1-4-component-types.md)

Previous tutorial: [1.2 Rocrastinate Store](1-2-rocrastinate-store.md)

[Directory](../README.md#tutorial)

## The Observer Pattern

In order to understand how we can re-draw our components based on store updates, we must first look at the way in which the Rocrastinate Store propogates updates

As we saw in the last tutorial, reducers are given a special function `set()`, which mutates a value in the store.

Technically, for the root reducer, the actual function `get()` passed to the reducer is `store.getState()`, and the actual function `set()` is `store.setState()`.

What `store.getState(...keypath)` is parse a provided series of string keys until a value is found in the store. If a key does not exist at a given path, the store will return `nil`. For the sake of mutation safety, the store will NOT directly return a table if it is encountered using `store.getState(...)`; instead, the table will be cloned first, and then returned.

If you want a table in the store to be directly mutable when it is retrieved using `get()`, you can create a pointer to it by wrapping it in a function:

```lua
local function createPointer(...)
    local args = { ... }
    return function()
        return unpack(args)
    end
end
local myTable = {}
store.setState("myTable", createPointer(myTable))

. . .

local ptr_myTable = store.getState("myTable")
print(myTable == ptr_myTable()) -- true
```

In addition to `get()` doing more that directly returning the value in the store, the function `set()` also does more than directly mutating the value in the store. It also keeps track of each key that was changed, and notifies any observers of the change.

You can observe store changes using the `store.subscribe('path.to.key', callback)` function. Unlike `getState` and `setState`, the key path is denoted using the dot notation. subscribing to the empty string `''` will observe all store changes.

Example:
```lua
local store = Rocrastinate.createStore(function()end, { playerStats = { coins = 0 } })

local unsubscribe = store.subscribe('playerStats.coins', function()
    local coins = store.getState('playerStats', 'coins')
    print("You have", coins, "Coins")
end)
store.setState('playerStats', 'coins', 10) -- You have 10 Coins
unsubscribe()
store.setState('playerStats', 'coins', 20) -- ( No output )
```

## Observing with Components

Your Components can listen to changes in a store and automatically queue updates when a value in the store has changed. In order to do this, some preconditions need to be set:
1. The component needs to know what store to observe changes from
2. The component needs to know what key paths to subscribe to, and how to display them.

The first precondition is simple: We can simply pass the store in as an argument in the Component's constructor. **In fact, Rocrastinate Components must receive a store as the first argument in their constructor in order to observe changes from that store**.

While passing the same first argument through every single component down the tree of components may seem verbose, this actually makes it easy to differentiate "Container Components" (which are generally coupled with your particular segment of the application) from "Presentational Components" (which can generally be re-used throughout the application). More on that in a later tutorial.

Let's add the store to our CoinsDisplay's constructor from a previous tutorial:
```lua
function CoinsDisplay:constructor(store, parent)
    self.parent = parent
    self.store = store

    self.coins = 0
end
```
In this instance, we set `self.store = store` so that we can keep track of the store in case we need to give it to a nested component in our redraw function (similar to how we keep track of `parent` in order to know where we should inevitably place the copy of our component's template).

Now what we want is to subscribe to a value in the store (say, 'coins'), and automatically call `self.queueRedraw()` whenever this state changes. Rocrastinate provides an easy way of doing this for Components using a property called `Reduction`:

```lua
CoinsDisplay.Reduction = {
    coins = 'store.path.to.coins'
}
```
This will automatically subscribe new CoinsDisplay components to the keypath `'store.path.to.coins'`, and map it to the value `'coins'`. The reduced state will then be passed in as a table, as the first argument to `CoinsDisplay:Redraw()`

```lua
CoinsDisplay.Reduction = {
    coins = 'store.path.to.coins'
}
CoinsDisplay.RedrawBinding = "Heartbeat"
function CoinsDisplay:Redraw(reducedState)
    -- From earlier
    if not self.gui then
        self.gui = self.maid:GiveTask(script.CoinsDisplayTemplate:Clone())
        self.gui.Parent = self.parent
    end
    
    -- Now we are displaying from reducedState.coins instead of self.coins.
    -- In fact, we can get rid of self.coins, now that our data is coming from the store.
    self.gui.CoinsLabel.Text = "Coins: " .. reducedState.coins
end
```

We can get rid of `self.coins` now that the data is being pulled from our store. In fact, we can also get rid of the `CoinsDisplay:AddCoin()` method we defined earlier, and replace it with actions such as `ADD_COINS` from the last tutorial. Putting it all together:

## Final Code

### game.ReplicatedStorage.CoinsDisplay ModuleScript
```lua
local Rocrastinate = require(game.ReplicatedStorage.Rocrastinate)
local CoinsDisplay = Rocrastinate.Component:extend()

function CoinsDisplay:constructor(store, parent)
    self.store = store
    self.parent = parent
end

CoinsDisplay.Reduction = {
    coins = '' -- In this example, our store state is equivalent to coins
}
CoinsDisplay.RedrawBinding = "Heartbeat"
function CoinsDisplay:Redraw(reducedState)
    if not self.gui then
        self.gui = self.maid:GiveTask(script.CoinsDisplayTemplate:Clone())
        self.gui.Parent = self.parent
    end
    
    self.gui.CoinsLabel.Text = "Coins: " .. reducedState.coins
end

return CoinsDisplay
```
### A LocalScript:
```lua
-- Typically this would be put in a separate module called "actionTypes"
local ADD_COINS = 'ADD_COINS'

-- Typically this would be put in a separate module called "actions"
local function addCoins(amount) 
    return {
        type = ADD_COINS,
        amount = amount,
    }
end

-- Typically this would be put in a separate module called "reducer" or "rootReducer"
local function reducer(action, get, set)
    if action.type == ADD_COINS then
        set(get() + action.amount)
    end
end
local initialState = 0

-- Typically this would be put at the entry point for our code
local Rocrastinate = require(game.ReplicatedStorage.Rocrastinate)
local CoinsDisplay = require(game.ReplicatedStorage.CoinsDisplay)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Create the store
local coinsStore = Rocrastinate.createStore(reducer, initialState)

-- Mount the root component; notice how coinsStore is given as the first argument
CoinsDisplay.new(coinsStore, PlayerGui)

-- Add 1 coin every second
while wait(1) do
    coinsStore.dispatch(addCoins(1))
end
```

This should functoin the same as before, but this time our coins are pulling directly from the store, and listening to action dispatches. We also don't need to store our `CoinsDisplay` instance as a variable in this case, as we don't need it in order to dispatch updates to the store.

In the next tutorial, we will discuss the different kinds of Component classes that can be made with Rocrastinate, and a good way of structuring components to isolate re-usable elements of your application.

---

Next tutorial: [1.4 Component Types](1-4-component-types.md)

Previous tutorial: [1.2 Rocrastinate Store](1-2-rocrastinate-store.md)

[Directory](../README.md#tutorial)