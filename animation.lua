local M = {}

local tween = require 'lib.tween'

local ripairs = lume.ripairs
local lerp = lume.lerp

---@class AnimationStep
---@field step? number default `1`. # of visible poses
---@field snap? number default `0`. sharpness
---@field bias? number default `1`. >1 ease out, <1 ease in
---@field duration number
---@field target table<string, any>

---@class Tween
---@field name string
---@field subject Actor
---@field steps AnimationStep[]
---@field tween? any
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

---@type Tween[]
local tweens = {}

---@param twn Tween
local do_first_step = function (twn)
    if #twn.steps > 0 then
        local step = twn.steps[1]
        twn.tween = tween.new(
            step.duration == 0 and 0.0001 or step.duration,
            twn.subject,
            step.target
             -- steppedEase(step.step, step.snap, step.bias)
        )
        return true
    end
    return false
end

---@param name string unique name (per actor, per animation)
---@param subject table<string, Actor>
---@param steps any
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
    }
    lume.push(tweens, twn)
end

M.update = function (dt)
    for i, twn in ripairs(tweens) do
        ---@cast i number
        ---@cast twn Tween

        if twn.abort then
            -- done animating
            table.remove(tweens, i)
        else
            local remove = false

            if not twn.tween then
                -- start animation
                remove = not do_first_step(twn)
            end

            if twn.tween then
                -- animate
                local done = twn.tween:update(dt)
                if done then
                    table.remove(twn.steps, 1)
                    remove = not do_first_step(twn)
                end
            end

            if remove then
                -- done animating
                table.remove(tweens, i)
            end
        end
    end
end

return M