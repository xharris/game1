local M = {}

local tween = require 'lib.tween'
local math2 = require 'lib.math2'
local tick = require 'lib.tick'

local ripairs = lume.ripairs
local lerp = lume.lerp
local math2_ease = math2.ease

---@class AnimationStep
---@field ease? number
---@field duration number
---@field delay? number
---@field target? table<string, any>
---@field wait? boolean

---@class Tween
---@field name string
---@field subject Actor
---@field steps AnimationStep[]
---@field tweens fun(dt:number)[]
---@field abort? boolean

--- (3, 0): hard cuts, (2, 0): stylized
---@param steps number # of visible poses
---@param snap number sharpness (0 = instant hard cut, 1 = small interp window)
---@param bias? number >1 ease out, <1 ease in
local steppedEase = lume.memoize(function(steps, snap, bias)
    steps = math.max(1, steps or 1)
    snap = math.max(0, math.min(snap or 0, 1))
    bias = bias or 1  -- 1 = linear spacing

    return function(t, b, c, d)
        if d == 0 then return b + c end

        local u = t / d
        if u >= 1 then return b + c end

        local stepSize = 1 / steps
        local stepIndex = math.floor(u / stepSize)
        local stepStartTime = stepIndex * stepSize
        local stepEndTime = stepStartTime + stepSize

        -- Apply bias to spatial distribution
        local function biasCurve(x)
            return 1 - (1 - x)^bias
        end

        local stepStart = biasCurve(stepStartTime)
        local stepEnd = biasCurve(stepEndTime)

        local snapStart = stepEndTime - (stepSize * snap)

        local progress

        if u < snapStart then
            progress = stepStart
        elseif snap > 0 then
            local interp = (u - snapStart) / (stepSize * snap)
            progress = stepStart + interp * (stepEnd - stepStart)
        else
            progress = stepEnd
        end

        return b + c * progress
    end
end)


local ease = function (ease_c)
    return function(t, b, c, d)
        return b + c * math2_ease(t / d, ease_c)
    end
end

---@type Tween[]
local tweens = {}

local is_animating = {}

---@param subject any
M.is_animating = function (subject)
    return is_animating[subject] and is_animating[subject] > 0
end

local do_next_step

---@param twn Tween
do_next_step = function (twn)
    local wait = false
    local all_done = #twn.steps == 0
    while #twn.steps > 0 and not wait do
        local step = twn.steps[1]
        table.remove(twn.steps, 1)
        if step.wait then
            wait = true
        end
        local create_tween = function ()
            log.debug('do step', twn.name, step.target, step.duration, 'sec')
            is_animating[twn.subject] = (is_animating[twn.subject] or 0) + 1
            if step.target then
                local new_tween = tween.new(
                    step.duration == 0 and 0.0001 or step.duration,
                    twn.subject,
                    step.target,
                    ease(step.ease or 1)
                    -- steppedEase(step.step, step.snap, step.bias)
                )
                lume.push(twn.tweens, lume.fn(new_tween.update, new_tween))
            else
                -- wait without animation
                local done = false
                tick.delay(function ()
                    done = true
                end, step.duration or 0)
                local is_done = function (dt)
                    return done
                end
                lume.push(twn.tweens, is_done)
            end
        end

        if (step.delay or 0) > 0 then
            tick.delay(create_tween, step.delay)
        else
            create_tween()
        end
    end
    return all_done
end

---@param name string unique name (per actor, per animation)
---@param subject table<string, Actor>
---@param steps AnimationStep[]
M.animate = function (name, subject, steps)
    for _, twn in ipairs(tweens) do
        if twn.name == name then
            is_animating[twn.subject] = (is_animating[twn.subject] or 1) - 1
            twn.abort = true
        end
    end
    ---@type Tween
    local twn = {
        name = name,
        steps = {table.unpack(steps)},
        subject = subject,
        tweens = {},
    }
    lume.push(tweens, twn)
    do_next_step(twn)
end

---@class TimelineStep
---@field name string
---@field subject any
---@field steps AnimationStep[]

---@param ... (TimelineStep?)[]
M.timeline = function (...)
    local subject
    for i = 1, select("#", ...) do
        for _, step in ipairs(select(i, ...)) do
            ---@cast step TimelineStep?
            if step and step.subject then
                if subject ~= step.subject then
                    subject = step.subject
                    log.debug('animation subject', subject)
                end
                M.animate(step.name, step.subject, step.steps)
            end
        end
    end
end

M.update = function (dt)
    for i, twn in ripairs(tweens) do
        ---@cast i number
        ---@cast twn Tween

        if twn.abort then
            -- done animating
            table.remove(tweens, i)
        else
            local all_done = true
            for j, running_tween in ripairs(twn.tweens) do
                -- update active tweens
                if running_tween(dt) then
                    table.remove(twn.tweens, j)
                else
                    all_done = false
                end
            end
            if all_done then
                local no_more = do_next_step(twn)
                if no_more then
                    -- done animating
                    table.remove(tweens, i)
                end
            end
        end
    end
end

return M