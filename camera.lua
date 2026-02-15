local M = {}

local xform = love.math.newTransform()
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop

M.DEFAULT_ID = 'default'

---@type table<string, Vector.lua>
M.pos = {}

---@param id? string
local update_xform = function (id)
    id = id or M.DEFAULT_ID
    if not M.pos[id] then
        M.pos[id] = vec2()
    end
    xform:reset()
    local ww, wh = love.graphics.getDimensions()
    if not M.pos[id] then
        M.pos[id] = vec2()
    end
    local pos = M.pos[id]
    xform:translate(-pos.x + (ww/2), -pos.y + (wh/2))
end

---@param x number
---@param y number
---@param id? string
M.set = function (x, y, id)
    id = id or M.DEFAULT_ID
    if not M.pos[id] then
        M.pos[id] = vec2()
    end
    M.pos[id]:set(x, y)
end

---@param id? string
M.push = function(id)
    push()
    update_xform(id)
    love.graphics.applyTransform(xform)
end

M.pop = function()
    pop()
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