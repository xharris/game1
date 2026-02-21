local M = {}

local tween = require 'lib.tween'

---@class AnimationStep
---@field t number
---@field immedate? boolean
---@field target table<string, Actor>

---@type AnimationStep[]
local swing_sword = {
    {
        t = 0,
        immediate = true,
        target = {
            arm_r = { r = -45 },
        },
    },
    {
        t = 0.5,
        immedate = true,
        target = {
            arm_r = { r = 45 },
        },
    },
}

---@param obj table<string, Actor>
---@param steps any
M.animate = function (obj, steps)
    
end

return M