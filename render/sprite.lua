local M = {}

---@class Sprite
---@field path string
---@field frames Vector.lua
---@field frame number

---@class Actor
---@field sprite? Sprite

local assets = require 'assets'

local draw = love.graphics.draw
local sign = lume.sign
local abs = math.abs

---@param path string
---@param frames_x number
---@param frames_y number
local get_objects = lume.memoize(function(path, frames_x, frames_y)
    local img = love.graphics.newImage(path)
    local quad = love.graphics.newQuad(0, 0, img:getWidth()/frames_x, img:getHeight()/frames_y, img)
    return img, quad
end)

---@param a Actor
M.draw = function (a)
    if not a.sprite then
        return
    end
    local img, quad = get_objects(a.sprite.path, a.sprite.frames.x, a.sprite.frames.y)
    if a.aim_dir and a.scale then
        a.scale.x = sign(a.aim_dir.x) * abs(a.scale.x)
    end
    draw(img, quad)
end

return M