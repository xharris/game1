local M = {}

local assets = require 'assets'
local mui = require 'lib.mui'

local draw = love.graphics.draw
local rectangle = love.graphics.rectangle
local setColor = love.graphics.setColor
local color = lume.color
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop

---@param path string
local get_objects = lume.memoize(function(path)
    local img = love.graphics.newImage(path)
    img:setWrap("repeat", "repeat")
    local quad = love.graphics.newQuad(0, 0, 1, 1, img)
    return img, quad
end)

---@param a Actor
M.draw = function (a)
    if not a.level_tile or a.level_tile.type == 0 or not a.size then
        return
    end

    local level = game.levels[a.level_tile.level]
    local side_color, img, quad
    -- pick themed image
    if level.theme == 'forest' then
        img, quad = get_objects(assets.grass)
        side_color = mui.GREEN_900
    end
    if side_color then
        -- draw 'side'
        push()
        setColor(color(side_color, 0.8))
        rectangle("fill", 0, a.size.y, a.size.x, 5)
        pop()
    end
    if img then
        -- draw repeating texture
        quad:setViewport(
            a.pos.x, a.pos.y, a.size.x, a.size.y,
            -- *2 makes the image larger
            img:getWidth()*2, img:getHeight()*2
        )
        draw(img, quad)
    end
end

return M