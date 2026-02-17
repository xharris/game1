return {
    seed = 1,
    maze = {
        trap_count = 2,
        width = 5,
        tile_colors = {
            '#ffffff', -- ground
            '#03a9f4', -- entrance
            '#8BC34A', -- exit
        },
        ---@enum TILE
        TILE = {
            none = 0,
            ground = 1,
            entrance = 2,
            exit = 3,
        },
        ---@type TILE[]
        tiles = {
            0, 1, 1, 1, 2,
            2, 0, 1, 0, 0,
            1, 1, 1, 0, 1,
            0, 0, 1, 0, 1,
            2, 1, 1, 1, 2,
        },
        tile_size = 128,
        traps = {'poison_gas'},
    },
    ---@type Actor[]
    actors = {},
}