local M = {}

---@class Hand
---@field dist number
---@field r number 0 is straight down, -left  +right
---@field back boolean
---@field sprite? Sprite
---@field state? hand_state
---@field item? Sprite

---@alias Hands table<string, Hand>

---@class Actor
---@field hands? Hands

local math2 = require 'lib.math2'

local render_sprite = require 'render.sprite'

local transform = math2.transform

---@enum hand_state
M.STATE = {
    neutral = 1,
    palm = 2,
    point = 3,
}

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
            -- draw hand
            local pop_hand = transform(0, hand.dist, hand.r, 1, 1, 0, 0)
            render_sprite.draw_sprite(hand.sprite)
            -- draw item
            local item = hand.item
            if item then
                local pop_item = transform(0, 0, 0, 1, 1, 0, 0) -- item_img:getWidth()/2, item_img:getHeight()/2)
                render_sprite.draw_sprite(item)
                pop_item()
            end
            pop_hand()
        end
    end
end

return M