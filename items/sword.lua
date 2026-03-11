---@type ItemModule
local M = {}

local assets = require 'assets'
local timeline = require 'timeline'
local api = require 'api'
local tick = require 'lib.tick'
local hitbox = require 'hitbox'
local anims = require 'animations'
local assets = require 'assets'
local lerp = lume.lerp
local min = math.min

M.name = 'sword'
M.primary_hand = true

local TIPPER = 'sword_tipper'
local NORMAL = 'sword_normal'
local ACTION_SWORD_HIT = 'sword_hit'
local MAX_CHARGE_SPEED = 0.3
local ULT_SPEED = 0.1
local TIPPER_ULT_CHARGE = 25-- 15
local NORMAL_ULT_CHARGE = 25-- 5

M.item = function ()
    return {
        name = M.name,
        cooldown = game.CD.use_item,
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

---@param item Item
local get_speed = function (item)
    local ult_progress = item.data.ult_charge / 100
    return 1 / lerp(1, item.data.ult_active and ULT_SPEED or MAX_CHARGE_SPEED, ult_progress)
end

---@type EvtActorShapeHit
local on_actor_shape_hit = function (action, a, other)
    local owner = api.actor.by_id(a.owner)
    if action == ACTION_SWORD_HIT and owner then
        local item = api.actor.get_item(owner, M.name)


        if item.data.ult_charge >= 100 and not item.data.ult_active then
            -- activate ult
            item.data.ult_active = true

            api.audio.play_from_actor(a, assets.sword_big_hit, {
                volume='sfx',
                pitch=2.5,
                effect='sword_ult_activate',
            })
                
            -- knock back nearby enemies
            
            -- sword breaks into many pieces

            -- no knockback
        end

        if a.name == TIPPER then
            item.data.ult_charge = min(100, item.data.ult_charge + TIPPER_ULT_CHARGE)
        end
        if a.name == NORMAL then
            item.data.ult_charge = min(100, item.data.ult_charge + NORMAL_ULT_CHARGE)
        end
        log.info(a.name, "ult charge", item.data.ult_charge)

        if item.data.ult_charge >= 100 and not item.data.ult_active then
            api.effect.set_delta_mod(0.05, 0.3)
            -- ult is ready animation        
            -- TODO 
            -- bullet time 
            -- glrowing sword
            -- shiny
        end

        api.cd.set(game.CD.use_item / get_speed(item), api.cd.names.use_item, owner.id, item.name)
    end
end

M.equip = function (a, item)
    item.data = {
        ult_charge = 0,
        ult_active = false,
    }
    events.actor.shape_hit.connect(on_actor_shape_hit)
    -- play sound

    -- api.audio.from_actor(a, assets.sword_slice)
    api.audio.play_from_actor(a, assets.sword_slice, { volume='sfx' })
    api.effect.set_delta_mod(0.2, 0.1)
end

local i = 0
M.activate = function (a, item, hand)
    local speed = get_speed(item)
    local knockback_amt = 1
    local knockback_dir = a.aim_dir:rotate(math.rad(lerp(-30, 30, love.math.random())))

    api.actor.knock_back(a, knockback_dir, knockback_amt)
    log.info("activate")

    -- play swing animation
    if hand then
        ---@type RunOptions[]
        local animations = {
            anims.hand_swing_down(a),
            anims.hand_swing_up(a),
        }
        -- determine next swing animation
        local idx = (item._animation_idx or 0) + 1
        idx = (idx - 1) % #animations + 1
        item._animation_idx = idx
        -- play animation
        local anim = animations[idx]
        anim.delta_mod = speed
        timeline.run(anim)
    end

    -- create hitbox(es) halfway through animation
    tick.delay(function ()
        i = i + 1
        local cd_id = ACTION_SWORD_HIT..tostring(i)
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
            size = vec2(18, 18),
            radial = {
                from_angle = aim_angle-math.rad(80),
                to_angle = aim_angle+math.rad(60),
                r = 45,
                segments = 10,
            },
            each = function (h)
                h.name = TIPPER
                h.dmg = 10
                h.shape.action = ACTION_SWORD_HIT
                h.shape.knockback = knockback_amt * 1.2
                h.shape.cd = {id=cd_id, duration=game.INF_TIME}
                -- h.shape.debug = true
                h.remove_after = 0.2
                h.aim_dir = knockback_dir
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
                h.name = NORMAL
                h.dmg = 5
                h.shape.action = ACTION_SWORD_HIT
                h.shape.knockback = knockback_amt * 1.2
                h.shape.cd = {id=cd_id, duration=game.INF_TIME}
                -- h.shape.debug = true
                h.remove_after = 0.2
                h.aim_dir = knockback_dir
                api.actor.add(h)
            end
        }
    end, 0.4 / speed)
end

return M