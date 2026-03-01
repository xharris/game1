---@type ItemModule
local M = {}

local assets = require 'assets'
local animation = require 'animation'
local api = require 'api'
local tick = require 'lib.tick'
local hitbox = require 'hitbox'
local a = require 'animations'

M.hold_in_hand = true

M.item = function ()
    return {
        name='SWORD',
        cooldown = 1,
    }
end

M.sprite = function ()
    return {
        path = assets.sword,
        frame = 1,
        frames = vec2(1, 1),
        off = vec2(17, 26),
        scale = vec2(0.75, 0.75),
    }
end

local swing_animations = {
    {a.hand_swing_down(0), a.hand_swing_up(1)},
    {a.hand_swing_up(0), a.hand_swing_down(1)},
}

M.equip = function (a, item)
    for _, b in ipairs(game.actors) do
        local b_ref = b
        -- slow everything down for a sec
        b.delta_mod = a.id == b.id and 0.8 or 0.2
        tick.delay(function ()
            -- reset
            b_ref.delta_mod = 1
        end, 1)
    end
end

M.activate = function (a, item, hand)
    -- play swing animation
    if hand then
        -- determine next swing animation
        local idx = (item._animation_idx or 0) + 1
        idx = (idx - 1) % #swing_animations + 1
        item._animation_idx = idx
        -- play animation
        animation.animate(api.key(a.id, 'sword activate'), hand, swing_animations[idx])
    end

    -- create hitbox(es) halfway through animation
    local hitboxes = {}
    tick.delay(function ()
        hitboxes = hitbox.create{
            pos = a.pos + (a.aim_dir * 20),
            vel = a.vel,
            size = vec2(32, 32),
            line = {
                to = a.pos + (a.aim_dir * 60),
                segments = 3,
            },
        }
        -- configure shapes
        for _, h in ipairs(hitboxes) do
            h.owner = a.id
            h.dmg = 5
            h.shape.knockback = 300
            h.shape.cd = 5
            h.shape.debug = true
        end
        api.actor.add_many(hitboxes)
    end, 0.4)
    :after(function ()
        api.actor.remove_many(hitboxes)
    end, 0.5)
end

return M