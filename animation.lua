local M = {}

local tween = require 'lib.tween'

---@class AnimationStep
---@field step? number default `1`. # of visible poses
---@field snap? number default `0`. sharpness
---@field target table<string, Actor>

---@type AnimationStep[]
local swing_sword = {
    {
        target = {
            arm_r = { r = -45 },
        },
    },
    {
        step = 3,
        target = {
            arm_r = { r = 45 },
        },
    },
}

--- (3, 0): hard cuts, (2, 0): stylized
---@param steps number # of visible poses
---@param snap number sharpness (0 = instant hard cut, 1 = small interp window)
local steppedEase = lume.memoize(function(steps, snap)
    steps = math.max(1, steps or 1)
    snap = snap or 0      -- 0 = hard snap

    return function(t)
        -- Which step are we in?
        local stepSize = 1 / steps
        local currentStep = math.floor(t / stepSize)

        -- Clamp final edge case
        if currentStep >= steps then
            return 1
        end

        local stepStart = currentStep * stepSize
        local stepEnd = stepStart + stepSize
        local snapStart = stepEnd - (stepSize * snap)

        -- Hard hold
        if t < snapStart then
            return stepStart
        end

        -- Optional micro-interpolation window
        if snap > 0 then
            local interpT = (t - snapStart) / (stepSize * snap)
            return stepStart + interpT * stepSize
        end

        return stepStart
    end
end)

---@param obj table<string, Actor>
---@param steps any
M.animate = function (obj, steps)
    
end

return M