local M = {}

---@alias Scenario fun(level_idx:number, level:NextLevel) used to set up level being created

local api = require 'api'
local filters = require 'actor_filters'
local actors = require 'actors'
local assets = require 'assets'
local events = require 'events'

local randomchoice = lume.randomchoice

---@type EvtLevelAdded
local level_added = function (level_idx, _, setup)
    for _, name in ipairs(setup.scenarios) do
        ---@type Scenario?
        local s = M[name]
        if s then
            log.info('apply scenario', name)
            s(level_idx, setup)
        else
            log.warn('missing scenario', name)
        end
    end
end

M.load = function ()
    events.level.added.connect(level_added)
end

---@type Scenario
M.big_tree_at_entrance = function (level_idx, level)
    local start_cell = api.level.get_cell(level_idx, 1)
    local cell_size = api.level.cell_size()
    local big_tree = api.actor.add{
        name = 'BIG_TREE',
        z = 58 - 60,
        y_sort = true,
        pos = start_cell.pos + (cell_size / 2),
        sprite = {
            path = assets.large_tree,
            frame = 1,
            frames = vec2(1, 1),
            off = vec2(32, 60),
            scale = vec2(3, 3),
        },
    }
    api.level.enter(level_idx, big_tree)
end

---@type Scenario
M.item_near_entrance = function (level_idx, level)
    ---@type Actor[]
    local items = {}

    -- iter all entrances
    local cells = api.level.get_cells(level_idx)
    local entrances = filters.apply(cells, {filters.level_cell(level_idx, game.CELL.entrance)})
    for _, entrance in ipairs(entrances) do
        -- get a random item that can spawn in this level
        local item_name = randomchoice(level.items)
        if item_name then
            ---@type ItemModule
            local item_mod = require('items.'..item_name)
            local item = api.actor.add(actors.item(item_mod.item(), item_mod.sprite()))
            lume.push(items, item)
            -- get nearby ground cell
            local cell = filters.randomchoice(cells, {
                filters.level_cell(level_idx, game.CELL.ground),
                api.filters.near_cell_type(entrance, game.CELL.ground, 4)
            })
            if cell then
                -- place item in cell
                item.pos = cell.pos + (api.level.cell_size() / 2)
                api.level.enter(level_idx, item, {
                    filters.level_cell(level_idx, game.CELL.ground),
                    api.filters.near_cell_type(entrance, game.CELL.ground, 2)
                })
            end
        end
    end

    -- random enemies near items
    for _, item in ipairs(items) do
        
    end
end

---@type Scenario
M.add_exits = function (level_idx, level)
    local tiles = api.level.get_cells(level_idx)
    local exits = filters.apply(tiles, {filters.cell_of_type(game.CELL.exit)})
    ---@type Actor?
    local exit
    if #exits > 0 then
        exit = randomchoice(exits)
    else
        exit = randomchoice(filters.apply(tiles, {filters.cell_of_type(game.CELL.entrance)}))
    end
    -- turn cell into exit
    exit.level_cell.type = 3
    local level_exit = api.actor.add{
        name = 'LEVEL_EXIT',
        pos = exit.pos + (api.level.cell_size() / 2),
        level_exit = randomchoice(game.LEVELS),
        shape = {
            tag = 'area',
            pos = vec2(),
            size = vec2(32, 32),
        },
        sprite = {
            frame = 1,
            frames = vec2(1, 1),
            off = vec2(32, 32),
            path = assets.stairs,
        },
        alt = api.level.get_alt(level_idx),
        z = exit.z + 10,
        y_sort = true,
    }
    log.info('spawn level exit', exit.pos, level_exit.pos)
end

return M