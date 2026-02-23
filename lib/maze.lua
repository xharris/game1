local M = {}

---@enum maze_dir
M.direction = {
    up = 1,
    down = 2,
    left = 3,
    right = 4,
}

---@param w number
---@param h number
M.prim = function (w, h)
    ---@type maze_dir[][]
    local cells = {}
    
    return cells
end

return M