
# Introduction

## Motivation
Roblox UI is not always easy to standardize. Making UI code that is simultaneously re-usable, decoupled, and well-performing on Roblox is ideal, but having all of these things at the same time can be challenging.

Frameworks such as [Roact](https://github.com/Roblox/roact) by LPGhatguy (generally accompanied with [Rodux](https://github.com/Roblox/rodux)) have been created to parallel Facebook's [React](https://github.com/facebook/react) framework (generally accompanied with [Redux](https://redux.js.org/)).

These frameworks offer a declarative approach to UI by instantly rendering accurate information to the user, as well as managing state so that the data displayed to the user derives from a single source of truth. This allows UI to be made that is responsive, re-usable, and accurate at all times.

While these frameworks do their job well, Roact/Rodux has some particular disadvantages in the context of Roblox development:
- Roact abstracts away important UI features, such as Tweening, or reading properties from rendered objects. This can get pretty hairy try doing certain simple things that are otherwise simple to do without Roact.
- Roact does not allow you to design UI templates; all UI must be created by script. While I wrote a script to somewhat [automate this](https://pastebin.com/jW4k4Ze7) for roblox-ts, if you have non-programmer UI designers on your team, this barrier can become overly complex to deal with.
- Rodux reconstructs the entire store for every action that is dispatched. Lua tables are significantly slower to deal with than JavaScript objects.
- Roact requires you to declaratively re-state every single property on every single rendered GUI object every time a component is updated. This can have negative performance implications, especially on UI that updates many times per frame.
- Roact creates and destroys instances rapidly. There is no room for optimizations such as object pooling, which should otherwise be simple to implement outside of Roact.
- Unless paired with [roblox-ts](https://roblox-ts.github.io/), the syntax for declaring Roact components can be rather verbose, whereas facebook's React uses JSX (an HTML-like syntax that makes things a lot more readable)


# Features of Rocrastinate
Rocrastinate offers similar benifits to Roact and Rodux, while still giving the developer a large amount of control over when and how UI is redrawn.

One of the main optimizations of Rocrastinate is that UI Components are only ever updated once per frame at most. This allows complex display updates to be deferred whenever a portion of your application's state changes, as each component will only be re-drawn as much as it needs to be redrawn.

## Components

Components are classes that can be created using
```lua
local myComponentObject = MyComponent.new(...)
```
and destroyed using
```lua
myComponentObject:Destroy()
```

To make a Component class, you can use the following API
```lua
local Rocrastinate = require(location.of.Rocrastinate)
local MyComponent = Rocrastinate.Component:extend()
```

When a new Component object is created using `MyComponent.new()`, the `constructor` is called with the same arguments passed through `new`. Here is a simple printer component:

```lua
local Printer = Rocrastinate.Component:extend()

function Printer:constructor(message)
    self.message = message
end

function Printer:Print()
    print(self.message)
end

local myPrinter = Printer.new("Hello, World!")
myPrinter:Print() -- Hello, World!
```

### Drawing UI Components

Rocrastinate gives you total control over what a component does when it is constructed. You can create as many Gui objects as you like, and update them however you like.

The information you actually display to the user can be controlled using the Component class' `:Redraw()` method. **You should not call :Redraw() directly**, as this is automatically called on RunService.RenderStep or RunService.Heartbeat depending how your Component class is set up.

To queue a redraw on the next frame, use `self.queueRedraw()` instead. This is an anonymous, idempotent function that tells Rocrastinate to call `:Redraw()` automatically on the next RenderStep or Heartbeat.

You can control whether `:Redraw()` is called on RenderStep or Heartbeat using the `RedrawBinding` variable.

```lua
local Rocrastinate = require(game.ReplicatedStorage.Rocrastinate)
local CoinsDisplay = Rocrastinate.Component:extend()

function CoinsDisplay:constructor()
    self.coins = 0

    self.gui = Instance.new("ScreenGui")
    self.coinsLabel = Instance.new("TextLabel", self.gui)
    self.coinsLabel.Size = UDim2.new(0, 100, 0, 100)

    -- See below
    self.maid:GiveTask(
        self.gui,
        self.coinsLabel
    )

    self.gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

function CoinsDisplay:AddCoin()
    self.coins = self.coins + 1

    self.queueRedraw()
end

CoinsDisplay.RedrawBinding = "Heartbeat"
function CoinsDisplay:Redraw()
    self.coinsLabel.Text = self.coins
end

local myCoinsDisplay = CoinsDisplay.new()
while wait(1) do
    myCoinsDisplay:AddCoin()
end

```
![example](introduction_coins_example.mp4)