local api = require 'api'
local actors = require 'actors'
local sword = require 'items.sword'
local math2 = require 'lib.math2'

local set_color = love.graphics.setColor
local line = love.graphics.line

---@type State
return {
    load = function ()
        api.camera.set_scale(2)
        local player_actor = actors.player(1)
        player_actor.pos:set(-100, 0)
        player_actor.cam_follow = {}
        game.CAMERA_SMOOTH = nil

        api.actor.add(player_actor)
        
        local item_actor = actors.item(sword.item(), sword.sprite())
        item_actor.pos:set(100, 0)
        api.actor.add(item_actor)
    end,

    update = function (dt)

    end,

    draw = function ()
        api.camera.push()
        local pop = math2.transform(0, 0, 0, 1, 1, 0, 0)
        set_color(1,1,1,1)
        line(0, -200, 0, 200)
        line(-200, 0, 200, 0)
        pop()
        api.camera.pop()

        api.draw()
    end
}