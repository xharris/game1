local M = {}

local assets = require 'assets'
local mui = require 'lib.mui'

local draw = love.graphics.draw
local rectangle = love.graphics.rectangle
local setColor = love.graphics.setColor
local color = lume.color
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop
local abs = math.abs
local lerp = lume.lerp
local min = math.min
local max = math.max

---@param path string
local get_objects = lume.memoize(function(path)
    local img = love.graphics.newImage(path)
    img:setWrap("repeat", "repeat")
    local quad = love.graphics.newQuad(0, 0, 1, 1, img)
    return img, quad
end)

---@param dt number
---@param a Actor
---@param players Actor[]
M.update = function (dt, a, players)
    if not a.alt then
        return
    end
    local alpha = 0
    local min_dist = game.LEVEL_ALT / 2
    for _, p in ipairs(players) do
        if p.alt then
            local dist = a.alt - p.alt
            if dist == 0 then
                alpha = max(alpha, 1)
            elseif dist < 0 and abs(dist) <= min_dist then
                alpha = max(alpha, lerp(1, 0.5, abs(dist) / min_dist))
            elseif dist < 0 then
                alpha = max(alpha, 0.5)
            end
        end
    end
    a.alpha = alpha
end

---@param a Actor
M.draw = function (a)
    if not a.level_cell or a.level_cell.type == 0 or not a.size then
        return
    end

    local level = game.levels[a.level_cell.level]
    local side_color, img, quad
    -- pick themed image
    if level.theme == 'forest' then
        img, quad = get_objects(assets.grass)
        side_color = mui.GREEN_900
    end
    if side_color then
        -- draw 'side'
        push()
        setColor(color(side_color, a.alpha or 1))
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