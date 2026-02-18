local M = {}

local clone = lume.clone

M.HP = 10

---@param player number
M.player = function (player)
    ---@type Actor
    return {
        group = 'player',
        z = 10,
        player = player,
        pos = vec2(),
        off = -vec2(16, 16),
        vel = vec2(),
        move_dir = vec2(),
        max_move_speed = 300,
        mass = 10,
        hp = M.HP,
        inventory = {capacity=1, items={M.sword().item}},
        shape = {
            tag = 'body',
            pos = vec2(-16, 0),
            size = vec2(32, 16),
        },
        range = 48,
    }
end

M.slime = function ()
    ---@type Actor
    return {
        z = 10,
        enemy = 'slime',
        pos = vec2(),
        off = -vec2(16, 16),
        vel = vec2(),
        move_dir = vec2(),
        max_move_speed = 200,
        mass = 10,
        map_path = {},
        hp = M.HP,
        shape = {
            tag = 'body',
            pos = vec2(-16, 0),
            size = vec2(32, 16),
            knockback = 500,
            cd = 1,
        },
        -- tile_path pathing in tile grid
    }
end

---@param item Item
M.item = function (item)
    ---@type Actor
    return {
        z = 10,
        item = clone(item),
        pos = vec2(),
        off = -vec2(16, 16),
        shape = {
            tag = 'area',
            pos = vec2(-16, -16),
            size = vec2(32, 32),
        },
    }
end

M.sword = function ()
    return M.item{
        name='sword',
        cooldown = 0.2
    }
end

return M 