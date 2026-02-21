local M = {}

---@class Hand
---@field dist number
---@field r number 0 is straight down, -left  +right
---@field back boolean
---@field path? string
---@field state? hand_state
---@field item? string

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
local origin = love.graphics.origin

---@enum hand_state
M.STATE = {
    neutral = 1,
    palm = 2,
    point = 3,
}

local state_count = #lume.keys(M.STATE)

---@type table<string, love.Image>
local images = {}

---@param back boolean
---@param path string
---@param state hand_state
local get_objects = lume.memoize(function (back, path, state)
    local img = love.graphics.newImage(path)
    local state_count = #lume.keys(M.STATE)
    local quad = love.graphics.newQuad((state-1) * (img:getWidth()/state_count), 0, img:getWidth()/state_count, img:getHeight(), img)
    return img, quad
end)

---@param back boolean
---@param a Actor
M.draw = function (back, a)
    local hands = a.hands
    if not hands then
        return
    end
    
    for _, hand in pairs(hands) do
        -- hand.r = hand.r + math.rad(1)
        if back == hand.back then
            -- get sprite
            local img, quad = get_objects(back, hand.path or assets.hand, hand.state)
            
            push()
            -- transform
            if a.off then
                translate(a.off.x, a.off.y)
            end
            scale(0.8)
            rotate(hand.r - math.rad(90))
            translate(-img:getWidth()/state_count, -img:getHeight())
            translate(0, hand.dist)
            draw(img, quad)
            pop()
        end
    end
end

return M