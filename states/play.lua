local actors = require 'actors'
local api = require 'api'

---@type State
return {
    load = function ()
        api.camera.set_scale(game.CAMERA_ZOOM)

        -- load level 1
        local level_idx = api.level.add('forest')

        -- add player to level
        api.level.enter(level_idx, api.actor.add(actors.player(1)))
    end,

    update = function (dt)
        api.camera.set_scale(game.CAMERA_ZOOM)
    end,

    draw = function ()
        api.draw()
    end
}