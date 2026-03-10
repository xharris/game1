local actors = require 'actors'
local api = require 'api'
local assets = require 'assets'
local animation = require 'animation'
local anims = require 'animations'
local save = require 'save'

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

---@type EvtLevelEntered
local level_entered = function (_, a)
    if a.player then
        save.write()
    end
end

---@class PlaySaveData
---@field players {level?:number, inventory?:Inventory}[]
---@field levels? {name:string}[] NextLevel name

---@type EvtGameSaving
local game_saving = function (write)
    ---@type PlaySaveData
    local data = {
        players = {},
        levels = {},
    }
    -- levels
    for _, level in ipairs(game.levels) do
        lume.push(data.levels, {
            name = level.name,
        })
    end
    -- players
    for _, p in ipairs(api.actor.get_group('player')) do
        data.players[p.player] = {
            level = p.current_level,
            inventory = p.inventory,
        }
    end
    write(data)
end

---@type EvtGameLoading
local game_loading = function (load)
    ---@type PlaySaveData?
    local data = load()
    if not data then return end
    -- levels
    if data.levels then
        for _, level in ipairs(data.levels) do
            -- re-create levels
            local next_level = lume.match(game.LEVELS, function (v)
                return v.name == level.name
            end)
            if not next_level and game.START_LEVEL.name == level.name then
                next_level = game.START_LEVEL
            end
            if next_level then
                api.level.add(next_level)
            end
        end
    end
    -- players
    if data.players then
        for _, p in ipairs(api.actor.get_group('player')) do
            local p_data = data.players[p.player]
            p.inventory = p_data.inventory or p.inventory
            for _, item in ipairs(p.inventory.items) do
                -- re-equip item
                if item.equipped then
                    item.equipped = false
                    api.actor.equip_item(p, item)
                end
            end
            if p_data.level then
                -- place in level
                api.level.enter(p_data.level, p)
            end
        end
    end
end

---@type EvtActorItemEquipped
local actor_item_equipped = function (a, item)
    if a.player then
        save.write()
    end
end

---@type EvtActorCurrentLevelChanged
local actor_current_level_changed = function (a)
    if a.player then
        save.write()
    end
end

---@type State
return {
    load = function ()
        events.status_effect.applied.connect(status_effect_applied)
        events.status_effect.removed.connect(status_effect_removed)
        events.level.entered.connect(level_entered)
        events.game.saving.connect(game_saving)
        events.game.loading.connect(game_loading)
        events.actor.item_equipped.connect(actor_item_equipped)
        events.actor.current_level_changed.connect(actor_current_level_changed)

        api.camera.get().zoom = game.CAMERA_ZOOM

        -- add player 
        local player = api.actor.add(actors.player(1))

        -- load saved game data
        if not save.load() then
            log.info('new game')
            -- new game
            -- load ground level
            local level_idx = api.level.add(game.START_LEVEL)

            api.level.enter(level_idx, player)
            -- ...sitting by tree
            player.pos.x = player.pos.x - 16
            -- ...facing left
            player.scale.x = -math.abs(player.scale.x)
            -- ...sleeping
            -- api.actor.status_effects.apply(player, 'sleeping', game.INF_TIME)
        end
    end,

    update = function (dt)
        local cam = api.camera.get()
        cam.zoom = game.CAMERA_ZOOM
    end,

    draw = function ()
        api.draw()
    end
}