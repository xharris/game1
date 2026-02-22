local M = {}

local api = require 'api'
local render_hands = require 'render.hands'
local animation = require 'animation'

M.idle = function ()
    ---@type AnimationStep
    return {
        duration = 0,
        target = {
            dist = 8,
            animated_arm_r = -math.rad(45),
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
M.swing_up = function (duration)
    return {
        duration = duration,
        ease = -5,
        target = {
            dist = 8,
            animated_arm_r = -math.rad(40+90),
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
M.swing_down = function (duration)
    return {
        duration = duration,
        ease = -5,
        target = {
            dist = 6,
            animated_arm_r = -math.rad(5),
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
    {M.swing_down(0), M.swing_up(1)},
    -- down
    {M.swing_up(0), M.swing_down(1)},
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