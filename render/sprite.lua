local M = {}

---@class Sprite
---@field path string
---@field frames Vector.lua
---@field frame number
---@field pos? Vector.lua will be relative to actor
---@field r? number
---@field scale? Vector.lua
---@field off? Vector.lua
---@field debug? boolean

---@class Actor
---@field sprite? Sprite

local assets = require 'assets'
local math2 = require 'lib.math2'
local mui = require 'lib.mui'

local draw = love.graphics.draw
local sign = lume.sign
local abs = math.abs
local transform = math2.transform
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle

---@param path string
---@param frames_x number
---@param frames_y number
M.get_objects = lume.memoize(function(path, frames_x, frames_y)
    local img = love.graphics.newImage(path)
    local quad = love.graphics.newQuad(0, 0, img:getWidth()/frames_x, img:getHeight()/frames_y, img)
    return img, quad
end)

---@param sprite Sprite
M.transform = function (sprite)
    return transform(
        sprite.pos and sprite.pos.x or 0,
        sprite.pos and sprite.pos.y or 0,
        sprite.r and sprite.r or 0,
        sprite.scale and sprite.scale.x or 1,
        sprite.scale and sprite.scale.y or 1,
        sprite.off and sprite.off.x or 0,
        sprite.off and sprite.off.y or 0
    )
end

---@param sprite Sprite
M.draw_sprite = function (sprite)
    local img, quad = M.get_objects(sprite.path, sprite.frames.x, sprite.frames.y)
    local pop = M.transform(sprite)
    draw(img, quad)
    if sprite.debug then
        set_color(lume.color(mui.RED_400))
        local _, _, w, h = quad:getViewport()
        rectangle("line", 0, 0, w, h)
    end
    pop()
end

---@param a Actor
M.draw = function (a)
    if not a.sprite then
        return
    end
    M.draw_sprite(a.sprite)
end

return M