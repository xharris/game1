local M = {}

local render_hands = require 'render.hands'

M.hand_idle = function ()
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
M.hand_swing_up = function (duration)
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
M.hand_swing_down = function (duration)
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

return M