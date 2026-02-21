return {
    SEED = 2,
    LOG_GAME_STATE_ON_ERR = false,

    CAMERA_ZOOM = 1.75,
    -- big map square section
    LEVEL_CELL_SIZE = vec2(10, 10),
    -- tile in each map cell
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
    ---@type Actor[]
    actors = {},
}