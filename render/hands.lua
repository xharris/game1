local M = {}

---@class Hand
---@field dist number
---@field animated_arm_r number
---@field arm_r number 0 is straight down, -left  +right
---@field layer hand_layer
---@field sprite? Sprite
---@field state? hand_state
---@field item? Sprite
---@field item_layer? hand_layer

---@alias Hands table<string, Hand>

---@class Actor
---@field hands? Hands

local math2 = require 'lib.math2'

local render_sprite = require 'render.sprite'

local transform = math2.transform
local rad = math.rad
local floor = math.floor
local round = math2.round

---@enum hand_state
M.STATE = {
    neutral = 1,
    palm = 2,
    point = 3,
}

---@enum hand_layer
M.LAYER = {
    back_1 = 1,
    back_2 = 2,
    front_1 = 3,
    front_2 = 4,
}

---@param layer hand_layer
---@param a Actor
M.draw = function (layer, a)
    local hands = a.hands
    if not hands then
        return
    end
    
    for _, hand in pairs(hands) do
        -- hand.r = hand.r + math.rad(1)
        local pop_hand = transform(0, hand.dist, hand.arm_r + hand.animated_arm_r, 1, 1, 0, 0)
        if layer == round(hand.layer) then
            -- draw hand
            render_sprite.draw_sprite(hand.sprite)
        end
        -- draw item
        local item = hand.item
        if item and layer == round(hand.item_layer) then
            local pop_item = transform(0, 0, (hand.sprite.r or rad(0)) + rad(90), 1, 1, 0, 0) -- item_img:getWidth()/2, item_img:getHeight()/2)
            render_sprite.draw_sprite(item)
            pop_item()
        end
        pop_hand()
    end
end

return M