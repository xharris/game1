local api = require 'api'
local baton = require 'lib.baton'
local actors = require 'actors'
local animation = require 'animation'

local render_level_tile = require 'render.level_tile'
local render_sprite = require 'render.sprite'
local render_hands = require 'render.hands'

local idx = 1

local swing_sword = {
    -- up
    {
        {
            step = 3, snap = 0.05, bias = 2.5, duration = 0.1,
            target = {
                r = -math.rad(45+90),
            },
        },
    },
    -- down
    {
        {
            step = 3, snap = 0.05, bias = 2.5, duration = 0.1,
            target = {
                r = -math.rad(45),
            },
        },
    },
}

local input = baton.new{
    controls = {
        go = {'key:space'},
        move_in = {'key:='},
        move_out = {'key:-'}
    }
}

---@type Actor
local player

local zoom = 1

---@type State
return {
    load = function ()
        api.renderers = {
            render_level_tile.draw,
            lume.fn(render_hands.draw, true),
            render_sprite.draw,
            lume.fn(render_hands.draw, false),
        }

        player = api.actor.add(actors.player(1))
        player.hands.right.item = actors.sword().sprite
        player.alt = nil
    end,

    update = function (dt)
        if input:pressed 'go' then
            log.debug('go')
            -- replay animation
            animation.animate(
                api.key(player.id, 'swing sword'),
                player.hands.right,
                swing_sword[idx]
            )
            idx = idx + 1
            idx = (idx - 1) % #swing_sword + 1
        end

        if input:down 'move_in' then
            zoom = zoom + dt * 5
        end
        if input:down 'move_out' then
            zoom = zoom - dt * 5
        end

        api.camera.set_scale(zoom)
        input:update()
        animation.update(dt)
        api.update(dt)
    end,

    draw = function ()
        api.camera.push()
        for _, a in ipairs(game.actors) do
            api.actor.draw(a)
        end
        api.camera.pop()
    end
}