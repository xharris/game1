local M = {}

local get_time = love.timer.getTime

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

-- stores absolute expiry time, or math.huge for INF_TIME
local cd_timers = {}

---@param ... any
local key = function (...)
    local id = {}
    for _, prop in ipairs{...} do
        lume.push(id, tostring(prop))
    end
    return table.concat(id, '_')
end

---@param duration number
---@param name cooldown_name
---@param ... string actor_ids
M.use = function (duration, name, ...)
    local k = key(name, ...)
    local expiry = cd_timers[k]
    if not expiry or get_time() >= expiry then
        if duration == game.INF_TIME then
            cd_timers[k] = math.huge
        elseif duration > 0 then
            cd_timers[k] = get_time() + duration
        end
        return true
    end
    return false
end

M.set = function (duration, name, ...)
    local k = key(name, ...)
    if duration == game.INF_TIME then
        cd_timers[k] = math.huge
    elseif duration > 0 then
        cd_timers[k] = get_time() + duration
    else
        cd_timers[k] = nil
    end
end

---@param name string
---@param ... string actor_ids
M.reset = function (name, ...)
    log.debug("reset", name, ...)
    local k = key(name, ...)
    if cd_timers[k] then
        -- dont fully reset to make things feel more natural, like auto reset
        M.set(game.CD.reset, name, ...)
    end
end

return M
