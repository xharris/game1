local M = {}

local api = require 'api'
local render_hands = require 'render.hands'
local animation = require 'animation'

---@param duration number
---@return AnimationStep
local up = function (duration)
    return {
        duration = duration,
        target = {
            dist = 8,
            arm_r = -math.rad(45+90),
            sprite = {
                r = math.rad(0),
            },
            layer = render_hands.LAYER.back_1,
            item_layer = render_hands.LAYER.back_2
        },
    }
end

---@param duration number
---@return AnimationStep
local down = function (duration)
    return {
        duration = duration,
        target = {
            dist = 6,
            arm_r = -math.rad(0),
            sprite = {
                r = math.rad(180+45),
            },
            layer = render_hands.LAYER.front_2,
            item_layer = render_hands.LAYER.front_1,
        },
    }
end

---@type AnimationStep[][]
M.steps = {
    -- up
    {down(0), up(0.25)},
    -- down
    {up(0), down(0.25)},
}

---@param id string
---@param hand Hand
---@param idx number
M.animate = function(id, hand, idx)
    return animation.animate(
        api.key(id, 'swing sword'),
        hand,
        M.steps[idx]
    )
end

return M