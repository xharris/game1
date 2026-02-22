---@type ItemModule
local M = {}

local assets = require 'assets'
local animation = require 'animation'
local swing_item = require 'animations.swing_item'
local api = require 'api'
local tick = require 'lib.tick'

local clone = lume.clone

M.hold_in_hand = true

M.item = function ()
    return {
        name='sword',
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

M.activate = function (a, item)
    -- play swing animation_test
    if a.hands and a.hands.right then
        -- next swing animation
        local idx = (item._animation_idx or 0) + 1
        idx = (idx - 1) % #swing_item.steps + 1
        item._animation_idx = idx

        swing_item.animate(a.id, a.hands.right, idx)
    end
    -- create hitbox(es) halfway through animation
    local sword_hitbox
    tick.delay(function ()
        -- create sword dmg+hitbox
        sword_hitbox = api.actor.add{
            owner = a.id,
            pos = a.pos + (a.aim_dir * a.range),
            vel = a.vel,
            dmg = 5,
            shape = {
                tag = 'hit',
                pos=vec2(-16, -16),
                size=vec2(32, 32),
                knockback = 300,
                cd = 5,
            },
            alt = a.alt,
        }
    end, 0.1)
    :after(function ()
        -- remove hitbox at 0.6 sec
        api.actor.remove(sword_hitbox)
    end, 0.1)
end

return M