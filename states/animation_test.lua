local api = require 'api'
local baton = require 'lib.baton'
local actors = require 'actors'

local rad = math.rad

local sword = require 'items.sword'

local idx = 1
local current_animation = require 'animations.swing_item'

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

---@type State
return {
    load = function ()
        player = api.actor.add(actors.player(1))
        api.actor.add_to_inventory(player, sword.item())
        player.alt = nil
    end,

    update = function (dt)
        if player.aim_dir then
            if player.aim_dir.x < 0 then
                player.hands.right.arm_r = player.aim_dir:heading() + rad(180)
            else
                player.hands.right.arm_r = -player.aim_dir:heading()
            end
        end

        if input:down 'move_in' then
            zoom = zoom + dt * 5
        end
        if input:down 'move_out' then
            zoom = zoom - dt * 5
        end

        api.camera.set_scale(zoom)
        input:update()
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