---@type ItemModule
local M = {}

local assets = require 'assets'
local animation = require 'animation'
local api = require 'api'
local tick = require 'lib.tick'
local hitbox = require 'hitbox'
local anims = require 'animations'
local assets = require 'assets'
local math2 = require 'lib.math2'

M.hold_in_hand = true

M.item = function ()
    return {
        name='SWORD',
        cooldown = 1,
    }
end

M.sprite = function ()
    ---@type Sprite
    return {
        path = assets.sword,
        frame = 1,
        frames = vec2(1, 1),
        off = vec2(32, 44),
        scale = vec2(0.75, 0.75),
        debug = true,
        points = {
            { x=32, y=18 } -- tip of sword TODO add visuals
        }
    }
end

-- local swing_animations = {
--     {a.hand_swing_down(0), a.hand_swing_up(1)},
--     {a.hand_swing_up(0), a.hand_swing_down(1)},
-- }

M.equip = function (a, item)
    -- play sound
    api.audio.play_from_actor(a, assets.sword_slice)
    for _, b in ipairs(game.actors) do
        local b_ref = b
        -- slow everything down for a sec
        b.delta_mod = 0.2
        tick.delay(function ()
            -- reset
            b_ref.delta_mod = 1
        end, 0.8)
    end
end

M.activate = function (a, item, hand)
    -- play swing animation
    if hand then
        local animations = {
            anims.hand_swing_down(a),
            anims.hand_swing_up(a),
        }
        -- determine next swing animation
        local idx = (item._animation_idx or 0) + 1
        idx = (idx - 1) % #animations + 1
        item._animation_idx = idx
        -- play animation
        animation.timeline(animations[idx])
    end

    -- create hitbox(es) halfway through animation
    local hitboxes = {}
    tick.delay(function ()
        local aim_angle
        if a.aim_dir.x < 0 then
            aim_angle = a.aim_dir:heading() + math.rad(20)
        else
            aim_angle = a.aim_dir:heading()
        end

        -- tipper hitboxes
        hitbox.create{
            pos = a.pos + vec2(8, 8),
            vel = a.vel,
            size = vec2(20, 20),
            radial = {
                from_angle = aim_angle-math.rad(80),
                to_angle = aim_angle+math.rad(60),
                r = 45,
                segments = 10,
            },
            each = function (h)
                h.owner = a.id
                h.dmg = 10
                h.shape.knockback = 500
                h.shape.cd = 5
                h.shape.debug = false
                h.remove_after = 0.2
                api.actor.add(h)
            end
        }
        -- create normal hitbox
        hitbox.create{
            pos = a.pos + vec2(12, 12),
            vel = a.vel,
            size = vec2(40, 40),
            radial = {
                from_angle = aim_angle-math.rad(80),
                to_angle = aim_angle+math.rad(60),
                r = 25,
                segments = 10,
            },
            each = function (h)
                h.owner = a.id
                h.dmg = 5
                h.shape.knockback = 300
                h.shape.cd = 5
                h.shape.debug = false
                h.remove_after = 0.2
                api.actor.add(h)
            end
        }
    end, 0.2)
end

return M