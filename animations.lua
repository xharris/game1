local M = {}

local hands = require 'render.hands'
local assets = require 'assets'

local rad = math.rad

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

---@param duration number
M.hand_swing_up = function (duration)
    ---@type AnimationStep
    return {
        duration = duration,
        ease = -5,
        wait = true,
        target = {
            dist = 8,
            animated_arm_r = -math.rad(40+90),
            sprite = {
                r = math.rad(0),
            },
            layer = hands.LAYER.back_1,
            item_layer = hands.LAYER.back_2
        },
    }
end

---@param duration number
M.hand_swing_down = function (duration)
    ---@type AnimationStep
    return {
        duration = duration,
        ease = -5,
        wait = true,
        target = {
            dist = 6,
            animated_arm_r = -math.rad(5),
            sprite = {
                r = math.rad(180+45),
            },
            layer = hands.LAYER.front_2,
            item_layer = hands.LAYER.front_1,
        },
    }
end

---@param a Actor
---@param close_eyes? boolean
M.sit = function (a, close_eyes)
    ---@type TimelineStep[]
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
                        frame = close_eyes and assets.player_frame.sit_sleep[1] or assets.player_frame.sit[1],
                    }
                }
            }
        },
    }
end

---@param a Actor
M.stand = function (a)
    ---@type TimelineStep[]
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
                        frame = assets.player_frame.idle[1],
                    }
                }
            }
        }
    }
end

return M