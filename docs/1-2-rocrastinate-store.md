# 1.2 Rocrastinate Store

Next tutorial: [1.3 Component State Reduction](1-3-component-state-reduction.md)

Previous tutorial: [1.1 Introduction](1-1-introduction.md)

[Directory](../README.md#tutorial)

## Redux Similarities and Differences

Rocrastinate's store is inspired by [Redux](https://redux.js.org/basics/basic-tutorial), a state management library that is often used in JavaScript web applications. If you are unfamiliar with how Redux works, I would recommend reading and/or following the Redux tutorial before moving on, although I will attempt to explain how Rocrastinate's store functions here.

Like Redux, the Rocrastinate Store is where you can centralize the state of your UI application, and it uses "Actions" to update the application state, and "Reducers" to control how the state changes with a given action.

Rocrastinate's Store is NOT equivalent to Redux or [Rodux](https://github.com/Roblox/rodux) (the Roblox port). Some differences are as follows:
 * Rocrastinate's store is coupled with Rocrastinate components (this will be explained later on in the tutorial).
 * Rocrastinate stores must be passed as the first argument in the constructors of components that use Store objects. This means that the "store" a component is in is not determined by context, but by explicit argument.
 * Redux reduces actions by re-creating the entire application state. For the sake of optimization and because of the coupling of Rocrastinate Components with Store, Rocrastinate Store reducers are passed the functions `get` and `set`, which copy/mutate the application's state respectively.
 * With React/Redux (or Roact/Rodux), changes to the store will immediately re-render a component. With Rocrastinate Components, subscribed changes only call `queueUpdate()`, which defers rendering changes to the next frame binding. 

## Actions

"Actions" are the *only* source of information for your Rocrastinate Store. They represent information needed to change some portion of the application state, and are represented as lua objects. They are sent using `store.dispatch()`.

Actions should typically be represented as tables, and habe a `type` property denoting what kind of action is being sent. Example:

```lua
local myAction = {
    type = 'ADD_COINS',
    amount = 1,
}

store.dispatch(myAction)
```

## Action Creators

Typically, instead of creating actions directly, you can use "Action Creators", which are simply functions that create actions with a given set of arguments. These simply **create the action**, and **do not dispatch them**:
```lua
local function addCoins(amount)
    return {
        type = 'ADD_COINS',
        amount = amount,
    }
end

store.dispatch(addCoins(1))
```

Actions can be dispatched from anywhere in the application, including the middle of a Redraw()

## Responding to Actions

Like Redux, Rocrastinate uses "Reducers", which are functions that respond to an action by modifying a certain portion of the store's state.

Reducers are given three arguments: `(action, get, set)`.

 * `action` is the action that was dispatched
 * `get(...keypath)` is a function that gets a value in the store by name
 * `set(...keypath, value)` is a function that sets a value in the store by name.

If we want to set the value of `'coins'` in the store whenever an 'ADD_COINS' action is received, we can use the following code:

```lua
local function reducer(action, get, set)
    if action.type == 'ADD_COINS' then
        local coins = get('coins')
        set('coins', coins + action.amount)
    end
end
```

This code makes a few assumptions:

1. There is already a value in the store named 'coins', and that it is a number
2. That the action has a property named 'type'
3. That the action (which we've identified as an 'ADD_COINS' action) has a property named 'amount', and that it is a number.

It is generally best to centralize actions or action creators in an `actions` module, so that these assumptions can be standardized. Additionally, we need to declare the initial state of our store somewhere:

```lua
local initialState = {
    coins = 0,
}
```

Then, when we call

```lua

store.dispatch(addCoins(1))
```
our store should conceptually look something like this table:

```lua
{
    coins = 1,
}
```

Additionally, we can nest tables in our store structure:

```lua
local initialState = {
    playerStats = {
        coins = 0,
    }
}
local function reducer(action, get, set)
    if action.type == 'ADD_COINS' then
        local coins = get('playerStats', 'coins')
        set('playerStats', 'coins', coins + action.amount)
    end
end
```

In the above example, we provide an aditional argument to `get` and `set`. These are just strings representing the key path to the exact value we want to set in our store.

If we kept this all in the same module, we may run into a problem when our tree becomes more complex:
```lua
local function reducer(action, get, set)
    if action.type == 'DO_SOMETHING_IN_A_SPECIFIC_DOMAIN' then
        set('path', 'to', 'specific', 'domain', value)
    elseif  . . .  then
        . . .
    end
end
```
This can become very verbose. What if we wanted to create a reducer that just deals with playerStats, and another reducer that just deals with some other domain?

To do this, you can use the `combineReducers()` function. Let's say we put our main reducer in a module called "rootReducer", and nested reducers for playerStats underneath the root reducer:

### rootReducer ModuleScript
```lua
local Rocrastinate = require(game.ReplicatedStorage.Rocrastinate)
local playerStats = require(script.playerStats)

local reducer = Rocrastinate.combineReducers({
    playerStats = playerStats.reducer,
})

local initialStats = {
    playerStats = playerStats.initialState,
}

return {
    reducer = reducer,
    initialState = initialState,
}
```
### rootReducer.playerStats ModuleScript
```lua
local function reducer(action, get, set)
    if action.type == 'ADD_COINS' then
        local coins = get('coins')
        set('coins', coins + action.amount)
    end
end
local initialState = {
    coins = 0,
}
return {
    reducer = reducer,
    initialState = initialState,
}
```

If we wanted to, we could subdivide this even further by making a reducer for coins, and use `combineReducers()` in the playerStates module instead. The "coins" module would then look something like this:
### rootReducer.playerStats.coins ModuleScript
```lua
local function reducer(action, get, set)
    if action.type == 'ADD_COINS' then
        set(get() + action.amount)
    end
end
local initialState = 0

return {
    reducer = reducer,
    initialState = initialState,
}
```

Now that we've separated the concerns of our reducers and actions, how do we actually create the store and have it interact with our application?

Rocrastinate uses the function `createStore(reducer, initialState)`
Putting it all together, here is a very simple store reduces a single value of "coins"

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
local coinsStore = Rocrastinate.createStore(reducer, initialState)

print(coinsStore.getState()) -- 0

coinsStore.dispatch(addCoins(10))
print(coinsStore.getState()) -- 10

coinsStore.dispatch(addCoins(10))
print(coinsStore.getState()) -- 20
```

In the next tutorial, we'll learn how to propogate changes in the Rocrastinate store to queue a redraw in our components, as well as how to display data pulled directly from the store.

---

Next tutorial: [1.3 Component State Reduction](1-3-component-state-reduction.md)

Previous tutorial: [1.1 Introduction](1-1-introduction.md)

[Directory](../README.md#tutorial)
