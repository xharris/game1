---@type ItemModule
local M = {}

local assets = require 'assets'
local timeline = require 'timeline'
local api = require 'api'
local tick = require 'lib.tick'
local hitbox = require 'hitbox'
local anims = require 'animations'
local assets = require 'assets'
local math2 = require 'lib.math2'

M.name = 'SWORD'
M.primary_hand = true

M.item = function ()
    return {
        name=M.name,
        cooldown = 1,
    }
end

M.sprite = function ()
    ---@type Sprite
    return {
        path = assets.sword,
        rows_cols = assets.sword_rows_cols,
        frames = assets.sword_frames.idle,
        progress = 0,
        off = vec2(32, 44),
        scale = vec2(0.75, 0.75),
        points = {
            { x=32, y=18 } -- tip of sword TODO add visuals
        },
    }
end

---@type EvtActorShapeHit
local on_actor_shape_hit = function (action, a, other)
    local owner = api.actor.by_id(a.owner)
    if action == 'reset_auto_timer' and owner then
        api.cd.reset(api.cd.names.use_item, owner.id, M.name)
    end
end

M.equip = function (a, item)
    events.actor.shape_hit.connect(on_actor_shape_hit)
    -- play sound
    api.audio.play_from_actor(a, assets.sword_slice)
    for _, b in ipairs(game.actors) do
        local b_ref = b
        -- slow everything down for a sec
        b.delta_mod = game.DELTA_MOD.bullet_time
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
        timeline.run(animations[idx])
    end

    -- create hitbox(es) halfway through animation
    tick.delay(function ()
        local aim_angle
        if a.aim_dir.x < 0 then
            aim_angle = a.aim_dir:heading() + math.rad(20)
        else
            aim_angle = a.aim_dir:heading()
        end

        -- tipper hitboxes
        hitbox.create{
            owner = a,
            pos = a.pos + vec2(8, 8),
            size = vec2(15, 15),
            radial = {
                from_angle = aim_angle-math.rad(80),
                to_angle = aim_angle+math.rad(60),
                r = 45,
                segments = 10,
            },
            each = function (h)
                h.name = 'sword_tipper'
                h.dmg = 10
                h.shape.knockback = 80
                h.shape.action = 'reset_auto_timer'
                -- h.shape.debug = true
                h.remove_after = 0.2
                api.actor.add(h)
            end
        }
        -- create normal hitbox
        hitbox.create{
            owner = a,
            pos = a.pos + vec2(12, 12),
            size = vec2(40, 40),
            radial = {
                from_angle = aim_angle-math.rad(80),
                to_angle = aim_angle+math.rad(60),
                r = 25,
                segments = 10,
            },
            each = function (h)
                h.name = 'sword_normal'
                h.dmg = 5
                h.shape.knockback = 200
                -- h.shape.debug = true
                h.remove_after = 0.2
                api.actor.add(h)
            end
        }
    end, 0.2)
end

return M