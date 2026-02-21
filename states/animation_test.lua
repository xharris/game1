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
            step = 3,
            snap = 0.05,
            duration = 0.1,
            target = {
                r = -math.rad(45+90),
            },
        },
    },
    -- down
    {
        {
            step = 3,
            snap = 0.05,
            duration = 0.2,
            target = {
                r = -math.rad(45),
            },
        },
    },
}

local input = baton.new{
    controls = {
        go = {'key:space'}
    }
}

---@type Actor
local player

---@type State
return {
    load = function ()
        api.camera.set_scale(3, 3)

        api.renderers = {
            render_level_tile.draw,
            lume.fn(render_hands.draw, true),
            render_sprite.draw,
            lume.fn(render_hands.draw, false),
        }

        player = api.actor.add(actors.player(1))
        player.alt = nil
    end,

    update = function (dt)
        input:update()
        animation.update(dt)

        if input:pressed 'go' then
            -- replay animation
            log.info('play animation', idx)
            animation.animate(
                api.key(player.id, 'swing sword'),
                player.hands.right,
                swing_sword[idx]
            )
            idx = idx + 1
            idx = (idx - 1) % #swing_sword + 1
        end

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