
# 2.1 Middlewares

Next tutorial: [](1-.md)

Previous tutorial: [1.6 Usage Examples](1-6-usage-examples.md)

[Directory](../README.md#tutorial)

## Enhancing the store

Middlewares are a [common way to enhance stores in Redux applications](https://www.codementor.io/vkarpov/beginner-s-guide-to-redux-middleware-du107uyud). Up until this point, the actions we've created are fairly dumb—all they can really do is get and set data. What if we want our dispatched actions to do more complex things like request data from the server?

Rocrastinate supports middlewares, which are simply functions that intercept actions upon being dispatched, and allow custom logic to be applied to them. The way middlewares intercept actions is by providing a bridge in between `store.dispatch` being called and the root reducer receiving those actions that were dispatched.

Middlewares take the form of three nested functions:
```lua
local middleware = function(store)
    return function(nextDispatch)
        return function(action)
            . . .
        end
    end
end
```
The first function takes in the current store that the middleware is being used on. We can call normal store functions on this object such as `setState`, `getState`, `dispatch`, and `subscribe`.

The second nested function takes in `nextDispatch`. In a store with a single middleware applied, calling `nextDispatch(action)` will forward the the action directly to the store's reducer.

The third nested function is the actual function that decides what to do with actions when they are dispatched. To keep the actions moving through to the reducer without consuming it, you can call `nextDispatch(action)`.

```lua
local redundantMiddleware = function(store)
    return function(nextDispatch)
        return function(action)
            nextDispatch(action)
        end
    end
end

. . .

store.applyMiddleware(redundantMiddleware)
```
In the above code, `redundantMiddleware` is a middleware that listens to actions when `store.dispatch` is called, and immediately forwards them to the store's reducer with no side effects.

Let's look at the source code of LoggerMiddleware, one of the middlewares bundled with Rocrastinate:

```lua
local function LoggerMiddleware(store)
    return function(nextDispatch)
        return function(action)
            print(action.type)
            nextDispatch(action)
        end
    end
end

return LoggerMiddleware
```

This middleware is nearly equivalent to our `redundantMiddleware`, with the one difference that the type of the action being dispatched is printed to the output console.

In effect, this will "log" every action that is dispatached in our store. This can be useful for debugging actions that are dispatched through our application:

```lua
local DEBUGGING_ENABLED = true

local rootReducer, initialState = . . .

local myStore = Rocrastinate.createStore(rootReducer, initialState)

if DEBUGGING_ENABLED then
    myStore.applyMiddleware(Rocrastinate.LoggerMiddleware)
end
```

Rocrastinate offers a few built-in middlewares:

* `Rocrastinate.LoggerMiddleware` - Prints out the action types of every action dispatched
* `Rocrastinate.InspectorMiddleware` - Prints out the whole action being dispatched
    Note: this is created through `Rocrastinate.InspectorMiddleware.createInspectorMiddleware(maxDepth)`
* `Rocrastinate.ThunkMiddleware` - Like its Redux counterpary, thunk middleware allows functions to be dispatched as regular actions. When a function is encountered by the middleware in place of an action, that function will be intercepted and called with the arguments `myThunk(dispatch, getState)`
* `Rocrastinate.SpunkMiddleware` - Like ThunkMiddleware, allows functions to be dispatched. The only difference is that the functions being dispatched will be spawned immediately in a separate thread. This could be more ideal for roblox development as opposed to JavaScript do to the lack of Promise objects.

A usage example for SpunkMiddleware would be an action that needs to fetch data from the server:

### Entry point:
```lua
local store = Rocrastinate.createStore(rootReducer, initialState)
store.applyMiddleware(Rocrastinate.SpunkMiddleware)
```
### Actions module:
```lua
local actions = {}

function actions.fetchCoins()
    return function(dispatch, getState) -- Where we would normally return an action here,
                                        -- we instead return a spawned thunk that defers
                                        -- our change in state
        local coins = game.ReplicatedStorage.SomeRemoteFunction:InvokeServer()
        dispatch({
            type = 'SET_COINS',
            payload = coins,
        })
    end
end

return actions
```

### Some component in our application:
```lua
self.maid:GiveTask(
    self.gui.FetchCoinsButton.MouseButton1Click:Connect(function()
        self.store.dispatch(actions.fetchCoins())
    end)
end)
```

Your use case for middlewares may vary. You might not need it at all for your application; alternatively, you may find a need to write your own middlewares for debugging or managing state. Middleware-facilitated operations such as thunks are generally the best place to put logic that affect state after yielding calls, such as when retrieving data from the server.

The examples on the [previous page](1-6-usage-examples.md) make use of a few middlewares to handle more complex logic, such as linking the "width", "height", and "aspect ratio" values together in the Icon Creator plugin.

---

Next tutorial: [](1-.md)

Previous tutorial: [1.6 Usage Examples](1-6-usage-examples.md)

[Directory](../README.md#tutorial)