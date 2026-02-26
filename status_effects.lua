local M = {}

local input = require 'input'

---@alias StatusEffectName 'sleeping'|'stunned'

---@class StatusEffect
---@field apply? fun(a:Actor, time_left:number)
---@field update? fun(a:Actor, dt:number, time_left:number):number? return new time_left
---@field remove? fun(a:Actor)

---@param a Actor
M._key_pressed = function (a, key, scancode, isrepeat)
    if a.sleeping_strength then
        if a.sleeping_strength > 0 then
            a.sleeping_strength = a.sleeping_strength - 10
            log.debug('sleep str', a.sleeping_strength)
        else
            
        end
    end
end

---@param dt number
---@param a Actor
M.update = function (dt, a)
    local status_effs = a.status_effects
    if not status_effs then return end

    for name, time_left in pairs(status_effs) do
        local t = M.effects[name]
        if time_left ~= game.INF_TIME then
            -- reduce time left
            time_left = time_left - dt
        end
        if t and t.update then
            -- tick
            local new_time_left = t.update(a, dt, time_left)
            if new_time_left then
                time_left = new_time_left
            end
        end
        -- update may have already removed the effect; don't resurrect or double-remove
        if not status_effs[name] then
        elseif time_left ~= game.INF_TIME and time_left <= 0 then
            -- status effect expired
            M.remove(a, name)
        else
            status_effs[name] = time_left
        end
    end
end

---@param a Actor
---@param name StatusEffectName
---@param duration number
M.apply = function(a, name, duration)
    if not a.status_effects then
        a.status_effects = {}
    end
    local t = M.effects[name]
    log.debug('apply', name, duration == game.INF_TIME and 'INF_TIME' or duration)
    if t and t.apply then
        t.apply(a, duration)
        events.status_effect.applied.emit(a, name)
    end
    a.status_effects[name] = duration
end

---@param a Actor
---@param name StatusEffectName
M.has = function (a, name)
    return a.status_effects ~= nil and a.status_effects[name] ~= 0
end

---@param a Actor
---@param name StatusEffectName
M.remove = function (a, name)
    if not a.status_effects or not a.status_effects[name] then
        return
    end
    local t = M.effects[name]
    log.debug('remove', name)
    -- status effect expired
    a.status_effects[name] = nil
    if t and t.remove then
        t.remove(a)
        events.status_effect.removed.emit(a, name)
    end
end

---@class Actor
---@field sleeping_strength? number

---@type table<StatusEffectName, StatusEffect>
M.effects = {
    sleeping = {
        apply = function (a, time_left)
            a.sleeping_strength = 50
        end,
        update = function (a, dt, time_left)
            if a.vel then
                a.vel:set(0, 0)
            end
            if a.move_dir then
                a.move_dir:set(0, 0)
            end
            if a.aim_dir then
                a.aim_dir:set(0, 0)
            end
            local strength = a.sleeping_strength
            strength = strength + 2 * dt
            if strength <= 0 then
                -- wake up
                M.remove(a, 'sleeping')
            end
            a.sleeping_strength = strength
        end,
        remove = function (a)
            a.sleeping_strength = nil
        end
    },
}

return M