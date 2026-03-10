local api = require 'api'
local baton = require 'lib.baton'
local actors = require 'actors'
local a = require 'animations'
local animation = require 'animation'
local math2 = require 'lib.math2'
local timeline = require 'timeline'

local sword = require 'items.sword'

local input = baton.new{
    controls = {
        go = {'key:space'},
        move_in = {'key:='},
        move_out = {'key:-'}
    }
}

---@type Actor
local player

local zoom = 2

local animation_idx = 1

---@type State
return {
    load = function ()
        player = api.actor.add(actors.player(1))
        player.cam_follow = nil
        api.actor.add_to_inventory(player, sword.item())
    end,

    update = function (dt)
        input:update()
        if input:pressed 'go' then
            log.info('reload modules')
            lume.hotswap('items.sword')
            lume.hotswap('animations')
            local animations = {
                a.hand_swing_up(player),
                a.hand_swing_down(player),
            }
            animation_idx = math2.wrap(animation_idx + 1, 1, #animations+1)
            log.info('play animation', animation_idx)
            timeline.run(animations[animation_idx])
        end
        if input:down 'move_in' then
            zoom = zoom + 0.2 * dt
        end
        if input:down 'move_out' then
            zoom = zoom - 0.2 * dt
        end

        api.camera.get().zoom = zoom
    end,

    draw = function ()
        api.camera.push()
        for _, a in ipairs(game.actors) do
            api.actor.draw(a)
        end
        api.camera.pop()
    end
}