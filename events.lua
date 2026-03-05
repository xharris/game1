local M = {}

---@class EvtConnetion
---@field fn function
---@field once? boolean

local ripairs = lume.ripairs

---@param name string
local event = function (name)
    ---@type EvtConnetion[]
    local conns = {}

    ---@type table<function, boolean>
    local is_connected = {}

    return {
        emit = function (...)
            for i, c in ripairs(conns) do
                c.fn(...)
                if c.once then
                    table.remove(conns, i)
                end
            end
        end,

        ---@param fn function
        ---@param once? boolean
        connect = function (fn, once)
            if not is_connected[fn] then
                -- log.debug('connect', name, 'once?', once)
                lume.push(conns, {
                    fn = fn,
                    once = once,
                })
            end
            is_connected[fn] = true
        end,

        ---@param fn function
        disconnect = function (fn)
            for i, c in ripairs(conns) do
                if c.fn == fn then
                    table.remove(conns, i)
                end
            end
        end
    }
end

M.actor = {
    current_level_changed = event('actor.current_level_changed'), ---@alias EvtActorCurrentLevelChanged fun(a:Actor)
    item_equipped = event('actor.item_equipped'), ---@alias EvtActorItemEquipped fun(a:Actor, item:Item)
}

M.status_effect = {
    applied = event('status_effect.applied'), ---@alias EvtStatusEffectApplied fun(a:Actor, name:StatusEffectName)
    removed = event('status_effect.removed'), ---@alias EvtStatusEffectRemoved fun(a:Actor, name:StatusEffectName)
}

M.level = {
    added = event('level.added'), ---@alias EvtLevelAdded fun(level_idx:number, level:Level, setup:NextLevel)
    entered = event('level.entered') ---@alias EvtLevelEntered fun(level_idx:number, a:Actor)
}

M.game = {
    saving = event('game.saving'), ---@alias EvtGameSaving fun(write:SaveWriteFn)
    loading = event('game.loading'), ---@alias EvtGameLoading fun(load:SaveLoadFn)
}

return M