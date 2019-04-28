# 1.3 Component State Reduction

Next tutorial: [1.4 Component Types](1-4-component-types.md)

Previous tutorial: [1.2 Rocrastinate Store](1-2-rocrastinate-store.md)

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

You can observe store changes using the `store.subscribe('path.to.key', callback)` function. Unlike get and set, the key path is denoted using the dot notation. subscribing to the empty string `''` will observe all store changes.

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

---

Next tutorial: [1.4 Component Types](1-4-component-types.md)

Previous tutorial: [1.2 Rocrastinate Store](1-2-rocrastinate-store.md)