local api = require 'api'
local baton = require 'lib.baton'
local actors = require 'actors'

local render_level_tile = require 'render.level_tile'
local render_sprite = require 'render.sprite'
local render_hands = require 'render.hands'

local input = baton.new{
    go = {'key:space'}
}

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

        local player = api.actor.add(actors.player(1))
        player.alt = nil
    end,

    update = function (dt)
        input:update()

        if input:pressed 'go' then
            -- replay animation
            
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