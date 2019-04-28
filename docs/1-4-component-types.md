# 1.4 Component Types

Next tutorial: [1.5 Maid Revisited](1-5-maid-revisited.md)

Previous tutorial: [1.3 Component State Reduction](1-3-component-state-reduction.md)

[Directory](../README.md#tutorial)

## Component Re-usability

In the last tutorial, we built a CoinsDisplay component that listens to a portion of the state of our store and displays it to the user.

Now comes the big question: Did we improve our `CoinsDisplay` by tying it into the store, or did we just make the code more complex than it needs to be?

Let's compare the two:

--- 
## CoinsDisplay from [1.1](1-1-introduction.md#final-code)

* CoinsDisplay module is slightly longer, but the code that utilizes our component is quite short compared to the module that used the Rocrastinate Store:
```lua
local CoinsDisplay = require(game.ReplicatedStorage.CoinsDisplay)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Add 1 coin every second
local myCoinsDisplay = CoinsDisplay.new(PlayerGui)
while wait(1) do
    myCoinsDisplay:AddCoin()
end
```
* We only need to pass in the parent argument (`PlayerGui`) on order to construct our CoinsDisplay component
* We need to manually keep track of our CoinsDisplay component and call :AddCoin() to update the CoinsDisplay object's state

---
## CoinsDisplay from [1.3](1-3-component-state-reduction.md#final-code)
* CoinsDisplay module is slightly shorder, but the code that utilizes our component is quite long. While most of this should be split into separate modules, here is our main entry point code:
```lua
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
* We need to pass in both the Store argument (`coinsStore`) and the parent argument (`PlayerGui`) to construct our CoinsDisplay component.
* We do not need to track our CoinsDisplay component (unless we want to destroy it later on), and the store subscription model takes care of our Coins state for us. All we need to do is give the store a set of actions, and Rocrastinate takes care of updating the display of our 'CoinsDisplay' component in particular.

---

So which one is better? Well, it largely depends on the context in which we're using the component, and how much we need to re-use the logic of the component.

If we are just displaying the User's coins, the second option (store-dependent) may be preferable, especially since the Rocrastinate Store helps maintain a single source of truth over what the user's coins are (we wouldn't want the CoinsDisplay in one menu to show a different result from the CoinsDisplay in another menu, and we also don't want to juggle this state around by having to update every single CoinsDisplay component with the accurate information).

On the other hand, let's say we were making a game like [Settlers of Catan](https://www.catan.com/), in which players have five different "currency" resources (Wood, Sheep, Bricks, Wheat, and Ore).

We may not want to share the logic of displaying "Coins" to the user in this case, but we might want to share the logic of displaying a "Currency" to the user in general. In this case, the first option (store-independent) may be preferrable. Keep in mind, however, that we might still want a component type (store-dependent) that observes the value of each resource in the store, and *then* propogates that value to the CurrencyDisplay component using `:SetValue()`. This would likely be called during the `:Redraw()` portion of our store-dependent component.

## Presentational components

The first example highlights what can be called a "Presentational" component. These components are typically standalone, and can be re-used in multiple places as well as across multiple application contexts. They do not take in a store as their first argument when constructed, or have a defined `Reduction` property.

## Container components

The second example highlights what can be called a "Container" component. These components are less re-usable across applications, although they can be re-used within the same application in some instances. They must take in a store as their first argument when constructed, and usually have a `Reduction` property that is defined.

In real-world React/Redux applications, you typically get a project structure that separates components into two folders: one for for "containers" (i.e. Container components), and one for "components" (i.e. Presentational Components). This separation is made easier with Rocrastinate because of the required 'store' argument for containers.

## Decorator components

Decorator components are another type of component somewhat unique to Rocrastinate, but similar in function to [Higher-Order Components](https://reactjs.org/docs/higher-order-components.html) in React. Instead of creating new GUI elements from a template, Decorator components are typically constructed with another GuiObject as the first parameters.

Examples would include components whose is roughly equivalent to their function, such as `Draggable`, or `AutoResizeAroundChildren`.

Example - Decorating a GuiObject with a `Draggable` component:
```lua
local myLabel = Instance.new("TextLabel")
Draggable.new(myLabel) -- Makes the label draggable

 . . .
```

As you can see, `Draggable` does not create any new UI instances of its own, but rather wraps, or "decorates" an existing UI element. This is a powerful way to [compose](https://en.wikipedia.org/wiki/Composition_over_inheritance) functionality of UI elements, and make component logic re-usable.

Decorator components generally do not have access to state, although container decorators are possible; However, Container decorators are generally less re-usable across different applications, and are coupled to the store of the application they're used in.

## Props

Often times, you will want to pass extra properties onto a component when it is constructed. A good example of this would be callbacks: A 'Draggable' decorator may optionally let you provide a function that gets called whenever the element is dragged.

```lua
Draggable.new(myLabel, { onDrag = function(dx, dy) print("Moved label by", dx, dy) end })
```

This second argument is the "props" argument, which is a table of extra properties given to the "Draggable" component.

It may be helpful to introduce some element of [type safety](https://en.wikipedia.org/wiki/Type_safety) into your props in order to make it very clear what your component does and does not accept as an argument. A good library for dynamic type safety is Osyris's [t library](https://github.com/osyrisrblx/t).

```lua
local t = require(game.ReplicatedStorage.t)
local IProps = t.strictInterface {
    onDrag = t.callback,
}
function Draggable:constructor(wrapped, props)
    -- Check prop types
    assert(IProps(props))
    . . .
end
```
[Roblox-ts](roblox-ts.github.io) also provides static type safety in this scenario; however, this assumes you want your entire codebase to be written in TypeScript

It should be noted that "props" in this case means something different from "props" in Roact/React. "props" are properties defined upon constructing Components, but these values can also be changed using Getter/Setter methods if defined.  In React terms, 'props' and 'state' are conflated here.

## Common signatures

The following constructor arguments may be useful for structuring your components, as well as differentiating the different types of components:

### Container Component constructor signature

```lua
function MyContainer:constructor(store, parent, [props])
```
### Presentational Component constructor signature

```lua
function MyComponent:constructor(parent, [props])
```

### Decorator Component constructor signature

```lua
function MyDecorator:constructor(wrapped, [props])
```

In the next tutorial, we'll revisit the Maid concept that was mentioned in a previous tutorial, but not explained in depth

---

Next tutorial: [1.5 Maid Revisited](1-5-maid-revisited.md)

Previous tutorial: [1.3 Component State Reduction](1-3-component-state-reduction.md)

[Directory](../README.md#tutorial)