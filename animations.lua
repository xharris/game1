local M = {}

local hands = require 'render.hands'
local assets = require 'assets'
local math2 = require 'lib.math2'

local rad = math.rad
local lerp = lume.lerp

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
            layer = hands.LAYER.back_1,
            item_layer = hands.LAYER.back_2
        },
    }
end

M.player_hand_idle = function (a)
    ---@type TimelineStep[]
    return {

    }
end

---@param a Actor
M.hand_swing_up = function (a)
    local right = a.hands.right

    ---@param v number
    local ease_in = function (v)
        return math2.ease(v, math2.EASE_OUT)
    end

    ---@type RunOptions
    return {
        key = a.id..' hand swing up',
        delta_mod = a.delta_mod,
        ease = ease_in,
        steps = {
            {tick=function (t)
                -- lower arm
                right.dist = 8
                right.animated_arm_r = -rad(5)
                right.sprite.r = rad(180+45)
                right.layer = hands.LAYER.front_2
                -- reset item sprite
                right.item_layer = hands.LAYER.front_1
                right.item.progress = 0
                right.item.frames = assets.sword_frames.idle
                a.vibration.amt = 0
            end},
            {duration=0.4, tick=function (t)
                -- arm start slow swing up
                right.animated_arm_r = lerp(-rad(5), -rad(15), t)
                right.sprite.r = lerp(rad(180+45), rad(180+35), t)
                -- vibrate a little
                a.vibration.amt = lerp(0, game.VIBRATE.sm, t)
            end},
            {tick=function (t)
                -- quick, big vibrate
                a.vibration.amt = game.VIBRATE.md
                -- position arm
                right.dist = 8
                right.animated_arm_r = -rad(40+80)
                right.sprite.r = rad(10)
                right.layer = hands.LAYER.back_1
                right.item_layer = hands.LAYER.back_2
                -- start weapon smear
                right.item.progress = 0
                right.item.frames = assets.sword_frames.swing
                right.item.scale.x = math.abs(right.item.scale.x)
            end},
            {duration=0.1, tick=function (t)
                a.vibration.amt = 0
                -- animate smear
                right.item.progress = t
                -- recoil
                right.animated_arm_r = lerp(-rad(40+80), -rad(40+90), t)
                right.sprite.r = lerp(rad(10), rad(0), t)
            end}
        },
    }
end

---@param a Actor
M.hand_swing_down = function (a, delta_mod)
    local right = a.hands.right

    ---@type RunOptions
    return {
        key = a.id..' hand swing up',
        delta_mod = a.delta_mod,
        steps = {
            {tick=function (t)
                -- raise arm
                right.dist = 8
                right.animated_arm_r = -math.rad(40+90)
                right.sprite.r = rad(0)
                right.layer = hands.LAYER.back_1
                -- reset item sprite
                right.item_layer = hands.LAYER.back_2
                right.item.progress = 0
                right.item.frames = assets.sword_frames.idle
                a.vibration.amt = 0
            end},
            {duration=0.4, tick=function (t)
                -- arm start slow swing down
                right.animated_arm_r = lerp(-math.rad(40+90), -rad(40+80), t)
                right.sprite.r = lerp(rad(0), rad(10), t)
                -- vibrate a little
                a.vibration.amt = lerp(0, game.VIBRATE.sm, t)
            end},
            {tick=function (t)
                -- quick, big vibrate
                a.vibration.amt = game.VIBRATE.md
                -- position arm
                right.dist = 8
                right.animated_arm_r = -rad(15)
                right.sprite.r = rad(180+35)
                right.layer = hands.LAYER.front_2
                right.item_layer = hands.LAYER.front_1
                -- start weapon smear
                right.item.progress = 0
                right.item.frames = assets.sword_frames.swing
                right.item.scale.x = -math.abs(right.item.scale.x)
            end},
            {duration=0.1, tick=function (t)
                a.vibration.amt = 0
                -- animate smear
                right.item.progress = t
                -- recoil
                right.animated_arm_r = lerp(-rad(15), -rad(5), t)
                right.sprite.r = lerp(rad(180+35), rad(180+45), t)
            end}
        },
    }
end

---@param a Actor
---@param close_eyes? boolean
M.sit = function (a, close_eyes)
    ---@type AnimTimelineStep[]
    return {
        {
            name = 'hands_sit',
            subject = a.hands,
            steps = {
                {
                    duration = 0,
                    target = {
                        left = {
                            sprite = {
                                frame = 2,
                                r = -rad(180),
                                off = {
                                    x = 10,
                                    y = 8,
                                },
                            },
                        },
                        right = {
                            sprite = {
                                frame = 2,
                                r = rad(140),
                                off = {
                                    y = 3,
                                }
                            },
                        },
                    },
                }
            }
        },
        {
            name = 'sprite_sit',
            subject = a.sprite,
            steps = {
                {
                    duration = 0,
                    target = {
                        frame = close_eyes and assets.player_frames.sit_sleep[1] or assets.player_frames.sit[1],
                    }
                }
            }
        },
    }
end

---@param a Actor
M.stand = function (a)
    ---@type AnimTimelineStep[]
    return {
        {
            name = 'hands_stand',
            subject = a.hands,
            steps = {
                {
                    duration = 0,
                    target = {
                        left = {
                            sprite = {
                                frame = 1,
                                off = {
                                    x = 8,
                                    y = 8,
                                },
                            },
                        },
                        right = {
                            dist = game.PLAYER_ARM_DIST,
                            sprite = {
                                frame = 1,
                                off = {
                                    y = 8,
                                }
                            },
                        },
                    },
                }
            }
        },
        {
            name = 'sprite_stand',
            subject = a.sprite,
            steps = {
                {
                    duration = 0,
                    target = {
                        frame = assets.player_frames.idle[1],
                    }
                }
            }
        }
    }
end

return M