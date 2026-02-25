local actors = require 'actors'
local api = require 'api'
local assets = require 'assets'
local animation = require 'animation'
local anims = require 'animations'

---@type EvtStatusEffectApplied
local status_effect_applied = function (a, name)
    if name == 'sleeping' then
        animation.timeline(anims.sit(a, true))
    end
end

---@type EvtStatusEffectRemoved
local status_effect_removed = function (a, name)
    if name == 'sleeping' then
        animation.timeline(anims.stand(a), anims.hand_idle())
    end
end

---@type State
return {
    load = function ()
        events.status_effect.applied.connect(status_effect_applied)
        events.status_effect.removed.connect(status_effect_removed)

        api.camera.set_scale(game.CAMERA_ZOOM)

        -- load ground level
        local level_idx = api.level.add('forest', {
            game.TILE.entrance, game.TILE.ground, game.TILE.exit,
        }, 3)

        -- add player 
        local player = api.actor.add(actors.player(1))
        player.stunned = true
        api.level.enter(level_idx, player)

        -- player is sitting by tree
        player.pos.x = player.pos.x - 16
        player.scale.x = -math.abs(player.scale.x)
        api.actor.status_effects.apply(player, 'sleeping', game.INF_TIME)
        
        -- add big tree
        local start_cell = api.level.get_cell(level_idx, 1)
        local cell_size = api.level.cell_size()
        local big_tree = api.actor.add{
            pos = start_cell.pos + (cell_size / 2),
            sprite = {
                path = assets.large_tree,
                frame = 1,
                frames = vec2(1, 1),
                off = vec2(32, 60),
                scale = vec2(3, 3),
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