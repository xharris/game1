local M = {}

local math2 = require 'lib.math2'

local transform = math2.transform
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle

---@class Hitbox
---@field pos Vector.lua
---@field size Vector.lua
---@field line? {to:Vector.lua, segments:number}
---@field delay number
---@field duration number

---@param hitboxes Hitbox[]
M.create = function (hitboxes)
    
end

---@param a Actor
M.draw = function (a)
    if a.shape then
        set_color(1, 0, 0, 0.7)
        rectangle('fill',
            a.shape.pos.x, a.shape.pos.y,
            a.shape.size.x, a.shape.size.y
        )
    end
end

return M