--- Create hitboxes in a pattern
local M = {}

local math2 = require 'lib.math2'
local tick = require 'lib.tick'

local transform = math2.transform
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle
local lerp = lume.lerp

---@class Hitbox
---@field pos Vector.lua
---@field vel? Vector.lua
---@field size Vector.lua
---@field line? {to:Vector.lua, segments:number}

---@param h Hitbox
---@return Actor[]
M.create = function(h)
    ---@type Actor[]
    local actors = {}
    local segments = h.line and h.line.segments or 1
    local to = h.line and h.line.to or h.pos

    for i = 1, segments do
        local pos = vec2(
            lerp(h.pos.x, to.x, i / segments),
            lerp(h.pos.y, to.y, i / segments)
        )
        lume.push(actors, {
            pos = pos,
            vel = h.vel and h.vel:clone() or nil,
            shape = {
                tag = 'hit',
                pos = vec2(0, 0), -- -h.size/2,
                size = h.size/2,
            }
        } --[[@as Actor]])
    end
    
    return actors
end

---@param a Actor
M.draw = function (a)
    if a.shape and a.shape.debug then
        set_color(1, 0, 0, 0.7)
        rectangle('fill',
            a.shape.pos.x, a.shape.pos.y,
            a.shape.size.x, a.shape.size.y
        )
    end
end

return M