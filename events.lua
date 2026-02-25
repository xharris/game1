local M = {}

local event = function ()
    return {
        emit = function (...)
        -- TODO    
        end,
        connect = function (fn, once)
            -- TODO
        end,
        disconnect = function (fn)
            -- TODO
        end
    }
end

M.status_effect = {
    applied = event(), ---@alias EvtStatusEffectApplied fun(a:Actor, name:StatusEffectName)
    removed = event(), ---@alias EvtStatusEffectRemoved fun(a:Actor, name:StatusEffectName)
}

return M