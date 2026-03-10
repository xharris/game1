local M = {}

local math2 = require 'lib.math2'

local xform = love.math.newTransform()
local love_push = lume.fn(love.graphics.push, 'all')
local love_pop = love.graphics.pop
local round = math2.round
local ease = math2.ease
local smooth = lume.smooth
local lerp = lume.lerp
local noise = love.math.noise
local get_time = love.timer.getTime
local curve = math2.curve

---@class Camera
---@field pos Vector.lua
---@field target Vector.lua
---@field zoom number
---@field shake_intensity number [0,1]
---@field shake_falloff number seconds
---@field pos_smooth? number

M.DEFAULT_ID = 'default'

---@type number?
M.position_smoothing = nil

local ids = {}

---@type table<string, Camera>
M.cameras = {}

local get = function (id)
    id = id or M.DEFAULT_ID
    local cam = M.cameras[id]
    if not cam then
        ---@type Camera
        cam = {
            pos = vec2(),
            target = vec2(),
            zoom = 0,
            shake_falloff = 1,
            shake_intensity = 0,
        }
        M.cameras[id] = cam
        table.insert(ids, id)
    end
    return cam
end

---@param id? string
local update_xform = function (id)
    local cam = get(id)
    xform:reset()
    local ww, wh = shove.getViewportDimensions()

    -- move position to target
    local x, y = cam.target.x, cam.target.y
    if cam.pos_smooth then
        x, y = smooth(cam.pos.x, cam.target.x, cam.pos_smooth), smooth(cam.pos.y, cam.target.y, cam.pos_smooth)
    end
    cam.pos:set(x, y)

    -- screen shake
    if cam.shake_intensity > 0 then
        local intensity = math2.curve(game.CURVE.camera_shake_intensity, cam.shake_intensity)
        local range = lerp(1, 3, cam.shake_intensity)
        local t = get_time() * intensity
        local off = vec2(
            range * noise(1, t), --  (noise(1, t) * 2 - 1),
            range * noise(2, t) --  (noise(2, t) * 2 - 1)
        )
        x, y = x + off.x, y + off.y
    end

    -- zoom
    local scale = vec2(1, 1) * curve(game.CURVE.camera_zoom, cam.zoom)

    xform:translate(ww/2, wh/2)
    xform:scale(scale.x, scale.y)
    xform:translate(-x, -y) -- -round(pos.x), -round(pos.y))
end

M.get = get

---@param dt number
M.update = function (dt)
    local cam
    for _, id in pairs(ids) do
        cam = get(id)
        if cam.shake_intensity > 0 then
            cam.shake_intensity = cam.shake_intensity - dt * cam.shake_falloff
        else
            cam.shake_intensity = 0
        end
    end
end

---@param intensity? number [0,1]
---@param falloff? number [0,1]
---@param id? string camera id
M.shake = function (intensity, falloff, id)
    local cam = get(id)
    cam.shake_intensity = curve(game.CURVE.camera_shake_intensity, intensity or 0)
    cam.shake_falloff = curve(game.CURVE.camera_shake_falloff, falloff or 1)
end

---@param id? string
M.push = function(id)
    love_push()
    update_xform(id)
    love.graphics.applyTransform(xform)
end

M.pop = function()
    love_pop()
end

---@param x number
---@param y number
---@param id? string
M.to_world = function(x, y, id)
    update_xform(id)
    return xform:inverseTransformPoint(x, y)
end

---@param x number
---@param y number
---@param id? string
M.to_screen = function(x, y, id)
    update_xform(id)
    return xform:transformPoint(x, y)
end

---@param id? string
M.get_bbox = function (id)
    update_xform(id)
    local ww, wh = shove.getViewportDimensions()
    local l, t = M.to_world(0, 0)
    local r, b = M.to_world(ww, wh)
    return l, t, r, b
end

---@param x number
---@param y number
---@param id? string
M.is_visible = function(x, y, id)
    update_xform(id)
    local ww, wh = love.graphics.getDimensions()
    local l, t = M.to_world(0, 0)
    local r, b = M.to_world(ww, wh)
    return x >= l and x <= r and y >= t and y <= b
end

return M