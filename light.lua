local M = {}

local bump = require 'lib.bump'

---@class LightSource
---@field radius number

local stencil = love.graphics.stencil
local circle = love.graphics.circle
local setStencilTest = love.graphics.setStencilTest
local rectangle = love.graphics.rectangle
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop
local origin = love.graphics.origin

local bump_world = bump.newWorld()

---@type table<any, LightSource>
local sources = {}

---@param item any
---@param source LightSource
M.add_light = function (item, source)
    if not bump_world:hasItem(item) then
        bump_world:add(item, 0, 0, 1, 1)
    end
    sources[item] = source
    return sources
end

M.update_light = M.add_light

---@param item any
M.remove_light = function (item)
    bump_world:remove(item)
    sources[item] = nil
end

---@param item any
---@param x number
---@param y number
M.move_light = function (item, x, y)
    bump_world:update(item, x, y)
end

local canvas

M.draw = function ()  -- opacity: 0=no darkness, 1=full darkness
    if not canvas then
        canvas = love.graphics.newCanvas()
    end
    local opacity = 1
    local w, h = love.graphics.getDimensions()

    canvas:renderTo(function ()
        -- draw darkness as rectangle
        push()
        origin()
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0, 0, 0, opacity)
        rectangle("fill", 0, 0, w, h)
        pop()
        local items = bump_world:getItems()
        love.graphics.setBlendMode("replace")
        for _, item in pairs(items) do
            local source = sources[item]
            local x, y = bump_world:getRect(item)
            push()
            -- light: cut hole in darkness
            love.graphics.setColor(0, 0, 0, 0.5)
            circle("fill", x, y, source.radius)
            love.graphics.setColor(0, 0, 0, 0)
            circle("fill", x, y, source.radius - 10)
            pop()
        end
        love.graphics.setBlendMode("alpha")
    end)

    push()
    origin()
    love.graphics.draw(canvas)
    pop()
end

return M