local M = {}

---@class EvtConnetion
---@field fn function
---@field once? boolean

local ripairs = lume.ripairs

local event = function ()
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

M.status_effect = {
    applied = event(), ---@alias EvtStatusEffectApplied fun(a:Actor, name:StatusEffectName)
    removed = event(), ---@alias EvtStatusEffectRemoved fun(a:Actor, name:StatusEffectName)
}

M.level = {
    added = event(), ---@alias EvtLevelAdded fun(level_idx:number, level:Level)
}

M.item = {
    equipped = event(), ---@alias EvtActorItemEquipped fun(a:Actor, item:Item)
}

return M