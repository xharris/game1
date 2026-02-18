return {
    SEED = 2,

    CAMERA_ZOOM = 0.25,
    LEVEL_CELL_SIZE = vec2(5, 5),
    LEVEL_TILE_SIZE = vec2(32, 32),
    TILE_COLORS = {
        '#ffffff', -- ground
        '#03a9f4', -- entrance
        '#8BC34A', -- exit
    },
    LEVEL_ALT = 600,
    ---@enum TILE
    TILE = {
        none = 0,
        ground = 1,
        entrance = 2,
        exit = 3,
    },
    ---@type Level[]
    levels = {},

    maze = {
        trap_count = 2,
        width = 5,
        tile_colors = {
            '#ffffff', -- ground
            '#03a9f4', -- entrance
            '#8BC34A', -- exit
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