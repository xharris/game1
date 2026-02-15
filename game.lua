return {
    maze = {
        trap_count = 2,
        width = 5,
        --[[
        1: ground
        2: exits/entrance(s)
        3: trap (auto-placed)
        ]]
        tile_colors = {
            '#ffffff', -- ground
            '#03a9f4', -- entrance/exit
        },
        tiles = {
            0, 1, 1, 1, 2,
            2, 0, 1, 0, 0,
            1, 1, 1, 0, 1,
            0, 0, 1, 0, 1,
            2, 1, 1, 1, 2,
        },
        tile_size = 128,
        ---@type number[] tile index
        entrances = {},
        ---@type number[] tile index
        exits = {},
    },
    players = {
        {
            pos = vec2(),
            vel = vec2(),
            move_dir = vec2(),
            max_move_speed = 200,
            mass = 10,
        }
    },
    enemies = {
        {
            pos = vec2(),
            vel = vec2(),
            move_dir = vec2(),
            max_move_speed = 200,
            mass = 10,
        }
    },
    traps = {'poison_gas'}
}