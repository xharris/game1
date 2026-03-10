local M = {}

local mui = require 'lib.mui'
local assets = require 'assets'
local render_hands = require 'render.hands'

local clone = lume.clone

---@param player number
M.player = function (player)
    ---@type Actor
    return {
        name = 'PLAYER'..tostring(player),
        group = 'player',
        z = 25 - 16,
        y_sort = true,
        player = player,
        pos = vec2(),
        vel = vec2(),
        move_dir = vec2(),
        max_move_speed = game.PLAYER_MAX_MOVE_SPEED,
        mass = 10,
        hp = game.HP,
        alt = 0,
        vibration = {
            amt = 0,
        },
        inventory = {capacity=1, items={}},
        cam_follow = {
            aim_dir_offset = true,
            move_dir_offset = true,
        },
        dmg = 5, -- player should do some damage when colliding with enemies
        shape = {
            tag = 'body',
            pos = vec2(-4, 0),
            size = vec2(8, 8),
            -- debug = true,
        },
        range = 48,
        light = {
            color = mui.WHITE,
            radius = 600, -- 300,
        },
        faction = 'human',
        breadcrumbs = {capacity=4, cd=0.2, points={}},
        sprite = {
            path = assets.player,
            rows_cols = assets.player_rows_cols,
            progress = 0,
            frames = assets.player_frames.idle,
            off = vec2(16, 16),
        },
        scale = vec2(2, 2),
        hands = {
            left = {
                dist = game.PLAYER_ARM_DIST,
                animated_arm_r =math.rad(45),
                arm_r = 0,
                state = render_hands.STATE.neutral,
                layer = render_hands.LAYER.front_2,
                item_layer = render_hands.LAYER.back_2,
                sprite = {
                    path = assets.hand,
                    rows_cols = vec2(3, 1),
                    progress = 0,
                    frames = assets.hand_frames.idle,
                    off = vec2(8, 8),
                    scale = vec2(0.8, 0.8),
                    r = math.rad(0),
                },
            },
            right = {
                dist = game.PLAYER_ARM_DIST,
                animated_arm_r = -math.rad(45),
                arm_r = 0, -- controlled by aim_dir
                state = render_hands.STATE.neutral,
                layer = render_hands.LAYER.back_1,
                item_layer = render_hands.LAYER.front_1,
                sprite = {
                    path = assets.hand,
                    rows_cols = vec2(3, 1),
                    progress = 0,
                    frames = assets.hand_frames.idle,
                    off = vec2(8, 8),
                    scale = vec2(0.8, 0.8),
                    r = math.rad(0),
                },
            },
        }
    }
end

M.slime = function ()
    ---@type Actor
    return {
        name = 'SLIME',
        group = 'enemy',
        z = 10,
        y_sort = true,
        enemy = 'slime',
        pos = vec2(),
        vel = vec2(),
        move_dir = vec2(),
        max_move_speed = 150,
        mass = 10,
        map_path = {},
        hp = game.HP,
        shape = {
            tag = 'body',
            pos = vec2(-16, 0),
            size = vec2(32, 16),
            knockback = 500,
        },
        ai = {
            vision_radius = 400,
            breadcrumb_radius = 800,
        },
        faction = 'wild_aggro',
        hates = {'human'},
        sprite = {
            path = assets.slime,
            rows_cols = assets.slime_rows_cols,
            frames = assets.slime_frames.neutral,
            progress = 0,
        }
    }
end

M.training_dummy = function ()
    ---@type Actor
    return {
        name = 'TRAINING_DUMMY',
        z = 25 - 16,
        y_sort = true,
        pos = vec2(),
        vel = vec2(),
        move_dir = vec2(),
        max_move_speed = 10,
        mass = 10,
        map_path = {},
        shape = {
            tag = 'body',
            pos = vec2(-4, 0),
            size = vec2(8, 8),
            -- debug = true,
            knockback = 500,
        },
        ai = {
            vision_radius = 400,
            breadcrumb_radius = 800,
        },
        faction = 'robot',
        hates = {'human'},
        scale = vec2(2, 2),
        sprite = {
            path = assets.dummy,
            rows_cols = assets.dummy_rows_cols,
            frames = assets.dummy_frames.idle,
            progress = 0,
            off = vec2(16, 16),
        }
    }
end

---@param item Item
---@param sprite Sprite
M.item = function (item, sprite)
    ---@type Actor
    return {
        group = 'item',
        name = item.name,
        z = 10,
        y_sort = true,
        item = clone(item),
        pos = vec2(),
        shape = {
            tag = 'area',
            pos = vec2(-8, -8),
            size = vec2(16, 16),
            debug = false,
        },
        sprite = sprite,
        status_effects = {
            invincible = game.INF_TIME,
        },
    }
end

--[[

state = 'sleeping',
status_effects = {
    move_stunned = 3, -- 3 sec left
    aim_stunned = 3,
    poisoned = 5.5,
    burning = 1
}

]]

return M 