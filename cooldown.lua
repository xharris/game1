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
}

local cd_timers = {}

---@param ... any
local key = lume.memoize(function (...)
    local id = {}
    for _, prop in ipairs{...} do
        lume.push(id, tostring(prop))
    end
    return table.concat(id, '_')
end)

---@param name cooldown_name
---@param ... string actor_ids
M.use = function (duration, name, ...)
    local k = key(name, ...)
    local timer = cd_timers[k]
    if not timer then
        -- log.debug(duration, "sec <- use", name, ...)
        if duration > 0 then
            cd_timers[k] = tick.delay(function ()
                -- log.debug(name, "off cooldown")
                cd_timers[k] = nil
            end, duration)
        end
        return true
    end
    return false
end

M.set = M.use

---@param name string
---@param ... string actor_ids
M.reset = function (name, ...)
    log.info("reset", name, ...)
    local k = key(name, ...)
    local timer = cd_timers[k]
    if timer then
        timer:stop()
        cd_timers[k] = nil
    end
end

return M