---@class Transform
---@field ox? number
---@field oy? number
---@field r? number
---@field sx? number
---@field sy? number
---@field kx? number
---@field ky? number

local M = {}

local weakkeytable = require 'lib.weakkeytable'

local floor = math.floor
local abs = math.abs
local lerp = lume.lerp

---@type Transform
M.default_xform = {r=0, ox=0, oy=0, sx=0, sy=0, kx=0, ky=0}

---Get position from direction and distance
---@param r? number
---@param dist? number
M.move_direction = function (r, dist)
    dist = dist or 0
    r = r or 0
    -- use sin/cos so that 0 radians == down (0,1)
    return math.sin(r) * dist, math.cos(r) * dist
end

---@type table<Actor, love.Transform>
local transforms = weakkeytable()

---@param a Actor
local get_transform = function (a)
    local xform = transforms[a]
    if not xform then
        xform = love.math.newTransform()
        transforms[a] = xform
    end
    xform:reset()
    if a.pos then
        xform:translate(a.pos.x, a.pos.y)
    end
    if a.scale then
        xform:scale(a.scale.x, a.scale.y)
    end
    if a.sprite then
        xform:rotate(a.sprite.r or 0)
        if a.sprite.off then
            xform:translate(-a.sprite.off.x, -a.sprite.off.y)
        end
    end 
    return xform
end

M.get_transform = get_transform

---@param x number
local round = function (x)
    return floor(x + 0.5)
end

M.round = round

---@param x number
---@param y number
---@param grid_width number
M.array2d_to_array1d = function (x, y, grid_width)
    return (y * grid_width + x) + 1
end

---@param idx number
---@param grid_width number
M.array1d_to_array2d = function (idx, grid_width)
    local i = idx - 1      -- undo +1
    local x = i % grid_width
    local y = math.floor(i / grid_width)
    return x, y
end


local pow = math.pow

-- Godot ease()
-- https://byteatatime.dev/posts/easings/
--
-- NATURAL `[-2, -5]` _(jumping, ui)_ </br>
-- DECEL `[0.2, 0.5]` _(landing, falling with resistance)_ </br>
-- ACCEL `[2, 4]` _(charge, takeoff)_ </br>
-- BULLET TIME `[-0.3, -0.8]` _(special effects)_
--
-- 0=0, 1=no ease
M.ease = function(x, c)
    if x < 0 then
        x = 0
    elseif x > 1.0 then
        x = 1.0
    end
    if c > 0 then
        if c < 1.0 then
            return 1.0 - pow(1.0 - x, 1.0 / c)
        else
            return pow(x, c)
        end
    elseif c < 0 then
        -- inout ease
        if (x < 0.5) then
            return pow(x * 2.0, -c) * 0.5
        else
            return (1.0 - pow(1.0 - (x - 0.5) * 2.0, -c)) * 0.5 + 0.5
        end
    else
        return 0 -- no ease (raw)
    end
end

M.EASE_IN = 0.2
M.EASE_OUT = 2.4
M.EASE_IN_OUT = -3.4

---@param vel Vector.lua current velocity
---@param move Vector.lua
---@param max_speed number
---@param mass number
---@return Vector.lua velocity
M.steer = function(vel, move, max_speed, mass, dt)
    local scaled = move:norm() * max_speed
    local steer = (scaled - vel) * math.min(dt * mass, 1)
    return vel + steer
end

---numbers are equal approx
---@param a number
---@param b number
---@param epsilon? number
M.eq = function (a, b, epsilon)
    epsilon = epsilon or 0.01
    return abs(a - b) < 0.01
end

local scale = love.graphics.scale
local rotate = love.graphics.rotate
local translate = love.graphics.translate
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop

---@param x number
---@param y number
---@param r number
---@param sx number
---@param sy number
---@param ox number
---@param oy number
M.transform = function (x, y, r, sx, sy, ox, oy)
    push()
    translate(x, y)
    scale(sx, sy)
    rotate(r)
    translate(-ox, -oy)
    return pop
end

---@param value number
---@param min number
---@param max number
M.wrap = function(value, min, max)
    local range = max - min
    return ((value - min) % range) + min
end

---Asymptotic Average
---@param x number
---@param target number
---@param blend? number [0, 1] default: `0.9`
M.blend = function (x, target, blend)
    blend = blend or 0.1
    return x + (target - x) * blend
end

---@class Curve
---@field min number
---@field max number

---@param c Curve
---@param amt number [0,1]
---@return number
M.curve = function (c, amt)
    return lerp(c.min, c.max, amt)
end

return M