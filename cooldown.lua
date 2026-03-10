local M = {}

local tick = require 'lib.tick'

---@enum cooldown_name
M.names = {
    -- me.id, src.id
    take_damage = 'take_damage',
    -- me.id
    knockback = 'knockback',
    -- me.id
    chase_enemy = 'chase_enemy',
    -- me.id
    leave_breadcrumb = 'leave_breadcrumb',
    -- <no-args>
    update_walkable = 'update_walkable',
    -- me.id
    pick_up_item = 'pick_up_item',
    -- me.id, item.name
    use_item = 'use_item',
    -- me.id, other.id, shape.cd.id
    collision = 'collision'
}

local cd_timers = {}
local cd_inf = {}

---@param ... any
local key = lume.memoize(function (...)
    local id = {}
    for _, prop in ipairs{...} do
        lume.push(id, tostring(prop))
    end
    return table.concat(id, '_')
end)

---@param duration number
---@param name cooldown_name
---@param ... string actor_ids
M.use = function (duration, name, ...)
    local k = key(name, ...)
    local timer = cd_timers[k]
    if not timer then
        if duration == game.INF_TIME then
            -- never come off cooldown
            cd_inf[name] = true
            return true
        end
        if duration > 0 then
            -- wait x sec
            cd_timers[k] = tick.delay(function ()
                cd_timers[k] = nil
            end, duration)
        end
        return true
    end
    return false
end

M.set = function (duration, name, ...)
    local k = key(name, ...)
    local timer = cd_timers[k]
    if timer then
        timer:stop()
        -- log.debug(duration, "sec <- use", name, ...)
    end
    if duration > 0 then
        cd_timers[k] = tick.delay(function ()
            -- log.debug(name, "off cooldown")
            cd_timers[k] = nil
        end, duration)
    end
    if duration == game.INF_TIME then
        cd_inf[name] = true
    end
end

---@param name string
---@param ... string actor_ids
M.reset = function (name, ...)
    log.debug("reset", name, ...)
    local k = key(name, ...)
    local timer = cd_timers[k]
    if timer then
        timer:stop()
        -- dont fully reset to make things feel more natural, like auto reset
        M.set(game.CD.reset, name, ...)
        -- cd_timers[k] = nil
    end
    if cd_inf[k] then
        cd_inf[k] = nil
    end
end

return M