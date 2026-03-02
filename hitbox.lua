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
---@field single? boolean
---@field line? {to:Vector.lua, segments:number}
---@field radial? {from_angle:number, to_angle:number, r:number, segments:number}
---@field each? fun(h:Actor)

---@param h Hitbox
---@return Actor[]
M.create = function(h)
    ---@type Actor[]
    local actors = {}
    local to = h.line and h.line.to or h.pos

    ---@type Vector.lua[]
    local positions = {}

    -- create hitboxes...
    if h.single then
        -- at a single point
        lume.push(positions, h.pos)
    end
    if h.radial then
        -- in a circle
        local segments = h.radial.segments
        for i = 0, segments-1 do
            local angle = lerp(h.radial.from_angle, h.radial.to_angle, i / segments)
            local radial_pos = vec2.fromAngle(angle) * h.radial.r
            lume.push(positions, h.pos + radial_pos)
        end
    end
    if h.line then
        -- in a line
        local segments = h.line.segments
        for i = 0, segments-1 do
            lume.push(positions, vec2(
                lerp(h.pos.x, to.x, i / segments),
                lerp(h.pos.y, to.y, i / segments)
            ))
        end
    else
        lume.push(positions, h.pos:clone())
    end

    for _, pos in ipairs(positions) do
        ---@type Actor
        local a = {
            pos = pos - (h.size/2),
            vel = h.vel and h.vel:clone() or nil,
            shape = {
                tag = 'hit',
                pos = vec2(0, 0), -- -h.size/2,
                size = h.size/2,
            }
        }
        lume.push(actors, a)
        if h.each then
            h.each(a)
        end
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