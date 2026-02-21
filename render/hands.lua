local M = {}

---@class Hand
---@field dist number
---@field r number
---@field path? string
---@field state? hand_state

---@alias Hands table<string, Hand>

---@class Actor
---@field hands? Hands

local assets = require 'assets'
local math2 = require 'lib.math2'

local draw = love.graphics.draw
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop
local translate = love.graphics.translate
local rotate = love.graphics.rotate
local round = math2.round
local scale = love.graphics.scale

---@enum hand_state
M.STATE = {
    neutral = 1,
    palm = 2,
    point = 3,
}

---@type table<string, love.Image>
local images = {}

---@param path string
---@param state hand_state
local get_objects = lume.memoize(function (path, state)
    local img = love.graphics.newImage(path)
    local state_count = #lume.keys(M.STATE)
    local quad = love.graphics.newQuad((state-1) * (img:getWidth()/state_count), 0, img:getWidth()/state_count, img:getHeight(), img)
    return img, quad
end)

---@param a Actor
M.draw = function (a)
    local hands = a.hands
    if not hands then
        return
    end
    for _, hand in pairs(hands) do
        -- get sprite
        local img, quad = get_objects(hand.path or assets.hand, hand.state)
        push()
        if a.off then
            translate(round(a.off.x), round(a.off.y))
        end
        scale(0.75)
        rotate(hand.r)
        translate(-8, -8) -- offset
        translate(0, hand.dist)
        draw(img, quad)
        pop()
    end
end

return M