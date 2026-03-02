local G = {
    DISPLAY = 2,
    FULLSCREEN = false,
    WINDOW_SCALE = 0.5,
    GAME_SCALE = 0.75,

    -- STATE = 'states.play',
    STATE = 'states.animation_test',
    -- STATE = 'states.sound_test',

    SEED = 2,
    LOG_GAME_STATE_ON_ERR = false,

    DRAW_Z_ORDER = false,
    DRAW_AIM_POSITION = false,

    CAMERA_ZOOM = 1.5,
    CAMERA_SMOOTH = 0.1,

    -- big map square section
    LEVEL_CELL_SIZE = vec2(10, 10),
    -- tile in each map cell
    LEVEL_TILE_SIZE = vec2(32, 32),
    TILE_COLORS = {
        '#ffffff', -- ground
        '#03a9f4', -- entrance
        '#8BC34A', -- exit
    },
    LEVEL_ALT = 96,
    ---@enum cell_type
    TILE = {
        none = 0,
        ground = 1,
        entrance = 2,
        exit = 3,
    },
    ---@enum level_theme
    THEME = {
        forest = 'forest',
        castle = 'castle',
    },

    HP = 10,
    PLAYER_ARM_DIST = 8,
    INF_TIME = -100,
    PLAYER_MAX_MOVE_SPEED = 120,

    VOLUME = {
        global = 0.5,
        SFX = 1,
        MUSIC = 0.8,
    },

    ---@type Level[]
    levels = {},

    ---@type Actor[]
    actors = {},
}

---@type NextLevel
G.START_LEVEL = {
    name = 'start',
    theme = G.THEME.forest,
    tiles = {G.TILE.entrance, G.TILE.ground, G.TILE.exit},
    width = 3,
    items = {'sword'},
}

---@type NextLevel[]
G.LEVELS = {
    {
        name = 'forest1',
        theme = G.THEME.forest,
        tiles = {
            1, 1, 1, 1, 1,
            1, 0, 1, 0, 1,
            1, 2, 1, 3, 1,
            0, 0, 1, 0, 1,
            1, 1, 1, 0, 1,
        },
        width = 5,
        items = {'sword'}
    },
}

return G