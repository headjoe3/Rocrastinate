local Rocrastinate = {}

Rocrastinate.createStore = require(script.createStore)
Rocrastinate.combineReducers = require(script.combineReducers)

Rocrastinate.Component = require(script.Component)
Rocrastinate.LoggerMiddleware = require(script.Middlewares.LoggerMiddleware)
Rocrastinate.InspectorMiddleware = require(script.Middlewares.InspectorMiddleware)
Rocrastinate.ThunkMiddleware = require(script.Middlewares.ThunkMiddleware)
Rocrastinate.SpunkMiddleware = require(script.Middlewares.SpunkMiddleware)

return Rocrastinate