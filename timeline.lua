local M = {}

local tick = require 'lib.tick'

local ripairs = lume.ripairs

---@class TimelineStep
---@field delay? number
---@field duration? number nil means instant
---@field tick fun(t:number) t is [0,1] where 0 is start of step and 1 is end of step (`duration` reached)

---@class ActiveTimeline
---@field key string
---@field opts RunOptions
---@field steps TimelineStep[]
---@field dt number
---@field delay_timer? any
---@field delay_done? boolean

---@class RunOptions
---@field key string
---@field steps TimelineStep[]
---@field delta_mod? number

M.lerp = lume.lerp

---@type ActiveTimeline[]
local running = {}

---@param opts RunOptions
M.run = function (opts)
    -- remove already running with same key
    for i, active in ripairs(running) do
        if active.key == opts.key then
            table.remove(running, i)
            if active.delay_timer then
                active.delay_timer:stop()
            end
        end
    end
    -- add to running list
    lume.push(running, {
        key = opts.key,
        steps = opts.steps,
        dt = 0,
        opts = opts,
    } --[[@as ActiveTimeline]])
    return
end

M.update = function (dt)
    for i, active in ripairs(running) do
        if active.delay_timer and not active.delay_done then
            -- wait for delay
            
        elseif #active.steps > 0 then
            -- run current step
            local step = active.steps[1]
            local done = false
            if step.delay and not active.delay_done then
                log.debug("delay", step)
                -- wait a sec
                active.delay_done = false
                active.delay_timer = tick.delay(function ()
                    log.debug("delay done")
                    active.delay_timer = nil
                    active.delay_done = true
                end, step.delay)
            elseif step.duration then
                if active.dt == 0 then
                    log.debug("do step", step)
                end
                -- tick for duration
                active.dt = active.dt + dt
                step.tick(active.dt / step.duration)
                if active.dt > step.duration then
                    done = true
                end
            else
                log.debug("do step now", step)
                -- no duration, run immediately
                step.tick(1)
                done = true
            end
            if done then
                -- done, remove step
                active.dt = 0
                active.delay_done = false
                active.delay_timer = nil
                table.remove(active.steps, 1)
            end
        else
            -- nothing to do
            table.remove(running, i)
        end
    end
end

return M