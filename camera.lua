local M = {}

local math2 = require 'lib.math2'

local xform = love.math.newTransform()
local love_push = lume.fn(love.graphics.push, 'all')
local love_pop = love.graphics.pop
local round = math2.round
local ease = math2.ease
local smooth = lume.smooth

M.DEFAULT_ID = 'default'

---@type number?
M.position_smoothing = nil

---@type table<string, Vector.lua>
M.pos = {}

---@type table<string, Vector.lua>
M.scale = {}

---@param id? string
local update_xform = function (id)
    id = id or M.DEFAULT_ID
    if not M.pos[id] then
        M.pos[id] = vec2()
    end
    xform:reset()
    local ww, wh = shove.getViewportDimensions()

    local pos = M.pos[id]
    if not M.pos[id] then
        M.pos[id] = vec2()
        pos = M.pos[id]
    end
    local scale = M.scale[id]
    if not M.scale[id] then
        M.scale[id] = vec2()
        scale = M.scale[id]
    end

    xform:translate(ww/2, wh/2)
    xform:scale(scale.x, scale.y)
    xform:translate(-pos.x, -pos.y)---round(pos.x), -round(pos.y))
end

---@param x number
---@param y number
---@param id? string
M.set_pos = function (x, y, id)
    id = id or M.DEFAULT_ID
    local pos = M.pos[id]
    if not pos then
        pos = vec2()
    end
    if M.position_smoothing then
        x, y = smooth(pos.x, x, M.position_smoothing), smooth(pos.y, y, M.position_smoothing)
    end
    pos:set(x, y)
    M.pos[id] = pos
end

---@param x number
---@param y? number
---@param id? string
M.set_scale = function (x, y, id)
    y = y or x
    id = id or M.DEFAULT_ID
    if not M.scale[id] then
        M.scale[id] = vec2()
    end
    M.scale[id]:set(x, y)
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