local M = {}

M.HP = 10

---@param player number
M.player = function (player)
    ---@type Actor
    return {
        player = player,
        pos = vec2(),
        vel = vec2(),
        move_dir = vec2(),
        max_move_speed = 200,
        mass = 10,
        hp = M.HP,
    }
end

---@return Actor
M.slime = function ()
    return {
        enemy = 'slime',
        pos = vec2(),
        vel = vec2(),
        move_dir = vec2(),
        max_move_speed = 200,
        mass = 10,
        map_path = {},
        hp = M.HP,
        dmg = M.HP,
        -- tile_path pathing in tile grid
    }
end

return M 