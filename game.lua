return {
    DISPLAY = 2,
    FULLSCREEN = false,
    WINDOW_SCALE = 0.5,
    GAME_SCALE = 0.75,

    STATE = 'states.play',
    -- STATE = 'states.animation_test',

    SEED = 2,
    LOG_GAME_STATE_ON_ERR = false,

    CAMERA_ZOOM = 1.5,
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

    HP = 10,
    PLAYER_ARM_DIST = 8,
    INF_TIME = -100,
    
    ---@type Level[]
    levels = {},
    ---@type Actor[]
    actors = {},
}