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

---@param a Actor
M.hand_swing_up_old = function (a)
    ---@type AnimTimelineStep[]
    return {
        {
            name = 'hand_swing_up',
            subject = a.hands.right,
            steps = {
                -- arm lower
                {
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
                },
                -- arm start swing up
                {
                    fn = function ()
                        a.vibration.amt = 0
                        a.hands.right.sprite.progress = 0
                    end
                },
                {
                    duration = 0.2,
                    ease = math2.EASE_OUT,
                    subject = a.vibration,
                    target = {
                        amt = game.VIBRATE.sm,
                    }
                },
                {
                    duration = 0.2,
                    ease = math2.EASE_OUT,
                    wait = true,
                    target = {
                        animated_arm_r = -math.rad(15),
                        sprite = {
                            r = math.rad(180+35),
                        },
                    },
                },
                -- instant swing up
                {
                    wait = true,
                    fn = function ()
                        local right = a.hands.right

                        -- big quick vibrate
                        a.vibration.amt = game.VIBRATE.md
                        -- reset sword animation
                        right.item.progress = 0
                        right.item.frames = assets.sword_frames.swing
                        -- position arm
                        right.dist = 8
                        right.animated_arm_r = -math.rad(40+80)
                        right.sprite.r = math.rad(10)
                        right.layer = hands.LAYER.back_1
                        right.item_layer = hands.LAYER.back_2
                    end
                },
                -- weapon smear
                {
                    duration = 0.4,
                    subject = a.hands.right.item,
                    target = {
                        progress = 1,
                    }
                },
                -- 'recoil'
                {
                    duration = 0.2,
                    subject = a.vibration,
                    target = {
                        amt = 0,
                    }
                },
                {
                    duration = 0.2,
                    ease = math2.EASE_IN,
                    wait = true,
                    target = {
                        animated_arm_r = -math.rad(40+90),
                        sprite = {
                            r = math.rad(0),
                        },
                    },
                },
            },
        }
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

    ---@type RunOptions
    return {
        key = a.id..' hand swing up',
        delta_mod = a.delta_mod,
        steps = {
            {tick=function (t)
                -- lower arm
                right.dist = 6
                right.animated_arm_r = -rad(45)
                right.sprite.r = rad(180+45)
                right.layer = hands.LAYER.front_2
                -- reset item sprite
                right.item_layer = hands.LAYER.front_1
                right.item.progress = 0
                right.item.frames = assets.sword_frames.idle
                a.vibration.amt = 0
            end},
            {duration=0.2, tick=function (t)
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
M.hand_swing_down = function (a)
    ---@type AnimTimelineStep[]
    return {
        {
            name = 'hand_swing_down',
            subject = a.hands.right,
            steps = {
                -- arm raise
                {
                    wait = true,
                    target = {
                        dist = 8,
                        animated_arm_r = -math.rad(40+90),
                        sprite = {
                            r = math.rad(0),
                        },
                        layer = hands.LAYER.back_1,
                        item_layer = hands.LAYER.back_2,
                    },
                    fn = function ()
                        local right = a.hands.right
                        right.dist = 8
                        right.animated_arm_r = -math.rad(40+90)
                        right.sprite.r = math.rad(0)
                        right.layer = hands.LAYER.back_1

                    end
                },
                -- arm start swing down
                {
                    duration = 0,
                    subject = a.vibration,
                    target = {
                        amt = 0,
                    }
                },
                {
                    duration = 0.2,
                    ease = math2.EASE_OUT,
                    subject = a.vibration,
                    target = {
                        amt = game.VIBRATE.sm,
                    }
                },
                {
                    duration = 0.2,
                    ease = math2.EASE_OUT,
                    wait = true,
                    target = {
                        animated_arm_r = -math.rad(40+80),
                        sprite = {
                            r = math.rad(10),
                        },
                    },
                },
                -- instant swing down
                {
                    duration = 0,
                    subject = a.vibration,
                    target = {
                        amt = game.VIBRATE.md,
                    }
                },
                {
                    duration = 0,
                    wait = true,
                    target = {
                        animated_arm_r = -math.rad(15),
                        sprite = {
                            r = math.rad(180+35),
                        },
                        layer = hands.LAYER.front_2,
                        item_layer = hands.LAYER.front_1,
                    },
                },
                -- 'recoil'
                {
                    duration = 0.2,
                    subject = a.vibration,
                    target = {
                        amt = 0,
                    }
                },
                {
                    duration = 0.2,
                    ease = math2.EASE_IN,
                    wait = true,
                    target = {
                        dist = 6,
                        animated_arm_r = -math.rad(5),
                        sprite = {
                            r = math.rad(180+45),
                        },
                    },
                },
            }
        }
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