local M = {}

local filter = lume.filter
local randomchoice = lume.randomchoice

---@alias ActorFilter fun(a:Actor):boolean

---@param actors Actor[]
---@param filters? ActorFilter[]
M.apply = function (actors, filters)
    if filters then
        for _, f in ipairs(filters) do
            actors = filter(actors, f)
        end
    end
    return actors
end

---@param actors Actor[]
---@param filters? ActorFilter[]
M.randomchoice = function (actors, filters)
    actors = M.apply(actors, filters)
    return randomchoice(actors)
end

M.noop = function ()
    ---@type ActorFilter
    return function (a)
        return true
    end
end

---@param cell cell_type
M.cell_of_type = function (cell)
    ---@type ActorFilter
    return function (a)
        return a.level_cell ~= nil and a.level_cell.type == cell
    end
end

---@param level_idx? number
---@param cell_type? cell_type
M.level_cell = function (level_idx, cell_type)
    ---@type ActorFilter
    return function (a)
        local cell = a.level_cell
        return 
            cell ~= nil and
            (not level_idx or cell.level == level_idx) and
            (not cell_type or cell.type == cell_type)
    end
end

return M