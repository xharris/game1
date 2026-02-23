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
---@field target table<string, any>
---@field wait? boolean

---@class Tween
---@field name string
---@field subject Actor
---@field steps AnimationStep[]
---@field tweens any[]
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

---@param twn Tween
local do_next_step = function (twn)
    local wait = false
    local all_done = #twn.steps == 0
    while #twn.steps > 0 and not wait do
        local step = twn.steps[1]
        table.remove(twn.steps, 1)
        if step.wait then
            wait = true
        end
        local create_tween = function ()
            local new_tween = tween.new(
                step.duration == 0 and 0.0001 or step.duration,
                twn.subject,
                step.target,
                ease(step.ease or 1)
                -- steppedEase(step.step, step.snap, step.bias)
            )
            lume.push(twn.tweens, new_tween)
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
                if running_tween:update(dt) then
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