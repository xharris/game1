local actors = require 'actors'
local api = require 'api'
local assets = require 'assets'

---@type State
return {
    load = function ()
        api.camera.set_scale(game.CAMERA_ZOOM)

        -- load ground level
        local level_idx = api.level.add('forest', {
            game.TILE.entrance, game.TILE.ground, game.TILE.exit,
        }, 3)

        -- add player 
        local player = api.actor.add(actors.player(1))
        player.stunned = true
        api.level.enter(level_idx, player)
        
        -- add big tree
        local x, y, w, h = api.level.get_tile_bbox(1, level_idx)
        local big_tree = api.actor.add{
            pos = vec2(x + (w/2), y + (h/2)),
            sprite = {
                path = assets.large_tree,
                frame = 1,
                frames = vec2(1, 1),
                off = vec2(32, 32),
            },
        }
        api.level.enter(level_idx, big_tree)
    end,

    update = function (dt)
        api.camera.set_scale(game.CAMERA_ZOOM)
    end,

    draw = function ()
        api.draw()
    end
}