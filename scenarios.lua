local M = {}

---@alias Scenario fun(level_idx:number, level:NextLevel) used to set up level being created

local api = require 'api'
local filters = require 'actor_filters'
local actors = require 'actors'
local assets = require 'assets'

local randomchoice = lume.randomchoice

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
M.turn_rand_entrance_into_exit = function (level_idx, level)
    local tiles = api.level.get_cells(level_idx)
    local exits = filters.apply(tiles, {filters.cell_of_type(game.CELL.exit)})
    local exit
    if #exits > 0 then
        exit = randomchoice(exits)
    else
        exit = randomchoice(filters.apply(tiles, {filters.cell_of_type(game.CELL.entrance)}))
    end
    local exit_tile = tiles[exit]
    exit_tile.level_cell.type = 3
    local level_exit = api.actor.add{
        name = 'LEVEL_EXIT',
        pos = exit_tile.pos + (api.level.cell_size() / 2),
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
        z = exit_tile.z + 10,
        y_sort = true,
    }
    log.debug('add level exit', level_exit.pos)
end

return M